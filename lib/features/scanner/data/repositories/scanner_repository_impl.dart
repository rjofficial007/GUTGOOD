import 'dart:async';
import 'dart:typed_data';

import 'package:gutgood/core/constants/ai_constants.dart';
import 'package:gutgood/core/data/additive_concern_db.dart';
import 'package:gutgood/core/models/ai_analysis_result.dart';
import 'package:gutgood/core/models/chat_message.dart';
import 'package:gutgood/core/models/off_product.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/services/ai_classifier_service.dart';
import 'package:gutgood/core/services/ai_service.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/domain_event_persister.dart';
import 'package:gutgood/core/services/firestore/chat_firestore_service.dart';
import 'package:gutgood/core/services/firestore/history_firestore_service.dart';
import 'package:gutgood/core/services/notification_service.dart';
import 'package:gutgood/core/services/off_service.dart';
import 'package:gutgood/core/services/prompts.dart';
import 'package:gutgood/core/services/streak_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/model_utils.dart';
import 'package:gutgood/core/utils/narrative_text.dart';
import 'package:gutgood/core/utils/yuka_score.dart';
import 'package:gutgood/features/chat/domain/usecases/process_chat_tag_usecase.dart';
import 'package:gutgood/features/scanner/domain/repositories/scanner_repository.dart';
import 'package:uuid/uuid.dart';

class ScannerRepositoryImpl implements ScannerRepository {
  ScannerRepositoryImpl({
    required OffService offService,
    required AiService aiService,
    required AiClassifierService aiClassifierService,
    required ChatFirestoreService chatFirestoreService,
    required HistoryFirestoreService historyFirestoreService,
    required NotificationService notificationService,
    required AppStateService appStateService,
    required AnalyticsService analyticsService,
    required StreakService streakService,
    required ProcessChatTagUseCase processChatTagUseCase,
    required DomainEventPersister eventPersister,
  }) : _offService = offService,
       _aiService = aiService,
       _aiClassifierService = aiClassifierService,
       _chatFirestoreService = chatFirestoreService,
       _historyFirestoreService = historyFirestoreService,
       _notificationService = notificationService,
       _appStateService = appStateService,
       _analyticsService = analyticsService,
       _streakService = streakService,
       _processChatTagUseCase = processChatTagUseCase,
       _persister = eventPersister;
  final OffService _offService;
  final AiService _aiService;
  final AiClassifierService _aiClassifierService;
  final ChatFirestoreService _chatFirestoreService;
  final HistoryFirestoreService _historyFirestoreService;
  final NotificationService _notificationService;
  final AppStateService _appStateService;
  final AnalyticsService _analyticsService;
  final StreakService _streakService;
  final ProcessChatTagUseCase _processChatTagUseCase;
  final DomainEventPersister _persister;

  @override
  Future<OffProduct?> getProductByBarcode(String barcode) async => _offService.getProduct(barcode);

  @override
  Future<ScanResult?> getCachedBarcodeScan({required String barcode, required List<String> sensitivities}) async {
    if (barcode.isEmpty) return null;
    try {
      final cached = await _historyFirestoreService.getLatestScanByBarcode(barcode);
      if (cached == null) return null;
      if (DateTime.now().difference(cached.createdAt) > ScannerRepository.barcodeCacheMaxAge) {
        AppLogger.ai('ScannerRepository: barcode cache stale for $barcode — running full analysis');
        return null;
      }

      // Engine inputs are persisted verbatim and the engine is deterministic,
      // so a zero-arg re-run reproduces the original score exactly while the
      // explanation is recomposed fresh from the same factors.
      final rescored = _applyEngineScore(cached);
      final turnId = const Uuid().v4();
      final view = rescored.copyWith(
        flaggedIngredients: _reflagWithSensitivities(rescored, sensitivities),
        // Fresh IDs: this is a new turn viewing an old result. The stored doc
        // is untouched (no counter bump, no history duplicate).
        scanId: const Uuid().v4(),
        chatMessageId: turnId,
        createdAt: DateTime.now(),
      );

      await _chatFirestoreService.saveMessage(
        ChatMessage(
          localId: turnId,
          role: 'ai',
          text: 'Welcome back — **${view.productName}**, from your scan history with a fresh score ✨\n\n${NarrativeText.ratingLine(view.score)}',
          scanData: view,
          source: view.source,
          createdAt: DateTime.now(),
        ),
      );
      _appStateService.notifyChatUpdated();
      await _analyticsService.logEvent(name: 'scan_performed', parameters: {'source': 'barcode_cache', 'product_name': view.productName, 'score': view.score});
      AppLogger.ai('ScannerRepository: barcode cache HIT for ${view.productName} — skipped OFF + AI');
      return view;
    } catch (e) {
      // The cache must never break scanning — any failure falls through.
      AppLogger.error('ScannerRepository: barcode cache lookup failed', error: e);
      return null;
    }
  }

