import 'dart:convert';

import 'package:gutgood/core/ai/protocol/ai_constants.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/utils/ai_display_text.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/model_utils.dart';

/// Maximum cards returned per generation; keep usable partial results.
const int kSwapCardCount = 4;

SwapNutrition _markSwapNutritionAsEstimate(SwapNutrition nutrition) {
  if (!nutrition.hasData || nutrition.basis?.toLowerCase().contains('not verified') == true) return nutrition;
  final basis = nutrition.basis?.trim();
  return SwapNutrition(
    calories: nutrition.calories,
    protein: nutrition.protein,
    totalFat: nutrition.totalFat,
    fiber: nutrition.fiber,
    basis: basis?.isNotEmpty == true ? 'AI estimate · $basis · not verified' : 'AI-generated estimate · serving basis not recorded · not verified',
  );
}

/// Keep meaningful, distinct recommendations and hydrate matching catalog facts.
/// Catalog candidates are not recommendations until the response selects them.
List<ProductSwap> normalizeSwapCards(List<ProductSwap> swaps, List<ProductSwap> fallback) {
  final kept = <ProductSwap>[];
  final names = <String>{};
  final barcodes = <String>{};
  for (var swap in swaps) {
    final name = swap.title.trim().toLowerCase();
    if (name.isEmpty || name == 'string' || swap.subtitle.trim().isEmpty) continue;
    final replaces = swap.toAlternative().replaces?.trim().toLowerCase();
    if (name == replaces) continue;
    final matches = fallback.where((candidate) => (swap.barcode?.isNotEmpty == true && candidate.barcode == swap.barcode) || candidate.title.trim().toLowerCase() == name);
    final product = matches.isEmpty ? null : matches.first;
    final details = swap.toAlternative();
    final hasUnverifiedFacts = product == null && (fallback.isNotEmpty || details.nutrition.hasData || swap.imageUrl != null || swap.barcode != null || swap.nutriscore != null);
    if (product != null || hasUnverifiedFacts) {
      // Keep model-provided nutrition visible as an explicitly unverified
      // estimate; matched catalog facts take precedence when available.
      final nutrition = product?.toAlternative().nutrition ?? _markSwapNutritionAsEstimate(details.nutrition);
      swap = ProductSwap.fromMap({
        ...details.toMap(),
        'foodId': product?.barcode ?? product?.title ?? swap.title,
        'name': product?.title ?? swap.title,
        'barcode': product?.barcode,
        'nutriscore': product?.nutriscore,
        'imageUrl': product?.imageUrl,
        'nutrition': nutrition.toMap(),
      });
    }
    final resolvedName = swap.title.trim().toLowerCase();
    final code = swap.barcode?.trim();
    if (names.contains(resolvedName) || (code?.isNotEmpty == true && barcodes.contains(code))) continue;
    names.add(resolvedName);
    if (code?.isNotEmpty == true) barcodes.add(code!);
    kept.add(swap);
    if (kept.length == kSwapCardCount) break;
  }
  return kept;
}

class ProcessChatTagUseCase {
  ProcessChatTagUseCase();

