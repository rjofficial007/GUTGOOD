import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/router/app_router.dart';
import 'package:gutgood/core/services/app_version_services.dart';
import 'package:gutgood/core/services/device_info_services.dart';
import 'package:gutgood/core/services/internet_connection_checker.dart';
import 'package:gutgood/core/services/notification_service.dart';
import 'package:gutgood/core/theme/app_theme.dart';
import 'package:gutgood/core/theme/theme_provider.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/offline_banner.dart';
import 'package:gutgood/core/widgets/verification_overlay.dart';
import 'package:gutgood/features/auth/presentation/providers/auth_provider.dart';
import 'package:gutgood/features/auth/presentation/providers/purchase_provider.dart';
import 'package:gutgood/features/chat/presentation/providers/chat_composer_notifier.dart';
import 'package:gutgood/features/chat/presentation/providers/chat_history_notifier.dart';
import 'package:gutgood/features/history/presentation/providers/history_notifier.dart';
import 'package:gutgood/features/history/presentation/providers/saved_foods_provider.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:gutgood/features/profile/presentation/providers/usage_notifier.dart';
import 'package:gutgood/features/scanner/presentation/providers/scanner_notifier.dart';
import 'package:gutgood/firebase_options.dart';
import 'package:provider/provider.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  AppLogger.debug('Handling a background message: ${message.messageId}');
  await NotificationService.showBackgroundNotification(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.info('App starting...');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await init();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Crashlytics: capture Flutter framework errors and uncaught async errors in all modes.
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(FirebaseCrashlytics.instance.recordError(error, stack, fatal: true));
    return true;
  };

  // Initialize App Services
  await sl<AppVersionService>().fetchAppInfo();
  await sl<DeviceInfoService>().fetchDeviceInfo();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => sl<ThemeNotifier>()),
        ChangeNotifierProvider(create: (_) => sl<GutAuthNotifier>()),
        ChangeNotifierProvider(create: (_) => sl<ProfileNotifier>()),
        ChangeNotifierProvider(create: (_) => sl<UsageNotifier>()),
        ChangeNotifierProvider(create: (_) => sl<ChatHistoryNotifier>()),
        ChangeNotifierProvider(create: (_) => sl<ChatComposerNotifier>()),
        ChangeNotifierProvider(create: (_) => sl<InsightsNotifier>()),
        ChangeNotifierProvider(create: (_) => sl<ScannerNotifier>()),
        ChangeNotifierProvider(create: (_) => sl<PurchaseProvider>()),
        ChangeNotifierProvider(create: (_) => sl<HistoryNotifier>()),
        ChangeNotifierProvider(create: (_) => sl<SavedFoodsProvider>()),
      ],
      child: const GutGoodApp(),
    ),
  );
}

class GutGoodApp extends StatefulWidget {
  const GutGoodApp({super.key});

  @override
  State<GutGoodApp> createState() => _GutGoodAppState();
}

class _GutGoodAppState extends State<GutGoodApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Firestore handles connectivity restoration automatically.
    sl<InternetConnectionChecker>().startListening();
  }

  @override
  void dispose() {
    sl<InternetConnectionChecker>().stopListening();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      sl<InternetConnectionChecker>().checkConnection();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();

    return MaterialApp.router(
      routerConfig: AppRouter.router,
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeNotifier.themeMode,
      builder: (context, child) {
        Responsive.init(context);

        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Stack(
            children: [
              child ?? const SizedBox.shrink(),
              const Positioned(top: 0, left: 0, right: 0, child: OfflineBanner()),
              const Positioned.fill(child: VerificationOverlay()),
            ],
          ),
        );
      },
    );
  }
}
