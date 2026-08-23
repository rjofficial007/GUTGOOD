import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/symptom_log.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/services/firestore/history_firestore_service.dart';
import 'package:gutgood/core/services/streak_service.dart';
import 'package:gutgood/features/logs/domain/repositories/log_repository.dart';

class LogRepositoryImpl implements LogRepository {
  LogRepositoryImpl({
    required HistoryFirestoreService firestoreService,
    required AnalyticsService analyticsService,
    required StreakService streakService,
  }) : _firestoreService = firestoreService,
       _analyticsService = analyticsService,
       _streakService = streakService;
  final HistoryFirestoreService _firestoreService;
  final AnalyticsService _analyticsService;
  final StreakService _streakService;

  @override
  Future<void> logSymptom(SymptomLog log) async {
    await _firestoreService.logSymptom(log);
    await _streakService.markActivityToday();
    await _analyticsService.logEvent(
      name: 'symptom_logged',
      parameters: <String, Object?>{
        'symptom': log.symptom,
        'severity': log.severity,
      },
    );
  }

  @override
  Future<void> logMeal(MealLog log) async {
    await _firestoreService.logMeal(log);
    await _streakService.markActivityToday();
    await _analyticsService.logEvent(
      name: 'meal_logged',
      parameters: <String, Object?>{
        'meal_type': log.mealType,
        'food_count': log.items.length,
      },
    );
  }

  @override
  Future<List<SymptomLog>> getRecentSymptomLogs(int limit) async =>
      _firestoreService.getRecentSymptomLogs(limit: limit);

  @override
  Future<List<MealLog>> getRecentMealLogs(int limit) async =>
      _firestoreService.getRecentMealLogs(limit: limit);
}
