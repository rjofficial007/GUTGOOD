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
    ScanResult? scanData;
    MealLog? mealLog;
    final symptomLogs = <SymptomLog>[];
    var swapsList = <ProductSwap>[];
    final metadata = <String, dynamic>{};

    // --- STEP 1: PARSING NEW UNIFIED DATA BLOCK ---
    final lowerText = text.toLowerCase();
    const unifiedTag = 'gutgood_data';
    const startTag = '[$unifiedTag]';
    const endTag = '[/$unifiedTag]';

    final tagIndex = lowerText.indexOf(startTag);
    if (tagIndex != -1) {
      final endTagIndex = lowerText.indexOf(endTag, tagIndex + startTag.length);
      final isClosed = endTagIndex != -1;
      final content = isClosed 
          ? text.substring(tagIndex + startTag.length, endTagIndex) 
          : text.substring(tagIndex + startTag.length);

      try {
        final jsonStr = ModelUtils.extractJson(content);
        if (jsonStr != null) {
          final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
          
          intent = decoded['intent']?.toString();
          
          if (decoded['scan'] != null && decoded['scan'] is Map<String, dynamic>) {
            scanData = ScanResult.fromMap(decoded['scan']).copyWith(
              source: source,
              userImageUrl: imageUrl,
              chatMessageId: chatMessageId,
            );
          }
          
          if (decoded['meal'] != null && decoded['meal'] is Map<String, dynamic>) {
            mealLog = MealLog.fromMap({
              ...decoded['meal'],
              'photoUrl': imageUrl,
              'chatMessageId': chatMessageId,
            }).copyWith(source: source ?? 'chat');
          }
          
          if (decoded['symptoms'] != null && decoded['symptoms'] is List) {
            for (final s in decoded['symptoms']) {
              if (s is Map<String, dynamic>) {
                symptomLogs.add(SymptomLog.fromMap({
                  ...s,
                  'chatMessageId': chatMessageId,
                }).copyWith(source: source ?? 'chat'));
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
      } catch (e) {
        if (isFinal) AppLogger.warning('ProcessChatTagUseCase: Failed to parse unified data', error: e);
      }
    }

    // --- STEP 2: LEGACY FALLBACK FOR HISTORICAL MESSAGES ---
    if (intent == null && scanData == null && mealLog == null && symptomLogs.isEmpty && swapsList.isEmpty) {
      final legacyTags = ['INTENT', 'SYMPTOM', 'MEAL', 'SCAN', 'SWAPS'];
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
              } else if (tag == 'SCAN' && decoded is Map) {
                scanData = ScanResult.fromMap(Map<String, dynamic>.from(decoded)).copyWith(source: source, userImageUrl: imageUrl, chatMessageId: chatMessageId);
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
    final firstTagRegex = RegExp(r'\[(GUTGOOD_DATA|INTENT|SYMPTOM|MEAL|SCAN|SWAPS)\]', caseSensitive: false);
    final match = firstTagRegex.firstMatch(text);

    if (match != null) {
      var startIndex = match.start;
      while (startIndex > 0 && (text[startIndex - 1] == '#' || text[startIndex - 1] == ' ' || text[startIndex - 1] == '\n' || text[startIndex - 1] == '\r')) {
        startIndex--;
      }
      displayOutput = text.substring(0, startIndex).trim();
    }

    return AiAnalysisResult(
      text: displayOutput,
      intent: intent,
      scan: scanData,
      meal: mealLog,
      symptoms: symptomLogs,
      swaps: swapsList,
      metadata: metadata,
    );
  }
}
