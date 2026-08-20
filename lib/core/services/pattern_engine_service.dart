import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/symptom_log.dart';
import 'package:gutgood/core/services/firestore/history_firestore_service.dart';
import 'package:gutgood/core/services/firestore/insight_firestore_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';

abstract class PatternEngineService {
  Future<void> runAnalysis();
}

class PatternEngineServiceImpl implements PatternEngineService {
  PatternEngineServiceImpl({
    required HistoryFirestoreService historyFirestoreService,
    required InsightFirestoreService insightFirestoreService,
  }) : _historyFirestoreService = historyFirestoreService,
       _insightFirestoreService = insightFirestoreService;

  final HistoryFirestoreService _historyFirestoreService;
  final InsightFirestoreService _insightFirestoreService;

  @override
  Future<void> runAnalysis() async {
    AppLogger.insights('Starting dynamic analysis...');

    final meals = await _historyFirestoreService.getRecentMealLogs(limit: 150);
    final symptoms = await _historyFirestoreService.getRecentSymptomLogs(limit: 150);

    if (meals.isEmpty || symptoms.isEmpty) {
      AppLogger.insights('Insufficient data for correlation.');
      return;
    }

    final allPatterns = [
      ..._detectBloatingPatterns(meals, symptoms),
      ..._detectEnergyPatterns(meals, symptoms),
      ..._detectHeadachePatterns(meals, symptoms),
      ..._detectDigestionPatterns(meals, symptoms),
      ..._detectFullnessPatterns(meals, symptoms),
      ..._detectSleepPatterns(meals, symptoms),
    ];

    if (allPatterns.isNotEmpty) {
      // Sort by confidence (High first) and frequency
      allPatterns.sort((a, b) {
        if (a.confidence == b.confidence) {
          return b.frequency.compareTo(a.frequency);
        }
        return a.confidence == BodyPattern.confidenceHigh ? -1 : 1;
      });

      AppLogger.insights('Found ${allPatterns.length} meaningful patterns.');
      await _savePatterns(allPatterns);
    } else {
      AppLogger.insights('No patterns reached the threshold.');
      await _savePatterns([]); // Clear stale patterns if any
    }
  }

  String _getConfidence(int frequency) => frequency >= 5 ? BodyPattern.confidenceHigh : BodyPattern.confidenceMedium;

  /// 1. Bloating Pattern (Min 3 symptom-linked meals)
  List<BodyPattern> _detectBloatingPatterns(List<MealLog> meals, List<SymptomLog> symptoms) {
    final triggerCounts = <String, int>{};
    final bloatingLogs = symptoms.where((s) => s.symptom.toLowerCase().contains('bloat'));

    for (final log in bloatingLogs) {
      final windowStart = log.time.subtract(const Duration(hours: 4));
      final relevantMeals = meals.where((m) => m.time.isAfter(windowStart) && m.time.isBefore(log.time));

      for (final meal in relevantMeals) {
        for (final item in meal.items) {
          final key = item.toLowerCase().trim();
          triggerCounts[key] = (triggerCounts[key] ?? 0) + 1;
        }
      }
    }

    return triggerCounts.entries
        .where((e) => e.value >= 3)
        .map((e) => BodyPattern(
              type: BodyPattern.typeBloating,
              trigger: e.key,
              reaction: 'Bloating',
              frequency: e.value,
              confidence: _getConfidence(e.value),
              description: 'You reported bloating after ${e.value} of your recent meals containing ${e.key}.',
              involvedFoods: [e.key],
              updatedAt: DateTime.now().toIso8601String(),
            ))
        .toList();
  }

