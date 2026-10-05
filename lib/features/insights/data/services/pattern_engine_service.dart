import 'package:gutgood/core/ai/protocol/ai_constants.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/history_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/insight_firestore_service.dart';

abstract class PatternEngineService {
  Future<List<BodyPattern>> runAnalysis();
}

class PatternEngineServiceImpl implements PatternEngineService {
  PatternEngineServiceImpl({required HistoryFirestoreService historyFirestoreService, required InsightFirestoreService insightFirestoreService})
    : _historyFirestoreService = historyFirestoreService,
      _insightFirestoreService = insightFirestoreService;

  final HistoryFirestoreService _historyFirestoreService;
  final InsightFirestoreService _insightFirestoreService;

  /// P1-7: the analysis looks back a fixed TIME window (not just "last N
  /// logs"), so heavy and light loggers get comparable statistics. The limit
  /// stays as a cost guard. Range-on-createdAt needs no new Firestore index:
  /// the existing (type ==, createdAt orderBy) composite already serves it.
  static const _analysisWindowDays = 30;
  static const _fetchLimit = 150;
  static const _minFrequency = 2;

  /// P1-7: per-detector causality windows, exact [Duration] comparisons (the
  /// old `inHours <= N` checks leaked almost an extra hour via truncation).
  static const _bloatWindow = Duration(hours: 4);
  static const _energyWindow = Duration(hours: 4);
  static const _headacheWindow = Duration(hours: 6);
  static const _digestionWindow = Duration(hours: 6);
  static const _fullnessWindow = Duration(hours: 3);

  @override
  Future<List<BodyPattern>> runAnalysis() async {
    final startedAt = DateTime.now();
    final stopwatch = Stopwatch()..start();
    AppLogger.insights(
      '========== PATTERN GENERATION START ========== deviceTime=$startedAt (${startedAt.timeZoneName}, UTC${startedAt.timeZoneOffset}); windowDays=$_analysisWindowDays; fetchLimit=$_fetchLimit; minFrequency=$_minFrequency; mealSymptomWindows={bloating:$_bloatWindow, energy:$_energyWindow, headache:$_headacheWindow, digestion:$_digestionWindow, fullness:$_fullnessWindow}',
    );

    final since = startedAt.subtract(const Duration(days: _analysisWindowDays));
    final fetchedMeals = await _historyFirestoreService.getRecentMealLogs(limit: _fetchLimit, since: since);
    final fetchedScans = await _historyFirestoreService.getRecentScans(limit: _fetchLimit, since: since);
    final journalMeals = fetchedMeals.where((meal) => !meal.createdAt.isAfter(startedAt) && !meal.eventTime.isAfter(startedAt)).toList();
    final scanHistory = fetchedScans.where((scan) => !scan.createdAt.isAfter(startedAt)).toList();

    // Scans are now persisted as consumed meal projections. Keep the legacy
    // scan-to-meal fallback for older scan_history documents, but never count a
    // scan twice when its journal meal already carries the originating scanId.
    final scanMeals = standaloneScanRecords(meals: journalMeals, scans: scanHistory).map((s) => s.toMealLog()).toList();
    final meals = [...journalMeals, ...scanMeals];

    final fetchedSymptoms = await _historyFirestoreService.getRecentSymptomLogs(limit: _fetchLimit, since: since);
    final allSymptoms = fetchedSymptoms.where((symptom) => !symptom.createdAt.isAfter(startedAt) && !symptom.eventTime.isAfter(startedAt)).toList();
    // P2-4: keyword-guessed symptoms (no structured AI entry, no user numbers)
    // are excluded from corroboration until a confirmation flow exists. They
    // still render in chat/history and still feed the insight journal text.
    final symptoms = allSymptoms.where((s) => s.provenance != RecordProvenance.keywordFallback).toList();

    AppLogger.data('PATTERN GENERATION INPUT', {
      'startedAtDeviceLocal': startedAt.toIso8601String(),
      'windowStart': since.toIso8601String(),
      'windowDays': _analysisWindowDays,
      'fetchLimitPerCollection': _fetchLimit,
      'minimumFrequency': _minFrequency,
      'counts': {
        'journalMeals': journalMeals.length,
        'excludedFutureMeals': fetchedMeals.length - journalMeals.length,
        'scans': scanHistory.length,
        'excludedFutureScans': fetchedScans.length - scanHistory.length,
        'legacyStandaloneScanMeals': scanMeals.length,
        'combinedMeals': meals.length,
        'allSymptoms': allSymptoms.length,
        'excludedFutureSymptoms': fetchedSymptoms.length - allSymptoms.length,
        'excludedKeywordFallbackSymptoms': allSymptoms.length - symptoms.length,
        'correlationSymptoms': symptoms.length,
      },
      'mealEvents': meals.map((meal) => {
        'id': meal.journalEntryId ?? meal.firestoreId,
        'items': meal.items,
        'foodTags': meal.foodTags,
        'createdAt': meal.createdAt.toIso8601String(),
        'eventTime': meal.eventTime.toIso8601String(),
        'occurredAtProvenance': meal.occurredAtProvenance,
      }).toList(),
      'symptomEvents': allSymptoms.map((symptom) => {
        'id': symptom.journalEntryId ?? symptom.firestoreId,
        'symptom': symptom.symptom,
        'severity': symptom.severity,
        'energyLevel': symptom.energyLevel,
        'mood': symptom.mood,
        'sleep': symptom.sleep,
        'createdAt': symptom.createdAt.toIso8601String(),
        'eventTime': symptom.eventTime.toIso8601String(),
        'provenance': symptom.provenance,
        'occurredAtProvenance': symptom.occurredAtProvenance,
      }).toList(),
    });

    if (meals.isEmpty || symptoms.isEmpty) {
      AppLogger.insights('Pattern generation skipped: meals=${meals.length}, eligibleSymptoms=${symptoms.length}; clearing stale patterns.');
      await _savePatterns([]); // P1-7: clear stale patterns, same as no-match
      AppLogger.data('PATTERN GENERATION OUTPUT', const <BodyPattern>[]);
      AppLogger.insights('Pattern generation complete: 0 patterns; elapsed=${stopwatch.elapsedMilliseconds}ms');
      return [];
    }

    // P1-7: honest span across BOTH collections, clamped to [1, window]. The
    // old meals-only span with a 7-day floor reported "7 days" for two days
    // of data.
    final earliestMeal = meals.map((m) => m.eventTime).reduce((a, b) => a.isBefore(b) ? a : b);
    final earliestSymptom = symptoms.map((s) => s.eventTime).reduce((a, b) => a.isBefore(b) ? a : b);
    final earliest = earliestMeal.isBefore(earliestSymptom) ? earliestMeal : earliestSymptom;
    final timeframeDays = DateTime.now().difference(earliest).inDays.clamp(1, _analysisWindowDays);

    final rawPatterns = [
      ..._detectBloatingPatterns(meals, symptoms, timeframeDays: timeframeDays),
      ..._detectEnergyPatterns(meals, symptoms, timeframeDays: timeframeDays),
      ..._detectHeadachePatterns(meals, symptoms, timeframeDays: timeframeDays),
      ..._detectDigestionPatterns(meals, symptoms, timeframeDays: timeframeDays),
      ..._detectFullnessPatterns(meals, symptoms, timeframeDays: timeframeDays),
      ..._detectSleepPatterns(meals, symptoms, timeframeDays: timeframeDays),
    ];
    // A symptom after a meal containing several foods does not establish that
    // each item was independently causal. Collapse those exposures into one
    // conservative combination candidate before handing evidence to Insights.
    final allPatterns = _collapseCoOccurringPatterns(rawPatterns, meals);

    AppLogger.insights(
      'Detector results: raw=${rawPatterns.length}, afterCoOccurrenceCollapse=${allPatterns.length}, timeframeDays=$timeframeDays; detectors=bloating,energy,headache,digestion,fullness,sleep',
    );
    if (allPatterns.isNotEmpty) {
      // Sort by confidence (High first) and frequency. Rank map: the old
      // two-level comparator is inconsistent once Low exists.
      int rank(String c) => c == BodyPattern.confidenceHigh ? 0 : (c == BodyPattern.confidenceMedium ? 1 : 2);
      allPatterns.sort((a, b) {
        final rankCmp = rank(a.confidence).compareTo(rank(b.confidence));
        if (rankCmp != 0) return rankCmp;
        return b.frequency.compareTo(a.frequency);
      });

      AppLogger.insights('Found ${allPatterns.length} meaningful patterns.');
      await _savePatterns(allPatterns);
    } else {
      AppLogger.insights('No patterns reached the threshold.');
      await _savePatterns([]); // Clear stale patterns if any
    }

    AppLogger.data('PATTERN GENERATION OUTPUT', allPatterns.map((pattern) => pattern.toMap()).toList());
    AppLogger.insights('Pattern generation complete: ${allPatterns.length} patterns saved; elapsed=${stopwatch.elapsedMilliseconds}ms');
    return allPatterns;
  }

