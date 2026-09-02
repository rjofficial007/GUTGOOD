import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/ai_insight_details.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/pattern_occurrence.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/symptom_log.dart';
import 'package:gutgood/core/services/firestore/history_firestore_service.dart';
import 'package:gutgood/core/services/firestore/insight_firestore_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';

/// Service to generate pattern-rich mock data for testing.
class DebugMockDataService {
  DebugMockDataService({
    required HistoryFirestoreService historyFirestoreService,
    required InsightFirestoreService insightFirestoreService,
  }) : _historyFirestoreService = historyFirestoreService,
       _insightFirestoreService = insightFirestoreService;

  final HistoryFirestoreService _historyFirestoreService;
  final InsightFirestoreService _insightFirestoreService;

  Future<void> generateThirtyDaysData() async {
    AppLogger.mock('Generating 30 days of structured pattern-rich data...');
    final now = DateTime.now();

    // Track occurrences for pattern generation
    final pizzaOccurrences = <PatternOccurrence>[];
    final energyOccurrences = <PatternOccurrence>[];
    final headacheOccurrences = <PatternOccurrence>[];

    for (var i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = '${date.year}-${date.month}-${date.day}';

      // Patterns spread across 30 days for higher confidence
      final isPizzaDay = i % 4 == 0; // Bloating every 4 days
      final isEnergyDay = i % 3 == 0; // High Energy every 3 days
      final isHeadacheDay = i % 5 == 0; // Headache every 5 days
      final isDigestionDay = i % 7 == 0; // Digestion every 7 days
      final isFullnessDay = i % 2 == 0; // Fullness every 2 days
      final isSleepDay = i % 3 == 0 && i > 0; // Poor sleep linked to late eating

      // --- LOG MEALS ---
      // Breakfast
      await _historyFirestoreService.logMeal(
        MealLog(
          items: isFullnessDay ? const ['Steel Cut Oats', 'Walnuts', 'Blueberries'] : const ['White Toast', 'Jam'],
          mealType: 'breakfast',
          createdAt: DateTime(date.year, date.month, date.day, 8, 0),
          source: 'debug',
        ),
      );

      // Mid-Morning (Pattern triggers)
      if (isEnergyDay) {
        final time = DateTime(date.year, date.month, date.day, 10, 30);
        await _historyFirestoreService.logMeal(
          MealLog(items: const ['Whey Protein Shake', 'Banana'], mealType: 'snack', createdAt: time, source: 'debug'),
        );
        energyOccurrences.add(PatternOccurrence(date: dateStr, mealName: 'Whey Protein Shake', reaction: 'High Energy', timeAfter: '1.5h'));
      }
      if (isHeadacheDay) {
        final time = DateTime(date.year, date.month, date.day, 9, 0);
        await _historyFirestoreService.logMeal(
          MealLog(items: const ['Double Espresso', 'Sugar Packet'], mealType: 'snack', createdAt: time, source: 'debug'),
        );
        headacheOccurrences.add(PatternOccurrence(date: dateStr, mealName: 'Double Espresso', reaction: 'Headache', timeAfter: '2h'));
      }

      // Lunch
      await _historyFirestoreService.logMeal(
        MealLog(
          items: isDigestionDay ? const ['Spicy Street Tacos', 'Jalapeños'] : const ['Grilled Chicken Salad', 'Vinaigrette'],
          mealType: 'lunch',
          createdAt: DateTime(date.year, date.month, date.day, 13, 0),
          source: 'debug',
        ),
      );

      // Dinner
      if (isPizzaDay) {
        final time = DateTime(date.year, date.month, date.day, 19, 0);
        await _historyFirestoreService.logMeal(
          MealLog(items: const ['Pepperoni Pizza', 'Garlic Bread', 'Soda'], mealType: 'dinner', createdAt: time, source: 'debug'),
        );
        pizzaOccurrences.add(PatternOccurrence(date: dateStr, mealName: 'Pepperoni Pizza', reaction: 'Severe Bloating', timeAfter: '2.5h'));
      } else {
        await _historyFirestoreService.logMeal(
          MealLog(items: const ['Steamed Salmon', 'Broccoli', 'Brown Rice'], mealType: 'dinner', createdAt: DateTime(date.year, date.month, date.day, 19, 0), source: 'debug'),
        );
      }

      // Late Night
      if (isSleepDay) {
        await _historyFirestoreService.logMeal(MealLog(items: const ['Red Wine', 'Dark Chocolate'], mealType: 'snack', createdAt: DateTime(date.year, date.month, date.day, 22, 0), source: 'debug'));
      }

      // --- LOG SYMPTOMS (REACTIONS) ---

      // Morning Fullness Check
      if (isFullnessDay) {
        await _historyFirestoreService.logSymptom(
          SymptomLog(symptom: 'Sustained Fullness', severity: 1, notes: 'Feeling satisfied long after breakfast.', createdAt: DateTime(date.year, date.month, date.day, 11, 30), source: 'debug'),
        );
      }

      // Energy Spike
      if (isEnergyDay) {
        await _historyFirestoreService.logSymptom(
          SymptomLog(symptom: 'High Energy', energyLevel: 9, notes: 'Feeling very productive.', createdAt: DateTime(date.year, date.month, date.day, 12, 0), source: 'debug'),
        );
      }

      // Headache Check
      if (isHeadacheDay) {
        await _historyFirestoreService.logSymptom(
          SymptomLog(symptom: 'Headache', severity: 6, notes: 'Dull ache behind eyes.', createdAt: DateTime(date.year, date.month, date.day, 11, 0), source: 'debug'),
        );
      }

      // Digestion Check
      if (isDigestionDay) {
        await _historyFirestoreService.logSymptom(
          SymptomLog(symptom: 'Heartburn/Indigestion', severity: 5, notes: 'Burning sensation in chest.', createdAt: DateTime(date.year, date.month, date.day, 15, 0), source: 'debug'),
        );
      }

      // Bloating Check
      if (isPizzaDay) {
        await _historyFirestoreService.logSymptom(
          SymptomLog(symptom: 'Severe Bloating', severity: 8, notes: 'Stomach feels like a balloon.', createdAt: DateTime(date.year, date.month, date.day, 21, 30), source: 'debug'),
        );
      }

      // Sleep Check (logged the next morning)
      if (isSleepDay) {
        final nextDay = date.add(const Duration(days: 1));
        await _historyFirestoreService.logSymptom(
          SymptomLog(symptom: 'Restless Sleep', severity: 4, sleep: 'Poor', notes: 'Woke up multiple times.', createdAt: DateTime(nextDay.year, nextDay.month, nextDay.day, 7, 0), source: 'debug'),
        );
      }
    }

    // --- GENERATE SCAN HISTORY ---
    final scanProducts = [
      {'name': 'Greek Yogurt', 'brand': 'Chobani', 'score': 85, 'nutri': 'A', 'nova': 1, 'cat': 'food'},
      {'name': 'Organic Kombucha', 'brand': 'Health-Ade', 'score': 92, 'nutri': 'A', 'nova': 1, 'cat': 'food'},
      {'name': 'Dark Chocolate 85%', 'brand': 'Lindt', 'score': 70, 'nutri': 'B', 'nova': 2, 'cat': 'food'},
      {'name': 'Frozen Pepperoni Pizza', 'brand': 'Digiorno', 'score': 15, 'nutri': 'E', 'nova': 4, 'cat': 'food'},
      {'name': 'Almond Milk (Unsweetened)', 'brand': 'Malk', 'score': 88, 'nutri': 'A', 'nova': 1, 'cat': 'food'},
      {'name': 'Diet Soda', 'brand': 'Coca-Cola', 'score': 35, 'nutri': 'D', 'nova': 4, 'cat': 'food'},
      {'name': 'Whole Grain Bread', 'brand': 'Ezekiel 4:9', 'score': 95, 'nutri': 'A', 'nova': 1, 'cat': 'label'},
      {'name': 'Gastro Pub Menu', 'brand': 'The Local', 'score': 65, 'nutri': 'C', 'nova': 2, 'cat': 'menu'},
    ];

    for (var i = 0; i < scanProducts.length; i++) {
      final p = scanProducts[i];
      await _historyFirestoreService.saveToScanHistory(
        ScanResult(
          productName: p['name'] as String,
          brand: p['brand'] as String,
          score: p['score'] as int,
          impactType: (p['score'] as int) > 70 ? ImpactType.positive : ImpactType.negative,
          impact: 'Foundation for Gut Score logic.',
          nutriscore: p['nutri'] as String,
          novaGroup: (p['nova'] as int).toString(),
          category: p['cat'] as String,
          createdAt: now.subtract(Duration(hours: i * 12)),
          source: p['cat'] == 'food' ? 'barcode' : p['cat'] as String,
          isSaved: i < 3, // Save the first 3 items
        ),
      );
    }

    // --- GENERATE INSIGHTS & PATTERNS ---
    final patterns = [
      BodyPattern(
        type: BodyPattern.typeBloating,
        trigger: 'Ultra-Processed Dough & Pepperoni',
        reaction: 'Severe Bloating',
        frequency: pizzaOccurrences.length,
        confidence: BodyPattern.confidenceHigh,
        description: 'Your logs show a very strong link between pepperoni pizza and significant bloating within 3 hours.',
        involvedFoods: const ['Pepperoni Pizza', 'Garlic Bread'],
        recommendation: 'Try a sourdough crust or skip the pepperoni to see if it reduces the reaction.',
        updatedAt: now.toIso8601String(),
        occurrences: pizzaOccurrences,
        evidenceRatio: 1.0,
        positiveCount: pizzaOccurrences.length,
        totalSimilarMeals: pizzaOccurrences.length,
        commonFactors: const [CommonFactor(label: 'Late Night', icon: 'moon'), CommonFactor(label: 'Processed Meat', icon: 'beef')],
      ),
      BodyPattern(
        type: BodyPattern.typeEnergy,
        trigger: 'Whey Protein & Banana',
        reaction: 'Productive Energy Spike',
        frequency: energyOccurrences.length,
        confidence: BodyPattern.confidenceHigh,
        description: 'You consistently report high energy levels after your morning protein shake.',
        involvedFoods: const ['Whey Protein Shake', 'Banana'],
        recommendation: 'Keep this as a staple for your productive mornings.',
        updatedAt: now.toIso8601String(),
        occurrences: energyOccurrences,
        evidenceRatio: 0.9,
        positiveCount: energyOccurrences.length,
        totalSimilarMeals: energyOccurrences.length + 2,
        commonFactors: const [CommonFactor(label: 'Morning', icon: 'sun')],
      ),
      BodyPattern(
        type: BodyPattern.typeHeadache,
        trigger: 'Caffeine & Refined Sugar',
        reaction: 'Dull Headache',
        frequency: headacheOccurrences.length,
        confidence: BodyPattern.confidenceModerate,
        description: 'Headaches often follow your double espresso when paired with sugar.',
        involvedFoods: const ['Double Espresso', 'Sugar Packet'],
        recommendation: 'Try reducing the sugar or drinking more water with your coffee.',
        updatedAt: now.toIso8601String(),
        occurrences: headacheOccurrences,
        evidenceRatio: 0.7,
        positiveCount: headacheOccurrences.length,
        totalSimilarMeals: headacheOccurrences.length + 3,
        commonFactors: const [CommonFactor(label: 'Dehydration', icon: 'droplet')],
      ),
    ];

    await _insightFirestoreService.savePatternData(patterns);

    final latestInsight = AIInsight(
      gutScore: 78,
      scoreDiff: '+5',
      updatedAt: now,
      topInsight: const InsightSummary(
        title: 'Morning Momentum',
        description: 'Your morning protein shakes are fueling high-productivity days. Keep it up!',
        type: 'Positive Pattern',
        strength: 'High',
      ),
      healingFoods: const [
        HealingFood(name: 'Steel Cut Oats', effect: 'Sustained Fullness', emoji: '🥣'),
        HealingFood(name: 'Whey Protein', effect: 'Energy Boost', emoji: '🥤'),
        HealingFood(name: 'Salmon', effect: 'Anti-inflammatory', emoji: '🐟'),
      ],
      triggerFoods: const [
        TriggerFood(name: 'Pepperoni Pizza', effect: 'Severe Bloating', emoji: '🍕'),
        TriggerFood(name: 'Double Espresso', effect: 'Headache Trigger', emoji: '☕'),
        TriggerFood(name: 'Spicy Tacos', effect: 'Indigestion', emoji: '🌮'),
      ],
      detectedPatterns: patterns,
      topHealing: const TopHighlight(food: 'Whey Protein Shake', effects: 'High Energy', timeframe: 'Morning', frequency: '8/10 days', emoji: '⚡'),
      topTrigger: const TopHighlight(food: 'Pepperoni Pizza', effects: 'Severe Bloating', timeframe: 'Dinner', frequency: '7/7 days', emoji: '🎈'),
      foodImpacts: [
        FoodImpact(food: 'Oats', dateLabel: 'Daily', effect: 'Stable Energy', timeframeLabel: 'Morning', emoji: '🥣', impactType: 'positive'),
        FoodImpact(food: 'Salmon', dateLabel: 'Weekly', effect: 'Reduced Bloating', timeframeLabel: 'Dinner', emoji: '🐟', impactType: 'positive'),
        FoodImpact(food: 'Pizza', dateLabel: 'Weekly', effect: 'Inflammation', timeframeLabel: 'Evening', emoji: '🍕', impactType: 'negative'),
      ],
      weeklyRecap: const WeeklyRecap(
        dateRange: 'Oct 24 - Oct 31',
        avgScore: 78,
        scoreSub: 'Up from 73 last week',
        bestDay: 'Wednesday',
        foodsLogged: 24,
        loggedSub: 'Consistent tracking!',
        highlights: [
          RecapHighlight(icon: 'zap', text: '3 High Energy Days', color: 'green'),
          RecapHighlight(icon: 'alert-triangle', text: 'Pizza identified as major trigger', color: 'red'),
          RecapHighlight(icon: 'moon', text: 'Improved sleep on Salmon days', color: 'blue'),
        ],
      ),
    );

    await _insightFirestoreService.saveInsights(latestInsight);

    AppLogger.mock('Complete 30-day history, detailed patterns, and weekly insights generated.');
  }
}
