import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gutgood/core/services/ai_service.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/services/app_services.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/app_version_services.dart';
import 'package:gutgood/core/services/config_service.dart';
import 'package:gutgood/core/services/crashlytics_service.dart';
import 'package:gutgood/core/services/device_info_services.dart';
import 'package:gutgood/core/services/export_service.dart';
import 'package:gutgood/core/services/firestore_service.dart';
import 'package:gutgood/core/services/internet_connection_checker.dart';
import 'package:gutgood/core/services/link_service.dart';
import 'package:gutgood/core/services/notification_service.dart';
import 'package:gutgood/core/services/off_service.dart';
import 'package:gutgood/core/services/pattern_engine_service.dart';
import 'package:gutgood/core/services/purchase_service.dart';
import 'package:gutgood/core/services/remote_config_service.dart';
import 'package:gutgood/core/services/storage_service.dart';
import 'package:gutgood/core/services/usage_service.dart';
import 'package:gutgood/core/theme/theme_provider.dart';
import 'package:gutgood/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:gutgood/features/auth/domain/repositories/auth_repository.dart';
import 'package:gutgood/features/auth/presentation/providers/auth_provider.dart';
import 'package:gutgood/features/auth/presentation/providers/purchase_provider.dart';
import 'package:gutgood/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:gutgood/features/chat/domain/repositories/chat_repository.dart';
import 'package:gutgood/features/chat/domain/usecases/process_chat_tag_usecase.dart';
import 'package:gutgood/features/chat/domain/usecases/send_message_stream_usecase.dart';
import 'package:gutgood/features/chat/presentation/providers/chat_provider.dart';
import 'package:gutgood/features/history/data/repositories/history_repository_impl.dart';
import 'package:gutgood/features/history/domain/repositories/history_repository.dart';
import 'package:gutgood/features/insights/data/repositories/insight_repository_impl.dart';
import 'package:gutgood/features/insights/domain/repositories/insight_repository.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/logs/data/repositories/log_repository_impl.dart';
import 'package:gutgood/features/logs/domain/repositories/log_repository.dart';
import 'package:gutgood/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:gutgood/features/profile/domain/repositories/profile_repository.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:gutgood/features/profile/presentation/providers/usage_notifier.dart';
import 'package:gutgood/features/scanner/data/repositories/scanner_repository_impl.dart';
import 'package:gutgood/features/scanner/domain/repositories/scanner_repository.dart';
import 'package:gutgood/features/scanner/presentation/providers/scanner_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

/// Launch the app against the Firebase Emulator Suite with:
/// `flutter run --dart-define=USE_FIREBASE_EMULATOR=true`
const bool _useFirebaseEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');

String get _emulatorHost => Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';