  /// P1-7/§H: confidence combines frequency with the evidence ratio.
  /// High = freq ≥ 5 AND ratio ≥ 0.66 AND ≥ 1 negative observed (without a
  /// contrast case, 5-of-5 can't be distinguished from coincidence, so it
  /// caps at Medium). 3-of-3 reads Medium; 3-of-20 reads Low.
  String _getConfidence({required int frequency, required double evidenceRatio, required int negativeCount}) {
    if (frequency >= 5 && evidenceRatio >= 0.66 && negativeCount >= 1) return BodyPattern.confidenceHigh;
    if (evidenceRatio >= 0.4) return BodyPattern.confidenceMedium;
    return BodyPattern.confidenceLow;
  }

  /// P1-7: normalizes food-item keys so "Pizza", "pizza " and "2x Pizza" group
  /// together instead of fragmenting into separate triggers.
  static final _quantityPrefix = RegExp(r'^\s*(?:\d+\s*(?:x|×)?\s*|an?\s+)?', caseSensitive: false);
  static final _whitespaceRun = RegExp(r'\s+');
  String _foodKey(String item) => item.toLowerCase().replaceAll(_quantityPrefix, '').replaceAll(_whitespaceRun, ' ').trim();

  /// P1-7: unlinked symptoms must be strictly after [meal.eventTime] within
  /// [window], sorted ASCENDING by event time. An explicit same-turn or
  /// nearest-meal journal link is authoritative over clock-only matching.
  List<SymptomLog> _symptomsAfter(List<SymptomLog> logs, MealLog meal, Duration window) {
    final mealId = meal.journalEntryId ?? meal.firestoreId;
    return logs.where((s) {
      final symptomLink = s.journalEntryId ?? s.lastMealFirestoreId;
      if (symptomLink != null && symptomLink.isNotEmpty) {
        // A persisted link is authoritative: do not reuse the same symptom as
        // a time-window match for a different nearby meal.
        return mealId != null && symptomLink == mealId;
      }
      final gap = s.eventTime.difference(meal.eventTime);
      return !gap.isNegative && gap <= window;
    }).toList()
      ..sort((a, b) => a.eventTime.compareTo(b.eventTime));
  }

