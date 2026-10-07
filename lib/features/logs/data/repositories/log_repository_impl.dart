import 'dart:async';

import 'package:gutgood/core/models/journal/meal_log.dart';
import 'package:gutgood/core/models/journal/symptom_log.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/streak_service.dart';
import 'package:gutgood/features/logs/domain/repositories/log_repository.dart';
import 'package:gutgood/infrastructure/firebase/analytics_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/history_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/notification_service.dart';

class LogRepositoryImpl implements LogRepository {
  LogRepositoryImpl({
    required HistoryFirestoreService firestoreService,
    required AnalyticsService analyticsService,
    required StreakService streakService,
    required NotificationService notificationService,
    required AppStateService appStateService,
  }) : _firestoreService = firestoreService,
       _analyticsService = analyticsService,
       _streakService = streakService,
       _notificationService = notificationService,
       _appStateService = appStateService;
  final HistoryFirestoreService _firestoreService;
  final AnalyticsService _analyticsService;
  final StreakService _streakService;
  final NotificationService _notificationService;
  final AppStateService _appStateService;

  @override
  Future<void> logSymptom(SymptomLog log) async {
    final logId = await _firestoreService.logSymptom(log);
    if (logId == null) return;
    _appStateService.notifyChatUpdated();
    await _streakService.markActivityToday();
    unawaited(_notificationService.scheduleNoMealLoggedReminder());
    await _analyticsService.logEvent(name: 'symptom_logged', parameters: <String, Object?>{'symptom': log.symptom, 'severity': log.severity});
  }

  @override
  Future<void> logMeal(MealLog log) async {
    final logId = await _firestoreService.logMeal(log);
    if (logId == null) return;
    _appStateService.notifyChatUpdated();
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
