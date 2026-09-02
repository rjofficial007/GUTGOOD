import 'dart:convert';

import 'package:gutgood/core/models/ai_analysis_result.dart';
import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/models/symptom_log.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/model_utils.dart';

class ProcessChatTagUseCase {
  ProcessChatTagUseCase();

  AiAnalysisResult call(String text, {String? imageUrl, String? source, String? chatMessageId, bool isFinal = false}) {
    var displayOutput = text;
    String? intent;
    String? imageMode;
    ScanResult? scanData;
    MealLog? mealLog;
    final symptomLogs = <SymptomLog>[];
    var swapsList = <ProductSwap>[];
    Map<String, dynamic>? menuData;
    final metadata = <String, dynamic>{};

    // --- STEP 1: PARSING NEW UNIFIED DATA BLOCK ---
    final lowerText = text.toLowerCase();
    const unifiedTag = 'gutgood_data';
    const startTag = '[$unifiedTag]';
    const endTag = '[/$unifiedTag]';

    final tagIndex = lowerText.indexOf(startTag);
    Map<String, dynamic>? decoded;

    if (tagIndex != -1) {
      final endTagIndex = lowerText.indexOf(endTag, tagIndex + startTag.length);
      final isClosed = endTagIndex != -1;
      final content = isClosed ? text.substring(tagIndex + startTag.length, endTagIndex) : text.substring(tagIndex + startTag.length);

      try {
        final jsonStr = ModelUtils.extractJson(content);
        if (jsonStr != null) {
          decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        }
      } catch (e) {
        if (isFinal) AppLogger.warning('ProcessChatTagUseCase: Failed to parse unified data', error: e);
      }
    } else {
      // 🚀 ROBUST FALLBACK: If no tags are found, attempt to parse the entire text as JSON.
      // This handles cases where the AI is forced into JSON mode or ignores instructions.
      try {
        final jsonStr = ModelUtils.extractJson(text);
        if (jsonStr != null) {
          final rawDecoded = jsonDecode(jsonStr);
          if (rawDecoded is Map<String, dynamic>) {
            // Check if it's a flat scan object or a unified block
            if (rawDecoded.containsKey('scan') || rawDecoded.containsKey('intent')) {
              decoded = rawDecoded;
            } else if (rawDecoded.containsKey('productName') || rawDecoded.containsKey('score')) {
              // It's a flat scan object, wrap it for unified processing
              decoded = {'scan': rawDecoded};
            }
          }
        }
      } catch (_) {}
    }

    if (decoded != null) {
      intent = decoded['intent']?.toString();
      imageMode = decoded['image_mode']?.toString();

      if (decoded['scan'] != null && decoded['scan'] is Map<String, dynamic>) {
        final scanMap = Map<String, dynamic>.from(decoded['scan']);
        if (decoded['menu'] != null) {
          scanMap['menu'] = decoded['menu'];
        }
        // 🚀 Professional ID Mapping: Ensure the scanId used in Firestore (convention: msgId_scan)
        // is attached to the model so hydration works correctly when viewing full reports.
        // We also pass 'decoded' as rawData so all context (meal strategy, etc.) is preserved.
        scanData = ScanResult.fromMap(
          scanMap,
        ).copyWith(source: imageMode ?? source, userImageUrl: imageUrl, chatMessageId: chatMessageId, scanId: chatMessageId != null ? '${chatMessageId}_scan' : null, rawData: decoded);
      }

      if (decoded['menu'] != null && decoded['menu'] is Map<String, dynamic>) {
        menuData = decoded['menu'];
      } else if (intent == 'menu_analysis' || source == 'menu') {
        // Support unified format where menu items are in 'scan' and strategy is in 'meal'
        menuData = decoded;
      }

      if (decoded['meal'] != null && decoded['meal'] is Map<String, dynamic>) {
        // 🚀 Unified Data Strategy: If we have a 'scan' block, we treat the 'meal' info
        // as part of the scan's rich context (rawData) rather than a separate loggable entity.
        // This prevents duplicate entries in the journal history.
        if (scanData == null) {
          mealLog = MealLog.fromMap({...decoded['meal'], 'photoUrl': imageUrl, 'chatMessageId': chatMessageId}).copyWith(source: source ?? 'chat');
        }
      }

      if (decoded['symptoms'] != null && decoded['symptoms'] is List) {
        for (final s in decoded['symptoms']) {
          if (s is Map<String, dynamic>) {
            symptomLogs.add(SymptomLog.fromMap({...s, 'chatMessageId': chatMessageId}).copyWith(source: source ?? 'chat'));
          } else if (s != null && s is String && s.isNotEmpty) {
            // 🚀 Robust Fallback: Handle cases where AI returns a simple string list instead of objects
            symptomLogs.add(SymptomLog(symptom: s, chatMessageId: chatMessageId, createdAt: DateTime.now(), source: source ?? 'chat'));
          }
        }
      }

      if (decoded['swaps'] != null && decoded['swaps'] is List) {
        swapsList = ModelUtils.parseModelList<ProductSwap>(decoded['swaps'], ProductSwap.fromMap);
      }

      if (decoded['metadata'] != null && decoded['metadata'] is Map<String, dynamic>) {
        metadata.addAll(decoded['metadata']);
      }
    }

    // --- STEP 2: LEGACY FALLBACK FOR HISTORICAL MESSAGES ---
    if (intent == null && scanData == null && mealLog == null && symptomLogs.isEmpty && swapsList.isEmpty) {
      final legacyTags = ['INTENT', 'SYMPTOM', 'MEAL', 'SCAN', 'SWAPS', 'SCAN_CONTEXT'];
      for (final tag in legacyTags) {
        final lStart = '[${tag.toLowerCase()}]';
        final lEnd = '[/${tag.toLowerCase()}]';
        final lIndex = lowerText.indexOf(lStart);
        if (lIndex != -1) {
          final lEndIndex = lowerText.indexOf(lEnd, lIndex + lStart.length);
          final lContent = lEndIndex != -1 ? text.substring(lIndex + lStart.length, lEndIndex) : text.substring(lIndex + lStart.length);
          try {
            final jsonStr = ModelUtils.extractJson(lContent, isArray: tag == 'SWAPS');
            if (jsonStr != null) {
              final decoded = jsonDecode(jsonStr);
              if (tag == 'INTENT' && decoded is Map) {
                intent = decoded['category']?.toString();
              } else if ((tag == 'SCAN' || tag == 'SCAN_CONTEXT') && decoded is Map) {
                final scanMap = Map<String, dynamic>.from(decoded);
                scanData = ScanResult.fromMap(
                  scanMap,
                ).copyWith(source: source, userImageUrl: imageUrl, chatMessageId: chatMessageId, scanId: chatMessageId != null ? '${chatMessageId}_scan' : null, rawData: scanMap);
              } else if (tag == 'MEAL' && decoded is Map) {
                mealLog = MealLog.fromMap(Map<String, dynamic>.from(decoded)).copyWith(source: source ?? 'chat');
              } else if (tag == 'SYMPTOM' && decoded is Map) {
                symptomLogs.add(SymptomLog.fromMap(Map<String, dynamic>.from(decoded)).copyWith(source: source ?? 'chat'));
              } else if (tag == 'SWAPS') {
                swapsList = ModelUtils.parseModelList<ProductSwap>(decoded, ProductSwap.fromMap);
              }
            }
          } catch (_) {}
        }
      }
    }

    // --- STEP 3: UI STRIPPING ---
    final firstTagRegex = RegExp(r'\[(GUTGOOD_DATA|INTENT|SYMPTOM|MEAL|SCAN|SWAPS|SCAN_CONTEXT)\]', caseSensitive: false);
    final match = firstTagRegex.firstMatch(text);

    if (match != null) {
      var startIndex = match.start;
      while (startIndex > 0 && (text[startIndex - 1] == '#' || text[startIndex - 1] == ' ' || text[startIndex - 1] == '\n' || text[startIndex - 1] == '\r')) {
        startIndex--;
      }
      displayOutput = text.substring(0, startIndex).trim();
    }

    // 🚀 Professional Sync: Ensure swaps are attached to scanData for consistent UI & persistence.
    if (scanData != null && swapsList.isNotEmpty && scanData.swaps.isEmpty) {
      scanData = scanData.copyWith(swaps: swapsList);
    }

    return AiAnalysisResult(text: displayOutput, intent: intent, imageMode: imageMode, scan: scanData, meal: mealLog, symptoms: symptomLogs, swaps: swapsList, menu: menuData, metadata: metadata);
  }
}
