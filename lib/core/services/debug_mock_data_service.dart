import 'dart:math';

import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/ai_insight_details.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/symptom_log.dart';
import 'package:gutgood/core/services/firestore/history_firestore_service.dart';
import 'package:gutgood/core/services/firestore/insight_firestore_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';

class DebugMockDataService {
  DebugMockDataService({required HistoryFirestoreService historyFirestoreService, required InsightFirestoreService insightFirestoreService})
    : _historyFirestoreService = historyFirestoreService,
      _insightFirestoreService = insightFirestoreService;

  final HistoryFirestoreService _historyFirestoreService;
  final InsightFirestoreService _insightFirestoreService;

  Future<void> generateTwoWeeksData() async {
    AppLogger.info('MockData: Generating 2 weeks of data...');
    final now = DateTime.now();

    // 1. Generate Meal Logs & Symptom Logs for 14 days
    for (var i = 0; i < 14; i++) {
      final date = now.subtract(Duration(days: i));

      // 3 meals per day
      await _historyFirestoreService.logMeal(MealLog(items: const ['Oatmeal', 'Berries', 'Coffee'], mealType: 'breakfast', time: DateTime(date.year, date.month, date.day, 8, 30), source: 'debug'));

      await _historyFirestoreService.logMeal(MealLog(items: const ['Chicken Salad', 'Avocado'], mealType: 'lunch', time: DateTime(date.year, date.month, date.day, 13, 0), source: 'debug'));

      await _historyFirestoreService.logMeal(MealLog(items: const ['Grilled Salmon', 'Asparagus', 'Quinoa'], mealType: 'dinner', time: DateTime(date.year, date.month, date.day, 19, 30), source: 'debug'));

      // 1 symptom per day
      await _historyFirestoreService.logSymptom(
        SymptomLog(
          symptom: i % 3 == 0 ? 'Bloating' : 'Better energy',
          severity: i % 3 == 0 ? 4 : null,
          energyLevel: i % 3 == 0 ? 3 : 8,
          time: DateTime(date.year, date.month, date.day, 15, 0),
          source: 'debug',
        ),
      );
    }

    // 2. Generate Insight History
    for (var i = 0; i < 3; i++) {
      final date = now.subtract(Duration(days: i * 4));
      await _insightFirestoreService.saveInsights(
        AIInsight(
          gutScore: 70 + Random().nextInt(20),
          scoreDiff: i == 0 ? '+4' : '-2',
          updatedAt: date,
          healingGoal: 'Microbiome Diversification',
          healingTrend: 'Your intake of diverse plant fibers has increased by 15% this week.',
          triggerTrend: 'Occasional dairy intake continues to correlate with mild bloating.',
          healingFoods: const [
            HealingFood(name: 'Blueberries', effect: 'Improved focus', emoji: '🫐'),
            HealingFood(name: 'Salmon', effect: 'Better mood', emoji: '🐟'),
          ],
          triggerFoods: const [
            TriggerFood(name: 'Pizza', effect: 'Bloating + Fatigue', emoji: '🍕'),
            TriggerFood(name: 'Ice Cream', effect: 'Heaviness', emoji: '🍦'),
          ],
          foodImpacts: const [
            FoodImpact(food: 'Eggs', dateLabel: 'Today, 8:30 AM', effect: 'Better energy', timeframeLabel: 'Next day', emoji: '🥚', impactType: 'positive'),
            FoodImpact(food: 'Pizza', dateLabel: 'Yesterday, 1:30 PM', effect: 'Bloating', timeframeLabel: '2 hrs later', emoji: '🍕', impactType: 'negative'),
          ],
          topHealing: const TopHighlight(food: 'Blueberries', effects: 'High antioxidants', timeframe: 'Morning', frequency: '85%', emoji: '🫐'),
          topTrigger: const TopHighlight(food: 'Pizza', effects: 'Gluten sensitivity', timeframe: 'Afternoon', frequency: '100%', emoji: '🍕'),
          confidenceLevel: 'High',
          topInsight: const InsightSummary(title: 'Dairy sensitivity detected', description: 'Dairy shows up in 60% of your bloating days.', type: 'Pattern'),
        ),
      );
    }

    // 3. Generate Body Patterns
    await _insightFirestoreService.savePatternData([
      BodyPattern(
        type: 'food_symptom',
        trigger: 'Pizza',
        reaction: 'Bloating',
        frequency: 3,
        confidence: 'High',
        description: 'Pizza appears often before you report bloating.',
        updatedAt: now.toIso8601String(),
      ),
      BodyPattern(
        type: 'protein_energy',
        trigger: 'Protein-rich meals',
        reaction: 'High Energy',
        frequency: 5,
        confidence: 'High',
        description: 'Protein-rich meals are linked to sustained energy levels for you.',
        updatedAt: now.toIso8601String(),
      ),
    ]);

    AppLogger.info('MockData: 2 weeks of data generated successfully.');
  }
}
