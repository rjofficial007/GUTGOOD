import 'dart:async';

import 'package:gutgood/core/di/di_instance.dart';
import 'package:gutgood/features/chat/application/usecases/persist_ai_response_usecase.dart';
import 'package:gutgood/features/chat/domain/usecases/process_chat_tag_usecase.dart';
import 'package:gutgood/features/chat/domain/usecases/send_message_stream_usecase.dart';
import 'package:gutgood/features/insights/application/usecases/generate_insight_usecase.dart';
import 'package:gutgood/features/insights/application/usecases/summarize_journal_usecase.dart';
import 'package:gutgood/features/insights/domain/usecases/build_unified_journal_usecase.dart';
import 'package:gutgood/features/insights/domain/usecases/check_insight_threshold_usecase.dart';
import 'package:gutgood/features/logs/data/services/domain_event_persister.dart';
import 'package:gutgood/infrastructure/firebase/notification_service.dart';

void initUseCaseDI() {
  sl
    ..registerLazySingleton(() => SendMessageStreamUseCase(sl()))
    ..registerLazySingleton(ProcessChatTagUseCase.new)
    ..registerLazySingleton(() => DomainEventPersister(historyFirestoreService: sl(), onMealPersisted: _recheckNoMealReminder))
    ..registerLazySingleton(() => PersistAiResponseUseCase(firestoreService: sl(), appStateService: sl(), streakService: sl(), onMealPersisted: _recheckNoMealReminder))
    ..registerLazySingleton(() => const CheckInsightThresholdUseCase())
    ..registerLazySingleton(() => const BuildUnifiedJournalUseCase())
    ..registerLazySingleton(() => SummarizeJournalUseCase(aiService: sl()))
    ..registerLazySingleton(
      () => GenerateInsightUseCase(
        insightRepository: sl(),
        authFirestoreService: sl(),
        checkThreshold: sl(),
        buildJournal: sl(),
        summarizeJournal: sl(),
        prefs: sl(),
        notificationService: sl(),
        patternEngineService: sl(),
        gutScoreCalculatorService: sl(),
        gutScoreFirestoreService: sl(),
      ),
    );
}

/// Fire-and-forget re-check after a meal is persisted: re-evaluates the
/// "no meals logged" reminder so today's evening nudge is silenced (and
/// deferred to tomorrow) as soon as a meal exists.
void _recheckNoMealReminder() {
  unawaited(sl<NotificationService>().scheduleNoMealLoggedReminder());
}