  /// 2. Energy Pattern (Min 3 energy logs)
  List<BodyPattern> _detectEnergyPatterns(List<MealLog> meals, List<SymptomLog> symptoms) {
    final patterns = <BodyPattern>[];
    final energyLogs = symptoms.where((s) => s.energyLevel != null);

    final highEnergyTriggers = <String, int>{};
    final lowEnergyTriggers = <String, int>{};

    for (final log in energyLogs) {
      final windowStart = log.time.subtract(const Duration(hours: 4));
      final relevantMeals = meals.where((m) => m.time.isAfter(windowStart) && m.time.isBefore(log.time));

      for (final meal in relevantMeals) {
        for (final item in meal.items) {
          final key = item.toLowerCase().trim();
          if (log.energyLevel! >= 7) {
            highEnergyTriggers[key] = (highEnergyTriggers[key] ?? 0) + 1;
          } else if (log.energyLevel! <= 3) {
            lowEnergyTriggers[key] = (lowEnergyTriggers[key] ?? 0) + 1;
          }
        }
      }
    }

    highEnergyTriggers.forEach((food, count) {
      if (count >= 3) {
        patterns.add(BodyPattern(
          type: BodyPattern.typeEnergy,
          trigger: food,
          reaction: 'High Energy',
          frequency: count,
          confidence: _getConfidence(count),
          description: 'Meals containing $food were followed by higher energy levels in $count logs.',
          involvedFoods: [food],
          updatedAt: DateTime.now().toIso8601String(),
        ));
      }
    });

    lowEnergyTriggers.forEach((food, count) {
      if (count >= 3) {
        patterns.add(BodyPattern(
          type: BodyPattern.typeEnergy,
          trigger: food,
          reaction: 'Energy Drop',
          frequency: count,
          confidence: _getConfidence(count),
          description: 'You noticed energy drops after $count meals containing $food.',
          involvedFoods: [food],
          updatedAt: DateTime.now().toIso8601String(),
        ));
      }
    });

    return patterns;
  }

  /// 3. Headache Pattern (Min 3 headache-linked meals)
  List<BodyPattern> _detectHeadachePatterns(List<MealLog> meals, List<SymptomLog> symptoms) {
    final triggerCounts = <String, int>{};
    final headacheLogs = symptoms.where((s) => s.symptom.toLowerCase().contains('headache'));

    for (final log in headacheLogs) {
      final windowStart = log.time.subtract(const Duration(hours: 6));
      final relevantMeals = meals.where((m) => m.time.isAfter(windowStart) && m.time.isBefore(log.time));

      for (final meal in relevantMeals) {
        for (final item in meal.items) {
          final key = item.toLowerCase().trim();
          triggerCounts[key] = (triggerCounts[key] ?? 0) + 1;
        }
      }
    }

    return triggerCounts.entries
        .where((e) => e.value >= 3)
        .map((e) => BodyPattern(
              type: BodyPattern.typeHeadache,
              trigger: e.key,
              reaction: 'Headache',
              frequency: e.value,
              confidence: _getConfidence(e.value),
              description: 'You reported headaches after ${e.value} recent meals containing ${e.key}.',
              involvedFoods: [e.key],
              updatedAt: DateTime.now().toIso8601String(),
            ))
        .toList();
  }

  /// 4. Digestion Pattern (Min 3 digestion-related logs)
  List<BodyPattern> _detectDigestionPatterns(List<MealLog> meals, List<SymptomLog> symptoms) {
    final triggerCounts = <String, int>{};
    final digestiveKeywords = ['gas', 'stomach', 'digestion', 'constipation', 'diarrhea', 'discomfort'];
    final digestionLogs = symptoms.where((s) => digestiveKeywords.any((k) => s.symptom.toLowerCase().contains(k)));

    for (final log in digestionLogs) {
      final windowStart = log.time.subtract(const Duration(hours: 6));
      final relevantMeals = meals.where((m) => m.time.isAfter(windowStart) && m.time.isBefore(log.time));

      for (final meal in relevantMeals) {
        for (final item in meal.items) {
          final key = item.toLowerCase().trim();
          triggerCounts[key] = (triggerCounts[key] ?? 0) + 1;
        }
      }
    }

    return triggerCounts.entries
        .where((e) => e.value >= 3)
        .map((e) => BodyPattern(
              type: BodyPattern.typeDigestion,
              trigger: e.key,
              reaction: 'Digestive Discomfort',
              frequency: e.value,
              confidence: _getConfidence(e.value),
              description: 'Meals containing ${e.key} were frequently followed by digestive discomfort (${e.value} times).',
              involvedFoods: [e.key],
              updatedAt: DateTime.now().toIso8601String(),
            ))
        .toList();
  }

