import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/navigator_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'firestore_service.dart';

class NotificationIds {
  static const int postMealCheckIn = 100;
  static const int breakfastReminder = 101;
  static const int lunchReminder = 102;
  static const int dinnerReminder = 103;
  static const int noMealLogged = 104;
  static const int dailyReminder = 105;
  static const int scanReminder = 106;
  static const int restaurantReminder = 107;
  static const int insightGenerated = 108;
  static const int processedFoodWarning = 109;
  static const int streakSaver = 110;
}

abstract class NotificationService {
  Future<void> init();
  Future<void> showNotification({required int id, required String title, required String body, String? payload});
  Future<void> scheduleNotification({required int id, required String title, required String body, required DateTime scheduledDate, String? payload});
  Future<void> schedulePostMealCheckIn();
  Future<void> scheduleBreakfastReminder(int hour, int minute);
  Future<void> scheduleLunchReminder(int hour, int minute);
  Future<void> scheduleDinnerReminder(int hour, int minute);
  Future<void> scheduleScanReminder(int hour, int minute);
  Future<void> scheduleRestaurantReminder(int hour, int minute);
  Future<void> scheduleNoMealLoggedReminder({int hour = 19, int minute = 0});
  Future<void> scheduleDailyReminder({int hour = 9, int minute = 0});
  Future<void> markAppOpened();
  Future<void> showInsightGeneratedNotification();
  Future<void> checkAndTriggerProcessedFoodWarning();
  Future<void> scheduleStreakSaverReminder(int currentStreak);
  Future<void> cancel(int id);
  Future<void> cancelMealReminders();
  Future<void> cancelNoMealLoggedReminder();
  Future<void> cancelDailyReminder();
  Future<void> cancelAll();
  Future<void> setupDefaultReminders();
}

class NotificationServiceImpl implements NotificationService {
  final FlutterLocalNotificationsPlugin _notifications;
  final FirestoreService _firestoreService;
  final SharedPreferences _prefs;

  NotificationServiceImpl({required FlutterLocalNotificationsPlugin notifications, required FirestoreService firestoreService, required SharedPreferences prefs})
    : _notifications = notifications,
      _firestoreService = firestoreService,
      _prefs = prefs;

  @override
  Future<void> init() async {
    tz.initializeTimeZones();
    final String timeZoneName = (await FlutterTimezone.getLocalTimezone()).identifier;
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('ic_notification');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true);

