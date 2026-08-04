import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/services/firestore_service.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/navigator_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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
  static const int firebaseBackground = 111;
}

abstract class NotificationService {
  Future<void> init();
  Future<void> showNotification({required int id, required String title, required String body, String? payload});
  static Future<void> showBackgroundNotification(RemoteMessage message) async {
    // This will be implemented in the child class or as a standalone logic
  }
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
  Future<void> scheduleStreakSaverReminder(int currentStreak);
  Future<void> cancel(int id);
  Future<void> cancelMealReminders();
  Future<void> cancelNoMealLoggedReminder();
  Future<void> cancelDailyReminder();
  Future<void> cancelAll();
  Future<void> setupDefaultReminders();
  Future<void> testNotification();
}

class NotificationServiceImpl implements NotificationService {

  NotificationServiceImpl({required FlutterLocalNotificationsPlugin notifications, required FirestoreService firestoreService, required SharedPreferences prefs})
    : _notifications = notifications,
      _firestoreService = firestoreService,
      _prefs = prefs;
  final FlutterLocalNotificationsPlugin _notifications;
  final FirestoreService _firestoreService;
  final SharedPreferences _prefs;

  @override
  Future<void> init() async {
    tz.initializeTimeZones();
    final timeZoneName = (await FlutterTimezone.getLocalTimezone()).identifier;
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const androidSettings = AndroidInitializationSettings('ic_notification');
    const iosSettings = DarwinInitializationSettings(requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true);

    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        AppLogger.info('NotificationService: Tapped payload: ${details.payload}');
        _handleNotificationTap(details.payload);
      },
    );

    // Create high importance channel for Android
    if (defaultTargetPlatform == TargetPlatform.android) {
      const channel = AndroidNotificationChannel(
        'gutgood_reminders',
        'GutGood Reminders',
        description: 'This channel is used for important health alerts and reminders.',
        importance: Importance.max,
      );

      await _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
    }

    // Initialize FCM
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(alert: true, badge: true, sound: true);

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final token = await messaging.getToken();
        if (token != null) {
          await _firestoreService.saveFcmToken(token);
        }
      }

      messaging.onTokenRefresh.listen(_firestoreService.saveFcmToken);

      // 🟢 Fix: Listen for messages while the app is in the FOREGROUND
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        AppLogger.debug('NotificationService: Foreground message received: ${message.messageId}');
        // Manually show the notification since iOS/Android suppress them in foreground
        showBackgroundNotification(message);
      });
    } catch (e) {
      AppLogger.error('NotificationService: FCM init failed', error: e);
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      await Permission.notification.request();
      final status = await Permission.scheduleExactAlarm.status;
      if (status.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, badge: true, sound: true);
    }

    AppLogger.info('NotificationService: Initialized');
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
      AppLogger.error('NotificationService: Error showing immediately', error: e);
    }
  }

  static Future<void> showBackgroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'gutgood_reminders',
      'GutGood Reminders',
      importance: Importance.max,
      priority: Priority.high,
      color: AppPalette.black,
    );

    const platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    );

    await flutterLocalNotificationsPlugin.show(
      id: NotificationIds.firebaseBackground,
      title: notification.title,
      body: notification.body,
      notificationDetails: platformChannelSpecifics,
      payload: message.data['type'],
    );
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
    // 🟡 Fix: Use local start of day to match the user's local day experience.
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final count = await _firestoreService.getMealLogsCountSince(startOfToday);

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
    // 🟡 Fix: Respect user preference if they have customized the daily reminder time.
    final timeStr = _prefs.getString('notif_daily_time') ?? '9:00';
    final parts = timeStr.split(':');
    final hour = int.tryParse(parts[0]) ?? 9;
    final minute = int.tryParse(parts[1]) ?? 0;

    await scheduleDailyReminder(hour: hour, minute: minute);
  }

  @override
  Future<void> showInsightGeneratedNotification() async {
    // 🟡 Pro Fix: This is now handled by the Cloud Function (onInsightCreated)
    // for better reliability and cross-device consistency.
    AppLogger.debug('NotificationService: Skipping local insight notification (handled by server)');
  }

  @override
  Future<void> scheduleStreakSaverReminder(int currentStreak) async {
    if (currentStreak == 0) return;

    // Schedule for 8:00 PM today if they haven't been active
    final now = tz.TZDateTime.now(tz.local);
    final scheduledTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20, 0);

    if (scheduledTime.isBefore(now)) return;

    const title = AppStrings.notifStreakSaverTitle;
    final body = AppStrings.notifStreakSaverBody.replaceFirst('{streak}', currentStreak.toString());

    await scheduleNotification(id: NotificationIds.streakSaver, title: title, body: body, scheduledDate: scheduledTime, payload: 'streak_saver');

    // Note: We don't save to Firestore yet because it's scheduled for the future.
    // If they open the app, we cancel it.
    AppLogger.info('NotificationService: Streak saver scheduled for 8 PM');
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

  @override
  Future<void> testNotification() async {
    await showNotification(id: 999, title: 'GutGood Test', body: 'This is a test notification to verify FCM and local channels are working! 🚀', payload: 'test_notification');
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
