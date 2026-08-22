import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/symptom_log.dart';
import 'package:gutgood/core/services/firestore/history_firestore_service.dart';
import 'package:gutgood/core/services/firestore/insight_firestore_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';

class DebugMockDataService {
  DebugMockDataService({required HistoryFirestoreService historyFirestoreService, required InsightFirestoreService insightFirestoreService}) : _historyFirestoreService = historyFirestoreService;

  final HistoryFirestoreService _historyFirestoreService;

  Future<void> generateThirtyDaysData() async {
    AppLogger.mock('Generating 30 days of structured pattern-rich data...');
    final now = DateTime.now();

    for (var i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));

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
          time: DateTime(date.year, date.month, date.day, 8, 0),
          source: 'debug',
        ),
      );

      // Mid-Morning (Pattern triggers)
      if (isEnergyDay) {
        await _historyFirestoreService.logMeal(MealLog(items: const ['Whey Protein Shake', 'Banana'], mealType: 'snack', time: DateTime(date.year, date.month, date.day, 10, 30), source: 'debug'));
      }
      if (isHeadacheDay) {
        await _historyFirestoreService.logMeal(MealLog(items: const ['Double Espresso', 'Sugar Packet'], mealType: 'snack', time: DateTime(date.year, date.month, date.day, 9, 0), source: 'debug'));
      }

      // Lunch
      await _historyFirestoreService.logMeal(
        MealLog(
          items: isDigestionDay ? const ['Spicy Street Tacos', 'Jalapeños'] : const ['Grilled Chicken Salad', 'Vinaigrette'],
          mealType: 'lunch',
          time: DateTime(date.year, date.month, date.day, 13, 0),
          source: 'debug',
        ),
      );

      // Dinner
      await _historyFirestoreService.logMeal(
        MealLog(
          items: isPizzaDay ? const ['Pepperoni Pizza', 'Garlic Bread', 'Soda'] : const ['Steamed Salmon', 'Broccoli', 'Brown Rice'],
          mealType: 'dinner',
          time: DateTime(date.year, date.month, date.day, 19, 0),
          source: 'debug',
        ),
      );

      // Late Night
      if (isSleepDay) {
        await _historyFirestoreService.logMeal(MealLog(items: const ['Red Wine', 'Dark Chocolate'], mealType: 'snack', time: DateTime(date.year, date.month, date.day, 22, 0), source: 'debug'));
      }

      // --- LOG SYMPTOMS (REACTIONS) ---

      // Morning Fullness Check
      if (isFullnessDay) {
        await _historyFirestoreService.logSymptom(
          SymptomLog(symptom: 'Sustained Fullness', severity: 1, notes: 'Feeling satisfied long after breakfast.', time: DateTime(date.year, date.month, date.day, 11, 30), source: 'debug'),
        );
      }

      // Energy Spike
      if (isEnergyDay) {
        await _historyFirestoreService.logSymptom(
          SymptomLog(symptom: 'High Energy', energyLevel: 9, notes: 'Feeling very productive.', time: DateTime(date.year, date.month, date.day, 12, 0), source: 'debug'),
        );
      }

      // Headache Check
      if (isHeadacheDay) {
        await _historyFirestoreService.logSymptom(
          SymptomLog(symptom: 'Headache', severity: 6, notes: 'Dull ache behind eyes.', time: DateTime(date.year, date.month, date.day, 11, 0), source: 'debug'),
        );
      }

      // Digestion Check
      if (isDigestionDay) {
        await _historyFirestoreService.logSymptom(
          SymptomLog(symptom: 'Heartburn/Indigestion', severity: 5, notes: 'Burning sensation in chest.', time: DateTime(date.year, date.month, date.day, 15, 0), source: 'debug'),
        );
      }

      // Bloating Check
      if (isPizzaDay) {
        await _historyFirestoreService.logSymptom(
          SymptomLog(symptom: 'Severe Bloating', severity: 8, notes: 'Stomach feels like a balloon.', time: DateTime(date.year, date.month, date.day, 21, 30), source: 'debug'),
        );
      }

      // Sleep Check (logged the next morning)
      if (isSleepDay) {
        final nextDay = date.add(const Duration(days: 1));
        await _historyFirestoreService.logSymptom(
          SymptomLog(symptom: 'Restless Sleep', severity: 4, sleep: 'Poor', notes: 'Woke up multiple times.', time: DateTime(nextDay.year, nextDay.month, nextDay.day, 7, 0), source: 'debug'),
        );
      }
    }

    // 2. Generate Scan History (for foundational Gut Score calculation)
    final scanProducts = [
      {'name': 'Greek Yogurt', 'brand': 'Chobani', 'score': 85, 'nutri': 'A', 'nova': 1},
      {'name': 'Organic Kombucha', 'brand': 'Health-Ade', 'score': 92, 'nutri': 'A', 'nova': 1},
      {'name': 'Dark Chocolate 85%', 'brand': 'Lindt', 'score': 70, 'nutri': 'B', 'nova': 2},
      {'name': 'Frozen Pepperoni Pizza', 'brand': 'Digiorno', 'score': 15, 'nutri': 'E', 'nova': 4},
      {'name': 'Almond Milk (Unsweetened)', 'brand': 'Malk', 'score': 88, 'nutri': 'A', 'nova': 1},
      {'name': 'Diet Soda', 'brand': 'Coca-Cola', 'score': 35, 'nutri': 'D', 'nova': 4},
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
          category: 'food',
          time: now.subtract(Duration(hours: i * 12)),
          source: 'barcode',
        ),
      );
    }

    AppLogger.mock('Complete 30-day history generated. Ready for all 6 pattern category discovery.');
  }
}
