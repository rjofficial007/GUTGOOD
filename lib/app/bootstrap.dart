import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gutgood/app/di/injection_container.dart';
import 'package:gutgood/app/router/app_navigator.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/firebase_options.dart';
import 'package:gutgood/infrastructure/firebase/notification_service.dart';
import 'package:gutgood/infrastructure/platform/app_version_service.dart';
import 'package:gutgood/infrastructure/platform/device_info_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  AppLogger.debug('Handling a background message: ${message.messageId}');
  await NotificationService.showBackgroundNotification(message);
}

/// Process-level initialization for Firebase, dependency injection,
/// diagnostics, device metadata, and platform configuration.
///
/// Keeping this work outside the widget tree makes startup ordering explicit
/// and prevents [main] from becoming a second composition root.
class AppBootstrap {
  const AppBootstrap._();

  static Future<void> initialize() async {
    AppLogger.info('App starting...');

    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await init(notificationNavigation: const AppNotificationNavigation());

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Crashlytics: capture Flutter framework errors and uncaught async errors in all modes.
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    FlutterError.onError = (details) {
      // Skip the benign Firestore transaction-cancel echo (see above): it
      // fires after the transaction already completed. Genuine failures still
      // surface via the services' own try/catch (AppLogger -> Crashlytics)
      // with their real error, never with this signature.
      if (_isBenignTransactionTeardown(details)) {
        AppLogger.debug('Crashlytics: filtered benign Firestore transaction-cancel echo');
        return;
      }
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(FirebaseCrashlytics.instance.recordError(error, stack, fatal: true));
      return true;
    };

    // Initialize app services before the first frame, as in the original
    // startup sequence. Failures remain visible to the existing crash handler.
    await sl<AppVersionService>().fetchAppInfo();
    await sl<DeviceInfoService>().fetchDeviceInfo();

    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  /// True for the known-benign `cancel` echo on disposed Firestore
  /// transaction channels (see the transaction onError wiring in bootstrap).
  static bool _isBenignTransactionTeardown(FlutterErrorDetails details) {
    final exception = details.exception;
    return exception is MissingPluginException &&
        (exception.message?.contains('firebase_firestore/transaction') ?? false) &&
        (exception.message?.contains('cancel') ?? false);
  }
}