  /// Merges the AI's stored flags with deterministic matches against the
  /// CURRENT sensitivities. Union semantics are deliberate: entries are only
  /// ever added, so a newly added sensitivity can surface a warning the old
  /// analysis predates, while stale AI flags are never hidden (substring
  /// matching can't reproduce the model's synonym knowledge — e.g. "dairy" vs
  /// "whey" — so removal would risk dropping a real warning).
  List<String> _reflagWithSensitivities(ScanResult scan, List<String> sensitivities) {
    final flags = <String>{...scan.flaggedIngredients};
    if (sensitivities.isEmpty) return flags.toList();
    final haystacks = [...scan.ingredients.map((i) => i.name), ...scan.additiveItems, if (scan.allergens != null) scan.allergens!].map((s) => s.toLowerCase()).toList();
    for (final term in sensitivities) {
      final needle = term.toLowerCase().trim();
      if (needle.isEmpty) continue;
      if (haystacks.any((h) => h.contains(needle))) flags.add(term);
    }
    return flags.toList();
  }

  /// Runs the deterministic scoring engine and attaches an ENGINE-AUTHORED
  /// score + explanation to the scan's insight.
  ///
  /// Product requirement §7 asks for `Data → Scoring Engine → Score → AI
  /// Explanation` rather than `Data → LLM → arbitrary score`. The model
  /// supplies the structured inputs; it never authors the number, and the
  /// "why" is composed from the engine's own signed factors so the text can
  /// never contradict the number.
  ///
  /// When [nutriscore]/[novaGroup]/[nutrients] are supplied by a trusted source
  /// (Open Food Facts) they win over the model's estimates.
  ScanResult _applyEngineScore(
    ScanResult scan, {
    String? nutriscore,
    int? nutriscoreScore,
    int? novaGroup,
    num? energyKcal,
    num? fiberG,
    num? proteinG,
    num? sugarG,
    num? saltG,
    num? saturatedFatG,
    List<String>? additiveItems,
    bool? isOrganic,
    bool deferToModelWhenNoData = false,
    List<String>? miscTags,
  }) {
    final resolvedAdditives = <String>{...?additiveItems, ...scan.additiveItems};
    final additiveConcerns = AdditiveConcernDb.resolveAll(resolvedAdditives);

    final breakdown = YukaScore.evaluate(
      nutriscore: nutriscore ?? scan.nutriscore,
      // Scan fallbacks let barcode-cache hits re-run the engine with zero
      // explicit args and still reproduce the original score bit-for-bit.
      nutriscoreScore: nutriscoreScore ?? scan.nutriscoreScore,
      energyKcal: energyKcal ?? scan.nutrients?.calories,
      fiberG: fiberG ?? scan.nutrients?.fiber,
      proteinG: proteinG ?? scan.nutrients?.proteins,
      sugarG: sugarG ?? scan.nutrients?.sugars,
      saltG: saltG ?? scan.nutrients?.salt,
      saturatedFatG: saturatedFatG ?? scan.nutrients?.saturatedFat,
      additiveConcerns: additiveConcerns,
      isOrganic: isOrganic ?? scan.isOrganic,
    );

    // SAFEGUARD: for a *photo* scan the model has usually reasoned about the
    // food even where it cannot estimate grams. Overriding its score with a
    // data-less engine result would make every photo scan look identical, so
    // when the engine has nothing to go on, callers that opt in keep the
    // model's score instead.
    if (!breakdown.hasData && deferToModelWhenNoData) {
      AppLogger.ai('ScannerRepository: engine had no usable inputs — keeping model score ${scan.score}');
      return scan;
    }

    // No signal at all and no model score to defer to: stay neutral — but say
    // WHY. A bare neutral 50 reads as "the app is broken"; Open Food Facts
    // usually tells us exactly what is missing, so pass that through.
    if (!breakdown.hasData) {
      final reason = ModelUtils.unscorableReason(miscTags);
      return scan.copyWith(score: 50, impact: reason ?? scan.impact);
    }

    final score = breakdown.score;
    AppLogger.ai('ScannerRepository: engine score $score (nutrition ${breakdown.nutritionSubscore}, additives ${breakdown.additiveSubscore}, organic ${breakdown.organicSubscore})');

    return scan.copyWith(score: score, impact: breakdown.explanation.isNotEmpty ? breakdown.explanation : scan.impact);
  }

