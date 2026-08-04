import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:gutgood/core/models/chat_message.dart';
import 'package:gutgood/core/models/off_product.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/services/ai_service.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/firestore_service.dart';
import 'package:gutgood/core/services/notification_service.dart';
import 'package:gutgood/core/services/off_service.dart';
import 'package:gutgood/core/services/prompts.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/features/scanner/domain/repositories/scanner_repository.dart';
import 'package:uuid/uuid.dart';

class ScannerRepositoryImpl implements ScannerRepository {

  ScannerRepositoryImpl({
    required OffService offService,
    required AiService aiService,
    required FirestoreService firestoreService,
    required NotificationService notificationService,
    required AppStateService appStateService,
    required AnalyticsService analyticsService,
  }) : _offService = offService,
       _aiService = aiService,
       _firestoreService = firestoreService,
       _notificationService = notificationService,
       _appStateService = appStateService,
       _analyticsService = analyticsService;
  final OffService _offService;
  final AiService _aiService;
  final FirestoreService _firestoreService;
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

    final Map<String, dynamic> aiData = jsonDecode(aiResultStr);
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
    if (match != null) {
      final jsonStr = match.group(1)?.replaceAll('```json', '').replaceAll('```', '').trim() ?? '';
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

    await _firestoreService.saveMessage(userMsg);
    AppLogger.info('ScannerRepository: Scan result message saved to Firestore');

    // Passive logging (PRD §2 / §6.2 / §13): a completed scan is also a LOG.
    // Without this write, scan_history stayed empty -> the Scan History screen,
    // the Insights scan-trigger (3 scans, §8.2), scan-aware insight context and
    // the processed-food warning notification could never fire.
    await _firestoreService.saveToScanHistory(result, userImageUrl: userImageUrl);
    AppLogger.info('ScannerRepository: Scan result saved to scan_history. Image: ${userImageUrl != null}');

    // 🟢 Fix: Notify UI that history has updated
    _appStateService.notifyChatUpdated();
    AppLogger.info('ScannerRepository: UI notified of scan history update');

    unawaited(_notificationService.scheduleNoMealLoggedReminder());
    
    // 🚀 Professional Loop: Schedule a symptom check-in 2 hours after a scan.
    // This helps the Pattern Engine find correlations later.
    unawaited(_notificationService.schedulePostMealCheckIn());
  }
}
