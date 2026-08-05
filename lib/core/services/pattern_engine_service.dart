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
  })  : _historyFirestoreService = historyFirestoreService,
        _insightFirestoreService = insightFirestoreService;

  final HistoryFirestoreService _historyFirestoreService;
  final InsightFirestoreService _insightFirestoreService;

  @override
  Future<void> runAnalysis() async {
    AppLogger.info('PatternEngine: Starting analysis...');

    final meals = await _historyFirestoreService.getRecentMealLogs(limit: 100);
    final symptoms = await _historyFirestoreService.getRecentSymptomLogs(limit: 100);

    if (meals.isEmpty || symptoms.isEmpty) {
      AppLogger.debug('PatternEngine: Insufficient data for correlation. (Meals: ${meals.length}, Symptoms: ${symptoms.length}). Need at least one of each.');
      return;
    }

    final allPatterns = [
      ..._detectFoodSymptomPatterns(meals, symptoms),
      ..._detectProteinEnergyPatterns(meals, symptoms),
      ..._detectSugarCrashPatterns(meals, symptoms),
      ..._detectCaffeineSleepPatterns(meals, symptoms),
      ..._detectFiberDigestionPatterns(meals, symptoms),
    ];

    if (allPatterns.isNotEmpty) {
      AppLogger.info('PatternEngine: Found ${allPatterns.length} patterns.');
      await _savePatterns(allPatterns);
    }
  }

  List<BodyPattern> _detectFoodSymptomPatterns(List<MealLog> meals, List<SymptomLog> symptoms) {
    final foodToSymptoms = <String, List<String>>{};

    for (final symptom in symptoms) {
      final windowStart = symptom.time.subtract(const Duration(hours: 4));
      final relevantMeals = meals.where((m) => m.time.isAfter(windowStart) && m.time.isBefore(symptom.time));

      for (final meal in relevantMeals) {
        for (final food in meal.items) {
          final key = food.toLowerCase().trim();
          foodToSymptoms.putIfAbsent(key, () => []);
          foodToSymptoms[key]!.add(symptom.symptom);
        }
      }
    }

    final patterns = <BodyPattern>[];
    foodToSymptoms.forEach((food, symptomList) {
      final counts = <String, int>{};
      for (final s in symptomList) {
        counts[s] = (counts[s] ?? 0) + 1;
      }

      counts.forEach((symptom, count) {
        if (count >= 2) {
          patterns.add(
            BodyPattern(
              type: 'food_symptom',
              trigger: food,
              reaction: symptom,
              frequency: count,
              confidence: count >= 3 ? 'High' : 'Moderate',
              description: '$food appears often before you report $symptom.',
              updatedAt: DateTime.now().toIso8601String(),
            ),
          );
        }
      });
    });
    return patterns;
  }

  List<BodyPattern> _detectProteinEnergyPatterns(List<MealLog> meals, List<SymptomLog> symptoms) {
    final proteinKeywords = ['chicken', 'beef', 'eggs', 'tofu', 'protein', 'steak', 'fish', 'salmon', 'turkey', 'yogurt'];
    var matchCount = 0;

    for (final symptom in symptoms) {
      if ((symptom.energyLevel ?? 0) >= 7) {
        final windowStart = symptom.time.subtract(const Duration(hours: 6));
        final windowEnd = symptom.time.subtract(const Duration(hours: 2));

        final hasProtein = meals.any((m) => m.time.isAfter(windowStart) && m.time.isBefore(windowEnd) && m.items.any((item) => proteinKeywords.any((k) => item.toLowerCase().contains(k))));

        if (hasProtein) matchCount++;
      }
    }

    if (matchCount >= 2) {
      return [
        BodyPattern(
          type: 'protein_energy',
          trigger: 'Protein-rich meals',
          reaction: 'High Energy',
          frequency: matchCount,
          confidence: matchCount >= 3 ? 'High' : 'Moderate',
          description: 'Protein-rich meals are linked to sustained energy levels for you.',
          updatedAt: DateTime.now().toIso8601String(),
        ),
      ];
    }
    return [];
  }

  List<BodyPattern> _detectSugarCrashPatterns(List<MealLog> meals, List<SymptomLog> symptoms) {
    final sugarKeywords = ['sugar', 'soda', 'candy', 'cake', 'dessert', 'cookie', 'juice', 'syrup', 'chocolate'];
    var matchCount = 0;

    for (final symptom in symptoms) {
      if ((symptom.energyLevel ?? 10) <= 3) {
        final windowStart = symptom.time.subtract(const Duration(hours: 3));

        final hasSugar = meals.any((m) => m.time.isAfter(windowStart) && m.time.isBefore(symptom.time) && m.items.any((item) => sugarKeywords.any((k) => item.toLowerCase().contains(k))));

        if (hasSugar) matchCount++;
      }
    }

    if (matchCount >= 2) {
      return [
        BodyPattern(
          type: 'sugar_crash',
          trigger: 'High sugar intake',
          reaction: 'Energy Crash',
          frequency: matchCount,
          confidence: matchCount >= 3 ? 'High' : 'Moderate',
          description: 'Your logs show a pattern of energy crashes after high sugar intake.',
          updatedAt: DateTime.now().toIso8601String(),
        ),
      ];
    }
    return [];
  }

  List<BodyPattern> _detectCaffeineSleepPatterns(List<MealLog> meals, List<SymptomLog> symptoms) {
    final caffeineKeywords = ['coffee', 'espresso', 'caffeine', 'energy drink', 'latte', 'cappuccino', 'black tea'];
    var matchCount = 0;

    for (final symptom in symptoms) {
      final sleep = symptom.sleep?.toLowerCase() ?? '';
      if (sleep == 'poor' || sleep == 'interrupted') {
        final startOfPreviousDay = DateTime(symptom.time.year, symptom.time.month, symptom.time.day).subtract(const Duration(days: 1));

        final hasLateCaffeine = meals.any(
          (m) => m.time.isAfter(startOfPreviousDay) && m.time.isBefore(symptom.time) && m.time.hour >= 14 && m.items.any((item) => caffeineKeywords.any((k) => item.toLowerCase().contains(k))),
        );

        if (hasLateCaffeine) matchCount++;
      }
    }

    if (matchCount >= 2) {
      return [
        BodyPattern(
          type: 'caffeine_sleep',
          trigger: 'Late caffeine',
          reaction: 'Poor Sleep',
          frequency: matchCount,
          confidence: matchCount >= 3 ? 'High' : 'Moderate',
          description: 'Caffeine after 2:00 PM is frequently followed by interrupted sleep patterns.',
          updatedAt: DateTime.now().toIso8601String(),
        ),
      ];
    }
    return [];
  }

  List<BodyPattern> _detectFiberDigestionPatterns(List<MealLog> meals, List<SymptomLog> symptoms) {
    final fiberKeywords = ['fiber', 'salad', 'beans', 'lentils', 'broccoli', 'vegetables', 'spinach', 'kale', 'avocado'];
    var gasMatch = 0;
    var bloatMatch = 0;

    for (final symptom in symptoms) {
      final s = symptom.symptom.toLowerCase();
      if (s == 'gas' || s == 'bloating') {
        final windowStart = symptom.time.subtract(const Duration(hours: 6));

        final hasFiber = meals.any((m) => m.time.isAfter(windowStart) && m.time.isBefore(symptom.time) && m.items.any((item) => fiberKeywords.any((k) => item.toLowerCase().contains(k))));

        if (hasFiber) {
          if (s == 'gas') gasMatch++;
          if (s == 'bloating') bloatMatch++;
        }
      }
    }

    final patterns = <BodyPattern>[];
    if (gasMatch >= 2) {
      patterns.add(
        BodyPattern(
          type: 'fiber_digestion',
          trigger: 'High fiber foods',
          reaction: 'Gas',
          frequency: gasMatch,
          confidence: gasMatch >= 3 ? 'High' : 'Moderate',
          description: 'Your system shows a sensitive reaction (gas) to high-fiber intake.',
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );
    }
    if (bloatMatch >= 2) {
      patterns.add(
        BodyPattern(
          type: 'fiber_digestion',
          trigger: 'High fiber foods',
          reaction: 'Bloating',
          frequency: bloatMatch,
          confidence: bloatMatch >= 3 ? 'High' : 'Moderate',
          description: 'High fiber intake appears to correlate with temporary bloating.',
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );
    }
    return patterns;
  }

  Future<void> _savePatterns(List<BodyPattern> patterns) async {
    try {
      await _insightFirestoreService.savePatternData(patterns);
      AppLogger.info('PatternEngine: Synced to Firestore');
    } catch (e) {
      AppLogger.error('PatternEngine: Sync failed', error: e);
    }
  }
}
