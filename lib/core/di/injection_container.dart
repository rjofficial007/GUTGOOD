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
import 'package:gutgood/core/services/app_services.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/app_version_services.dart';
import 'package:gutgood/core/services/config_service.dart';
import 'package:gutgood/core/services/device_info_services.dart';
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
import 'package:gutgood/features/scanner/data/repositories/scanner_repository_impl.dart';
import 'package:gutgood/features/scanner/domain/repositories/scanner_repository.dart';
import 'package:gutgood/features/scanner/presentation/providers/scanner_notifier.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

/// Launch the app against the Firebase Emulator Suite with:
/// `flutter run --dart-define=USE_FIREBASE_EMULATOR=true`
const bool _useFirebaseEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');

String get _emulatorHost => Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';

Future<void> init() async {
  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() {
    final auth = FirebaseAuth.instance;
    if (_useFirebaseEmulator && kDebugMode) auth.useAuthEmulator(_emulatorHost, 9099);
    return auth;
  });
  sl.registerLazySingleton(() {
    final firestore = FirebaseFirestore.instance;
    firestore.settings = const Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED);
    if (_useFirebaseEmulator && kDebugMode) firestore.useFirestoreEmulator(_emulatorHost, 8080);
    return firestore;
  });
  sl.registerLazySingleton(() {
    // Region pinned to match the deployed functions (us-central1).
    final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
    if (_useFirebaseEmulator && kDebugMode) functions.useFunctionsEmulator(_emulatorHost, 5001);
    return functions;
  });
  sl.registerLazySingleton(() {
    final storage = FirebaseStorage.instance;
    if (_useFirebaseEmulator && kDebugMode) storage.useStorageEmulator(_emulatorHost, 9199);
    return storage;
  });
  sl.registerLazySingleton(() => FirebaseRemoteConfig.instance);
  sl.registerLazySingleton(() => GoogleSignIn.instance);
  sl.registerLazySingleton(() => DeviceInfoPlugin());
  sl.registerLazySingleton(() => Dio(BaseOptions(connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 15))));
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => FlutterLocalNotificationsPlugin());

  //! Core Services
  sl.registerLazySingleton<ConfigService>(() => ConfigServiceImpl());
  sl.registerLazySingleton<AppVersionService>(() => AppVersionServiceImpl());
  sl.registerLazySingleton<DeviceInfoService>(() => DeviceInfoServiceImpl(deviceInfoPlugin: sl()));
  sl.registerLazySingleton<AppService>(() => AppServiceImpl(appVersionService: sl(), deviceInfoService: sl(), configService: sl(), httpClient: sl()));

  sl.registerLazySingleton<AppStateService>(() => AppStateServiceImpl());

  sl.registerLazySingleton<RemoteConfigService>(() => RemoteConfigServiceImpl(remoteConfig: sl()));

  // All AI traffic goes through the secure aiProxy Cloud Function — the OpenAI
  // key lives only on the server (PRD §3d). No on-device AI SDK keys.
  sl.registerLazySingleton<AiService>(() => AiServiceImpl(dio: sl(), auth: sl(), config: sl()));

  sl.registerLazySingleton<OffService>(() => OffServiceImpl(dio: sl()));

  sl.registerLazySingleton<StorageService>(() => StorageServiceImpl(auth: sl(), storage: sl()));

  sl.registerLazySingleton<FirestoreService>(() => FirestoreServiceImpl(auth: sl(), db: sl(), storageService: sl()));

  sl.registerLazySingleton<NotificationService>(() => NotificationServiceImpl(notifications: sl(), firestoreService: sl(), prefs: sl()));

  sl.registerLazySingleton<PatternEngineService>(() => PatternEngineServiceImpl(firestoreService: sl()));

  sl.registerLazySingleton<InternetConnectionChecker>(() => InternetConnectionCheckerImpl());

  sl.registerLazySingleton<LinkService>(() => LinkServiceImpl(authRepository: sl(), prefs: sl(), firebaseAuth: sl(), appStateService: sl()));

  sl.registerLazySingleton<PurchaseService>(() => PurchaseServiceImpl());

  sl.registerLazySingleton<UsageService>(() => UsageServiceImpl(authRepository: sl(), firestoreService: sl(), purchaseService: sl(), prefs: sl()));

  sl.registerLazySingleton(() => ThemeNotifier(sl()));

  //! Features
  // Auth
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(firebaseAuth: sl(), googleSignIn: sl(), firestoreService: sl(), purchaseService: sl(), storageService: sl(), prefs: sl(), appStateService: sl(), firebaseFunctions: sl()),
  );
  sl.registerLazySingleton(() => GutAuthNotifier(sl(), sl()));
  sl.registerLazySingleton(() => PurchaseProvider(purchaseService: sl(), connectionChecker: sl(), appStateService: sl(), prefs: sl(), firestoreService: sl()));

  // Profile
  sl.registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl(auth: sl(), firestoreService: sl()));
  sl.registerLazySingleton(() => ProfileNotifier(sl(), sl(), sl()));

  // Chat
  sl.registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl(firestoreService: sl(), aiService: sl()));
  sl.registerLazySingleton(
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
    ),
  );

  // Insights
  sl.registerLazySingleton<InsightRepository>(() => InsightRepositoryImpl(firestoreService: sl(), aiService: sl(), prefs: sl(), notificationService: sl(), patternEngineService: sl()));
  sl.registerLazySingleton(() => InsightsNotifier(repository: sl(), firestoreService: sl(), appStateService: sl()));

  // Scanner
  sl.registerLazySingleton<ScannerRepository>(() => ScannerRepositoryImpl(offService: sl(), aiService: sl(), firestoreService: sl(), notificationService: sl(), appStateService: sl()));
  sl.registerLazySingleton(() => ScannerNotifier(repository: sl(), firestoreService: sl(), offService: sl(), storageService: sl()));

  // Logs
  sl.registerLazySingleton<LogRepository>(() => LogRepositoryImpl(firestoreService: sl()));

  // History
  sl.registerLazySingleton<HistoryRepository>(() => HistoryRepositoryImpl(firestoreService: sl()));

  //! UseCases
  sl.registerLazySingleton(() => SendMessageStreamUseCase(sl()));
  sl.registerLazySingleton(() => ProcessChatTagUseCase(firestoreService: sl(), notificationService: sl()));
}