  AiAnalysisResult call(
    String text, {
    String? userText,
    String? imageUrl,
    String? source,
    String? chatMessageId,
    bool isFinal = false,
    int? promptVersion,
    String? servedModel,
    List<ProductSwap> fallbackSwaps = const [],
  }) {
    var displayOutput = text;
    String? intent;
    String? imageMode;
    int? schemaVersion;
    String? verdict;
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
    } else if (!RegExp(r'\[(INTENT|SYMPTOM|MEAL|SCAN|SWAPS|SCAN_CONTEXT)\]', caseSensitive: false).hasMatch(text)) {
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
      schemaVersion = (decoded['v'] as num?)?.toInt();
      verdict = decoded['verdict']?.toString();

      if (decoded['scan'] != null && decoded['scan'] is Map<String, dynamic>) {
        final scanMap = Map<String, dynamic>.from(decoded['scan']);
        final isFoodPhoto = decoded['image_mode']?.toString().toUpperCase() == 'FOOD';
        if (isFoodPhoto) {
          // A food photo cannot establish label-only facts or packaging data.
          for (final key in ['allergens', 'additives', 'servingsPerPack', 'servingSize', 'portionEaten', 'nutriscore', 'novaGroup']) {
            scanMap[key] = null;
          }
          scanMap['additiveItems'] = <String>[];
          scanMap['nutritionBasis'] = 'pictured_portion';
          scanMap['nutritionEstimated'] = true;
          final cycle = scanMap['cycleInsight'];
          if (cycle is Map) {
            final cycleMap = Map<String, dynamic>.from(cycle);
            for (final key in ['phase', 'description']) {
              final value = cycleMap[key]?.toString().trim().toLowerCase();
              if (value == 'string' || value == 'null' || value == 'unknown' || value == '') cycleMap[key] = null;
            }
            final tags = cycleMap['tags'];
            if (tags is List) {
              cycleMap['tags'] = tags.where((tag) => tag is Map && tag.values.every((value) => value?.toString().toLowerCase() != 'string')).toList();
            }
            if (cycleMap['phase'] == null && cycleMap['description'] == null && (cycleMap['tags'] as List?)?.isEmpty != false) {
              scanMap['cycleInsight'] = null;
            } else {
              scanMap['cycleInsight'] = cycleMap;
            }
          }
        }
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
        final rawData = Map<String, dynamic>.from(decoded)..['scan'] = scanMap;
        scanData = ScanResult.fromMap(
          scanMap,
        ).copyWith(source: imageMode ?? source, userImageUrl: imageUrl, chatMessageId: chatMessageId, scanId: chatMessageId != null ? '${chatMessageId}_scan' : null, rawData: rawData);
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

    // --- STEP 2.5: EXPLICIT SYMPTOM EXTRACTION FROM USER TEXT ---
    // This runs only when AI did not return a structured symptom. Match direct
    // first-person reports (or an exact one-word report), never mentions,
    // questions, or negations. These are user-reported observations, but no
    // severity or event time is inferred.
    if (symptomLogs.isEmpty && userText != null && userText.trim().isNotEmpty) {
      final userTextLower = userText.toLowerCase().trim();
      final symptomCountBefore = symptomLogs.length;

      bool explicitlyReports(List<String> terms) {
        for (final term in terms) {
          final escapedTerm = RegExp.escape(term);
          final directReport = RegExp(
            "\\bi(?:'m| am)?\\s+(?:(?:currently|really|very|so)\\s+)*(?:(?:feeling|feel|have|experiencing|get|getting)\\s+)?(?:a\\s+|an\\s+)?(?:(?:bad|mild|severe|poor)\\s+)?$escapedTerm\\b",
          );
          if (directReport.hasMatch(userTextLower) || userTextLower.replaceAll(RegExp(r'[.!?,;:]+$'), '').trim() == term) return true;
        }
        return false;
      }

      SymptomLog extractedSymptom(String symptom, {String? sleep}) =>
          SymptomLog(symptom: symptom, sleep: sleep, chatMessageId: chatMessageId, createdAt: DateTime.now(), source: source ?? 'chat', provenance: RecordProvenance.user);

      // 1. Energy
      if (explicitlyReports(['energetic', 'energized', 'high energy'])) {
        symptomLogs.add(extractedSymptom('Energetic'));
      } else if (explicitlyReports(['tired', 'fatigue', 'exhausted', 'low energy', 'sluggish', 'brain fog'])) {
        symptomLogs.add(extractedSymptom('Fatigue'));
      }
      // 2. Bloating
      else if (explicitlyReports(['bloat', 'bloated', 'bloating'])) {
        symptomLogs.add(extractedSymptom('Bloating'));
      }
      // 3. Headache
      else if (explicitlyReports(['headache', 'migraine', 'head pain'])) {
        symptomLogs.add(extractedSymptom('Headache'));
      }
      // 4. Digestion
      else if (explicitlyReports(['indigestion', 'gas', 'constipation', 'diarrhea', 'reflux', 'heartburn'])) {
        symptomLogs.add(extractedSymptom('Digestive Shift'));
      }
      // 5. Fullness & Satiety
      else if (explicitlyReports(['full', 'stuffed', 'hungry', 'hunger'])) {
        final isHungry = userTextLower.contains('hungry') || userTextLower.contains('hunger');
        symptomLogs.add(extractedSymptom(isHungry ? 'Hunger' : 'Fullness'));
      }
      // 6. Sleep
      else if (explicitlyReports(['insomnia', 'rested', 'poor sleep', 'bad sleep'])) {
        final isPoor = userTextLower.contains('poor') || userTextLower.contains('bad') || userTextLower.contains("can't sleep") || userTextLower.contains('insomnia');
        symptomLogs.add(extractedSymptom('Sleep Shift', sleep: isPoor ? 'Poor' : 'Good'));
      }
      // Other physical reactions
      else if (explicitlyReports(['nausea', 'nauseous'])) {
        symptomLogs.add(extractedSymptom('Nausea'));
      } else if (explicitlyReports(['cramps', 'stomach pain', 'stomach ache'])) {
        symptomLogs.add(extractedSymptom('Abdominal Pain'));
      }

      if (symptomLogs.length > symptomCountBefore) {
        AppLogger.ai('ProcessChatTagUseCase: recorded explicit user-reported symptom "${symptomLogs.last.symptom}" from user text.');
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
    displayOutput = stripAiStructuredDataForDisplay(text);

    swapsList = normalizeSwapCards(swapsList, fallbackSwaps);

    // 🚀 Professional Sync: Ensure swaps are attached to scanData for consistent UI & persistence.
    if (scanData != null) {
      scanData = scanData.copyWith(swaps: swapsList);
    }

    final confidence = (metadata['confidence'] as num?)?.toDouble();

    // J-4 §17: stamp every extracted record with the serving prompt/model.
    // Versions ride the sub-objects (the persisted artifacts); the carrier
    // result stays lean.
    if (promptVersion != null || servedModel != null) {
      scanData = scanData?.copyWith(promptVersion: promptVersion, model: servedModel);
      mealLog = mealLog?.copyWith(promptVersion: promptVersion, model: servedModel);
      for (var i = 0; i < symptomLogs.length; i++) {
        // Keyword fallbacks are regex-detected from the user's own text, not
        // extracted by the prompt — stamping them would misattribute provenance.
        if (symptomLogs[i].provenance == RecordProvenance.keywordFallback) continue;
        symptomLogs[i] = symptomLogs[i].copyWith(promptVersion: promptVersion, model: servedModel);
      }
    }

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
      schemaVersion: schemaVersion,
      verdict: verdict,
    );
  }
}
