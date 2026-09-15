import 'dart:async';

import 'package:gutgood/core/models/journal/meal_log.dart';
import 'package:gutgood/core/models/journal/symptom_log.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/services/firestore/history_firestore_service.dart';
import 'package:gutgood/core/services/notification_service.dart';
import 'package:gutgood/core/services/streak_service.dart';
import 'package:gutgood/features/logs/domain/repositories/log_repository.dart';

class LogRepositoryImpl implements LogRepository {
  LogRepositoryImpl({
    required HistoryFirestoreService firestoreService,
    required AnalyticsService analyticsService,
    required StreakService streakService,
    required NotificationService notificationService,
  }) : _firestoreService = firestoreService,
       _analyticsService = analyticsService,
       _streakService = streakService,
       _notificationService = notificationService;
  final HistoryFirestoreService _firestoreService;
  final AnalyticsService _analyticsService;
  final StreakService _streakService;
  final NotificationService _notificationService;

  @override
  Future<void> logSymptom(SymptomLog log) async {
    await _firestoreService.logSymptom(log);
    await _streakService.markActivityToday();
    await _analyticsService.logEvent(name: 'symptom_logged', parameters: <String, Object?>{'symptom': log.symptom, 'severity': log.severity});
  }

  @override
  Future<void> logMeal(MealLog log) async {
    await _firestoreService.logMeal(log);
    await _streakService.markActivityToday();
    // A meal now exists today — re-evaluate (silences today's "no meals
    // logged" reminder and keeps the daily series anchored from tomorrow).
    unawaited(_notificationService.scheduleNoMealLoggedReminder());
    await _analyticsService.logEvent(name: 'meal_logged', parameters: <String, Object?>{'meal_type': log.mealType, 'food_count': log.items.length});
  }

  @override
  Future<List<SymptomLog>> getRecentSymptomLogs(int limit) async => _firestoreService.getRecentSymptomLogs(limit: limit);

  @override
  Future<List<MealLog>> getRecentMealLogs(int limit) async => _firestoreService.getRecentMealLogs(limit: limit);
}
