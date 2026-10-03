import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:gutgood/core/router/notification_navigation_port.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/auth_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/history_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/notification_ids.dart';
import 'package:gutgood/infrastructure/firebase/notification_payload_router.dart';
import 'package:gutgood/infrastructure/firebase/notification_scheduler.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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
  NotificationServiceImpl({
    required FlutterLocalNotificationsPlugin notifications,
    required AuthFirestoreService authFirestoreService,
    required HistoryFirestoreService historyFirestoreService,
    required SharedPreferences prefs,
    required NotificationNavigationPort navigation,
  }) : _notifications = notifications,
       _authFirestoreService = authFirestoreService,
       _payloadRouter = NotificationPayloadRouter(navigation: navigation),
       _scheduler = NotificationScheduler(
         notifications: notifications,
         historyFirestoreService: historyFirestoreService,
         prefs: prefs,
       );

  final FlutterLocalNotificationsPlugin _notifications;
  final AuthFirestoreService _authFirestoreService;
  final NotificationPayloadRouter _payloadRouter;
  final NotificationScheduler _scheduler;

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
        _payloadRouter.handle(details.payload);
      },
    );

    // Create high importance channel for Android
    if (defaultTargetPlatform == TargetPlatform.android) {
      const channel = AndroidNotificationChannel('gutgood_reminders', 'GutGood Reminders', description: 'This channel is used for important health alerts and reminders.', importance: Importance.max);

      await _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
    }

    // Initialize FCM
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(alert: true, badge: true, sound: true);

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final token = await messaging.getToken();
        if (token != null) {
          await _authFirestoreService.saveFcmToken(token);
        }
      }

      messaging.onTokenRefresh.listen(_authFirestoreService.saveFcmToken);

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
      // scheduleExactAlarm is only needed for Android 12+ (API 31+)
      final status = await Permission.scheduleExactAlarm.status;
      if (status.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, badge: true, sound: true);
    }

    AppLogger.notifs('Initialized');
  }

  static Future<void> showBackgroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const androidPlatformChannelSpecifics = AndroidNotificationDetails('gutgood_reminders', 'GutGood Reminders', importance: Importance.max, priority: Priority.high, color: AppPalette.black);

    const platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics, iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true));

    // 🟢 Fix: Use a dynamic ID for background notifications to prevent overwriting
    // when multiple push messages arrive in a short window.
    final id = NotificationIds.firebaseBackground + (message.messageId?.hashCode ?? 0) % 1000;

    await flutterLocalNotificationsPlugin.show(id: id, title: notification.title, body: notification.body, notificationDetails: platformChannelSpecifics, payload: message.data['type']);
  }

  @override
  Future<void> showNotification({required int id, required String title, required String body, String? payload}) =>
      _scheduler.showNotification(id: id, title: title, body: body, payload: payload);

  @override
  Future<void> scheduleNotification({required int id, required String title, required String body, required DateTime scheduledDate, String? payload}) =>
      _scheduler.scheduleNotification(id: id, title: title, body: body, scheduledDate: scheduledDate, payload: payload);

  @override
  Future<void> schedulePostMealCheckIn() => _scheduler.schedulePostMealCheckIn();

  @override
  Future<void> scheduleBreakfastReminder(int hour, int minute) => _scheduler.scheduleBreakfastReminder(hour, minute);

  @override
  Future<void> scheduleLunchReminder(int hour, int minute) => _scheduler.scheduleLunchReminder(hour, minute);

  @override
  Future<void> scheduleDinnerReminder(int hour, int minute) => _scheduler.scheduleDinnerReminder(hour, minute);

  @override
  Future<void> scheduleScanReminder(int hour, int minute) => _scheduler.scheduleScanReminder(hour, minute);

  @override
  Future<void> scheduleRestaurantReminder(int hour, int minute) => _scheduler.scheduleRestaurantReminder(hour, minute);

  @override
  Future<void> scheduleNoMealLoggedReminder({int hour = 19, int minute = 0}) => _scheduler.scheduleNoMealLoggedReminder(hour: hour, minute: minute);

  @override
  Future<void> scheduleDailyReminder({int hour = 9, int minute = 0}) => _scheduler.scheduleDailyReminder(hour: hour, minute: minute);

  @override
  Future<void> markAppOpened() => _scheduler.markAppOpened();

  @override
  Future<void> showInsightGeneratedNotification() => _scheduler.showInsightGeneratedNotification();

  @override
  Future<void> scheduleStreakSaverReminder(int currentStreak) => _scheduler.scheduleStreakSaverReminder(currentStreak);

  @override
  Future<void> cancel(int id) => _scheduler.cancel(id);

  @override
  Future<void> cancelMealReminders() => _scheduler.cancelMealReminders();

  @override
  Future<void> cancelNoMealLoggedReminder() => _scheduler.cancelNoMealLoggedReminder();

  @override
  Future<void> cancelDailyReminder() => _scheduler.cancelDailyReminder();

  @override
  Future<void> cancelAll() => _scheduler.cancelAll();

  @override
  Future<void> setupDefaultReminders() => _scheduler.setupDefaultReminders();

  @override
  Future<void> testNotification() => _scheduler.testNotification();

}
