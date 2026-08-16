import 'dart:async';
import 'dart:convert';

import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/models/symptom_log.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/firestore/history_firestore_service.dart';
import 'package:gutgood/core/services/notification_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/model_utils.dart';

class ProcessChatTagResult {
  ProcessChatTagResult({required this.text, this.scanData, this.swapData, this.isSwap = false, this.foodMentions = const [], this.symptomMentions = const []});
  final String text;
  final ScanResult? scanData;
  final List<ProductSwap>? swapData;
  final bool isSwap;
  final List<String> foodMentions;
  final List<String> symptomMentions;
}

class ProcessChatTagUseCase {
  ProcessChatTagUseCase({required HistoryFirestoreService firestoreService, required NotificationService notificationService, required AppStateService appStateService})
    : _firestoreService = firestoreService,
      _notificationService = notificationService,
      _appStateService = appStateService;
  final HistoryFirestoreService _firestoreService;
  final NotificationService _notificationService;
  final AppStateService _appStateService;

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

  ProcessChatTagResult call(String text, {String? imageUrl, String? source, Set<String>? persistedTagBlocks, bool persist = true, bool isFinal = false}) {
    var displayOutput = text;
    ScanResult? scanData;
    List<ProductSwap>? swapData;
    var isSwap = false;
    final foodMentions = <String>[];
    final symptomMentions = <String>[];

    final tags = ['SYMPTOM', 'MEAL', 'SCAN', 'SWAPS'];

    // --- STEP 1: PARSING (Always use the full original text) ---
    for (final tag in tags) {
      final startTag = '[$tag]';
      final endTag = '[/$tag]';
      
      int searchPos = 0;
      while (true) {
        int tagIndex = text.indexOf(startTag, searchPos);
        if (tagIndex == -1) break;
        
        int endTagIndex = text.indexOf(endTag, tagIndex + startTag.length);
        bool isClosed = endTagIndex != -1;
        
        String rawBlock = isClosed 
            ? text.substring(tagIndex, endTagIndex + endTag.length)
            : text.substring(tagIndex);
            
        String content = isClosed 
            ? text.substring(tagIndex + startTag.length, endTagIndex)
            : text.substring(tagIndex + startTag.length);

        final alreadyPersisted = persistedTagBlocks?.contains(rawBlock) ?? false;

        try {
          final jsonStr = _extractJson(content, isArray: tag == 'SWAPS');
          if (jsonStr != null) {
            final decoded = jsonDecode(jsonStr);
            
            if (tag == 'SYMPTOM' && decoded is Map<String, dynamic>) {
              if (!alreadyPersisted && (isClosed || isFinal)) {
                if (persist) {
                  final log = SymptomLog.fromMap(decoded).copyWith(source: source ?? 'chat');
                  unawaited(_firestoreService.logSymptom(log));
                  _appStateService.notifyChatUpdated();
                }
                persistedTagBlocks?.add(rawBlock);
              }
              if (decoded['symptom'] != null) symptomMentions.add(decoded['symptom'].toString());
            } else if (tag == 'MEAL' && decoded is Map<String, dynamic>) {
              if (!alreadyPersisted && (isClosed || isFinal)) {
                if (persist) {
                  final log = MealLog.fromMap({...decoded, 'photoUrl': imageUrl}).copyWith(source: source ?? 'chat');
                  unawaited(_firestoreService.logMeal(log));
                  _appStateService.notifyChatUpdated();
                  persistedTagBlocks?.add('__MEAL_LOGGED_IN_TURN__');
                }
                persistedTagBlocks?.add(rawBlock);
              }
              final items = ModelUtils.parseList<String>(decoded['items']);
              foodMentions.addAll(items);
            } else if (tag == 'SCAN' && decoded is Map<String, dynamic>) {
              final currentScan = ScanResult.fromMap(decoded).copyWith(source: source, userImageUrl: imageUrl);
              scanData = currentScan;
              
              if (!alreadyPersisted && (isClosed || isFinal)) {
                if (persist && currentScan.isLoggableProduct) {
                  unawaited(_firestoreService.saveToScanHistory(currentScan, userImageUrl: imageUrl));

                  final isFoodImage = source == 'food' || source == 'meal' || source == 'gallery' || imageUrl != null;
                  final alreadyLogged = persistedTagBlocks?.contains('__MEAL_LOGGED_IN_TURN__') ?? false;
                  if (isFoodImage && !alreadyLogged) {
                    final mealLog = MealLog(items: [currentScan.productName], photoUrl: imageUrl ?? currentScan.imageUrl, time: DateTime.now(), source: source ?? 'chat');
                    unawaited(_firestoreService.logMeal(mealLog));
                    persistedTagBlocks?.add('__MEAL_LOGGED_IN_TURN__');
                  }
                  _appStateService.notifyChatUpdated();
                }
                persistedTagBlocks?.add(rawBlock);
              }
            } else if (tag == 'SWAPS' && decoded is List) {
              swapData = ModelUtils.parseModelList<ProductSwap>(jsonStr, ProductSwap.fromMap);
              isSwap = true;
              if (!alreadyPersisted && (isClosed || isFinal)) persistedTagBlocks?.add(rawBlock);
            }
          }
        } catch (e) {
          // Streaming noise
        }
        
        if (!isClosed) break;
        searchPos = endTagIndex + endTag.length;
      }
    }

    // --- STEP 2: UI STRIPPING (Proactively hide EVERYTHING from the first tag onwards) ---
    int firstTagPos = -1;
    for (final tag in tags) {
      int pos = text.indexOf('[$tag]');
      if (pos != -1) {
        if (firstTagPos == -1 || pos < firstTagPos) {
          firstTagPos = pos;
        }
      }
    }

    if (firstTagPos != -1) {
      // Find potential markdown headers immediately preceding the first tag
      int startIndex = firstTagPos;
      while (startIndex > 0 && (text[startIndex - 1] == '#' || text[startIndex - 1] == ' ' || text[startIndex - 1] == '\n' || text[startIndex - 1] == '\r')) {
        startIndex--;
      }
      displayOutput = text.substring(0, startIndex).trim();
    }

    return ProcessChatTagResult(text: displayOutput, scanData: scanData, swapData: swapData, isSwap: isSwap, foodMentions: foodMentions, symptomMentions: symptomMentions);
  }
}