  /// Finds co-occurring items that should be treated as one exposure
  /// candidate. The final collapse step uses this list to avoid publishing
  /// each ingredient from the same meal as an independent cause (cap 3 total).
  List<String> _involvedFoods(String triggerKey, List<MealLog> symptomaticMeals) {
    final counts = <String, int>{};
    for (final meal in symptomaticMeals) {
      for (final item in meal.items.map(_foodKey).toSet()) {
        if (item == triggerKey || item.isEmpty) continue;
        counts[item] = (counts[item] ?? 0) + 1;
      }
    }
    // ponytail: never infer a shared ingredient from a single exposure; if
    // this later fragments legitimate combinations, compare stable meal IDs.
    final threshold = (symptomaticMeals.length / 2).ceil().clamp(_minFrequency, symptomaticMeals.length);
    final co = counts.entries.where((e) => e.value >= threshold).map((e) => e.key).toList()..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return [triggerKey, ...co.take(2)];
  }

  List<BodyPattern> _collapseCoOccurringPatterns(List<BodyPattern> patterns, List<MealLog> meals) {
    final collapsed = <BodyPattern>[];
    final seen = <String>{};

    for (final pattern in patterns) {
      final involvedKeys = <String>[];
      for (final food in pattern.involvedFoods.map(_foodKey)) {
        if (food.isNotEmpty && !involvedKeys.contains(food)) involvedKeys.add(food);
      }
      if (involvedKeys.length < 2) {
        collapsed.add(pattern);
        continue;
      }

      final combinationMeals = meals.where((meal) => _mealContainsAll(meal, involvedKeys)).toList();
      final combinationMealNames = combinationMeals.map((meal) => _mealKey(meal.items)).toSet();
      final combinationOccurrences = pattern.occurrences.where((occurrence) => combinationMealNames.contains(_mealKey(occurrence.mealName.split(',')))).toList();
      if (combinationOccurrences.length < _minFrequency) {
        // The individual trigger did not have enough exact combination
        // evidence. Suppress it rather than publishing an independent claim.
        continue;
      }

      final sortedKeys = List<String>.from(involvedKeys)..sort();
      final groupKey = '${pattern.type}|${pattern.reaction}|${sortedKeys.join('|')}';
      if (!seen.add(groupKey)) continue;

      final frequency = combinationOccurrences.length;
      final totalSimilarMeals = combinationMeals.length;
      final negativeCount = (totalSimilarMeals - frequency).clamp(0, totalSimilarMeals).toInt();
      final evidenceRatio = totalSimilarMeals == 0 ? 0.0 : frequency / totalSimilarMeals;
      final label = involvedKeys.map(_capitalize).join(' + ');

      collapsed.add(
        BodyPattern(
          id: pattern.id,
          type: pattern.type,
          trigger: label,
          reaction: pattern.reaction,
          frequency: frequency,
          confidence: _getConfidence(frequency: frequency, evidenceRatio: evidenceRatio, negativeCount: negativeCount),
          confidenceScore: pattern.confidenceScore,
          description: 'Meals containing $label were followed by ${pattern.reaction.toLowerCase()} in $frequency recent logs.',
          involvedFoods: involvedKeys,
          relatedFoodIds: pattern.relatedFoodIds,
          recommendation: pattern.recommendation,
          updatedAt: pattern.updatedAt,
          occurrences: combinationOccurrences,
          commonFactors: pattern.commonFactors,
          totalSimilarMeals: totalSimilarMeals,
          timeframeDays: pattern.timeframeDays,
          typicalTiming: pattern.typicalTiming,
          typicalDelay: pattern.typicalDelay,
          impactDirection: pattern.impactDirection,
          impactLevel: pattern.impactLevel,
          evidenceRatio: evidenceRatio,
          positiveCount: frequency,
          negativeCount: negativeCount,
          schemaVersion: pattern.schemaVersion,
        ),
      );
    }
    return collapsed;
  }

  bool _mealContainsAll(MealLog meal, List<String> foodKeys) {
    final mealKeys = meal.items.map(_foodKey).where((key) => key.isNotEmpty).toSet();
    return foodKeys.every(mealKeys.contains);
  }

  String _mealKey(Iterable<String> items) {
    final keys = items.map(_foodKey).where((key) => key.isNotEmpty).toList()..sort();
    return keys.join('|');
  }

  String _formatDate(DateTime date) {
    final m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${m[date.month - 1]} ${date.day}';
  }

  String _formatTimeAfter(DateTime mealTime, DateTime symptomTime) {
    final diff = symptomTime.difference(mealTime);
    if (diff.inHours > 0) {
      final mins = diff.inMinutes % 60;
      if (mins >= 45) return 'About ${diff.inHours + 1} hour${diff.inHours + 1 > 1 ? 's' : ''} later';
      if (mins >= 15) return 'About ${diff.inHours}.5 hours later';
      return 'About ${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} later';
    }
    return '${diff.inMinutes} mins later';
  }

