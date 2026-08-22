import 'package:gutgood/core/di/di_instance.dart';
import 'package:gutgood/core/services/ai_service.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/services/app_services.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/app_version_services.dart';
import 'package:gutgood/core/services/config_service.dart';
import 'package:gutgood/core/services/crashlytics_service.dart';
import 'package:gutgood/core/services/debug_mock_data_service.dart';
import 'package:gutgood/core/services/device_info_services.dart';
import 'package:gutgood/core/services/firestore/auth_firestore_service.dart';
import 'package:gutgood/core/services/firestore/chat_firestore_service.dart';
import 'package:gutgood/core/services/firestore/history_firestore_service.dart';
import 'package:gutgood/core/services/firestore/insight_firestore_service.dart';
import 'package:gutgood/core/services/firestore/usage_firestore_service.dart';
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

void initServiceDI() {
  sl
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
    ..registerLazySingleton<AuthFirestoreService>(() => AuthFirestoreServiceImpl(auth: sl(), db: sl(), storageService: sl()))
    ..registerLazySingleton<ChatFirestoreService>(() => ChatFirestoreServiceImpl(auth: sl(), db: sl()))
    ..registerLazySingleton<HistoryFirestoreService>(() => HistoryFirestoreServiceImpl(auth: sl(), db: sl()))
    ..registerLazySingleton<InsightFirestoreService>(() => InsightFirestoreServiceImpl(auth: sl(), db: sl()))
    ..registerLazySingleton<UsageFirestoreService>(() => UsageFirestoreServiceImpl(auth: sl(), db: sl()))
    ..registerLazySingleton<NotificationService>(() => NotificationServiceImpl(notifications: sl(), authFirestoreService: sl(), historyFirestoreService: sl(), prefs: sl()))
    ..registerLazySingleton<PatternEngineService>(() => PatternEngineServiceImpl(historyFirestoreService: sl(), insightFirestoreService: sl()))
    ..registerLazySingleton<InternetConnectionChecker>(InternetConnectionCheckerImpl.new)
    ..registerLazySingleton<LinkService>(() => LinkServiceImpl(authRepository: sl(), prefs: sl(), firebaseAuth: sl(), appStateService: sl()))
    ..registerLazySingleton<PurchaseService>(PurchaseServiceImpl.new)
    ..registerLazySingleton<UsageService>(() => UsageServiceImpl(authRepository: sl(), authFirestoreService: sl(), usageFirestoreService: sl(), purchaseService: sl(), prefs: sl()))
    ..registerLazySingleton<DebugMockDataService>(() => DebugMockDataService(historyFirestoreService: sl()))
    ..registerLazySingleton(() => ThemeNotifier(sl()));
}
