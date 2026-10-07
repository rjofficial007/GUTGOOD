import 'package:gutgood/core/di/di_instance.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/streak_service.dart';
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
import 'package:gutgood/features/insights/application/usecases/generate_insight_ai_interpretation_usecase.dart';
import 'package:gutgood/features/insights/application/usecases/generate_insight_usecase.dart';
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
import 'package:gutgood/features/scanner/data/services/scanner_score_service.dart';
import 'package:gutgood/features/scanner/domain/repositories/scanner_repository.dart';
import 'package:gutgood/features/scanner/presentation/providers/scanner_notifier.dart';
import 'package:gutgood/infrastructure/firebase/analytics_service.dart';
import 'package:gutgood/infrastructure/firebase/crashlytics_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/auth_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/gut_score_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/history_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/usage_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/notification_service.dart';

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
    ..registerLazySingleton(() => GutAuthNotifier(sl<AuthRepository>(), sl<AppStateService>()))
    ..registerLazySingleton(() => PurchaseProvider(purchaseService: sl(), connectionChecker: sl(), appStateService: sl(), prefs: sl(), authFirestoreService: sl(), analyticsService: sl()))
    // --- Profile ---
    ..registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl(firestoreService: sl()))
    ..registerLazySingleton(
      () => ProfileNotifier(
        sl<AuthRepository>(),
        sl<AuthFirestoreService>(),
        sl<HistoryFirestoreService>(),
        sl<GutScoreFirestoreService>(),
        sl<AppStateService>(),
        sl<NotificationService>(),
        sl<AnalyticsService>(),
        sl<CrashlyticsService>(),
        sl<StreakService>(),
        auth: sl(),
        prefs: sl(),
      ),
    )
    ..registerLazySingleton(() => UsageNotifier(sl<UsageFirestoreService>(), sl<AuthRepository>(), sl<AppStateService>()))
    // --- Chat ---
    ..registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl(firestoreService: sl(), aiService: sl(), streakService: sl(), foodImages: sl()))
    ..registerLazySingleton(
      () => ChatHistoryNotifier(
        repository: sl(),
        chatFirestoreService: sl(),
        authFirestoreService: sl(),
        historyFirestoreService: sl(),
        domainEventPersister: sl(),
        aiService: sl(),
        appStateService: sl(),
        prefs: sl(),
        auth: sl(),
        usageService: sl(),
      ),
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
        onTurnCompleted: () => sl<ProfileNotifier>().triggerPendingCelebration(),
      ),
    )
    // --- Insights ---
    ..registerLazySingleton<InsightRepository>(
      () => InsightRepositoryImpl(
        historyFirestoreService: sl(),
        insightFirestoreService: sl(),
        prefs: sl(),
      ),
    )
    ..registerLazySingleton(
      () => InsightsNotifier(
        sl<InsightRepository>(),
        sl<AppStateService>(),
        sl<AuthRepository>(),
        sl<AnalyticsService>(),
        sl<GenerateInsightUseCase>(),
        sl<GenerateInsightAiInterpretationUseCase>(),
        sl<GutScoreFirestoreService>(),
      ),
    )
    // --- Scanner ---
    ..registerLazySingleton<ScannerScoreService>(ScannerScoreService.new)
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
        scoreService: sl(),
      ),
    )
    ..registerLazySingleton(
      () => ScannerNotifier(
        repository: sl(),
        authFirestoreService: sl(),
        offService: sl(),
        storageService: sl(),
        onScanCompleted: () => sl<ProfileNotifier>().triggerPendingCelebration(),
      ),
    )
    // --- Logs ---
    ..registerLazySingleton<LogRepository>(() => LogRepositoryImpl(firestoreService: sl(), analyticsService: sl(), streakService: sl(), notificationService: sl(), appStateService: sl()))
    // --- History ---
    ..registerLazySingleton<HistoryRepository>(() => HistoryRepositoryImpl(firestoreService: sl()))
    ..registerLazySingleton(() => HistoryNotifier(repository: sl(), appStateService: sl(), auth: sl()))
    ..registerLazySingleton(() => SavedFoodsProvider(repository: sl(), appStateService: sl(), authRepository: sl()));
}
