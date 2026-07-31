import 'dart:convert';
import 'dart:typed_data';

import 'package:gutgood/core/models/chat_message.dart';
import 'package:gutgood/core/models/off_product.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/services/ai_service.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/firestore_service.dart';
import 'package:gutgood/core/services/notification_service.dart';
import 'package:gutgood/core/services/off_service.dart';
import 'package:gutgood/core/services/prompts.dart';
import 'package:gutgood/features/scanner/domain/repositories/scanner_repository.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/logger_service.dart';

class ScannerRepositoryImpl implements ScannerRepository {
  final OffService _offService;
  final AiService _aiService;
  final FirestoreService _firestoreService;
  final NotificationService _notificationService;
  final AppStateService _appStateService;

  ScannerRepositoryImpl({
    required OffService offService,
    required AiService aiService,
    required FirestoreService firestoreService,
    required NotificationService notificationService,
    required AppStateService appStateService,
  }) : _offService = offService,
       _aiService = aiService,
       _firestoreService = firestoreService,
       _notificationService = notificationService,
       _appStateService = appStateService;

  @override
  Future<OffProduct?> getProductByBarcode(String barcode) async {
    return await _offService.getProduct(barcode);
  }

  @override
  Future<ScanResult> analyzeProductWithAi({
    required OffProduct product,
    required List<String> goals,
    required List<String> sensitivities,
    required String cyclePhase,
    List<OffProduct>? alternatives,
  }) async {
    String alternativesText = '';
    if (alternatives != null && alternatives.isNotEmpty) {
      alternativesText = '\n\nREAL PRODUCT ALTERNATIVES FROM DATABASE: ${alternatives.map((a) => '${a.productName} by ${a.brand} (Score: ${a.nutriscore})').join(', ')}';
    }

    final String prompt = '${Prompts.productAnalysisPrompt(productData: product.toMap(), userGoals: goals, userSensitivities: sensitivities, cyclePhase: cyclePhase)}$alternativesText';

    final aiResultStr = await _aiService.generateContent(prompt: prompt, systemInstruction: Prompts.barcodeAnalysisSystemInstruction);

    final Map<String, dynamic> aiData = jsonDecode(aiResultStr);
    aiData['imageUrl'] ??= product.imageUrl;
    aiData['barcode'] ??= product.barcode;
    aiData['nutrients'] ??= product.nutrients?.toMap();

    return ScanResult.fromMap(aiData);
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
    );

    final scanRegex = RegExp(r'\[SCAN\](.*?)\[/SCAN\]', dotAll: true);
    final match = scanRegex.firstMatch(aiResultStr);
    if (match != null) {
      final jsonStr = match.group(1)?.replaceAll('```json', '').replaceAll('```', '').trim() ?? '';
      return ScanResult.fromMap(jsonDecode(jsonStr));
    } else {
      throw Exception('ScannerRepository: Could not parse AI vision result');
    }
  }

  @override
  Future<void> saveScanResult(ScanResult result, {String? userImageUrl}) async {
    Log.i('ScannerRepository: Creating ChatMessage for scan: ${result.productName}');
    final userMsg = ChatMessage(localId: const Uuid().v4(), role: 'user', text: 'Scan: ${result.productName} ✨', scanData: result, imageUrl: userImageUrl, source: result.source, time: DateTime.now());

    await _firestoreService.saveMessage(userMsg);
    Log.i('ScannerRepository: Scan result message saved to Firestore');

    // Passive logging (PRD §2 / §6.2 / §13): a completed scan is also a LOG.
    // Without this write, scan_history stayed empty -> the Scan History screen,
    // the Insights scan-trigger (3 scans, §8.2), scan-aware insight context and
    // the processed-food warning notification could never fire.
    await _firestoreService.saveToScanHistory(result, userImageUrl: userImageUrl);
    Log.i('ScannerRepository: Scan result saved to scan_history');

    // 🟢 Fix: Notify UI that history has updated
    _appStateService.notifyChatUpdated();
    Log.i('ScannerRepository: UI notified of scan history update');

    _notificationService.scheduleNoMealLoggedReminder();
    _notificationService.checkAndTriggerProcessedFoodWarning();
  }
}