  /// 5. Fullness Pattern (Min 3 fullness logs)
  List<BodyPattern> _detectFullnessPatterns(List<MealLog> meals, List<SymptomLog> symptoms) {
    final satedTriggers = <String, int>{};
    final hungryTriggers = <String, int>{};

    final fullnessLogs = symptoms.where((s) {
      final text = (s.symptom + (s.notes ?? '')).toLowerCase();
      return text.contains('full') || text.contains('sati') || text.contains('hungry');
    });

    for (final log in fullnessLogs) {
      final text = (log.symptom + (log.notes ?? '')).toLowerCase();
      final isFull = text.contains('full') || text.contains('sati');
      final isHungry = text.contains('hungry');

      final windowStart = log.time.subtract(const Duration(hours: 3));
      final relevantMeals = meals.where((m) => m.time.isAfter(windowStart) && m.time.isBefore(log.time));

      for (final meal in relevantMeals) {
        for (final item in meal.items) {
          final key = item.toLowerCase().trim();
          if (isFull) satedTriggers[key] = (satedTriggers[key] ?? 0) + 1;
          if (isHungry) hungryTriggers[key] = (hungryTriggers[key] ?? 0) + 1;
        }
      }
    }

    final patterns = <BodyPattern>[];
    satedTriggers.forEach((food, count) {
      if (count >= 3) {
        patterns.add(BodyPattern(
          type: BodyPattern.typeFullness,
          trigger: food,
          reaction: 'Satiety',
          frequency: count,
          confidence: _getConfidence(count),
          description: 'Meals with $food kept you satisfied for significantly longer in $count recent logs.',
          involvedFoods: [food],
          updatedAt: DateTime.now().toIso8601String(),
        ));
      }
    });

    hungryTriggers.forEach((food, count) {
      if (count >= 3) {
        patterns.add(BodyPattern(
          type: BodyPattern.typeFullness,
          trigger: food,
          reaction: 'Hunger',
          frequency: count,
          confidence: _getConfidence(count),
          description: 'You reported feeling hungry shortly after $count meals containing $food.',
          involvedFoods: [food],
          updatedAt: DateTime.now().toIso8601String(),
        ));
      }
    });

    return patterns;
  }

  /// 6. Sleep Pattern (Min 3 evening meals with sleep data)
  List<BodyPattern> _detectSleepPatterns(List<MealLog> meals, List<SymptomLog> symptoms) {
    final patterns = <BodyPattern>[];
    final sleepLogs = symptoms.where((s) => s.sleep != null);

    var earlyDinnerBetterSleepCount = 0;
    var lateDinnerPoorSleepCount = 0;

    for (final log in sleepLogs) {
      final isGoodSleep = log.sleep!.toLowerCase().contains('good') || log.sleep!.toLowerCase().contains('great');
      final isPoorSleep = log.sleep!.toLowerCase().contains('poor') || log.sleep!.toLowerCase().contains('interrupted');

      // Look at the evening before the sleep log
      final eveningBefore = DateTime(log.time.year, log.time.month, log.time.day).subtract(const Duration(hours: 6));
      final eveningMeals = meals.where((m) => m.time.isAfter(eveningBefore) && m.time.isBefore(log.time) && m.time.hour >= 18);

      if (eveningMeals.isNotEmpty) {
        final latestMeal = eveningMeals.last;
        if (latestMeal.time.hour < 20 && isGoodSleep) earlyDinnerBetterSleepCount++;
        if (latestMeal.time.hour >= 21 && isPoorSleep) lateDinnerPoorSleepCount++;
      }
    }

    if (earlyDinnerBetterSleepCount >= 3) {
      patterns.add(BodyPattern(
        type: BodyPattern.typeSleep,
        trigger: 'Earlier dinners',
        reaction: 'Better Sleep',
        frequency: earlyDinnerBetterSleepCount,
        confidence: _getConfidence(earlyDinnerBetterSleepCount),
        description: 'Earlier dinners were associated with better sleep quality in $earlyDinnerBetterSleepCount of your recent logs.',
        updatedAt: DateTime.now().toIso8601String(),
      ));
    }

    if (lateDinnerPoorSleepCount >= 3) {
      patterns.add(BodyPattern(
        type: BodyPattern.typeSleep,
        trigger: 'Late night eating',
        reaction: 'Interrupted Sleep',
        frequency: lateDinnerPoorSleepCount,
        confidence: _getConfidence(lateDinnerPoorSleepCount),
        description: 'Late night meals (after 9:00 PM) correlated with poorer sleep quality $lateDinnerPoorSleepCount times.',
        updatedAt: DateTime.now().toIso8601String(),
      ));
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
