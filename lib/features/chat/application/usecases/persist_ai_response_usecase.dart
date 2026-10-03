import 'package:gutgood/core/ai/protocol/ai_analysis_result.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/streak_service.dart';
import 'package:gutgood/features/logs/data/services/domain_event_persister.dart';
import 'package:gutgood/infrastructure/firebase/firestore/history_firestore_service.dart';

/// Chat-path entry point for AI-turn persistence.
///
/// Thin wrapper since Phase 2: all record-write policy (validation, label/menu
/// gating, consumption gating, stable IDs, dedup) lives in the shared
/// [DomainEventPersister] so the chat and scanner paths can no longer diverge.
/// This wrapper preserves the chat path's exact observable behavior —
/// including its streak/UI side effects — on top of the shared outcome.
class PersistAiResponseUseCase {
  PersistAiResponseUseCase({required HistoryFirestoreService firestoreService, required AppStateService appStateService, required StreakService streakService, void Function()? onMealPersisted})
    : _appStateService = appStateService,
      _streakService = streakService,
      _persister = DomainEventPersister(historyFirestoreService: firestoreService, onMealPersisted: onMealPersisted);

  final AppStateService _appStateService;
  final StreakService _streakService;
  final DomainEventPersister _persister;

  Future<AiAnalysisResult> call(AiAnalysisResult result, {String? chatMessageId, String? imageUrl, String? source, required Set<String> persistedTagBlocks}) async {
    final outcome = await _persister.persist(result, chatMessageId: chatMessageId, imageUrl: imageUrl, source: source, persistedTagBlocks: persistedTagBlocks);

    if (outcome.hasPersistedAnything) {
      await _streakService.markActivityToday();
      _appStateService.notifyChatUpdated();
    } else if (outcome.chatOnlyReason == ChatOnlyReason.labelMenu) {
      // Label/menu turns still count as activity (chat interaction happened).
      await _streakService.markActivityToday();
    }
    return outcome.result;
  }
}
