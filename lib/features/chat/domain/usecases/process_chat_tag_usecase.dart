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

  AiAnalysisResult call(String text, {String? userText, String? imageUrl, String? source, String? chatMessageId, bool isFinal = false}) {
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
        // The layered insight (positives / ranked concerns / nutrition /
        // personalised / warnings) lives as a sibling of "scan" in the unified
        // block, so fold it in here — the scan model can't see it otherwise.
        if (decoded['insight'] != null) {
          scanMap['insight'] = decoded['insight'];
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

      final resolvedMode = (imageMode ?? source ?? '').toUpperCase();
      final resolvedIntent = (intent ?? '').toUpperCase();
      final isLabelOrMenuScan =
          resolvedMode.contains('LABEL') ||
          resolvedMode.contains('MENU') ||
          resolvedMode.contains('PACKAGED_PRODUCT') ||
          resolvedIntent.contains('LABEL') ||
          resolvedIntent.contains('MENU') ||
          resolvedIntent.contains('INGREDIENT');

      if (decoded['meal'] != null && decoded['meal'] is Map<String, dynamic> && !isLabelOrMenuScan) {
        if (scanData == null) {
          mealLog = MealLog.fromMap({...decoded['meal'], 'photoUrl': imageUrl, 'chatMessageId': chatMessageId}).copyWith(source: source ?? 'chat');
        }
      }

      if (decoded['symptoms'] != null) {
        final rawSymptoms = decoded['symptoms'];
        if (rawSymptoms is List) {
          for (final s in rawSymptoms) {
            if (s is Map) {
              final map = Map<String, dynamic>.from(s);
              symptomLogs.add(SymptomLog.fromMap({...map, 'chatMessageId': chatMessageId}).copyWith(source: source ?? 'chat'));
            } else if (s != null && s.toString().trim().isNotEmpty) {
              symptomLogs.add(SymptomLog(symptom: s.toString().trim(), chatMessageId: chatMessageId, createdAt: DateTime.now(), source: source ?? 'chat'));
            }
          }
        } else if (rawSymptoms is Map) {
          final map = Map<String, dynamic>.from(rawSymptoms);
          symptomLogs.add(SymptomLog.fromMap({...map, 'chatMessageId': chatMessageId}).copyWith(source: source ?? 'chat'));
        } else if (rawSymptoms is String && rawSymptoms.trim().isNotEmpty) {
          symptomLogs.add(SymptomLog(symptom: rawSymptoms.trim(), chatMessageId: chatMessageId, createdAt: DateTime.now(), source: source ?? 'chat'));
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
                if (decoded['confidence'] != null) {
                  metadata['intentConfidence'] = (decoded['confidence'] as num).toDouble();
                }
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

    // --- STEP 2.5: FALLBACK SYMPTOM EXTRACTION FROM USER TEXT ---
    // NOTE: this crude keyword-regex path only runs when the AI did not return a
    // structured `symptoms` entry in [GUTGOOD_DATA] (or the legacy [SYMPTOM] tag).
    // CRITICAL FIX: We now scan the ORIGINAL userText instead of the AI reply 'text'
    // to prevent hallucinated symptoms (e.g. AI mentioning "fullness" in a reply
    // shouldn't trigger a symptom log if the user didn't say it).
    if (symptomLogs.isEmpty && userText != null && userText.trim().isNotEmpty) {
      final userTextLower = userText.toLowerCase();
      final fallbackSymptomCountBefore = symptomLogs.length;

      // 1. Energy
      if (userTextLower.contains('energetic') ||
          userTextLower.contains('feel energetic') ||
          userTextLower.contains('feeling energetic') ||
          userTextLower.contains('high energy') ||
          userTextLower.contains('energized')) {
        symptomLogs.add(SymptomLog(symptom: 'Energetic', energyLevel: 8, notes: 'Extracted from user message', chatMessageId: chatMessageId, createdAt: DateTime.now(), source: source ?? 'chat'));
      } else if (userTextLower.contains('tired') ||
          userTextLower.contains('fatigue') ||
          userTextLower.contains('exhausted') ||
          userTextLower.contains('low energy') ||
          userTextLower.contains('sluggish') ||
          userTextLower.contains('brain fog')) {
        symptomLogs.add(SymptomLog(symptom: 'Fatigue', energyLevel: 2, notes: 'Extracted from user message', chatMessageId: chatMessageId, createdAt: DateTime.now(), source: source ?? 'chat'));
      }
      // 2. Bloating
      else if (userTextLower.contains('bloat') || userTextLower.contains('bloated') || userTextLower.contains('bloating')) {
        symptomLogs.add(SymptomLog(symptom: 'Bloating', severity: 5, notes: 'Extracted from user message', chatMessageId: chatMessageId, createdAt: DateTime.now(), source: source ?? 'chat'));
      }
      // 3. Headache
      else if (userTextLower.contains('headache') || userTextLower.contains('migraine') || userTextLower.contains('head pain')) {
        symptomLogs.add(SymptomLog(symptom: 'Headache', severity: 5, notes: 'Extracted from user message', chatMessageId: chatMessageId, createdAt: DateTime.now(), source: source ?? 'chat'));
      }
      // 4. Digestion
      else if (userTextLower.contains('digest') ||
          userTextLower.contains('indigestion') ||
          userTextLower.contains('gas') ||
          userTextLower.contains('constipat') ||
          userTextLower.contains('diarrhea') ||
          userTextLower.contains('reflux') ||
          userTextLower.contains('heartburn')) {
        symptomLogs.add(SymptomLog(symptom: 'Digestive Shift', severity: 5, notes: 'Extracted from user message', chatMessageId: chatMessageId, createdAt: DateTime.now(), source: source ?? 'chat'));
      }
      // 5. Fullness & Satiety
      else if (userTextLower.contains('full') || userTextLower.contains('satiat') || userTextLower.contains('stuffed') || userTextLower.contains('hungry') || userTextLower.contains('hunger')) {
        final isHungry = userTextLower.contains('hungry') || userTextLower.contains('hunger');
        symptomLogs.add(
          SymptomLog(symptom: isHungry ? 'Hunger' : 'Fullness', severity: 3, notes: 'Extracted from user message', chatMessageId: chatMessageId, createdAt: DateTime.now(), source: source ?? 'chat'),
        );
      }
      // 6. Sleep
      else if (userTextLower.contains('sleep') || userTextLower.contains('insomnia') || userTextLower.contains('slept') || userTextLower.contains('rested')) {
        final isPoor = userTextLower.contains('poor') || userTextLower.contains('bad') || userTextLower.contains("can't sleep") || userTextLower.contains('insomnia');
        symptomLogs.add(
          SymptomLog(symptom: 'Sleep Shift', sleep: isPoor ? 'Poor' : 'Good', notes: 'Extracted from user message', chatMessageId: chatMessageId, createdAt: DateTime.now(), source: source ?? 'chat'),
        );
      }
      // Other physical reactions
      else if (userTextLower.contains('nausea') || userTextLower.contains('nauseous')) {
        symptomLogs.add(SymptomLog(symptom: 'Nausea', severity: 5, notes: 'Extracted from user message', chatMessageId: chatMessageId, createdAt: DateTime.now(), source: source ?? 'chat'));
      } else if (userTextLower.contains('cramp') || userTextLower.contains('stomach pain') || userTextLower.contains('stomach ache')) {
        symptomLogs.add(SymptomLog(symptom: 'Abdominal Pain', severity: 6, notes: 'Extracted from user message', chatMessageId: chatMessageId, createdAt: DateTime.now(), source: source ?? 'chat'));
      }

      if (symptomLogs.length > fallbackSymptomCountBefore) {
        AppLogger.warning(
          'ProcessChatTagUseCase: keyword-regex symptom fallback fired '
          '(AI did not return a structured symptoms entry) — extracted '
          '"${symptomLogs.last.symptom}" from user text.',
        );
      }
    }

    // --- STEP 2.6: ENRICH SYMPTOMS WITH FOOD NAME AND IMAGE URL ---
    final resolvedFoodName = scanData?.productName ?? (mealLog != null && mealLog.items.isNotEmpty ? mealLog.items.join(', ') : null);
    final resolvedImageUrl = imageUrl ?? scanData?.userImageUrl ?? scanData?.imageUrl;

    if (symptomLogs.isNotEmpty && (resolvedFoodName != null || resolvedImageUrl != null)) {
      final enrichedSymptoms = symptomLogs.map((s) => s.copyWith(foodName: s.foodName ?? resolvedFoodName, imageUrl: s.imageUrl ?? resolvedImageUrl)).toList();
      symptomLogs
        ..clear()
        ..addAll(enrichedSymptoms);
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

    final confidence = (metadata['confidence'] as num?)?.toDouble();

    return AiAnalysisResult(
      text: displayOutput,
      intent: intent,
      imageMode: imageMode,
      scan: scanData,
      meal: mealLog,
      symptoms: symptomLogs,
      swaps: swapsList,
      menu: menuData,
      metadata: metadata,
      confidence: confidence,
    );
  }
}
