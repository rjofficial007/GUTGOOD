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
    AppLogger.insights('Starting dynamic analysis...');

    final since = DateTime.now().subtract(const Duration(days: _analysisWindowDays));
    final journalMeals = await _historyFirestoreService.getRecentMealLogs(limit: _fetchLimit, since: since);
    final scanHistory = await _historyFirestoreService.getRecentScans(limit: _fetchLimit, since: since);

    final scanMeals = scanHistory.map((s) => s.toMealLog()).toList();
    final meals = [...journalMeals, ...scanMeals];

    final allSymptoms = await _historyFirestoreService.getRecentSymptomLogs(limit: _fetchLimit, since: since);
    // P2-4: keyword-guessed symptoms (no structured AI entry, no user numbers)
    // are excluded from corroboration until a confirmation flow exists. They
    // still render in chat/history and still feed the insight journal text.
    final symptoms = allSymptoms.where((s) => s.provenance != RecordProvenance.keywordFallback).toList();

    if (meals.isEmpty || symptoms.isEmpty) {
      AppLogger.insights('Insufficient data for correlation.');
      await _savePatterns([]); // P1-7: clear stale patterns, same as no-match
      return [];
    }

    // P1-7: honest span across BOTH collections, clamped to [1, window]. The
    // old meals-only span with a 7-day floor reported "7 days" for two days
    // of data.
    final earliestMeal = meals.map((m) => m.eventTime).reduce((a, b) => a.isBefore(b) ? a : b);
    final earliestSymptom = symptoms.map((s) => s.eventTime).reduce((a, b) => a.isBefore(b) ? a : b);
    final earliest = earliestMeal.isBefore(earliestSymptom) ? earliestMeal : earliestSymptom;
    final timeframeDays = DateTime.now().difference(earliest).inDays.clamp(1, _analysisWindowDays);

    final allPatterns = [
      ..._detectBloatingPatterns(meals, symptoms, timeframeDays: timeframeDays),
      ..._detectEnergyPatterns(meals, symptoms, timeframeDays: timeframeDays),
      ..._detectHeadachePatterns(meals, symptoms, timeframeDays: timeframeDays),
      ..._detectDigestionPatterns(meals, symptoms, timeframeDays: timeframeDays),
      ..._detectFullnessPatterns(meals, symptoms, timeframeDays: timeframeDays),
      ..._detectSleepPatterns(meals, symptoms, timeframeDays: timeframeDays),
    ];

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

  /// P1-7: symptoms strictly after [mealTime] within [window], sorted
  /// ASCENDING by event time. Firestore returns newest-first, so callers must
  /// never rely on list order (`.first` used to mean "latest in window").
  List<SymptomLog> _symptomsAfter(List<SymptomLog> logs, DateTime mealTime, Duration window) =>
      logs.where((s) => s.eventTime.isAfter(mealTime) && s.eventTime.difference(mealTime) <= window).toList()..sort((a, b) => a.eventTime.compareTo(b.eventTime));

  /// P1-7: co-occurring items graduate from single-item triggers: items
  /// present in at least half the symptomatic meals join the trigger (cap 3
  /// total, trigger first, by co-occurrence count).
  List<String> _involvedFoods(String triggerKey, List<MealLog> symptomaticMeals) {
    final counts = <String, int>{};
    for (final meal in symptomaticMeals) {
      for (final item in meal.items.map(_foodKey).toSet()) {
        if (item == triggerKey || item.isEmpty) continue;
        counts[item] = (counts[item] ?? 0) + 1;
      }
    }
    final threshold = (symptomaticMeals.length / 2).ceil();
    final co = counts.entries.where((e) => e.value >= threshold).map((e) => e.key).toList()..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return [triggerKey, ...co.take(2)];
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
      if (_symptomsAfter(bloatingLogs, meal.eventTime, _bloatWindow).isNotEmpty) {
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
          final s = _symptomsAfter(bloatingLogs, m.eventTime, _bloatWindow).first;
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
      final nextSymptom = _symptomsAfter(energyLogs, meal.eventTime, _energyWindow);

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
              final s = _symptomsAfter(energyLogs, m.eventTime, _energyWindow).first;
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
              final s = _symptomsAfter(energyLogs, m.eventTime, _energyWindow).first;
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
      if (_symptomsAfter(headacheLogs, meal.eventTime, _headacheWindow).isNotEmpty) {
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
          final s = _symptomsAfter(headacheLogs, m.eventTime, _headacheWindow).first;
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
      if (_symptomsAfter(digestionLogs, meal.eventTime, _digestionWindow).isNotEmpty) {
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
          final s = _symptomsAfter(digestionLogs, m.eventTime, _digestionWindow).first;
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
      final nextSymptom = _symptomsAfter(fullnessLogs, meal.eventTime, _fullnessWindow);

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
              final s = _symptomsAfter(fullnessLogs, m.eventTime, _fullnessWindow).first;
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
              final s = _symptomsAfter(fullnessLogs, m.eventTime, _fullnessWindow).first;
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
    return MealLog(firestoreId: scanId, chatMessageId: chatMessageId, items: itemNames, notes: impact, photoUrl: imageUrl ?? userImageUrl, createdAt: createdAt);
  }
}