  String _capitalize(String s) => s.isEmpty ? '' : '${s[0].toUpperCase()}${s.substring(1)}';

  List<CommonFactor> _extractCommonFactors(List<MealLog> symptomaticMeals) {
    final factors = <String, int>{};
    for (final meal in symptomaticMeals) {
      for (final tag in meal.foodTags) {
        final clean = tag.replaceAll('#', '').toLowerCase().trim();
        factors[clean] = (factors[clean] ?? 0) + 1;
      }
      for (final item in meal.items) {
        final lower = item.toLowerCase();
        if (lower.contains('milk') || lower.contains('cheese') || lower.contains('cream') || lower.contains('dairy')) {
          factors['dairy products'] = (factors['dairy products'] ?? 0) + 1;
        }
        if (lower.contains('fried') || lower.contains('fries') || lower.contains('burger') || lower.contains('pizza') || lower.contains('chicken')) {
          factors['fried foods'] = (factors['fried foods'] ?? 0) + 1;
        }
        if (lower.contains('pasta') || lower.contains('bread') || lower.contains('flour') || lower.contains('dough') || lower.contains('carb')) {
          factors['refined carbs'] = (factors['refined carbs'] ?? 0) + 1;
        }
        if (lower.contains('salt') || lower.contains('sodium') || lower.contains('soy sauce')) {
          factors['higher sodium'] = (factors['higher sodium'] ?? 0) + 1;
        }
      }
    }

    return factors.entries
        .where((e) => e.value >= (symptomaticMeals.length / 2))
        .map((e) {
          var icon = 'leaf';
          if (e.key.contains('dairy')) icon = 'milk';
          if (e.key.contains('fried')) icon = 'utensils';
          if (e.key.contains('carb')) icon = 'wheat';
          if (e.key.contains('sodium')) icon = 'droplet';
          return CommonFactor(label: _capitalize(e.key), icon: icon);
        })
        .take(5)
        .toList();
  }

  /// 1. Bloating Pattern
  List<BodyPattern> _detectBloatingPatterns(List<MealLog> meals, List<SymptomLog> symptoms, {required int timeframeDays}) {
    final foodToSymptomaticMeals = <String, List<MealLog>>{};
    final bloatingLogs = symptoms.where((s) => s.symptom.toLowerCase().contains('bloat')).toList();

    for (final meal in meals) {
      if (_symptomsAfter(bloatingLogs, meal, _bloatWindow).isNotEmpty) {
        for (final item in meal.items) {
          final key = _foodKey(item);
          if (key.isEmpty) continue;
          if (!foodToSymptomaticMeals.containsKey(key)) foodToSymptomaticMeals[key] = [];
          if (!foodToSymptomaticMeals[key]!.contains(meal)) foodToSymptomaticMeals[key]!.add(meal);
        }
      }
    }

    return foodToSymptomaticMeals.entries.where((e) => e.value.length >= _minFrequency).map((e) {
      final food = e.key;
      final symptomaticMeals = e.value;
      final totalSimilar = meals.where((m) => m.items.any((i) => _foodKey(i) == food)).length;
      final asymptomatic = totalSimilar - symptomaticMeals.length;
      final ratio = totalSimilar > 0 ? symptomaticMeals.length / totalSimilar : 0.0;

      return BodyPattern(
        type: BodyPattern.typeBloating,
        trigger: _capitalize(food),
        reaction: 'Bloating',
        frequency: symptomaticMeals.length,
        confidence: _getConfidence(frequency: symptomaticMeals.length, evidenceRatio: ratio, negativeCount: asymptomatic),
        description: 'You reported bloating after ${symptomaticMeals.length} of your recent meals containing $food.',
        involvedFoods: _involvedFoods(food, symptomaticMeals),
        updatedAt: DateTime.now().toIso8601String(),
        totalSimilarMeals: totalSimilar,
        timeframeDays: timeframeDays,
        evidenceRatio: ratio,
        positiveCount: symptomaticMeals.length,
        negativeCount: asymptomatic,
        occurrences: symptomaticMeals.map((m) {
          final s = _symptomsAfter(bloatingLogs, m, _bloatWindow).first;
          return PatternOccurrence(date: _formatDate(m.eventTime), mealName: m.items.join(', '), imageUrl: m.photoUrl, reaction: 'Bloating', timeAfter: _formatTimeAfter(m.eventTime, s.eventTime));
        }).toList(),
        commonFactors: _extractCommonFactors(symptomaticMeals),
      );
    }).toList();
  }

