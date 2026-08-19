import 'dart:math';

import 'package:gutgood/core/models/chat_message.dart';
import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/symptom_log.dart';
import 'package:gutgood/core/services/firestore/chat_firestore_service.dart';
import 'package:gutgood/core/services/firestore/history_firestore_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:uuid/uuid.dart';

/// A utility to generate realistic mock data for testing GutGood's insight engine.
///
/// This seeder generates 45 days of historical data (meals and symptoms)
/// designed to trigger the six core patterns: Bloating, Energy, Headache,
/// Digestion, Fullness, and Sleep.
class MockDataSeeder {
  static Future<void> seedHistoricalData({required HistoryFirestoreService historyService, required ChatFirestoreService chatService, required String uid}) async {
    AppLogger.info('MockDataSeeder: Starting data generation for user: $uid');

    final random = Random();
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 45));

    int mealCount = 0;
    int symptomCount = 0;
    int chatCount = 0;

    for (int i = 0; i <= 45; i++) {
      final currentDate = startDate.add(Duration(days: i));

      // 1. Breakfast (7:30 AM - 9:30 AM)
      final breakfastTime = DateTime(currentDate.year, currentDate.month, currentDate.day, 7, 30 + random.nextInt(120));
      await _logBreakfast(historyService, chatService, uid, breakfastTime, i, random);
      mealCount++;

      // 2. Lunch (12:00 PM - 2:00 PM)
      final lunchTime = DateTime(currentDate.year, currentDate.month, currentDate.day, 12, random.nextInt(120));
      await _logLunch(historyService, uid, lunchTime, i, random);
      mealCount++;

      // 3. Afternoon Symptom/Energy Check (3:00 PM - 5:00 PM)
      final afternoonCheckTime = DateTime(currentDate.year, currentDate.month, currentDate.day, 15, random.nextInt(120));
      await _logAfternoonObservations(historyService, chatService, uid, afternoonCheckTime, i, random);
      symptomCount++;

      // 4. Dinner (6:30 PM - 9:30 PM)
      // Note: We vary dinner time to trigger the Sleep Pattern (Early vs Late)
      final dinnerHour = (i % 3 == 0) ? 21 : 18; // Every 3rd day is a late dinner
      final dinnerTime = DateTime(currentDate.year, currentDate.month, currentDate.day, dinnerHour, 30 + random.nextInt(30));
      await _logDinner(historyService, uid, dinnerTime, i, random);
      mealCount++;

      // 5. Night/Next Morning Sleep Check
      final sleepCheckTime = DateTime(currentDate.year, currentDate.month, currentDate.day + 1, 7, random.nextInt(60));
      await _logSleepObservation(historyService, uid, sleepCheckTime, i, random);
      symptomCount++;

      // 6. Occasional Snack or Extra Symptom
      if (random.nextDouble() > 0.6) {
        final snackTime = DateTime(currentDate.year, currentDate.month, currentDate.day, 10, random.nextInt(60));
        await historyService.logMeal(MealLog(uid: uid, items: ['Apple', 'Handful of Walnuts'], mealType: 'snack', time: snackTime));
        mealCount++;
      }
    }

    AppLogger.info('MockDataSeeder: Successfully seeded $mealCount meals, $symptomCount symptoms, and $chatCount chats.');
  }

  static Future<void> _logBreakfast(HistoryFirestoreService service, ChatFirestoreService chatService, String uid, DateTime time, int dayIndex, Random random) async {
    // PATTERN: ENERGY (Low Energy trigger: Sugary Cereal)
    // Trigger every 5 days for "Sugary Cereal"
    bool isLowEnergyTrigger = dayIndex % 5 == 0;

    final items = isLowEnergyTrigger ? ['Sugary Cereal', 'Whole Milk'] : ['Oatmeal', 'Blueberries', 'Almond Butter'];

    await service.logMeal(MealLog(uid: uid, items: items, mealType: 'breakfast', time: time));

    // Log corresponding energy drop if trigger was eaten
    if (isLowEnergyTrigger) {
      await service.logSymptom(SymptomLog(uid: uid, symptom: 'Sluggish', energyLevel: 2, notes: 'Feeling a big energy crash after breakfast.', time: time.add(const Duration(hours: 2))));

      // Also add a chat message for realism
      await chatService.saveMessage(
        ChatMessage(
          localId: const Uuid().v4(),
          uid: uid,
          role: 'user',
          text: 'I just had some sugary cereal and now I feel super sluggish. Why does this happen?',
          foodMentions: ['Sugary Cereal'],
          symptomMentions: ['Sluggish'],
          time: time.add(const Duration(hours: 2, minutes: 15)),
        ),
      );
    }
  }

  static Future<void> _logLunch(HistoryFirestoreService service, String uid, DateTime time, int dayIndex, Random random) async {
    // PATTERN: BLOATING (Trigger: Oat Milk)
    // PATTERN: FULLNESS (Trigger: White Bread vs Salmon)

    bool isBloatingTrigger = dayIndex % 6 == 0;
    bool isHungerTrigger = dayIndex % 4 == 0;
    bool isSatietyTrigger = dayIndex % 7 == 0;

    List<String> items = ['Grilled Chicken Salad', 'Vinaigrette'];
    if (isBloatingTrigger) items.add('Oat Milk Latte');
    if (isHungerTrigger) items = ['White Bread Toast', 'Jam'];
    if (isSatietyTrigger) items = ['Grilled Salmon & Quinoa', 'Steamed Broccoli'];

    await service.logMeal(MealLog(uid: uid, items: items, mealType: 'lunch', time: time));

    // Log Bloating
    if (isBloatingTrigger) {
      await service.logSymptom(SymptomLog(uid: uid, symptom: 'Bloating', severity: 7, time: time.add(const Duration(hours: 3))));
    }

    // Log Hunger shortly after
    if (isHungerTrigger) {
      await service.logSymptom(SymptomLog(uid: uid, symptom: 'Hungry', notes: 'Feeling hungry already, that lunch didn\'t last.', time: time.add(const Duration(hours: 2))));
    }

    // Log Satiety (Window for PatternEngine is 3 hours, so use 2.5)
    if (isSatietyTrigger) {
      await service.logSymptom(SymptomLog(uid: uid, symptom: 'Full', notes: 'Feeling very full and satisfied.', time: time.add(const Duration(hours: 2, minutes: 30))));
    }
  }

  static Future<void> _logAfternoonObservations(HistoryFirestoreService service, ChatFirestoreService chatService, String uid, DateTime time, int dayIndex, Random random) async {
    // PATTERN: HEADACHE (Trigger: Diet Soda)
    // PATTERN: ENERGY (High Energy trigger: Avocado Toast - sometimes as a late lunch/snack)

    bool isHeadacheTrigger = dayIndex % 8 == 0;
    bool isHighEnergyTrigger = dayIndex % 7 == 2;

    if (isHeadacheTrigger) {
      // Log the meal (soda)
      await service.logMeal(MealLog(uid: uid, items: ['Diet Soda', 'Pretzels'], mealType: 'snack', time: time.subtract(const Duration(hours: 2))));

      // Log the headache
      await service.logSymptom(SymptomLog(uid: uid, symptom: 'Headache', severity: 6, time: time.add(const Duration(hours: 3))));

      await chatService.saveMessage(
        ChatMessage(
          localId: const Uuid().v4(),
          uid: uid,
          role: 'user',
          text: 'My head hurts after having that diet soda earlier.',
          foodMentions: ['Diet Soda'],
          symptomMentions: ['Headache'],
          time: time.add(const Duration(hours: 3, minutes: 10)),
        ),
      );
    }

    if (isHighEnergyTrigger) {
      await service.logMeal(MealLog(uid: uid, items: ['Avocado Toast', 'Egg'], mealType: 'snack', time: time.subtract(const Duration(hours: 1))));

      await service.logSymptom(SymptomLog(uid: uid, symptom: 'Energized', energyLevel: 9, time: time.add(const Duration(hours: 2))));
    }
  }

  static Future<void> _logDinner(HistoryFirestoreService service, String uid, DateTime time, int dayIndex, Random random) async {
    // PATTERN: DIGESTION (Trigger: Spicy Tacos)

    bool isDigestionTrigger = dayIndex % 9 == 0;

    List<String> items = isDigestionTrigger ? ['Spicy Tacos', 'Jalapenos', 'Black Beans'] : ['Roasted Chicken', 'Sweet Potato', 'Spinach'];

    await service.logMeal(MealLog(uid: uid, items: items, mealType: 'dinner', time: time));

    if (isDigestionTrigger) {
      await service.logSymptom(SymptomLog(uid: uid, symptom: 'Stomach discomfort', notes: 'A bit of gas and discomfort after those tacos.', time: time.add(const Duration(hours: 4))));
    }
  }

  static Future<void> _logSleepObservation(HistoryFirestoreService service, String uid, DateTime time, int dayIndex, Random random) async {
    // PATTERN: SLEEP (Early vs Late Dinner)

    // We check the previous day's dinner time
    final lateDinner = dayIndex % 3 == 0;

    await service.logSymptom(
      SymptomLog(
        uid: uid,
        symptom: 'Sleep Quality',
        sleep: lateDinner ? 'Interrupted sleep' : 'Great sleep',
        notes: lateDinner ? 'Tossed and turned, felt heavy.' : 'Deep sleep, woke up refreshed.',
        time: time,
      ),
    );
  }
}
