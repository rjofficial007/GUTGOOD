import 'dart:convert';

import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/models/symptom_log.dart';
import 'package:gutgood/core/services/firestore_service.dart';
import 'package:gutgood/core/services/notification_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/model_utils.dart';

import '../../../../core/services/app_state_service.dart';

class ProcessChatTagResult {
  final String text;
  final ScanResult? scanData;
  final List<ProductSwap>? swapData;
  final bool isSwap;
  final List<String> foodMentions;
  final List<String> symptomMentions;

  ProcessChatTagResult({required this.text, this.scanData, this.swapData, this.isSwap = false, this.foodMentions = const [], this.symptomMentions = const []});
}

class ProcessChatTagUseCase {
  final FirestoreService _firestoreService;
  final NotificationService _notificationService;
  final AppStateService _appStateService;

  ProcessChatTagUseCase({required FirestoreService firestoreService, required NotificationService notificationService, required AppStateService appStateService})
    : _firestoreService = firestoreService,
      _notificationService = notificationService,
      _appStateService = appStateService;

  /// Robustly extracts JSON from a string that might contain noise (e.g., "JSON object: { ... }")
  String? _extractJson(String? raw, {bool isArray = false}) {
    if (raw == null || raw.isEmpty) return null;
    final startChar = isArray ? '[' : '{';
    final endChar = isArray ? ']' : '}';

    final startIndex = raw.indexOf(startChar);
    final endIndex = raw.lastIndexOf(endChar);

    if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
      return raw.substring(startIndex, endIndex + 1);
    }
    return raw.replaceAll('```json', '').replaceAll('```', '').trim();
  }

  /// Parses passive-logging tags ([MEAL]/[SYMPTOM]/[SCAN]/[SWAPS]) from an
  /// AI response. When [persist] is false, tags are only STRIPPED/parsed for
  /// display — nothing is written to Firestore. Used by regenerate, where the
  /// original response already logged its tags.
  ProcessChatTagResult call(String text, {String? imageUrl, String? source, Set<String>? persistedTagBlocks, bool persist = true}) {
    String processedText = text;
    ScanResult? scanData;
    List<ProductSwap>? swapData;
    bool isSwap = false;
    final List<String> foodMentions = [];
    final List<String> symptomMentions = [];

    if (!processedText.contains('[/')) {
      return ProcessChatTagResult(text: processedText);
    }

    // 1. SYMPTOM
    if (processedText.contains('[/SYMPTOM]')) {
      final regex = RegExp(r'\[SYMPTOM\](.*?)\[/SYMPTOM\]', dotAll: true);
      final match = regex.firstMatch(processedText);
      if (match != null) {
        final rawBlock = match.group(0) ?? '';
        final alreadyPersisted = persistedTagBlocks?.contains(rawBlock) ?? false;

        if (!alreadyPersisted) {
          try {
            final jsonStr = _extractJson(match.group(1));
            if (jsonStr != null) {
              final Map<String, dynamic> decoded = jsonDecode(jsonStr);
              if (persist) {
                final log = SymptomLog.fromMap(decoded).copyWith(source: source ?? 'chat');
                _firestoreService.logSymptom(log);
                _appStateService.notifyChatUpdated();
              }

              if (decoded['symptom'] != null) {
                symptomMentions.add(decoded['symptom'].toString());
              }
              persistedTagBlocks?.add(rawBlock);
            }
          } catch (e) {
            AppLogger.error('ProcessChatTagUseCase: Symptom parse failed', error: e);
          }
        }
        processedText = processedText.replaceAll(regex, '').trim();
      }
    }

    // 2. MEAL
    if (processedText.contains('[/MEAL]')) {
      final regex = RegExp(r'\[MEAL\](.*?)\[/MEAL\]', dotAll: true);
      final match = regex.firstMatch(processedText);
      if (match != null) {
        final rawBlock = match.group(0) ?? '';
        final alreadyPersisted = persistedTagBlocks?.contains(rawBlock) ?? false;

        if (!alreadyPersisted) {
          try {
            final jsonStr = _extractJson(match.group(1));
            if (jsonStr != null) {
              final Map<String, dynamic> decoded = jsonDecode(jsonStr);

              final items = ModelUtils.parseList<String>(decoded['items']);
              final tags = ModelUtils.parseList<String>(decoded['tags']);

              if (persist) {
                final log = MealLog.fromMap({...decoded, 'photoUrl': imageUrl}).copyWith(source: source ?? 'chat', foodTags: tags);
                _firestoreService.logMeal(log);
                _notificationService.schedulePostMealCheckIn();
                _notificationService.scheduleNoMealLoggedReminder();
                _appStateService.notifyChatUpdated();
              }
              foodMentions.addAll(items);
              persistedTagBlocks?.add(rawBlock);
            }
          } catch (e) {
            AppLogger.error('ProcessChatTagUseCase: Meal parse failed', error: e);
          }
        }
        processedText = processedText.replaceAll(regex, '').trim();
      }
    }

    // 3. SCAN
    if (processedText.contains('[/SCAN]')) {
      final regex = RegExp(r'\[SCAN\](.*?)\[/SCAN\]', dotAll: true);
      final match = regex.firstMatch(processedText);
      if (match != null) {
        final rawBlock = match.group(0) ?? '';
        final alreadyPersisted = persistedTagBlocks?.contains(rawBlock) ?? false;

        try {
          final jsonStr = _extractJson(match.group(1));
          if (jsonStr != null) {
            final Map<String, dynamic> decoded = jsonDecode(jsonStr);

            final ingredientsList = ModelUtils.parseList<dynamic>(decoded['ingredients']);
            final List<String> flagged = [];
            if (ingredientsList.isNotEmpty) {
              for (var ing in ingredientsList) {
                if (ing is Map && (ing['colorName'] == 'red' || ing['colorName'] == 'orange')) {
                  flagged.add(ing['name']?.toString() ?? 'Unknown');
                }
              }
            }

            scanData = ScanResult.fromMap(decoded).copyWith(source: source, userImageUrl: imageUrl, flaggedIngredients: flagged);

            if (!alreadyPersisted) {
              AppLogger.info('ProcessChatTagUseCase: [SCAN] parsed successfully: ${scanData.productName}. Image: ${imageUrl != null}');
              if (persist) {
                // 🟢 Fix: Ensure AI Vision scans from chat are also saved to scan_history
                _firestoreService.saveToScanHistory(scanData, userImageUrl: imageUrl);
                _appStateService.notifyChatUpdated();
                AppLogger.info('ProcessChatTagUseCase: [SCAN] saved to scan_history and UI notified. UID: ${_firestoreService.getUserMetadata().then((p) => p?.uid)}');
              }
              persistedTagBlocks?.add(rawBlock);
            }
          }
        } catch (e) {
          AppLogger.error('ProcessChatTagUseCase: SCAN parse failed', error: e);
        }
        processedText = processedText.replaceAll(regex, '').replaceAll('```json', '').replaceAll('```', '').trim();
      }
    }

    // 4. SWAPS
    if (processedText.contains('[/SWAPS]')) {
      final regex = RegExp(r'\[SWAPS\](.*?)\[/SWAPS\]', dotAll: true);
      final match = regex.firstMatch(processedText);
      if (match != null) {
        final rawBlock = match.group(0) ?? '';
        final alreadyPersisted = persistedTagBlocks?.contains(rawBlock) ?? false;

        try {
          final jsonStr = _extractJson(match.group(1), isArray: true);
          if (jsonStr != null) {
            swapData = ModelUtils.parseModelList<ProductSwap>(jsonStr, ProductSwap.fromMap);
            isSwap = true;
            if (!alreadyPersisted) {
              persistedTagBlocks?.add(rawBlock);
            }
          }
        } catch (e) {
          AppLogger.error('ProcessChatTagUseCase: SWAPS parse failed', error: e);
        }
        processedText = processedText.replaceAll(regex, '').replaceAll('```json', '').replaceAll('```', '').trim();
      }
    }

    return ProcessChatTagResult(text: processedText, scanData: scanData, swapData: swapData, isSwap: isSwap, foodMentions: foodMentions, symptomMentions: symptomMentions);
  }
}