  /// 2. Energy Pattern
  List<BodyPattern> _detectEnergyPatterns(List<MealLog> meals, List<SymptomLog> symptoms, {required int timeframeDays}) {
    final patterns = <BodyPattern>[];
    final energyLogs = symptoms.where((s) => s.energyLevel != null).toList();

    final highEnergyTriggers = <String, List<MealLog>>{};
    final lowEnergyTriggers = <String, List<MealLog>>{};

    for (final meal in meals) {
      // P1-7: the NEAREST reading after the meal (ascending sort), not
      // Firestore's newest-first `.first`.
      final nextSymptom = _symptomsAfter(energyLogs, meal, _energyWindow);

      if (nextSymptom.isNotEmpty) {
        final log = nextSymptom.first;
        for (final item in meal.items) {
          final key = _foodKey(item);
          if (key.isEmpty) continue;
          if (log.energyLevel! >= 7) {
            if (!highEnergyTriggers.containsKey(key)) highEnergyTriggers[key] = [];
            if (!highEnergyTriggers[key]!.contains(meal)) highEnergyTriggers[key]!.add(meal);
          } else if (log.energyLevel! <= 3) {
            if (!lowEnergyTriggers.containsKey(key)) lowEnergyTriggers[key] = [];
            if (!lowEnergyTriggers[key]!.contains(meal)) lowEnergyTriggers[key]!.add(meal);
          }
        }
      }
    }

    highEnergyTriggers.forEach((food, symptomaticMeals) {
      if (symptomaticMeals.length >= _minFrequency) {
        final totalSimilar = meals.where((m) => m.items.any((i) => _foodKey(i) == food)).length;
        final asymptomatic = totalSimilar - symptomaticMeals.length;
        final ratio = totalSimilar > 0 ? symptomaticMeals.length / totalSimilar : 0.0;
        patterns.add(
          BodyPattern(
            type: BodyPattern.typeEnergy,
            trigger: _capitalize(food),
            reaction: 'High Energy',
            frequency: symptomaticMeals.length,
            confidence: _getConfidence(frequency: symptomaticMeals.length, evidenceRatio: ratio, negativeCount: asymptomatic),
            description: 'Meals containing $food were followed by higher energy levels in ${symptomaticMeals.length} logs.',
            involvedFoods: _involvedFoods(food, symptomaticMeals),
            updatedAt: DateTime.now().toIso8601String(),
            totalSimilarMeals: totalSimilar,
            timeframeDays: timeframeDays,
            evidenceRatio: ratio,
            positiveCount: symptomaticMeals.length,
            negativeCount: asymptomatic,
            occurrences: symptomaticMeals.map((m) {
              final s = _symptomsAfter(energyLogs, m, _energyWindow).first;
              return PatternOccurrence(
                date: _formatDate(m.eventTime),
                mealName: m.items.join(', '),
                imageUrl: m.photoUrl,
                reaction: 'Energized',
                timeAfter: _formatTimeAfter(m.eventTime, s.eventTime),
              );
            }).toList(),
            commonFactors: _extractCommonFactors(symptomaticMeals),
          ),
        );
      }
    });

    lowEnergyTriggers.forEach((food, symptomaticMeals) {
      if (symptomaticMeals.length >= _minFrequency) {
        final totalSimilar = meals.where((m) => m.items.any((i) => _foodKey(i) == food)).length;
        final asymptomatic = totalSimilar - symptomaticMeals.length;
        final ratio = totalSimilar > 0 ? symptomaticMeals.length / totalSimilar : 0.0;
        patterns.add(
          BodyPattern(
            type: BodyPattern.typeEnergy,
            trigger: _capitalize(food),
            reaction: 'Energy Drop',
            frequency: symptomaticMeals.length,
            confidence: _getConfidence(frequency: symptomaticMeals.length, evidenceRatio: ratio, negativeCount: asymptomatic),
            description: 'You noticed energy drops after ${symptomaticMeals.length} meals containing $food.',
            involvedFoods: _involvedFoods(food, symptomaticMeals),
            updatedAt: DateTime.now().toIso8601String(),
            totalSimilarMeals: totalSimilar,
            timeframeDays: timeframeDays,
            evidenceRatio: ratio,
            positiveCount: symptomaticMeals.length,
            negativeCount: asymptomatic,
            occurrences: symptomaticMeals.map((m) {
              final s = _symptomsAfter(energyLogs, m, _energyWindow).first;
              return PatternOccurrence(date: _formatDate(m.eventTime), mealName: m.items.join(', '), imageUrl: m.photoUrl, reaction: 'Sluggish', timeAfter: _formatTimeAfter(m.eventTime, s.eventTime));
            }).toList(),
            commonFactors: _extractCommonFactors(symptomaticMeals),
          ),
        );
      }
    });

    return patterns;
  }

  /// 3. Headache Pattern (plus migraine, which previously had no coverage —
  /// both share [BodyPattern.typeHeadache] so no UI mapping changes).
  List<BodyPattern> _detectHeadachePatterns(List<MealLog> meals, List<SymptomLog> symptoms, {required int timeframeDays}) => [
    ..._detectHeadacheLike(meals, symptoms, keywords: const ['headache'], reaction: 'Headache', plural: 'headaches', timeframeDays: timeframeDays),
    ..._detectHeadacheLike(meals, symptoms, keywords: const ['migraine'], reaction: 'Migraine', plural: 'migraines', timeframeDays: timeframeDays),
  ];

