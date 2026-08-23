import 'dart:async';
import 'dart:convert';

import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/models/symptom_log.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/firestore/history_firestore_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/model_utils.dart';

class ProcessChatTagResult {
  ProcessChatTagResult({required this.text, this.scanData, this.swapData, this.isSwap = false, this.foodMentions = const [], this.symptomMentions = const [], this.mealLogs = const [], this.symptomLogs = const []});
  final String text;
  final ScanResult? scanData;
  final List<ProductSwap>? swapData;
  final bool isSwap;
  final List<String> foodMentions;
  final List<String> symptomMentions;
  final List<MealLog> mealLogs;
  final List<SymptomLog> symptomLogs;
}

class ProcessChatTagUseCase {
  ProcessChatTagUseCase({required HistoryFirestoreService firestoreService, required AppStateService appStateService}) : _firestoreService = firestoreService, _appStateService = appStateService;
  final HistoryFirestoreService _firestoreService;
  final AppStateService _appStateService;

  ProcessChatTagResult call(String text, {String? imageUrl, String? source, Set<String>? persistedTagBlocks, bool persist = true, bool isFinal = false, String? chatMessageId}) {
    var displayOutput = text;
    ScanResult? scanData;
    List<ProductSwap>? swapData;
    var isSwap = false;
    final foodMentions = <String>[];
    final symptomMentions = <String>[];
    final mealLogs = <MealLog>[];
    final symptomLogs = <SymptomLog>[];

    final tags = ['SYMPTOM', 'MEAL', 'SCAN', 'SWAPS'];

    // --- STEP 1: PARSING (Always use the full original text) ---
    final lowerText = text.toLowerCase();
    for (final tag in tags) {
      final startTag = '[${tag.toLowerCase()}]';
      final endTag = '[/${tag.toLowerCase()}]';

      var searchPos = 0;
      while (true) {
        final tagIndex = lowerText.indexOf(startTag, searchPos);
        if (tagIndex == -1) break;

        final endTagIndex = lowerText.indexOf(endTag, tagIndex + startTag.length);
        final isClosed = endTagIndex != -1;

        final rawBlock = isClosed ? text.substring(tagIndex, endTagIndex + endTag.length) : text.substring(tagIndex);

        final content = isClosed ? text.substring(tagIndex + startTag.length, endTagIndex) : text.substring(tagIndex + startTag.length);

        // 🟢 DATA INTEGRITY: Normalize the block for the persistence check to
        // prevent duplicates caused by streaming noise (extra spaces/newlines).
        final normalizedContent = content.trim();
        final persistenceKey = '${tag}_$normalizedContent';
        final alreadyPersisted = persistedTagBlocks?.contains(persistenceKey) ?? false;

        try {
          // Use balanced bracket extraction for robust JSON isolation
          final isArray = tag == 'SWAPS';
          final jsonStr = ModelUtils.extractJson(content, isArray: isArray);

          if (jsonStr != null) {
            final decoded = jsonDecode(jsonStr);

            if (tag == 'SYMPTOM' && decoded is Map<String, dynamic>) {
              AppLogger.debug('ProcessChatTag: Detected SYMPTOM tag');
              final log = SymptomLog.fromMap({...decoded, 'chatMessageId': chatMessageId}).copyWith(source: source ?? 'chat');
              symptomLogs.add(log);

              if (!alreadyPersisted && (isClosed || isFinal)) {
                if (persist) {
                  final log = SymptomLog.fromMap({...decoded, 'chatMessageId': chatMessageId}).copyWith(source: source ?? 'chat');
                  AppLogger.ai('Logging symptom: ${log.symptom}');
                  unawaited(_firestoreService.logSymptom(log));
                  _appStateService.notifyChatUpdated();
                }
                persistedTagBlocks?.add(persistenceKey);
              }
              if (decoded['symptom'] != null) symptomMentions.add(decoded['symptom'].toString());
            } else if (tag == 'MEAL' && decoded is Map<String, dynamic>) {
              AppLogger.debug('ProcessChatTag: Detected MEAL tag');
              final log = MealLog.fromMap({...decoded, 'photoUrl': imageUrl, 'chatMessageId': chatMessageId}).copyWith(source: source ?? 'chat');
              mealLogs.add(log);

              if (!alreadyPersisted && (isClosed || isFinal)) {
                if (persist) {
                  final log = MealLog.fromMap({...decoded, 'photoUrl': imageUrl, 'chatMessageId': chatMessageId}).copyWith(source: source ?? 'chat');
                  AppLogger.ai('Logging meal with ${log.items.length} items');
                  unawaited(_firestoreService.logMeal(log));
                  _appStateService.notifyChatUpdated();
                  persistedTagBlocks?.add('__MEAL_LOGGED_IN_TURN__');
                }
                persistedTagBlocks?.add(persistenceKey);
              }
              final items = ModelUtils.parseList<String>(decoded['items']);
              foodMentions.addAll(items);
            } else if (tag == 'SCAN' && decoded is Map<String, dynamic>) {
              final scanIdx = persistedTagBlocks?.where((e) => e.startsWith('SCAN_INDEX_')).length ?? 0;
              final stableScanId = chatMessageId != null ? '${chatMessageId}_scan_$scanIdx' : null;

              final currentScan = ScanResult.fromMap(decoded).copyWith(
                source: source,
                userImageUrl: imageUrl,
                scanId: stableScanId,
                chatMessageId: chatMessageId,
              );
              scanData = currentScan;

              if (!alreadyPersisted && (isClosed || isFinal)) {
                if (persist && currentScan.isLoggableProduct) {
                  AppLogger.ai('Logging scan from chat: ${currentScan.productName} (ID: $stableScanId)');
                  unawaited(_firestoreService.saveToScanHistory(currentScan, userImageUrl: imageUrl, scanId: stableScanId));

                  final isFoodImage = source == 'food' || source == 'meal' || source == 'gallery' || imageUrl != null;
                  final alreadyLogged = persistedTagBlocks?.contains('__MEAL_LOGGED_IN_TURN__') ?? false;
                  if (isFoodImage && !alreadyLogged) {
                    final mealLog = MealLog(
                      items: [currentScan.productName],
                      photoUrl: imageUrl ?? currentScan.imageUrl,
                      time: currentScan.time ?? DateTime.now(),
                      source: source ?? 'chat',
                      chatMessageId: chatMessageId,
                    );
                    unawaited(_firestoreService.logMeal(mealLog));
                    persistedTagBlocks?.add('__MEAL_LOGGED_IN_TURN__');
                  }
                  _appStateService.notifyChatUpdated();
                }
                persistedTagBlocks?.add(persistenceKey);
                if (chatMessageId != null) persistedTagBlocks?.add('SCAN_INDEX_$scanIdx');
              }
            } else if (tag == 'SWAPS') {
              // For SWAPS, we accept either a direct List or a Map containing a list
              final List<dynamic> swapsList = decoded is List ? decoded : (decoded is Map && decoded['swaps'] is List ? decoded['swaps'] : []);

              if (swapsList.isNotEmpty) {
                swapData = ModelUtils.parseModelList<ProductSwap>(swapsList, ProductSwap.fromMap);
                isSwap = true;
                if (!alreadyPersisted && (isClosed || isFinal)) persistedTagBlocks?.add(persistenceKey);
              }
            }
          } else if (tag == 'SWAPS' && content.trim().startsWith('[') && content.trim().length > 1) {
            // FALLBACK: If extraction failed but we clearly have a starting bracket, flag it as a swap
            // to ensure UI truncation happens even if the JSON is still streaming/invalid.
            isSwap = true;
          }
        } catch (e) {
          // Streaming noise - keep isSwap true if we already identified the tag
          if (tag == 'SWAPS') isSwap = true;
        }

        if (!isClosed) break;
        searchPos = endTagIndex + endTag.length;
      }
    }

    // --- STEP 2: UI STRIPPING (Proactively hide EVERYTHING from the first tag onwards) ---
    // We use a Case-Insensitive Regex to find the first tag to be more robust.
    final firstTagRegex = RegExp(r'\[(SYMPTOM|MEAL|SCAN|SWAPS)\]', caseSensitive: false);
    final match = firstTagRegex.firstMatch(text);

    if (match != null) {
      var startIndex = match.start;
      // Find potential markdown headers immediately preceding the first tag
      while (startIndex > 0 && (text[startIndex - 1] == '#' || text[startIndex - 1] == ' ' || text[startIndex - 1] == '\n' || text[startIndex - 1] == '\r')) {
        startIndex--;
      }
      displayOutput = text.substring(0, startIndex).trim();
    }

    return ProcessChatTagResult(text: displayOutput, scanData: scanData, swapData: swapData, isSwap: isSwap, foodMentions: foodMentions, symptomMentions: symptomMentions, mealLogs: mealLogs, symptomLogs: symptomLogs);
  }
}
