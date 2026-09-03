import 'dart:async';
import 'dart:typed_data';

import 'package:gutgood/core/models/ai_analysis_result.dart';
import 'package:gutgood/core/models/chat_message.dart';
import 'package:gutgood/core/models/off_product.dart';
import 'package:gutgood/core/services/ai_classifier_service.dart';
import 'package:gutgood/core/services/ai_service.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/firestore/chat_firestore_service.dart';
import 'package:gutgood/core/services/firestore/history_firestore_service.dart';
import 'package:gutgood/core/services/notification_service.dart';
import 'package:gutgood/core/services/off_service.dart';
import 'package:gutgood/core/services/prompts.dart';
import 'package:gutgood/core/services/streak_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/model_utils.dart';
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
  }) : _offService = offService,
       _aiService = aiService,
       _aiClassifierService = aiClassifierService,
       _chatFirestoreService = chatFirestoreService,
       _historyFirestoreService = historyFirestoreService,
       _notificationService = notificationService,
       _appStateService = appStateService,
       _analyticsService = analyticsService,
       _streakService = streakService,
       _processChatTagUseCase = processChatTagUseCase;
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

  @override
  Future<OffProduct?> getProductByBarcode(String barcode) async => _offService.getProduct(barcode);

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

    final aiResultStr = await _aiService.generateContent(prompt: prompt, systemInstruction: Prompts.barcodeAnalysisSystemInstruction, usageType: 'scan', mode: 'plain');

    final result = _processChatTagUseCase(aiResultStr, source: 'barcode');

    if (result.scan != null) {
      final scan = result.scan!;
      final deterministicScore = ModelUtils.computeDeterministicScore(
        nutriscore: product.nutriscore,
        novaGroup: int.tryParse(product.novaGroup?.toString() ?? ''),
        fiberG: product.nutrients?.fiber,
        proteinG: product.nutrients?.proteins,
        sugarG: product.nutrients?.sugars,
        saltG: product.nutrients?.salt,
        saturatedFatG: product.nutrients?.saturatedFat,
      );

      final updatedScan = scan.copyWith(score: deterministicScore, barcode: product.barcode, imageUrl: product.imageUrl, createdAt: DateTime.now());

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
    // 🟢 AI-BASED CLASSIFICATION: The visual content wins over the UI entry point.
    final classification = await _aiClassifierService.classifyImage(imageBytes: imageBytes, userText: userText);

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
    );

    final result = _processChatTagUseCase(aiResultStr, source: classification.imageMode);

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

    final source = (scan.source ?? '').toUpperCase();
    final category = (scan.category ?? '').toUpperCase();
    final isLabelOrMenu = source.contains('LABEL') || category.contains('LABEL') || source.contains('MENU') || category.contains('MENU');

    // 🚀 Consistent UX: Use the AI's actual conversational text in the chat bubble
    final aiMsg = ChatMessage(
      localId: finalScanId,
      role: 'ai',
      text: result.text.isEmpty ? 'I analyzed **${scan.productName}** for you. ✨' : result.text,
      scanData: scan.copyWith(scanId: finalScanId, userImageUrl: userImageUrl),
      imageUrl: userImageUrl,
      symptomLogs: result.symptoms,
      mealLogs: (!isLabelOrMenu && result.meal != null) ? [result.meal!] : const [],
      source: scan.source,
      createdAt: DateTime.now(),
    );

    await _chatFirestoreService.saveMessage(aiMsg);
    await _streakService.markActivityToday();
    AppLogger.info('ScannerRepository: Chat message saved and activity marked');

    // 🚀 Persist Symptoms to journal_logs
    if (result.symptoms.isNotEmpty) {
      for (var i = 0; i < result.symptoms.length; i++) {
        var symptom = result.symptoms[i];
        final stableSymptomId = '${finalScanId}_symptom_$i';
        symptom = symptom.copyWith(chatMessageId: finalScanId, foodName: symptom.foodName ?? scan.productName, imageUrl: symptom.imageUrl ?? userImageUrl ?? scan.imageUrl);
        await _historyFirestoreService.logSymptom(symptom, docId: stableSymptomId);
        AppLogger.info('ScannerRepository: Saved symptom ${symptom.symptom} (${symptom.foodName}) to journal_logs');
      }
    }

    // 🚀 Persist Meal Log to journal_logs (ONLY for food/meal scans, NOT label or menu)
    if (!isLabelOrMenu && result.meal != null) {
      final stableMealId = '${finalScanId}_meal';
      await _historyFirestoreService.logMeal(
        result.meal!.copyWith(chatMessageId: finalScanId, source: scan.source),
        docId: stableMealId,
      );
      AppLogger.info('ScannerRepository: Saved meal log to journal_logs');
    }

    // 🚀 Intent-Based Persistence Router: Label and Menu scans are saved ONLY to chat_history
    if (isLabelOrMenu) {
      AppLogger.info('ScannerRepository: Label/Menu scan - saved ONLY to chat_history');
    } else {
      // Normal Meal/Food Scan - Save to scan_history
      if (scan.isLoggableProduct) {
        final updatedResult = scan.copyWith(scanId: finalScanId, chatMessageId: finalScanId);
        await _historyFirestoreService.saveToScanHistory(updatedResult, userImageUrl: userImageUrl, scanId: finalScanId);
        AppLogger.info('ScannerRepository: Routed product to scan_history');
      } else {
        AppLogger.info('ScannerRepository: Non-product scan skipped for history collection');
      }
    }

    _appStateService.notifyChatUpdated();
    unawaited(_notificationService.scheduleNoMealLoggedReminder());
    unawaited(_notificationService.schedulePostMealCheckIn());
  }
}