  @override
  Future<AiAnalysisResult> analyzeProductWithAi({
    required OffProduct product,
    required List<String> goals,
    required List<String> sensitivities,
    required List<String> lifestyle,
    required String cyclePhase,
    List<OffProduct>? alternatives,
  }) async {
    var alternativesText = '';
    if (alternatives != null && alternatives.isNotEmpty) {
      alternativesText = '\n\nREAL PRODUCT ALTERNATIVES FROM DATABASE: ${alternatives.map((a) => '${a.productName} by ${a.brand} (Score: ${a.nutriscore})').join(', ')}';
    }

    final productMap = product.toMap();
    // 🟢 OPTIMIZED: Limit the number of ingredients sent to the AI to prevent 502/Token errors.
    if (product.ingredients != null && product.ingredients!.length > 15) {
      productMap['ingredients'] = product.ingredients!.take(15).toList();
    }

    final prompt = '${Prompts.productAnalysisPrompt(productData: productMap, userGoals: goals, userSensitivities: sensitivities, userLifestyle: lifestyle, cyclePhase: cyclePhase)}$alternativesText';

    final aiResultStr = await _aiService.generateContent(
      prompt: prompt,
      systemInstruction: Prompts.barcodeAnalysisSystemInstruction,
      usageType: 'scan',
      mode: 'plain',
      promptVersion: AiVersions.visionPromptVersion,
    );

    // Ground-truth backfill for the swap cards: real OFF alternatives, so the
    // "Better swaps" section can always reach exactly kSwapCardCount cards
    // even when the model recommends fewer (normalizeSwapCards trims/drops).
    final fallbackSwaps = (alternatives ?? const <OffProduct>[])
        .map(
          (a) => ProductSwap(
            title: a.productName,
            subtitle: '${a.brand ?? 'Alternative'}${a.nutriscore != null ? ' · Nutri-Score ${a.nutriscore!.toUpperCase()}' : ''}',
            imageKeyword: a.productName,
            imageUrl: a.imageUrl,
            tag: a.nutriscore != null ? 'NUTRI-SCORE ${a.nutriscore!.toUpperCase()}' : 'BETTER CHOICE',
            barcode: a.barcode,
            nutriscore: a.nutriscore,
          ),
        )
        .toList();

    final result = _processChatTagUseCase(
      aiResultStr,
      source: 'barcode',
      promptVersion: _aiService.lastPromptVersion ?? AiVersions.visionPromptVersion,
      servedModel: _aiService.lastServedModel,
      fallbackSwaps: fallbackSwaps,
    );

    if (result.scan != null) {
      final scan = result.scan!;
      // Merge OFF additive tags (ground-truth E-codes) with AI-extracted items
      // so per-additive detail + concern-based scoring always have data.
      final mergedAdditives = <String>{...scan.additiveItems, ...?product.additives};

      // OFF label data is ground truth, so it drives the score (not the model).
      final updatedScan = _applyEngineScore(
        // Persist OFF's numeric score + organic flag so future cache hits
        // re-run the engine on identical inputs (P0-3).
        scan.copyWith(
          barcode: product.barcode,
          imageUrl: product.imageUrl,
          additiveItems: mergedAdditives.toList(),
          nutriscoreScore: product.nutriscoreScore,
          isOrganic: product.isOrganic,
          createdAt: DateTime.now(),
        ),
        nutriscore: product.nutriscore,
        nutriscoreScore: product.nutriscoreScore,
        novaGroup: int.tryParse(product.novaGroup?.toString() ?? ''),
        energyKcal: product.nutrients?.calories,
        fiberG: product.nutrients?.fiber,
        proteinG: product.nutrients?.proteins,
        sugarG: product.nutrients?.sugars,
        saltG: product.nutrients?.salt,
        saturatedFatG: product.nutrients?.saturatedFat,
        additiveItems: mergedAdditives.toList(),
        isOrganic: product.isOrganic,
        miscTags: product.miscTags,
      );

      await _analyticsService.logEvent(name: 'scan_performed', parameters: {'source': 'barcode', 'product_name': updatedScan.productName, 'score': updatedScan.score});
      return result.copyWith(scan: updatedScan);
    }

    throw Exception('ScannerRepository: Could not parse AI barcode analysis result');
  }

