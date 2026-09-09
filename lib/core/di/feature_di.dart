import 'package:gutgood/core/di/di_instance.dart';
import 'package:gutgood/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:gutgood/features/auth/domain/repositories/auth_repository.dart';
import 'package:gutgood/features/auth/presentation/providers/auth_provider.dart';
import 'package:gutgood/features/auth/presentation/providers/purchase_provider.dart';
import 'package:gutgood/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:gutgood/features/chat/domain/repositories/chat_repository.dart';
import 'package:gutgood/features/chat/presentation/providers/chat_composer_notifier.dart';
import 'package:gutgood/features/chat/presentation/providers/chat_history_notifier.dart';
import 'package:gutgood/features/history/data/repositories/history_repository_impl.dart';
import 'package:gutgood/features/history/domain/repositories/history_repository.dart';
import 'package:gutgood/features/history/presentation/providers/history_notifier.dart';
import 'package:gutgood/features/history/presentation/providers/saved_foods_provider.dart';
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

void initFeatureDI() {
  // --- Auth ---
  sl
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
        notificationService: sl(),
      ),
    )
    ..registerLazySingleton(() => GutAuthNotifier(sl(), sl()))
    ..registerLazySingleton(() => PurchaseProvider(purchaseService: sl(), connectionChecker: sl(), appStateService: sl(), prefs: sl(), authFirestoreService: sl(), analyticsService: sl()))
    // --- Profile ---
    ..registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl(auth: sl(), firestoreService: sl()))
    ..registerLazySingleton(() => ProfileNotifier(sl(), sl(), sl(), sl(), sl(), sl(), sl(), sl()))
    ..registerLazySingleton(() => UsageNotifier(sl(), sl()))
    // --- Chat ---
    ..registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl(firestoreService: sl(), aiService: sl(), streakService: sl(), foodImages: sl()))
    ..registerLazySingleton(
      () =>
          ChatHistoryNotifier(repository: sl(), chatFirestoreService: sl(), authFirestoreService: sl(), historyFirestoreService: sl(), aiService: sl(), appStateService: sl(), prefs: sl(), auth: sl(), usageService: sl()),
    )
    ..registerLazySingleton(
      () => ChatComposerNotifier(
        repository: sl(),
        historyNotifier: sl(),
        storageService: sl(),
        offService: sl(),
        aiClassifierService: sl(),
        auth: sl(),
        connectionChecker: sl(),
        sendMessageStreamUseCase: sl(),
        processChatTagUseCase: sl(),
        persistAiResponseUseCase: sl(),
        analyticsService: sl(),
        appStateService: sl(),
        outboxService: sl(),
        uploadOutbox: sl(),
        foodImages: sl(),
      ),
    )
    // --- Insights ---
    ..registerLazySingleton<InsightRepository>(
      () => InsightRepositoryImpl(
        historyFirestoreService: sl(),
        insightFirestoreService: sl(),
        chatFirestoreService: sl(),
        aiService: sl(),
        prefs: sl(),
        analyticsService: sl(),
        crashlyticsService: sl(),
      ),
    )
    ..registerLazySingleton(() => InsightsNotifier(sl(), sl(), sl(), sl(), sl()))
    // --- Scanner ---
    ..registerLazySingleton<ScannerRepository>(
      () => ScannerRepositoryImpl(
        offService: sl(),
        aiService: sl(),
        aiClassifierService: sl(),
        chatFirestoreService: sl(),
        historyFirestoreService: sl(),
        notificationService: sl(),
        appStateService: sl(),
        analyticsService: sl(),
        streakService: sl(),
        processChatTagUseCase: sl(),
        eventPersister: sl(),
      ),
    )
    ..registerLazySingleton(() => ScannerNotifier(repository: sl(), authFirestoreService: sl(), offService: sl(), storageService: sl()))
    // --- Logs ---
    ..registerLazySingleton<LogRepository>(() => LogRepositoryImpl(firestoreService: sl(), analyticsService: sl(), streakService: sl()))
    // --- History ---
    ..registerLazySingleton<HistoryRepository>(() => HistoryRepositoryImpl(firestoreService: sl()))
    ..registerLazySingleton(() => HistoryNotifier(repository: sl(), appStateService: sl(), auth: sl()))
    ..registerLazySingleton(() => SavedFoodsProvider(repository: sl(), appStateService: sl()));
}