  List<BodyPattern> _detectHeadacheLike(
    List<MealLog> meals,
    List<SymptomLog> symptoms, {
    required List<String> keywords,
    required String reaction,
    required String plural,
    required int timeframeDays,
  }) {
    final foodToSymptomaticMeals = <String, List<MealLog>>{};
    final headacheLogs = symptoms.where((s) => keywords.any((k) => s.symptom.toLowerCase().contains(k))).toList();

    for (final meal in meals) {
      if (_symptomsAfter(headacheLogs, meal, _headacheWindow).isNotEmpty) {
        for (final item in meal.items) {
          final key = _foodKey(item);
          if (key.isEmpty) continue;
          if (!foodToSymptomaticMeals.containsKey(key)) foodToSymptomaticMeals[key] = [];
          if (!foodToSymptomaticMeals[key]!.contains(meal)) foodToSymptomaticMeals[key]!.add(meal);
        }
      }
    }

    return foodToSymptomaticMeals.entries.where((e) => e.value.length >= _minFrequency).map((e) {
      final food = e.key;
      final symptomaticMeals = e.value;
      final totalSimilar = meals.where((m) => m.items.any((i) => _foodKey(i) == food)).length;
      final asymptomatic = totalSimilar - symptomaticMeals.length;
      final ratio = totalSimilar > 0 ? symptomaticMeals.length / totalSimilar : 0.0;

      return BodyPattern(
        type: BodyPattern.typeHeadache,
        trigger: _capitalize(food),
        reaction: reaction,
        frequency: symptomaticMeals.length,
        confidence: _getConfidence(frequency: symptomaticMeals.length, evidenceRatio: ratio, negativeCount: asymptomatic),
        description: 'You reported $plural after ${symptomaticMeals.length} recent meals containing $food.',
        involvedFoods: _involvedFoods(food, symptomaticMeals),
        updatedAt: DateTime.now().toIso8601String(),
        totalSimilarMeals: totalSimilar,
        timeframeDays: timeframeDays,
        evidenceRatio: ratio,
        positiveCount: symptomaticMeals.length,
        negativeCount: asymptomatic,
        occurrences: symptomaticMeals.map((m) {
          final s = _symptomsAfter(headacheLogs, m, _headacheWindow).first;
          return PatternOccurrence(date: _formatDate(m.eventTime), mealName: m.items.join(', '), imageUrl: m.photoUrl, reaction: reaction, timeAfter: _formatTimeAfter(m.eventTime, s.eventTime));
        }).toList(),
        commonFactors: _extractCommonFactors(symptomaticMeals),
      );
    }).toList();
  }

  /// 4. Digestion Pattern
  List<BodyPattern> _detectDigestionPatterns(List<MealLog> meals, List<SymptomLog> symptoms, {required int timeframeDays}) {
    final foodToSymptomaticMeals = <String, List<MealLog>>{};
    final digestiveKeywords = ['gas', 'stomach', 'digestion', 'constipation', 'diarrhea', 'discomfort'];
    final digestionLogs = symptoms.where((s) => digestiveKeywords.any((k) => s.symptom.toLowerCase().contains(k))).toList();

    for (final meal in meals) {
      if (_symptomsAfter(digestionLogs, meal, _digestionWindow).isNotEmpty) {
        for (final item in meal.items) {
          final key = _foodKey(item);
          if (key.isEmpty) continue;
          if (!foodToSymptomaticMeals.containsKey(key)) foodToSymptomaticMeals[key] = [];
          if (!foodToSymptomaticMeals[key]!.contains(meal)) foodToSymptomaticMeals[key]!.add(meal);
        }
      }
    }

    return foodToSymptomaticMeals.entries.where((e) => e.value.length >= _minFrequency).map((e) {
      final food = e.key;
      final symptomaticMeals = e.value;
      final totalSimilar = meals.where((m) => m.items.any((i) => _foodKey(i) == food)).length;
      final asymptomatic = totalSimilar - symptomaticMeals.length;
      final ratio = totalSimilar > 0 ? symptomaticMeals.length / totalSimilar : 0.0;

      return BodyPattern(
        type: BodyPattern.typeDigestion,
        trigger: _capitalize(food),
        reaction: 'Digestive Discomfort',
        frequency: symptomaticMeals.length,
        confidence: _getConfidence(frequency: symptomaticMeals.length, evidenceRatio: ratio, negativeCount: asymptomatic),
        description: 'Meals containing $food were frequently followed by digestive discomfort (${symptomaticMeals.length} times).',
        involvedFoods: _involvedFoods(food, symptomaticMeals),
        updatedAt: DateTime.now().toIso8601String(),
        totalSimilarMeals: totalSimilar,
        timeframeDays: timeframeDays,
        evidenceRatio: ratio,
        positiveCount: symptomaticMeals.length,
        negativeCount: asymptomatic,
        occurrences: symptomaticMeals.map((m) {
          final s = _symptomsAfter(digestionLogs, m, _digestionWindow).first;
          return PatternOccurrence(date: _formatDate(m.eventTime), mealName: m.items.join(', '), imageUrl: m.photoUrl, reaction: 'Discomfort', timeAfter: _formatTimeAfter(m.eventTime, s.eventTime));
        }).toList(),
        commonFactors: _extractCommonFactors(symptomaticMeals),
      );
    }).toList();
  }

