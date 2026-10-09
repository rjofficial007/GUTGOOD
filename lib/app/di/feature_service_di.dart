import 'dart:io';

import 'package:gutgood/core/di/di_instance.dart';
import 'package:gutgood/core/services/gut_score_calculator_service.dart';
import 'package:gutgood/core/services/streak_service.dart';
import 'package:gutgood/core/theme/theme_provider.dart';
import 'package:gutgood/features/auth/data/services/link_service.dart';
import 'package:gutgood/features/auth/data/services/usage_service.dart';
import 'package:gutgood/features/chat/data/services/chat_outbox_service.dart';
import 'package:gutgood/features/chat/data/services/image_upload_outbox.dart';
import 'package:gutgood/features/insights/data/services/pattern_engine_service.dart';
import 'package:gutgood/features/profile/data/services/debug_mock_data_service.dart';

/// Registers shared application policies and feature-owned service helpers.
void initFeatureServiceDI() {
  sl
    ..registerLazySingleton<GutScoreCalculatorService>(GutScoreCalculatorService.new)
    ..registerLazySingleton<StreakService>(() => StreakServiceImpl(prefs: sl()))
    ..registerLazySingleton<ChatOutboxService>(() => ChatOutboxServiceImpl(prefs: sl()))
    // Pending bytes live in the cache dir (expendable by design): if the OS
    // purges them, the outbox drops those entries gracefully on flush.
    ..registerLazySingleton<ImageUploadOutbox>(() => ImageUploadOutboxImpl(prefs: sl(), storageService: sl(), baseDir: Directory('${Directory.systemTemp.path}/pending_uploads')))
    ..registerLazySingleton<PatternEngineService>(() => PatternEngineServiceImpl(historyFirestoreService: sl(), insightFirestoreService: sl()))
    ..registerLazySingleton<LinkService>(() => LinkServiceImpl(authRepository: sl(), prefs: sl(), firebaseAuth: sl(), appStateService: sl()))
    ..registerLazySingleton<UsageService>(() => UsageServiceImpl(authRepository: sl(), authFirestoreService: sl(), usageFirestoreService: sl(), purchaseService: sl(), prefs: sl()))
    ..registerLazySingleton<DebugMockDataService>(
      () => DebugMockDataService(historyFirestoreService: sl(), insightFirestoreService: sl(), chatFirestoreService: sl(), generateInsightUseCase: sl()),
    )
    ..registerLazySingleton(() => ThemeNotifier(sl()));
}
