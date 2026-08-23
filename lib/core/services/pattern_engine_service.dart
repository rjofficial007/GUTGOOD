import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/pattern_occurrence.dart';
import 'package:gutgood/core/models/symptom_log.dart';
import 'package:gutgood/core/services/firestore/history_firestore_service.dart';
import 'package:gutgood/core/services/firestore/insight_firestore_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';

abstract class PatternEngineService {
  Future<List<BodyPattern>> runAnalysis();
}

class PatternEngineServiceImpl implements PatternEngineService {
  PatternEngineServiceImpl({required HistoryFirestoreService historyFirestoreService, required InsightFirestoreService insightFirestoreService})
    : _historyFirestoreService = historyFirestoreService,
      _insightFirestoreService = insightFirestoreService;

  final HistoryFirestoreService _historyFirestoreService;
  final InsightFirestoreService _insightFirestoreService;

  @override
  Future<List<BodyPattern>> runAnalysis() async {
    AppLogger.insights('Starting dynamic analysis...');

    final meals = await _historyFirestoreService.getRecentMealLogs(limit: 150);
    final symptoms = await _historyFirestoreService.getRecentSymptomLogs(limit: 150);

    if (meals.isEmpty || symptoms.isEmpty) {
      AppLogger.insights('Insufficient data for correlation.');
      return [];
    }

    final earliest = meals.map((m) => m.time).reduce((a, b) => a.isBefore(b) ? a : b);
    final timeframeDays = DateTime.now().difference(earliest).inDays.clamp(7, 90);

    final allPatterns = [
      ..._detectBloatingPatterns(meals, symptoms, timeframeDays: timeframeDays),
      ..._detectEnergyPatterns(meals, symptoms, timeframeDays: timeframeDays),
      ..._detectHeadachePatterns(meals, symptoms, timeframeDays: timeframeDays),
      ..._detectDigestionPatterns(meals, symptoms, timeframeDays: timeframeDays),
      ..._detectFullnessPatterns(meals, symptoms, timeframeDays: timeframeDays),
      ..._detectSleepPatterns(meals, symptoms, timeframeDays: timeframeDays),
    ];

    if (allPatterns.isNotEmpty) {
      // Sort by confidence (High first) and frequency
      allPatterns.sort((a, b) {
        if (a.confidence != b.confidence) {
          return a.confidence == BodyPattern.confidenceHigh ? -1 : 1;
        }
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

  String _getConfidence(int frequency) => frequency >= 5 ? BodyPattern.confidenceHigh : BodyPattern.confidenceMedium;

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
      final symptomFollowed = bloatingLogs.where((s) => s.time.isAfter(meal.time) && s.time.difference(meal.time).inHours <= 4).toList();

      if (symptomFollowed.isNotEmpty) {
        for (final item in meal.items) {
          final key = item.toLowerCase().trim();
          if (!foodToSymptomaticMeals.containsKey(key)) foodToSymptomaticMeals[key] = [];
          if (!foodToSymptomaticMeals[key]!.contains(meal)) foodToSymptomaticMeals[key]!.add(meal);
        }
      }
    }

    return foodToSymptomaticMeals.entries.where((e) => e.value.length >= 3).map((e) {
      final food = e.key;
      final symptomaticMeals = e.value;
      final totalSimilar = meals.where((m) => m.items.any((i) => i.toLowerCase().trim() == food)).length;
      final asymptomatic = totalSimilar - symptomaticMeals.length;

      return BodyPattern(
        type: BodyPattern.typeBloating,
        trigger: _capitalize(food),
        reaction: 'Bloating',
        frequency: symptomaticMeals.length,
        confidence: _getConfidence(symptomaticMeals.length),
        description: 'You reported bloating after ${symptomaticMeals.length} of your recent meals containing $food.',
        involvedFoods: [food],
        updatedAt: DateTime.now().toIso8601String(),
        totalSimilarMeals: totalSimilar,
        timeframeDays: timeframeDays,
        evidenceRatio: totalSimilar > 0 ? symptomaticMeals.length / totalSimilar : 0.0,
        positiveCount: symptomaticMeals.length,
        negativeCount: asymptomatic,
        occurrences: symptomaticMeals.map((m) {
          final s = bloatingLogs.firstWhere((s) => s.time.isAfter(m.time) && s.time.difference(m.time).inHours <= 4);
          return PatternOccurrence(date: _formatDate(m.time), mealName: m.items.join(', '), imageUrl: m.photoUrl, reaction: 'Bloating', timeAfter: _formatTimeAfter(m.time, s.time));
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
      final nextSymptom = energyLogs.where((s) => s.time.isAfter(meal.time) && s.time.difference(meal.time).inHours <= 4).toList();

      if (nextSymptom.isNotEmpty) {
        final log = nextSymptom.first;
        for (final item in meal.items) {
          final key = item.toLowerCase().trim();
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
      if (symptomaticMeals.length >= 3) {
        final totalSimilar = meals.where((m) => m.items.any((i) => i.toLowerCase().trim() == food)).length;
        final asymptomatic = totalSimilar - symptomaticMeals.length;
        patterns.add(
          BodyPattern(
            type: BodyPattern.typeEnergy,
            trigger: _capitalize(food),
            reaction: 'High Energy',
            frequency: symptomaticMeals.length,
            confidence: _getConfidence(symptomaticMeals.length),
            description: 'Meals containing $food were followed by higher energy levels in ${symptomaticMeals.length} logs.',
            involvedFoods: [food],
            updatedAt: DateTime.now().toIso8601String(),
            totalSimilarMeals: totalSimilar,
            timeframeDays: timeframeDays,
            evidenceRatio: totalSimilar > 0 ? symptomaticMeals.length / totalSimilar : 0.0,
            positiveCount: symptomaticMeals.length,
            negativeCount: asymptomatic,
            occurrences: symptomaticMeals.map((m) {
              final s = energyLogs.firstWhere((s) => s.time.isAfter(m.time) && s.time.difference(m.time).inHours <= 4);
              return PatternOccurrence(date: _formatDate(m.time), mealName: m.items.join(', '), imageUrl: m.photoUrl, reaction: 'Energized', timeAfter: _formatTimeAfter(m.time, s.time));
            }).toList(),
            commonFactors: _extractCommonFactors(symptomaticMeals),
          ),
        );
      }
    });

    lowEnergyTriggers.forEach((food, symptomaticMeals) {
      if (symptomaticMeals.length >= 3) {
        final totalSimilar = meals.where((m) => m.items.any((i) => i.toLowerCase().trim() == food)).length;
        final asymptomatic = totalSimilar - symptomaticMeals.length;
        patterns.add(
          BodyPattern(
            type: BodyPattern.typeEnergy,
            trigger: _capitalize(food),
            reaction: 'Energy Drop',
            frequency: symptomaticMeals.length,
            confidence: _getConfidence(symptomaticMeals.length),
            description: 'You noticed energy drops after ${symptomaticMeals.length} meals containing $food.',
            involvedFoods: [food],
            updatedAt: DateTime.now().toIso8601String(),
            totalSimilarMeals: totalSimilar,
            timeframeDays: timeframeDays,
            evidenceRatio: totalSimilar > 0 ? symptomaticMeals.length / totalSimilar : 0.0,
            positiveCount: symptomaticMeals.length,
            negativeCount: asymptomatic,
            occurrences: symptomaticMeals.map((m) {
              final s = energyLogs.firstWhere((s) => s.time.isAfter(m.time) && s.time.difference(m.time).inHours <= 4);
              return PatternOccurrence(date: _formatDate(m.time), mealName: m.items.join(', '), imageUrl: m.photoUrl, reaction: 'Sluggish', timeAfter: _formatTimeAfter(m.time, s.time));
            }).toList(),
            commonFactors: _extractCommonFactors(symptomaticMeals),
          ),
        );
      }
    });

    return patterns;
  }

  /// 3. Headache Pattern
  List<BodyPattern> _detectHeadachePatterns(List<MealLog> meals, List<SymptomLog> symptoms, {required int timeframeDays}) {
    final foodToSymptomaticMeals = <String, List<MealLog>>{};
    final headacheLogs = symptoms.where((s) => s.symptom.toLowerCase().contains('headache')).toList();

    for (final meal in meals) {
      final symptomFollowed = headacheLogs.where((s) => s.time.isAfter(meal.time) && s.time.difference(meal.time).inHours <= 6).toList();

      if (symptomFollowed.isNotEmpty) {
        for (final item in meal.items) {
          final key = item.toLowerCase().trim();
          if (!foodToSymptomaticMeals.containsKey(key)) foodToSymptomaticMeals[key] = [];
          if (!foodToSymptomaticMeals[key]!.contains(meal)) foodToSymptomaticMeals[key]!.add(meal);
        }
      }
    }

    return foodToSymptomaticMeals.entries.where((e) => e.value.length >= 3).map((e) {
      final food = e.key;
      final symptomaticMeals = e.value;
      final totalSimilar = meals.where((m) => m.items.any((i) => i.toLowerCase().trim() == food)).length;
      final asymptomatic = totalSimilar - symptomaticMeals.length;

      return BodyPattern(
        type: BodyPattern.typeHeadache,
        trigger: _capitalize(food),
        reaction: 'Headache',
        frequency: symptomaticMeals.length,
        confidence: _getConfidence(symptomaticMeals.length),
        description: 'You reported headaches after ${symptomaticMeals.length} recent meals containing $food.',
        involvedFoods: [food],
        updatedAt: DateTime.now().toIso8601String(),
        totalSimilarMeals: totalSimilar,
        timeframeDays: timeframeDays,
        evidenceRatio: totalSimilar > 0 ? symptomaticMeals.length / totalSimilar : 0.0,
        positiveCount: symptomaticMeals.length,
        negativeCount: asymptomatic,
        occurrences: symptomaticMeals.map((m) {
          final s = headacheLogs.firstWhere((s) => s.time.isAfter(m.time) && s.time.difference(m.time).inHours <= 6);
          return PatternOccurrence(date: _formatDate(m.time), mealName: m.items.join(', '), imageUrl: m.photoUrl, reaction: 'Headache', timeAfter: _formatTimeAfter(m.time, s.time));
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
      final symptomFollowed = digestionLogs.where((s) => s.time.isAfter(meal.time) && s.time.difference(meal.time).inHours <= 6).toList();

      if (symptomFollowed.isNotEmpty) {
        for (final item in meal.items) {
          final key = item.toLowerCase().trim();
          if (!foodToSymptomaticMeals.containsKey(key)) foodToSymptomaticMeals[key] = [];
          if (!foodToSymptomaticMeals[key]!.contains(meal)) foodToSymptomaticMeals[key]!.add(meal);
        }
      }
    }

    return foodToSymptomaticMeals.entries.where((e) => e.value.length >= 3).map((e) {
      final food = e.key;
      final symptomaticMeals = e.value;
      final totalSimilar = meals.where((m) => m.items.any((i) => i.toLowerCase().trim() == food)).length;
      final asymptomatic = totalSimilar - symptomaticMeals.length;

      return BodyPattern(
        type: BodyPattern.typeDigestion,
        trigger: _capitalize(food),
        reaction: 'Digestive Discomfort',
        frequency: symptomaticMeals.length,
        confidence: _getConfidence(symptomaticMeals.length),
        description: 'Meals containing $food were frequently followed by digestive discomfort (${symptomaticMeals.length} times).',
        involvedFoods: [food],
        updatedAt: DateTime.now().toIso8601String(),
        totalSimilarMeals: totalSimilar,
        timeframeDays: timeframeDays,
        evidenceRatio: totalSimilar > 0 ? symptomaticMeals.length / totalSimilar : 0.0,
        positiveCount: symptomaticMeals.length,
        negativeCount: asymptomatic,
        occurrences: symptomaticMeals.map((m) {
          final s = digestionLogs.firstWhere((s) => s.time.isAfter(m.time) && s.time.difference(m.time).inHours <= 6);
          return PatternOccurrence(date: _formatDate(m.time), mealName: m.items.join(', '), imageUrl: m.photoUrl, reaction: 'Discomfort', timeAfter: _formatTimeAfter(m.time, s.time));
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
      final nextSymptom = fullnessLogs.where((s) => s.time.isAfter(meal.time) && s.time.difference(meal.time).inHours <= 3).toList();

      if (nextSymptom.isNotEmpty) {
        final log = nextSymptom.first;
        final text = (log.symptom + (log.notes ?? '')).toLowerCase();
        final isFull = text.contains('full') || text.contains('sati');
        final isHungry = text.contains('hungry');

        for (final item in meal.items) {
          final key = item.toLowerCase().trim();
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
      if (symptomaticMeals.length >= 3) {
        final totalSimilar = meals.where((m) => m.items.any((i) => i.toLowerCase().trim() == food)).length;
        final asymptomatic = totalSimilar - symptomaticMeals.length;
        patterns.add(
          BodyPattern(
            type: BodyPattern.typeFullness,
            trigger: _capitalize(food),
            reaction: 'Satiety',
            frequency: symptomaticMeals.length,
            confidence: _getConfidence(symptomaticMeals.length),
            description: 'Meals with $food kept you satisfied for significantly longer in ${symptomaticMeals.length} recent logs.',
            involvedFoods: [food],
            updatedAt: DateTime.now().toIso8601String(),
            totalSimilarMeals: totalSimilar,
            timeframeDays: timeframeDays,
            evidenceRatio: totalSimilar > 0 ? symptomaticMeals.length / totalSimilar : 0.0,
            positiveCount: symptomaticMeals.length,
            negativeCount: asymptomatic,
            occurrences: symptomaticMeals.map((m) {
              final s = fullnessLogs.firstWhere((s) => s.time.isAfter(m.time) && s.time.difference(m.time).inHours <= 3);
              return PatternOccurrence(date: _formatDate(m.time), mealName: m.items.join(', '), imageUrl: m.photoUrl, reaction: 'Satisfied', timeAfter: _formatTimeAfter(m.time, s.time));
            }).toList(),
            commonFactors: _extractCommonFactors(symptomaticMeals),
          ),
        );
      }
    });

    hungryTriggers.forEach((food, symptomaticMeals) {
      if (symptomaticMeals.length >= 3) {
        final totalSimilar = meals.where((m) => m.items.any((i) => i.toLowerCase().trim() == food)).length;
        final asymptomatic = totalSimilar - symptomaticMeals.length;
        patterns.add(
          BodyPattern(
            type: BodyPattern.typeFullness,
            trigger: _capitalize(food),
            reaction: 'Hunger',
            frequency: symptomaticMeals.length,
            confidence: _getConfidence(symptomaticMeals.length),
            description: 'You reported feeling hungry shortly after ${symptomaticMeals.length} meals containing $food.',
            involvedFoods: [food],
            updatedAt: DateTime.now().toIso8601String(),
            totalSimilarMeals: totalSimilar,
            timeframeDays: timeframeDays,
            evidenceRatio: totalSimilar > 0 ? symptomaticMeals.length / totalSimilar : 0.0,
            positiveCount: symptomaticMeals.length,
            negativeCount: asymptomatic,
            occurrences: symptomaticMeals.map((m) {
              final s = fullnessLogs.firstWhere((s) => s.time.isAfter(m.time) && s.time.difference(m.time).inHours <= 3);
              return PatternOccurrence(date: _formatDate(m.time), mealName: m.items.join(', '), imageUrl: m.photoUrl, reaction: 'Hungry', timeAfter: _formatTimeAfter(m.time, s.time));
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

      final eveningBefore = DateTime(log.time.year, log.time.month, log.time.day).subtract(const Duration(hours: 6));
      final eveningMeals = meals.where((m) => m.time.isAfter(eveningBefore) && m.time.isBefore(log.time) && m.time.hour >= 18).toList();

      if (eveningMeals.isNotEmpty) {
        final latestMeal = eveningMeals.last;
        if (latestMeal.time.hour < 20 && isGoodSleep) {
          if (!earlyDinnerMeals.contains(latestMeal)) earlyDinnerMeals.add(latestMeal);
        } else if (latestMeal.time.hour >= 21 && isPoorSleep) {
          if (!lateDinnerMeals.contains(latestMeal)) lateDinnerMeals.add(latestMeal);
        }
      }
    }

    if (earlyDinnerMeals.length >= 3) {
      final totalSimilar = meals.where((m) => m.time.hour >= 18 && m.time.hour < 20).length;
      final asymptomatic = totalSimilar - earlyDinnerMeals.length;
      patterns.add(
        BodyPattern(
          type: BodyPattern.typeSleep,
          trigger: 'Earlier dinners',
          reaction: 'Better Sleep',
          frequency: earlyDinnerMeals.length,
          confidence: _getConfidence(earlyDinnerMeals.length),
          description: 'Earlier dinners were associated with better sleep quality in ${earlyDinnerMeals.length} of your recent logs.',
          updatedAt: DateTime.now().toIso8601String(),
          totalSimilarMeals: totalSimilar,
          timeframeDays: timeframeDays,
          evidenceRatio: totalSimilar > 0 ? earlyDinnerMeals.length / totalSimilar : 0.0,
          positiveCount: earlyDinnerMeals.length,
          negativeCount: asymptomatic,
          occurrences: earlyDinnerMeals
              .map((m) => PatternOccurrence(date: _formatDate(m.time), mealName: m.items.join(', '), imageUrl: m.photoUrl, reaction: 'Good Sleep', timeAfter: 'Next morning'))
              .toList(),
        ),
      );
    }

    if (lateDinnerMeals.length >= 3) {
      final totalSimilar = meals.where((m) => m.time.hour >= 21).length;
      final asymptomatic = totalSimilar - lateDinnerMeals.length;
      patterns.add(
        BodyPattern(
          type: BodyPattern.typeSleep,
          trigger: 'Late night eating',
          reaction: 'Interrupted Sleep',
          frequency: lateDinnerMeals.length,
          confidence: _getConfidence(lateDinnerMeals.length),
          description: 'Late night meals (after 9:00 PM) correlated with poorer sleep quality ${lateDinnerMeals.length} times.',
          updatedAt: DateTime.now().toIso8601String(),
          totalSimilarMeals: totalSimilar,
          timeframeDays: timeframeDays,
          evidenceRatio: totalSimilar > 0 ? lateDinnerMeals.length / totalSimilar : 0.0,
          positiveCount: lateDinnerMeals.length,
          negativeCount: asymptomatic,
          occurrences: lateDinnerMeals
              .map((m) => PatternOccurrence(date: _formatDate(m.time), mealName: m.items.join(', '), imageUrl: m.photoUrl, reaction: 'Poor Sleep', timeAfter: 'Next morning'))
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