    const InitializationSettings initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        Log.i('NotificationService: Tapped payload: ${details.payload}');
        _handleNotificationTap(details.payload);
      },
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      await Permission.notification.request();
      final status = await Permission.scheduleExactAlarm.status;
      if (status.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, badge: true, sound: true);
    }

    Log.i('NotificationService: Initialized');
  }

  NotificationDetails get _defaultDetails => const NotificationDetails(
    iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    android: AndroidNotificationDetails('gutgood_reminders', 'GutGood Reminders', importance: Importance.max, priority: Priority.high, color: AppPalette.black),
  );

  @override
  Future<void> showNotification({required int id, required String title, required String body, String? payload}) async {
    try {
      await _notifications.show(id: id, title: title, body: body, notificationDetails: _defaultDetails, payload: payload);
    } catch (e) {
      Log.e('NotificationService: Error showing immediately', error: e);
    }
  }

  @override
  Future<void> scheduleNotification({required int id, required String title, required String body, required DateTime scheduledDate, String? payload}) async {
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
    } catch (e) {
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
      } else {
        rethrow;
      }
    }
  }

  Future<void> _scheduleDaily({required int id, required String title, required String body, required int hour, required int minute, String? payload}) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    try {
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
        rethrow;
      }
    }
  }

  @override
  Future<void> schedulePostMealCheckIn() async {
    final scheduledTime = DateTime.now().add(const Duration(hours: 2));
    await scheduleNotification(id: NotificationIds.postMealCheckIn, title: AppStrings.notifMealCheckTitle, body: AppStrings.notifMealCheckBody, scheduledDate: scheduledTime, payload: 'symptom_check');
  }

  @override
  Future<void> scheduleBreakfastReminder(int hour, int minute) => _scheduleDaily(
    id: NotificationIds.breakfastReminder,
    title: AppStrings.notifMealReminderTitle,
    body: AppStrings.notifMealReminderBody,
    hour: hour,
    minute: minute,
    payload: 'meal_reminder_breakfast',
  );

  @override
  Future<void> scheduleLunchReminder(int hour, int minute) =>
      _scheduleDaily(id: NotificationIds.lunchReminder, title: AppStrings.notifLunchReminderTitle, body: AppStrings.notifLunchReminderBody, hour: hour, minute: minute, payload: 'meal_reminder_lunch');

  @override
  Future<void> scheduleDinnerReminder(int hour, int minute) => _scheduleDaily(
    id: NotificationIds.dinnerReminder,
    title: AppStrings.notifEveningCheckInTitle,
    body: AppStrings.notifEveningCheckInBody,
    hour: hour,
    minute: minute,
    payload: 'meal_reminder_dinner',
  );

  @override
  Future<void> scheduleScanReminder(int hour, int minute) =>
      _scheduleDaily(id: NotificationIds.scanReminder, title: AppStrings.notifFoodScanReminderTitle, body: AppStrings.notifFoodScanReminderBody, hour: hour, minute: minute, payload: 'scan_reminder');

  @override
  Future<void> scheduleRestaurantReminder(int hour, int minute) => _scheduleDaily(
    id: NotificationIds.restaurantReminder,
    title: AppStrings.notifRestaurantReminderTitle,
    body: AppStrings.notifRestaurantReminderBody,
    hour: hour,
    minute: minute,
    payload: 'restaurant_reminder',
  );

  @override
  Future<void> scheduleNoMealLoggedReminder({int hour = 19, int minute = 0}) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final count = await _firestoreService.getMealLogsCountSince(startOfDay);

    if (count == 0) {
      await _scheduleDaily(id: NotificationIds.noMealLogged, title: AppStrings.notifNoMealLoggedTitle, body: AppStrings.notifNoMealLoggedBody, hour: hour, minute: minute, payload: 'no_meal_logged');
    } else {
      await cancel(NotificationIds.noMealLogged);
    }
  }

  @override
  Future<void> scheduleDailyReminder({int hour = 9, int minute = 0}) =>
      _scheduleDaily(id: NotificationIds.dailyReminder, title: AppStrings.notifDailyCheckInTitle, body: AppStrings.notifDailyCheckInBody, hour: hour, minute: minute, payload: 'daily_reminder');

  @override
  Future<void> markAppOpened() async {
    await scheduleDailyReminder(hour: 9, minute: 0);
  }

  @override
  Future<void> showInsightGeneratedNotification() async {
    await showNotification(id: NotificationIds.insightGenerated, title: AppStrings.notifInsightGeneratedTitle, body: AppStrings.notifInsightGeneratedBody, payload: 'insight_generated');
  }

  @override
  Future<void> checkAndTriggerProcessedFoodWarning() async {
    try {
      final lastShownStr = _prefs.getString('last_processed_warning_time');
      if (lastShownStr != null) {
        final lastShown = DateTime.parse(lastShownStr);
        if (DateTime.now().difference(lastShown).inDays < 7) return;
      }

      final recentScans = await _firestoreService.getRecentScans(limit: 100);
      final processedCount = recentScans.where((s) => s.novaGroup == '3' || s.novaGroup == '4').length;

      if (processedCount >= 3) {
        await showNotification(id: NotificationIds.processedFoodWarning, title: 'GutGood', body: AppStrings.notifProcessedFoodWarning, payload: 'processed_food_warning');
        await _prefs.setString('last_processed_warning_time', DateTime.now().toIso8601String());
      }
    } catch (e) {
      Log.e('NotificationService: Processed warning failed', error: e);
    }
  }

  @override
  Future<void> scheduleStreakSaverReminder(int currentStreak) async {
    if (currentStreak == 0) return;

    // Schedule for 8:00 PM today if they haven't been active
    final now = tz.TZDateTime.now(tz.local);
    final scheduledTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20, 0);

    if (scheduledTime.isBefore(now)) return;

    await scheduleNotification(
      id: NotificationIds.streakSaver,
      title: AppStrings.notifStreakSaverTitle,
      body: AppStrings.notifStreakSaverBody.replaceFirst('{streak}', currentStreak.toString()),
      scheduledDate: scheduledTime,
      payload: 'streak_saver',
    );
    Log.i('NotificationService: Streak saver scheduled for 8 PM');
  }

  @override
  Future<void> cancel(int id) => _notifications.cancel(id: id);

  @override
  Future<void> cancelMealReminders() async {
    await cancel(NotificationIds.breakfastReminder);
    await cancel(NotificationIds.lunchReminder);
    await cancel(NotificationIds.dinnerReminder);
  }

  @override
  Future<void> cancelNoMealLoggedReminder() => cancel(NotificationIds.noMealLogged);

  @override
  Future<void> cancelDailyReminder() => cancel(NotificationIds.dailyReminder);

  @override
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  @override
  Future<void> setupDefaultReminders() async {
    await scheduleBreakfastReminder(8, 0);
    await scheduleLunchReminder(12, 30);
    await scheduleDinnerReminder(19, 0);
    await scheduleDailyReminder(hour: 9, minute: 0);
    await scheduleNoMealLoggedReminder(hour: 19, minute: 0);
    await scheduleScanReminder(11, 0);
    await scheduleRestaurantReminder(18, 0);
  }

  void _handleNotificationTap(String? payload) {
    if (payload == null) return;
    if (payload == 'symptom_check' || payload == 'daily_reminder') {
      AppNavigator.push('/symptom-check-in');
    } else if (payload.startsWith('meal_reminder_') || payload == 'no_meal_logged') {
      AppNavigator.push('/home/chat');
    } else if (payload == 'insight_generated') {
      AppNavigator.push('/home/insights');
    } else if (payload == 'scan_reminder' || payload == 'restaurant_reminder') {
      AppNavigator.push('/home/chat');
    }
  }
}
