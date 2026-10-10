import 'package:gutgood/core/di/di_instance.dart';
import 'package:gutgood/core/router/notification_navigation_port.dart';
import 'package:gutgood/infrastructure/firebase/analytics_service.dart';
import 'package:gutgood/infrastructure/firebase/crashlytics_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/auth_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/chat_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/food_image_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/gut_score_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/history_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/insight_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/swap_recommendation_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/usage_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/notification_service.dart';
import 'package:gutgood/infrastructure/firebase/remote_config_service.dart';
import 'package:gutgood/infrastructure/firebase/storage_service.dart';

/// Registers shared Firebase adapters and their cross-cutting integrations.
void initFirebaseDI({required NotificationNavigationPort notificationNavigation}) {
  sl
    ..registerLazySingleton<AnalyticsService>(AnalyticsServiceImpl.new)
    ..registerLazySingleton<CrashlyticsService>(CrashlyticsServiceImpl.new)
    ..registerLazySingleton<RemoteConfigService>(() => RemoteConfigServiceImpl(remoteConfig: sl()))
    ..registerLazySingleton<FoodImageService>(() => FoodImageServiceImpl(auth: sl(), db: sl(), prefs: sl()))
    ..registerLazySingleton<StorageService>(() => StorageServiceImpl(auth: sl(), storage: sl(), prefs: sl(), foodImages: sl()))
    ..registerLazySingleton<AuthFirestoreService>(() => AuthFirestoreServiceImpl(auth: sl(), db: sl(), storageService: sl()))
    ..registerLazySingleton<ChatFirestoreService>(() => ChatFirestoreServiceImpl(auth: sl(), db: sl()))
    ..registerLazySingleton<HistoryFirestoreService>(() => HistoryFirestoreServiceImpl(auth: sl(), db: sl(), foodImages: sl(), gutScoreService: sl()))
    ..registerLazySingleton<InsightFirestoreService>(() => InsightFirestoreServiceImpl(auth: sl(), db: sl()))
    ..registerLazySingleton<SwapRecommendationFirestoreService>(
      () => SwapRecommendationFirestoreServiceImpl(auth: sl(), db: sl()),
    )
    ..registerLazySingleton<GutScoreFirestoreService>(() => GutScoreFirestoreServiceImpl(auth: sl(), db: sl()))
    ..registerLazySingleton<UsageFirestoreService>(() => UsageFirestoreServiceImpl(auth: sl(), db: sl()))
    ..registerLazySingleton<NotificationService>(
      () => NotificationServiceImpl(
        notifications: sl(),
        authFirestoreService: sl(),
        historyFirestoreService: sl(),
        prefs: sl(),
        navigation: notificationNavigation,
      ),
    );
}
