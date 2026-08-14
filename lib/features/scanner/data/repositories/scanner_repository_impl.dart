import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:gutgood/core/models/chat_message.dart';
import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/off_product.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/services/ai_service.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/firestore/chat_firestore_service.dart';
import 'package:gutgood/core/services/firestore/history_firestore_service.dart';
import 'package:gutgood/core/services/notification_service.dart';
import 'package:gutgood/core/services/off_service.dart';
import 'package:gutgood/core/services/prompts.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/model_utils.dart';
import 'package:gutgood/features/scanner/domain/repositories/scanner_repository.dart';
import 'package:uuid/uuid.dart';

class ScannerRepositoryImpl implements ScannerRepository {
  ScannerRepositoryImpl({
    required OffService offService,
    required AiService aiService,
    required ChatFirestoreService chatFirestoreService,
    required HistoryFirestoreService historyFirestoreService,
    required NotificationService notificationService,
    required AppStateService appStateService,
    required AnalyticsService analyticsService,
  }) : _offService = offService,
       _aiService = aiService,
       _chatFirestoreService = chatFirestoreService,
       _historyFirestoreService = historyFirestoreService,
       _notificationService = notificationService,
       _appStateService = appStateService,
       _analyticsService = analyticsService;
  final OffService _offService;
  final AiService _aiService;
  final ChatFirestoreService _chatFirestoreService;
  final HistoryFirestoreService _historyFirestoreService;
  final NotificationService _notificationService;
  final AppStateService _appStateService;
  final AnalyticsService _analyticsService;

  @override
  Future<OffProduct?> getProductByBarcode(String barcode) async => _offService.getProduct(barcode);

  @override
  Future<ScanResult> analyzeProductWithAi({
    required OffProduct product,
    required List<String> goals,
    required List<String> sensitivities,
    required String cyclePhase,
    List<OffProduct>? alternatives,
  }) async {
    var alternativesText = '';
    if (alternatives != null && alternatives.isNotEmpty) {
      alternativesText = '\n\nREAL PRODUCT ALTERNATIVES FROM DATABASE: ${alternatives.map((a) => '${a.productName} by ${a.brand} (Score: ${a.nutriscore})').join(', ')}';
    }

    final prompt = '${Prompts.productAnalysisPrompt(productData: product.toMap(), userGoals: goals, userSensitivities: sensitivities, cyclePhase: cyclePhase)}$alternativesText';

    final aiResultStr = await _aiService.generateContent(prompt: prompt, systemInstruction: Prompts.barcodeAnalysisSystemInstruction, usageType: 'scan');

    final jsonStr = ModelUtils.extractJson(aiResultStr);
    if (jsonStr == null) {
      throw Exception('ScannerRepository: Could not parse AI barcode analysis result');
    }

    final Map<String, dynamic> aiData = jsonDecode(jsonStr);
    aiData['imageUrl'] ??= product.imageUrl;
    aiData['barcode'] ??= product.barcode;
    aiData['nutrients'] ??= product.nutrients?.toMap();

    final result = ScanResult.fromMap(aiData);
    await _analyticsService.logEvent(name: 'scan_performed', parameters: {'source': 'barcode', 'product_name': result.productName, 'score': result.score});
    return result;
  }

  @override
  Future<ScanResult> analyzeImageWithAi({
    required Uint8List imageBytes,
    required List<String> goals,
    required List<String> sensitivities,
    required List<String> lifestyle,
    required String cyclePhase,
  }) async {
    final aiResultStr = await _aiService.generateContent(
      imageBytes: imageBytes,
      systemInstruction: Prompts.visionAnalysisSystemInstruction(userGoals: goals, userSensitivities: sensitivities, userLifestyle: lifestyle, cyclePhase: cyclePhase),
      prompt: 'Analyze this ingredient label or meal photo and return a [SCAN] JSON object.',
      usageType: 'scan',
    );

    final scanRegex = RegExp(r'\[SCAN\](.*?)\[/SCAN\]', dotAll: true);
    final match = scanRegex.firstMatch(aiResultStr);
    final rawJson = match != null ? match.group(1) : aiResultStr;

    final jsonStr = ModelUtils.extractJson(rawJson);
    if (jsonStr != null) {
      final result = ScanResult.fromMap(jsonDecode(jsonStr));
      await _analyticsService.logEvent(name: 'scan_performed', parameters: {'source': 'vision', 'product_name': result.productName, 'score': result.score});
      return result;
    } else {
      throw Exception('ScannerRepository: Could not parse AI vision result');
    }
  }

  @override
  Future<void> saveScanResult(ScanResult result, {String? userImageUrl}) async {
    AppLogger.info('ScannerRepository: Creating ChatMessage for scan: ${result.productName}');
    final userMsg = ChatMessage(localId: const Uuid().v4(), role: 'user', text: 'Scan: ${result.productName} ✨', scanData: result, imageUrl: userImageUrl, source: result.source, time: DateTime.now());

    await _chatFirestoreService.saveMessage(userMsg);
    AppLogger.info('ScannerRepository: Scan result message saved to Firestore');

    // 🚀 Professional Filter: Only persist scans and auto-log meals if it's an actual product.
    // Restaurant menus and raw ingredient labels are analyzed for the chat context but 
    // shouldn't clutter the history or impact the gut health trend.
    if (result.isLoggableProduct) {
      await _historyFirestoreService.saveToScanHistory(result, userImageUrl: userImageUrl);
      AppLogger.info('ScannerRepository: Scan result saved to scan_history. Image: ${userImageUrl != null}');

      // 🟢 Automatically add to Meal Log if it's a food image/snap or gallery upload
      if (result.source == 'food' || result.source == 'meal' || result.source == 'gallery') {
        final mealLog = MealLog(items: [result.productName], photoUrl: userImageUrl ?? result.imageUrl, time: DateTime.now(), source: result.source);
        await _historyFirestoreService.logMeal(mealLog);
        AppLogger.info('ScannerRepository: Food image (${result.source}) automatically logged as a meal');
      }
    } else {
      AppLogger.info('ScannerRepository: Skipping history/meal log for non-product scan: ${result.productName}');
    }

    // 🟢 Fix: Notify UI that history has updated
    _appStateService.notifyChatUpdated();
    AppLogger.info('ScannerRepository: UI notified of scan history update');

    unawaited(_notificationService.scheduleNoMealLoggedReminder());

    // 🚀 Professional Loop: Schedule a symptom check-in 2 hours after a scan.
    // This helps the Pattern Engine find correlations later.
    unawaited(_notificationService.schedulePostMealCheckIn());
  }
}