  @override
  Future<AiAnalysisResult> analyzeImageWithAi({
    required Uint8List imageBytes,
    required String mode,
    required List<String> goals,
    required List<String> sensitivities,
    required List<String> lifestyle,
    required String cyclePhase,
    String? userText,
  }) async {
    // K-3: the UI entry point wins — a dedicated scanner mode already knows what
    // the bytes are, so the classifier skips its vision round-trip (the old
    // "visual content wins" behavior doubled vision bytes on every scan).
    // Unknown modes still fall back to full vision classification inside.
    final classification = await _aiClassifierService.classifyImage(imageBytes: imageBytes, userText: userText, modeHint: mode);

    final userPrompt = (userText != null && userText.trim().isNotEmpty)
        ? 'Analyze this image and user message: "$userText". Provide your full analysis followed by the [GUTGOOD_DATA] block. Intent: ${classification.intent}'
        : 'Analyze this image and provide your full analysis followed by the [GUTGOOD_DATA] block. Intent: ${classification.intent}';

    final aiResultStr = await _aiService.generateContent(
      imageBytes: imageBytes,
      systemInstruction: Prompts.visionAnalysisSystemInstruction(
        mode: classification.imageMode, // Use AI detected mode
        userGoals: goals,
        userSensitivities: sensitivities,
        userLifestyle: lifestyle,
        cyclePhase: cyclePhase,
      ),
      prompt: userPrompt,
      usageType: 'scan',
      mode: 'plain',
      promptVersion: AiVersions.visionPromptVersion,
    );

    var result = _processChatTagUseCase(
      aiResultStr,
      userText: userText,
      source: classification.imageMode,
      promptVersion: _aiService.lastPromptVersion ?? AiVersions.visionPromptVersion,
      servedModel: _aiService.lastServedModel,
    );

    // Photo scans used to take whatever score the model invented. Run the same
    // deterministic engine used for barcode scans over the model's structured
    // extraction instead, and attach the engine's factors as the explanation.
    // (Values are estimates here — `nutritionEstimated` already tells the UI.)
    final visionScan = result.scan;
    if (visionScan != null) {
      result = result.copyWith(scan: _applyEngineScore(visionScan, deferToModelWhenNoData: true));
    }

    // Add classification info to result
    final finalResult = result.copyWith(imageMode: classification.imageMode, intent: classification.intent);

    if (finalResult.scan != null) {
      await _analyticsService.logEvent(
        name: 'scan_performed',
        parameters: {
          'source': 'vision',
          'detected_mode': classification.imageMode,
          'detected_intent': classification.intent,
          'product_name': finalResult.scan!.productName,
          'score': finalResult.scan!.score,
        },
      );
      return finalResult;
    } else {
      throw Exception('ScannerRepository: Could not parse AI vision result');
    }
  }

