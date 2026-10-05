import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/history_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/notification_ids.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

/// Owns local notification display, scheduling, reminder preferences, and
/// cancellation. Firebase Messaging and payload navigation remain outside
/// this class.
class NotificationScheduler {
  NotificationScheduler({
    required FlutterLocalNotificationsPlugin notifications,
    required HistoryFirestoreService historyFirestoreService,
    required SharedPreferences prefs,
  }) : _notifications = notifications,
       _historyFirestoreService = historyFirestoreService,
       _prefs = prefs;

  final FlutterLocalNotificationsPlugin _notifications;
  final HistoryFirestoreService _historyFirestoreService;
  final SharedPreferences _prefs;

  NotificationDetails get _defaultDetails => const NotificationDetails(
    iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    android: AndroidNotificationDetails('gutgood_reminders', 'GutGood Reminders', importance: Importance.max, priority: Priority.high, color: AppPalette.black),
  );

  Future<void> showNotification({required int id, required String title, required String body, String? payload}) async {
    try {
      await _notifications.show(id: id, title: title, body: body, notificationDetails: _defaultDetails, payload: payload);
    } catch (e) {
      AppLogger.error('NotificationService: Error showing immediately', error: e);
    }
  }

  Future<void> scheduleNotification({required int id, required String title, required String body, required DateTime scheduledDate, String? payload}) async {
    AppLogger.info('NotificationService: Scheduling notification "$title" (ID: $id) for $scheduledDate');
    try {
      await _notifications.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: _defaultDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      AppLogger.info('NotificationService: Notification $id scheduled successfully (Exact).');
    } catch (e) {
      AppLogger.error('NotificationService: Failed to schedule exact notification $id, trying inexact.', error: e);
      if (e.toString().contains('exact_alarms_not_permitted')) {
        await _notifications.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
          notificationDetails: _defaultDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: payload,
        );
        AppLogger.info('NotificationService: Notification $id scheduled successfully (Inexact).');
      } else {
        AppLogger.error('NotificationService: Critical failure scheduling notification $id', error: e);
        rethrow;
      }
    }
  }

  Future<void> _scheduleDaily({required int id, required String title, required String body, required int hour, required int minute, String? payload, DateTime? notBefore}) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    // Defer the first occurrence past [notBefore] (e.g. tomorrow, when today's
    // condition was already satisfied) while keeping the daily repeat intact.
    if (notBefore != null) {
      final earliest = tz.TZDateTime.from(notBefore, tz.local);
      while (scheduled.isBefore(earliest)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
    }

    try {
      AppLogger.info('NotificationService: Scheduling daily "$title" (ID: $id) for ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
      await _notifications.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduled,
        notificationDetails: _defaultDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
    } catch (e) {
      if (e.toString().contains('exact_alarms_not_permitted')) {
        AppLogger.warning('NotificationService: Using inexact scheduling for daily $id');
        await _notifications.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduled,
          notificationDetails: _defaultDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: payload,
        );
      } else {
        AppLogger.error('NotificationService: Failed to schedule daily $id', error: e);
        rethrow;
      }
    }
  }

  Future<void> schedulePostMealCheckIn() async {
    final scheduledTime = DateTime.now().add(const Duration(hours: 2));
    AppLogger.info('NotificationService: Triggering schedulePostMealCheckIn for $scheduledTime');
    await scheduleNotification(id: NotificationIds.postMealCheckIn, title: AppStrings.notifMealCheckTitle, body: AppStrings.notifMealCheckBody, scheduledDate: scheduledTime, payload: 'symptom_check');
  }

  Future<void> scheduleBreakfastReminder(int hour, int minute) => _scheduleDaily(
    id: NotificationIds.breakfastReminder,
    title: AppStrings.notifMealReminderTitle,
    body: AppStrings.notifMealReminderBody,
    hour: hour,
    minute: minute,
    payload: 'meal_reminder_breakfast',
  );

  Future<void> scheduleLunchReminder(int hour, int minute) =>
      _scheduleDaily(id: NotificationIds.lunchReminder, title: AppStrings.notifLunchReminderTitle, body: AppStrings.notifLunchReminderBody, hour: hour, minute: minute, payload: 'meal_reminder_lunch');

  Future<void> scheduleDinnerReminder(int hour, int minute) => _scheduleDaily(
    id: NotificationIds.dinnerReminder,
    title: AppStrings.notifEveningCheckInTitle,
    body: AppStrings.notifEveningCheckInBody,
    hour: hour,
    minute: minute,
    payload: 'meal_reminder_dinner',
  );

  Future<void> scheduleScanReminder(int hour, int minute) =>
      _scheduleDaily(id: NotificationIds.scanReminder, title: AppStrings.notifFoodScanReminderTitle, body: AppStrings.notifFoodScanReminderBody, hour: hour, minute: minute, payload: 'scan_reminder');

  Future<void> scheduleRestaurantReminder(int hour, int minute) => _scheduleDaily(
    id: NotificationIds.restaurantReminder,
    title: AppStrings.notifRestaurantReminderTitle,
    body: AppStrings.notifRestaurantReminderBody,
    hour: hour,
    minute: minute,
    payload: 'restaurant_reminder',
  );

  Future<void> scheduleNoMealLoggedReminder({int hour = 19, int minute = 0}) async {
    // Respect the user's toggles — automatic re-checks (app open, meal logged)
    // must never re-arm a reminder the user explicitly turned off.
    if (!(_prefs.getBool('notif_enable_all') ?? true) || !(_prefs.getBool('notif_no_meal_logged') ?? true)) {
      return;
    }

    // 🟡 Fix: Use local start of day to match the user's local day experience.
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final mealCount = await _historyFirestoreService.getMealLogsCountSince(startOfToday);
    final scanCount = await _historyFirestoreService.getScansCountSince(startOfToday);

    final symptomCount = await _historyFirestoreService.getSymptomLogsCountSince(startOfToday);

    if (mealCount < 0 || scanCount < 0 || symptomCount < 0) {
      // Any count query failed (offline / Firestore error). Leave the existing
      // schedule untouched rather than treating an unknown count as zero.
      AppLogger.notifs('NotificationService: activity count unknown; keeping noMealLogged schedule as-is');
      return;
    }

    // 🟢 Fix: The user wants this to be a general "no activity" reminder. 
    // If they have logged a meal, scanned a food, OR logged a symptom,
    // they have engaged with the app today and we should silence the nudge.
    final totalActivityToday = (mealCount > 0 ? mealCount : 0) + 
                               (scanCount > 0 ? scanCount : 0) + 
                               (symptomCount > 0 ? symptomCount : 0);

    if (totalActivityToday == 0) {
      await _scheduleDaily(
        id: NotificationIds.noMealLogged,
        title: AppStrings.notifNoMealLoggedTitle,
        body: AppStrings.notifNoMealLoggedBody,
        hour: hour,
        minute: minute,
        payload: 'no_meal_logged',
      );
    } else {
      // 🟢 Fix: A meal or food scan is already logged today. Replacing the schedule
      // (same id) with a tomorrow-anchored repeat silences today's 7 PM reminder
      // while keeping the daily series alive for future days — a plain
      // cancel() would kill it permanently.
      await _scheduleDaily(
        id: NotificationIds.noMealLogged,
        title: AppStrings.notifNoMealLoggedTitle,
        body: AppStrings.notifNoMealLoggedBody,
        hour: hour,
        minute: minute,
        payload: 'no_meal_logged',
        notBefore: startOfToday.add(const Duration(days: 1)),
      );
    }
  }

  Future<void> scheduleDailyReminder({int hour = 9, int minute = 0}) =>
      _scheduleDaily(id: NotificationIds.dailyReminder, title: AppStrings.notifDailyCheckInTitle, body: AppStrings.notifDailyCheckInBody, hour: hour, minute: minute, payload: 'daily_reminder');

  Future<void> markAppOpened() async {
    // 🟡 Fix: Respect user preference if they have customized the daily reminder time.
    final timeStr = _prefs.getString('notif_daily_time') ?? '9:00';
    final parts = timeStr.split(':');
    final hour = int.tryParse(parts[0]) ?? 9;
    final minute = int.tryParse(parts[1]) ?? 0;

    await scheduleDailyReminder(hour: hour, minute: minute);
    // 🟢 Fix: Re-evaluate the "no meals logged" reminder on every app open so
    // it reflects today's actual logs (silenced once a meal exists, re-armed
    // on a new day) instead of whatever was true when it was last scheduled.
    unawaited(scheduleNoMealLoggedReminder());
  }

  Future<void> showInsightGeneratedNotification() async {
    AppLogger.info('NotificationService: Showing local insight generated notification.');
    await showNotification(id: NotificationIds.insightGenerated, title: AppStrings.notifInsightGeneratedTitle, body: AppStrings.notifInsightGeneratedBody, payload: 'insight_generated');
  }

  Future<void> scheduleStreakSaverReminder(int currentStreak) async {
    if (currentStreak == 0) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduledTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20, 0);

    // 🟢 Fix: If it's already past 8:00 PM today, schedule for tomorrow evening.
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    const title = AppStrings.notifStreakSaverTitle;
    final body = AppStrings.notifStreakSaverBody.replaceFirst('{streak}', currentStreak.toString());

    await scheduleNotification(id: NotificationIds.streakSaver, title: title, body: body, scheduledDate: scheduledTime, payload: 'streak_saver');

    AppLogger.info('NotificationService: Streak saver scheduled for $scheduledTime');
  }

  Future<void> cancel(int id) => _notifications.cancel(id: id);

  Future<void> cancelMealReminders() async {
    await cancel(NotificationIds.breakfastReminder);
    await cancel(NotificationIds.lunchReminder);
    await cancel(NotificationIds.dinnerReminder);
  }

  Future<void> cancelNoMealLoggedReminder() => cancel(NotificationIds.noMealLogged);

  Future<void> cancelDailyReminder() => cancel(NotificationIds.dailyReminder);

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  Future<void> setupDefaultReminders() async {
    await scheduleBreakfastReminder(8, 0);
    await scheduleLunchReminder(12, 30);
    await scheduleDinnerReminder(19, 0);
    await scheduleDailyReminder(hour: 9, minute: 0);
    await scheduleNoMealLoggedReminder(hour: 19, minute: 0);
    await scheduleScanReminder(11, 0);
    await scheduleRestaurantReminder(18, 0);
  }

  Future<void> testNotification() async {
    await showNotification(id: 999, title: 'GutGood Test', body: 'This is a test notification to verify FCM and local channels are working! 🚀', payload: 'test_notification');
  }

}