Future<void> init() async {
  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl
    ..registerLazySingleton(() => sharedPreferences)
    ..registerLazySingleton(() {
      final auth = FirebaseAuth.instance;
      if (_useFirebaseEmulator && kDebugMode) {
        auth.useAuthEmulator(_emulatorHost, 9099);
      }
      return auth;
    })
    ..registerLazySingleton(() {
      final firestore = FirebaseFirestore.instance
        ..settings = const Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED);
      if (_useFirebaseEmulator && kDebugMode) {
        firestore.useFirestoreEmulator(_emulatorHost, 8080);
      }
      return firestore;
    })
    ..registerLazySingleton(() {
      // Region pinned to match the deployed functions (us-central1).
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      if (_useFirebaseEmulator && kDebugMode) {
        functions.useFunctionsEmulator(_emulatorHost, 5001);
      }
      return functions;
    })
    ..registerLazySingleton(() {
      final storage = FirebaseStorage.instance;
      if (_useFirebaseEmulator && kDebugMode) {
        storage.useStorageEmulator(_emulatorHost, 9199);
      }
      return storage;
    })
    ..registerLazySingleton(() => FirebaseRemoteConfig.instance)
    ..registerLazySingleton(() => GoogleSignIn.instance)
    ..registerLazySingleton(DeviceInfoPlugin.new)
    ..registerLazySingleton(() => Dio(BaseOptions(connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 15))))
    ..registerLazySingleton(FlutterLocalNotificationsPlugin.new)

  //! Core Services

    ..registerLazySingleton<ConfigService>(ConfigServiceImpl.new)
    ..registerLazySingleton<AnalyticsService>(AnalyticsServiceImpl.new)
    ..registerLazySingleton<CrashlyticsService>(CrashlyticsServiceImpl.new)
    ..registerLazySingleton<AppVersionService>(AppVersionServiceImpl.new)
    ..registerLazySingleton<DeviceInfoService>(() => DeviceInfoServiceImpl(deviceInfoPlugin: sl()))
    ..registerLazySingleton<AppService>(() => AppServiceImpl(appVersionService: sl(), deviceInfoService: sl(), configService: sl(), dio: sl()))
    ..registerLazySingleton<AppStateService>(AppStateServiceImpl.new)
    ..registerLazySingleton<RemoteConfigService>(() => RemoteConfigServiceImpl(remoteConfig: sl()))
    ..registerLazySingleton<AiService>(() => AiServiceImpl(dio: sl(), auth: sl(), config: sl(), analyticsService: sl(), crashlyticsService: sl()))
    ..registerLazySingleton<OffService>(() => OffServiceImpl(dio: sl()))
    ..registerLazySingleton<StorageService>(() => StorageServiceImpl(auth: sl(), storage: sl()))
    ..registerLazySingleton<FirestoreService>(() => FirestoreServiceImpl(auth: sl(), db: sl(), storageService: sl()))
    ..registerLazySingleton<NotificationService>(() => NotificationServiceImpl(notifications: sl(), firestoreService: sl(), prefs: sl()))
    ..registerLazySingleton<PatternEngineService>(() => PatternEngineServiceImpl(firestoreService: sl()))
    ..registerLazySingleton<InternetConnectionChecker>(InternetConnectionCheckerImpl.new)
    ..registerLazySingleton<LinkService>(() => LinkServiceImpl(authRepository: sl(), prefs: sl(), firebaseAuth: sl(), appStateService: sl()))
    ..registerLazySingleton<PurchaseService>(PurchaseServiceImpl.new)
    ..registerLazySingleton<UsageService>(() => UsageServiceImpl(authRepository: sl(), firestoreService: sl(), purchaseService: sl(), prefs: sl()))
    ..registerLazySingleton<ExportService>(() => ExportServiceImpl(firestoreService: sl()))
    ..registerLazySingleton(() => ThemeNotifier(sl()))

  //! Features
  // Auth

    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        firebaseAuth: sl(),
        googleSignIn: sl(),
        firestoreService: sl(),
        purchaseService: sl(),
        prefs: sl(),
        appStateService: sl(),
        firebaseFunctions: sl(),
        analyticsService: sl(),
        crashlyticsService: sl(),
      ),
    )
    ..registerLazySingleton(() => GutAuthNotifier(sl(), sl()))
    ..registerLazySingleton(() => PurchaseProvider(purchaseService: sl(), connectionChecker: sl(), appStateService: sl(), prefs: sl(), firestoreService: sl(), analyticsService: sl()))

    // Profile
    ..registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl(auth: sl(), firestoreService: sl()))
    ..registerLazySingleton(() => ProfileNotifier(sl(), sl(), sl(), sl(), sl(), sl()))
    ..registerLazySingleton(() => UsageNotifier(sl(), sl()))

    // Chat
    ..registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl(firestoreService: sl(), aiService: sl()))
    ..registerLazySingleton(
      () => ChatNotifier(
        repository: sl(),
        firestoreService: sl(),
        aiService: sl(),
        storageService: sl(),
        offService: sl(),
        prefs: sl(),
        auth: sl(),
        connectionChecker: sl(),
        sendMessageStreamUseCase: sl(),
        processChatTagUseCase: sl(),
        appStateService: sl(),
        analyticsService: sl(),
      ),
    )

    // Insights
    ..registerLazySingleton<InsightRepository>(
      () => InsightRepositoryImpl(firestoreService: sl(), aiService: sl(), prefs: sl(), notificationService: sl(), patternEngineService: sl(), analyticsService: sl(), crashlyticsService: sl()),
    )
    ..registerLazySingleton(() => InsightsNotifier(sl(), sl(), sl(), sl(), sl()))

    // Scanner
    ..registerLazySingleton<ScannerRepository>(
      () => ScannerRepositoryImpl(offService: sl(), aiService: sl(), firestoreService: sl(), notificationService: sl(), appStateService: sl(), analyticsService: sl()),
    )
    ..registerLazySingleton(() => ScannerNotifier(repository: sl(), firestoreService: sl(), offService: sl(), storageService: sl()))

    // Logs
    ..registerLazySingleton<LogRepository>(() => LogRepositoryImpl(firestoreService: sl(), analyticsService: sl()))

    // History
    ..registerLazySingleton<HistoryRepository>(() => HistoryRepositoryImpl(firestoreService: sl()))

  //! UseCases

    ..registerLazySingleton(() => SendMessageStreamUseCase(sl()))
    ..registerLazySingleton(() => ProcessChatTagUseCase(firestoreService: sl(), notificationService: sl(), appStateService: sl()));
}