  @override
  Future<void> saveScanResult(AiAnalysisResult result, {String? userImageUrl, String? scanId}) async {
    final scan = result.scan;
    if (scan == null) return;

    AppLogger.info('ScannerRepository: Processing scan result persistence for: ${scan.productName}');
    final finalScanId = scanId ?? scan.scanId ?? const Uuid().v4();

    // P1-4: record writes go through the shared persister — same validation,
    // label/menu gating, consumption gating, and stable IDs as the chat path
    // (this also fixes phantom meal logs on "is this healthy?" scans and
    // missing confidence gating here). The returned result carries hydrated
    // IDs, and cleared records for chat-only turns, which the bubble embeds.
    final outcome = await _persister.persist(result, chatMessageId: finalScanId, imageUrl: userImageUrl, source: scan.source);
    var hydrated = outcome.result;
    var hydratedScan = hydrated.scan ?? scan;

    // Barcode turns: the product identity is OFF ground truth, so an AI
    // verdict (non_food / uncertain / low-confidence) must not veto the
    // history record. If the persister declined the write, force it here so
    // every completed barcode analysis lands in scan_history. (Vision/label/
    // menu turns keep their chat-only gating — those categories are guessed,
    // not scanned.) Stable ID convention matches the persister exactly.
    if (!outcome.persistedScan && scan.source == 'barcode' && (scan.barcode ?? '').isNotEmpty) {
      final stableScanId = '${finalScanId}_scan';
      AppLogger.warning(
        'ScannerRepository: persister skipped scan_history for barcode turn '
        '(${outcome.chatOnlyReason ?? 'unknown'}; ${outcome.validationReasons.join('; ')}) — forcing write for verified OFF product',
      );
      final forcedScan = hydratedScan.copyWith(scanId: stableScanId, chatMessageId: finalScanId);
      await _historyFirestoreService.saveToScanHistory(forcedScan, userImageUrl: userImageUrl, scanId: stableScanId);
      hydrated = hydrated.copyWith(scan: forcedScan);
      hydratedScan = forcedScan;
    }

    // 🚀 Consistent UX: Use the AI's actual conversational text in the chat bubble.
    // Bracket-emoji decorations are stripped and the engine rating is spliced
    // under the greeting — the number can never drift from the score gauge.
    final narrative = NarrativeText.sanitize(hydrated.text.isEmpty ? '' : hydrated.text);
    final bubbleText = narrative.isNotEmpty
        ? NarrativeText.injectRating(narrative, hydratedScan.score)
        : 'I analyzed **${hydratedScan.productName}** for you. ✨\n\n${NarrativeText.ratingLine(hydratedScan.score)}';

    final aiMsg = ChatMessage(
      localId: finalScanId,
      role: 'ai',
      text: bubbleText,
      scanData: hydratedScan,
      imageUrl: userImageUrl,
      symptomLogs: hydrated.symptoms,
      mealLogs: hydrated.meal != null ? [hydrated.meal!] : const [],
      source: scan.source,
      createdAt: DateTime.now(),
    );

    await _chatFirestoreService.saveMessage(aiMsg);
    await _streakService.markActivityToday();
    AppLogger.info('ScannerRepository: Chat message saved and activity marked');

    _appStateService.notifyChatUpdated();
    unawaited(_notificationService.scheduleNoMealLoggedReminder());
    unawaited(_notificationService.schedulePostMealCheckIn());
  }
}
