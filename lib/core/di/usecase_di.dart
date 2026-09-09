import 'package:gutgood/core/di/di_instance.dart';
import 'package:gutgood/core/services/domain_event_persister.dart';
import 'package:gutgood/features/chat/domain/usecases/persist_ai_response_usecase.dart';
import 'package:gutgood/features/chat/domain/usecases/process_chat_tag_usecase.dart';
import 'package:gutgood/features/chat/domain/usecases/send_message_stream_usecase.dart';
import 'package:gutgood/features/insights/domain/usecases/build_unified_journal_usecase.dart';
import 'package:gutgood/features/insights/domain/usecases/check_insight_threshold_usecase.dart';
import 'package:gutgood/features/insights/domain/usecases/generate_insight_usecase.dart';
import 'package:gutgood/features/insights/domain/usecases/summarize_journal_usecase.dart';

void initUseCaseDI() {
  sl
    ..registerLazySingleton(() => SendMessageStreamUseCase(sl()))
    ..registerLazySingleton(ProcessChatTagUseCase.new)
    ..registerLazySingleton(() => DomainEventPersister(historyFirestoreService: sl()))
    ..registerLazySingleton(() => PersistAiResponseUseCase(firestoreService: sl(), appStateService: sl(), streakService: sl()))
    ..registerLazySingleton(() => const CheckInsightThresholdUseCase())
    ..registerLazySingleton(() => const BuildUnifiedJournalUseCase())
    ..registerLazySingleton(() => SummarizeJournalUseCase(aiService: sl()))
    ..registerLazySingleton(
      () => GenerateInsightUseCase(
        insightRepository: sl(),
        authFirestoreService: sl(),
        historyFirestoreService: sl(),
        checkThreshold: sl(),
        buildJournal: sl(),
        summarizeJournal: sl(),
        prefs: sl(),
        notificationService: sl(),
        patternEngineService: sl(),
      ),
    );
}