  /// 5. Fullness Pattern
  List<BodyPattern> _detectFullnessPatterns(List<MealLog> meals, List<SymptomLog> symptoms, {required int timeframeDays}) {
    final satedTriggers = <String, List<MealLog>>{};
    final hungryTriggers = <String, List<MealLog>>{};

    final fullnessLogs = symptoms.where((s) {
      final text = (s.symptom + (s.notes ?? '')).toLowerCase();
      return text.contains('full') || text.contains('sati') || text.contains('hungry');
    }).toList();

    for (final meal in meals) {
      // P1-7: nearest reading after the meal (ascending sort), not Firestore's
      // newest-first `.first`.
      final nextSymptom = _symptomsAfter(fullnessLogs, meal, _fullnessWindow);

      if (nextSymptom.isNotEmpty) {
        final log = nextSymptom.first;
        final text = (log.symptom + (log.notes ?? '')).toLowerCase();
        final isFull = text.contains('full') || text.contains('sati');
        final isHungry = text.contains('hungry');

        for (final item in meal.items) {
          final key = _foodKey(item);
          if (key.isEmpty) continue;
          if (isFull) {
            if (!satedTriggers.containsKey(key)) satedTriggers[key] = [];
            if (!satedTriggers[key]!.contains(meal)) satedTriggers[key]!.add(meal);
          }
          if (isHungry) {
            if (!hungryTriggers.containsKey(key)) hungryTriggers[key] = [];
            if (!hungryTriggers[key]!.contains(meal)) hungryTriggers[key]!.add(meal);
          }
        }
      }
    }

    final patterns = <BodyPattern>[];
    satedTriggers.forEach((food, symptomaticMeals) {
      if (symptomaticMeals.length >= _minFrequency) {
        final totalSimilar = meals.where((m) => m.items.any((i) => _foodKey(i) == food)).length;
        final asymptomatic = totalSimilar - symptomaticMeals.length;
        final ratio = totalSimilar > 0 ? symptomaticMeals.length / totalSimilar : 0.0;
        patterns.add(
          BodyPattern(
            type: BodyPattern.typeFullness,
            trigger: _capitalize(food),
            reaction: 'Satiety',
            frequency: symptomaticMeals.length,
            confidence: _getConfidence(frequency: symptomaticMeals.length, evidenceRatio: ratio, negativeCount: asymptomatic),
            description: 'Meals with $food kept you satisfied for significantly longer in ${symptomaticMeals.length} recent logs.',
            involvedFoods: _involvedFoods(food, symptomaticMeals),
            updatedAt: DateTime.now().toIso8601String(),
            totalSimilarMeals: totalSimilar,
            timeframeDays: timeframeDays,
            evidenceRatio: ratio,
            positiveCount: symptomaticMeals.length,
            negativeCount: asymptomatic,
            occurrences: symptomaticMeals.map((m) {
              final s = _symptomsAfter(fullnessLogs, m, _fullnessWindow).first;
              return PatternOccurrence(
                date: _formatDate(m.eventTime),
                mealName: m.items.join(', '),
                imageUrl: m.photoUrl,
                reaction: 'Satisfied',
                timeAfter: _formatTimeAfter(m.eventTime, s.eventTime),
              );
            }).toList(),
            commonFactors: _extractCommonFactors(symptomaticMeals),
          ),
        );
      }
    });

    hungryTriggers.forEach((food, symptomaticMeals) {
      if (symptomaticMeals.length >= _minFrequency) {
        final totalSimilar = meals.where((m) => m.items.any((i) => _foodKey(i) == food)).length;
        final asymptomatic = totalSimilar - symptomaticMeals.length;
        final ratio = totalSimilar > 0 ? symptomaticMeals.length / totalSimilar : 0.0;
        patterns.add(
          BodyPattern(
            type: BodyPattern.typeFullness,
            trigger: _capitalize(food),
            reaction: 'Hunger',
            frequency: symptomaticMeals.length,
            confidence: _getConfidence(frequency: symptomaticMeals.length, evidenceRatio: ratio, negativeCount: asymptomatic),
            description: 'You reported feeling hungry shortly after ${symptomaticMeals.length} meals containing $food.',
            involvedFoods: _involvedFoods(food, symptomaticMeals),
            updatedAt: DateTime.now().toIso8601String(),
            totalSimilarMeals: totalSimilar,
            timeframeDays: timeframeDays,
            evidenceRatio: ratio,
            positiveCount: symptomaticMeals.length,
            negativeCount: asymptomatic,
            occurrences: symptomaticMeals.map((m) {
              final s = _symptomsAfter(fullnessLogs, m, _fullnessWindow).first;
              return PatternOccurrence(date: _formatDate(m.eventTime), mealName: m.items.join(', '), imageUrl: m.photoUrl, reaction: 'Hungry', timeAfter: _formatTimeAfter(m.eventTime, s.eventTime));
            }).toList(),
            commonFactors: _extractCommonFactors(symptomaticMeals),
          ),
        );
      }
    });

    return patterns;
  }

