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

    final tags = ['INTENT', 'SYMPTOM', 'MEAL', 'SCAN', 'SWAPS'];

    // --- STEP 1: PARSING ---
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

        final content = isClosed ? text.substring(tagIndex + startTag.length, endTagIndex) : text.substring(tagIndex + startTag.length);

        try {
          final isArray = tag == 'SWAPS';
          final jsonStr = ModelUtils.extractJson(content, isArray: isArray);

          if (jsonStr != null) {
            final decoded = jsonDecode(jsonStr);

            if (tag == 'INTENT' && decoded is Map<String, dynamic>) {
              intent = decoded['category']?.toString();
              metadata['intentConfidence'] = decoded['confidence'];
            } else if (tag == 'SYMPTOM' && decoded is Map<String, dynamic>) {
              final log = SymptomLog.fromMap({...decoded, 'chatMessageId': chatMessageId}).copyWith(source: source ?? 'chat');
              symptomLogs.add(log);
            } else if (tag == 'MEAL' && decoded is Map<String, dynamic>) {
              mealLog = MealLog.fromMap({...decoded, 'photoUrl': imageUrl, 'chatMessageId': chatMessageId}).copyWith(source: source ?? 'chat');
            } else if (tag == 'SCAN' && decoded is Map<String, dynamic>) {
              scanData = ScanResult.fromMap(decoded).copyWith(source: source, userImageUrl: imageUrl, chatMessageId: chatMessageId);
            } else if (tag == 'SWAPS') {
              final List<dynamic> list = decoded is List ? decoded : (decoded is Map && decoded['swaps'] is List ? decoded['swaps'] : []);
              if (list.isNotEmpty) {
                swapsList = ModelUtils.parseModelList<ProductSwap>(list, ProductSwap.fromMap);
              }
            }
          }
        } catch (e) {
          // 🟢 SILENCE STREAMING NOISE: Only log parsing failures as warnings
          // if this is the final turn result. Partial tokens are EXPECTED
          // to fail occasionally during streaming as tags are being built.
          if (isFinal) {
            AppLogger.warning('ProcessChatTagUseCase: Failed to parse $tag block', error: e);
          }
        }

        if (!isClosed) break;
        searchPos = endTagIndex + endTag.length;
      }
    }

    // --- STEP 2: UI STRIPPING ---
    final firstTagRegex = RegExp(r'\[(INTENT|SYMPTOM|MEAL|SCAN|SWAPS)\]', caseSensitive: false);
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
