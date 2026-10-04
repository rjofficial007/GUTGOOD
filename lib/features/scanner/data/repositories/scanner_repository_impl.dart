import 'dart:async';
import 'dart:typed_data';

import 'package:gutgood/core/ai/classification/ai_classifier_service.dart';
import 'package:gutgood/core/ai/client/ai_client.dart';
import 'package:gutgood/core/ai/prompts/prompt_catalog.dart';
import 'package:gutgood/core/ai/protocol/ai_constants.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/streak_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/narrative_text.dart';
import 'package:gutgood/features/chat/domain/usecases/process_chat_tag_usecase.dart';
import 'package:gutgood/features/logs/data/services/domain_event_persister.dart';
import 'package:gutgood/features/scanner/data/services/scanner_score_service.dart';
import 'package:gutgood/features/scanner/domain/repositories/scanner_repository.dart';
import 'package:gutgood/infrastructure/firebase/analytics_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/chat_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/history_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/notification_service.dart';
import 'package:gutgood/infrastructure/open_food_facts/off_service.dart';
import 'package:uuid/uuid.dart';

class ScannerRepositoryImpl implements ScannerRepository {
  ScannerRepositoryImpl({
    required OffService offService,
    required AiClient aiService,
    required AiClassifierService aiClassifierService,
    required ChatFirestoreService chatFirestoreService,
    required HistoryFirestoreService historyFirestoreService,
    required NotificationService notificationService,
    required AppStateService appStateService,
    required AnalyticsService analyticsService,
    required StreakService streakService,
    required ProcessChatTagUseCase processChatTagUseCase,
    required DomainEventPersister eventPersister,
    ScannerScoreService? scoreService,
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
       _persister = eventPersister,
       _scoreService = scoreService ?? const ScannerScoreService();
  final OffService _offService;
  final AiClient _aiService;
  final AiClassifierService _aiClassifierService;
  final ChatFirestoreService _chatFirestoreService;
  final HistoryFirestoreService _historyFirestoreService;
  final NotificationService _notificationService;
  final AppStateService _appStateService;
  final AnalyticsService _analyticsService;
  final StreakService _streakService;
  final ProcessChatTagUseCase _processChatTagUseCase;
  final DomainEventPersister _persister;
  final ScannerScoreService _scoreService;

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
      final rescored = _scoreService.applyEngineScore(cached, refreshExplanation: true, onDiagnostic: AppLogger.ai);
      final turnId = const Uuid().v4();
      // A cache hit still represents a new intentional scan. Reuse the cached
      // analysis, but give this consumption its own scan-history and meal IDs
      // so repeated purchases of the same barcode remain countable events.
      final stableScanId = '${turnId}_scan';
      final stableMealId = '${stableScanId}_meal';
      final view = rescored.copyWith(
        flaggedIngredients: _scoreService.reflagWithSensitivities(rescored, sensitivities),
        scanId: stableScanId,
        chatMessageId: turnId,
        source: rescored.source ?? 'barcode_cache',
        createdAt: DateTime.now(),
      );

      final didPersistScan = await _historyFirestoreService.trySaveToScanHistory(
        view,
        userImageUrl: view.userImageUrl,
        scanId: stableScanId,
      );
      if (!didPersistScan) {
        AppLogger.warning('ScannerRepository: cached scan history write failed; continuing with meal projection');
      }
      final cacheMeal = _persister
          .mealFromScan(
            view,
            chatMessageId: turnId,
            source: view.source ?? 'barcode_cache',
            scanId: stableScanId,
          )
          .copyWith(journalEntryId: stableMealId);
      var hydratedMeal = cacheMeal;
      try {
        final mealId = await _historyFirestoreService.logMeal(cacheMeal, docId: stableMealId);
        hydratedMeal = cacheMeal.copyWith(firestoreId: mealId ?? stableMealId, journalEntryId: mealId ?? stableMealId);
      } catch (e) {
        // A cache hit must keep its existing resilient UX even if the additive
        // meal projection cannot be written while offline.
        AppLogger.warning('ScannerRepository: cached scan meal projection failed', error: e);
      }

      await _chatFirestoreService.saveMessage(
        ChatMessage(
          localId: turnId,
          role: 'ai',
          text: 'Welcome back — **${view.productName}**, from your scan history with a fresh score ✨\n\n${NarrativeText.ratingLine(view.score)}',
          scanData: view,
          mealLogs: [hydratedMeal],
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
      final updatedScan = _scoreService.applyEngineScore(
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
        onDiagnostic: AppLogger.ai,
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
      result = result.copyWith(scan: _scoreService.applyEngineScore(visionScan, deferToModelWhenNoData: true, onDiagnostic: AppLogger.ai));
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

    // P1-4: record writes go through the shared persister — the same
    // validation override, universal scan-as-consumption projection, and
    // stable IDs as the chat path. The returned result carries hydrated IDs
    // which the bubble embeds.
    final outcome = await _persister.persist(result, chatMessageId: finalScanId, imageUrl: userImageUrl, source: scan.source);
    final hydrated = outcome.result;
    final hydratedScan = hydrated.scan ?? scan;

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