  /// 6. Sleep Pattern
  List<BodyPattern> _detectSleepPatterns(List<MealLog> meals, List<SymptomLog> symptoms, {required int timeframeDays}) {
    final patterns = <BodyPattern>[];
    final sleepLogs = symptoms.where((s) => s.sleep != null).toList();

    final earlyDinnerMeals = <MealLog>[];
    final lateDinnerMeals = <MealLog>[];

    for (final log in sleepLogs) {
      final isGoodSleep = log.sleep!.toLowerCase().contains('good') || log.sleep!.toLowerCase().contains('great');
      final isPoorSleep = log.sleep!.toLowerCase().contains('poor') || log.sleep!.toLowerCase().contains('interrupted');

      final eveningBefore = DateTime(log.eventTime.year, log.eventTime.month, log.eventTime.day).subtract(const Duration(hours: 6));
      final eveningMeals = meals.where((m) => m.eventTime.isAfter(eveningBefore) && m.eventTime.isBefore(log.eventTime) && m.eventTime.hour >= 18).toList();

      if (eveningMeals.isNotEmpty) {
        // P1-7: latest by EVENT TIME — Firestore returns newest-first, so the
        // old `.last` picked the earliest evening meal. Buckets are now
        // contiguous (early < 20:00, late >= 20:00); the old >= 21 late cutoff
        // silently dropped 20:00–21:00 dinners from both buckets and totals.
        final latestMeal = eveningMeals.reduce((a, b) => a.eventTime.isAfter(b.eventTime) ? a : b);
        if (latestMeal.eventTime.hour < 20 && isGoodSleep) {
          if (!earlyDinnerMeals.contains(latestMeal)) earlyDinnerMeals.add(latestMeal);
        } else if (latestMeal.eventTime.hour >= 20 && isPoorSleep) {
          if (!lateDinnerMeals.contains(latestMeal)) lateDinnerMeals.add(latestMeal);
        }
      }
    }

    if (earlyDinnerMeals.length >= _minFrequency) {
      final totalSimilar = meals.where((m) => m.eventTime.hour >= 18 && m.eventTime.hour < 20).length;
      final asymptomatic = totalSimilar - earlyDinnerMeals.length;
      final earlyRatio = totalSimilar > 0 ? earlyDinnerMeals.length / totalSimilar : 0.0;
      patterns.add(
        BodyPattern(
          type: BodyPattern.typeSleep,
          trigger: 'Earlier dinners',
          reaction: 'Better Sleep',
          frequency: earlyDinnerMeals.length,
          confidence: _getConfidence(frequency: earlyDinnerMeals.length, evidenceRatio: earlyRatio, negativeCount: asymptomatic),
          description: 'Earlier dinners were associated with better sleep quality in ${earlyDinnerMeals.length} of your recent logs.',
          updatedAt: DateTime.now().toIso8601String(),
          totalSimilarMeals: totalSimilar,
          timeframeDays: timeframeDays,
          evidenceRatio: earlyRatio,
          positiveCount: earlyDinnerMeals.length,
          negativeCount: asymptomatic,
          occurrences: earlyDinnerMeals
              .map((m) => PatternOccurrence(date: _formatDate(m.eventTime), mealName: m.items.join(', '), imageUrl: m.photoUrl, reaction: 'Good Sleep', timeAfter: 'Next morning'))
              .toList(),
        ),
      );
    }

    if (lateDinnerMeals.length >= _minFrequency) {
      final totalSimilar = meals.where((m) => m.eventTime.hour >= 20).length;
      final asymptomatic = totalSimilar - lateDinnerMeals.length;
      final lateRatio = totalSimilar > 0 ? lateDinnerMeals.length / totalSimilar : 0.0;
      patterns.add(
        BodyPattern(
          type: BodyPattern.typeSleep,
          trigger: 'Late night eating',
          reaction: 'Interrupted Sleep',
          frequency: lateDinnerMeals.length,
          confidence: _getConfidence(frequency: lateDinnerMeals.length, evidenceRatio: lateRatio, negativeCount: asymptomatic),
          description: 'Late dinners (after 8:00 PM) correlated with poorer sleep quality ${lateDinnerMeals.length} times.',
          updatedAt: DateTime.now().toIso8601String(),
          totalSimilarMeals: totalSimilar,
          timeframeDays: timeframeDays,
          evidenceRatio: lateRatio,
          positiveCount: lateDinnerMeals.length,
          negativeCount: asymptomatic,
          occurrences: lateDinnerMeals
              .map((m) => PatternOccurrence(date: _formatDate(m.eventTime), mealName: m.items.join(', '), imageUrl: m.photoUrl, reaction: 'Poor Sleep', timeAfter: 'Next morning'))
              .toList(),
        ),
      );
    }

    return patterns;
  }

  Future<void> _savePatterns(List<BodyPattern> patterns) async {
    try {
      await _insightFirestoreService.savePatternData(patterns);
      AppLogger.insights('Synced ${patterns.length} patterns to Firestore');
    } catch (e) {
      AppLogger.error('PatternEngine: Sync failed', error: e);
    }
  }
}

extension ScanResultToMealLog on ScanResult {
  MealLog toMealLog() {
    final itemNames = <String>[];
    if (productName.isNotEmpty && productName.toLowerCase() != 'food' && productName.toLowerCase() != 'meal' && productName.toLowerCase() != 'scanned item') {
      itemNames.add(productName);
    }
    for (final ing in ingredients) {
      if (ing.name.isNotEmpty && !itemNames.contains(ing.name)) {
        itemNames.add(ing.name);
      }
    }
    if (itemNames.isEmpty && productName.isNotEmpty) {
      itemNames.add(productName);
    }
    return MealLog(
      firestoreId: scanId == null ? null : '${scanId}_meal',
      journalEntryId: scanId == null ? null : '${scanId}_meal',
      scanId: scanId,
      chatMessageId: chatMessageId,
      items: itemNames,
      notes: impact,
      photoUrl: imageUrl ?? userImageUrl,
      source: source ?? 'scan',
      mealType: 'scan',
      createdAt: createdAt,
    );
  }
}
