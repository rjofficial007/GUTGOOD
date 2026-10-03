import 'package:gutgood/core/ai/protocol/ai_analysis_result.dart';
import 'package:gutgood/core/ai/protocol/ai_constants.dart';
import 'package:gutgood/core/ai/validation/ai_response_validator.dart';
import 'package:gutgood/core/models/journal/symptom_log.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/history_firestore_service.dart';

/// Why a turn's records were deliberately kept out of permanent history.
enum ChatOnlyReason {
  /// The validator blocked persistence (low confidence, non-food verdict,
  /// unsupported envelope, model declined). Details in [PersistOutcome.validationReasons].
  validationFailed,

  /// Label/menu analysis: chat display only, by product policy.
  labelMenu,
}

/// Outcome of [DomainEventPersister.persist].
class PersistOutcome {
  const PersistOutcome({required this.result, this.persistedScan = false, this.persistedMeal = false, this.persistedSymptoms = false, this.chatOnlyReason, this.validationReasons = const []});

  /// The result with Firestore IDs hydrated (scanId/chatMessageId/firestoreIds),
  /// or cleared records when the turn went chat-only.
  final AiAnalysisResult result;
  final bool persistedScan;
  final bool persistedMeal;
  final bool persistedSymptoms;

  /// Set when records were deliberately skipped (turn still renders in chat).
  final ChatOnlyReason? chatOnlyReason;

  /// Validator notes (blocks + sanitizations), empty when validation passed clean.
  final List<String> validationReasons;

  bool get hasPersistedAnything => persistedScan || persistedMeal || persistedSymptoms;
}

/// Single persistence router for AI turns (P1-4 fix).
///
/// `PersistAiResponseUseCase` (chat path) and `ScannerRepositoryImpl`
/// (scanner path) used to re-implement label/menu gating, stable IDs, and
/// meal/symptom writes independently — and had already diverged (chat gated
/// on confidence and consumption intent; scanner on neither, so "is this
/// healthy?" barcode scans logged phantom meals). All record-write policy now
/// lives here; both paths delegate.
///
/// Deliberately side-effect-free beyond Firestore record writes: streaks,
/// chat-message saves, notifications, and UI refresh stay with the callers,
/// reported via [PersistOutcome] instead.
class DomainEventPersister {
  DomainEventPersister({required HistoryFirestoreService historyFirestoreService, this.onMealPersisted}) : _history = historyFirestoreService;

  final HistoryFirestoreService _history;

  /// Fired after a meal record is persisted. DI wires this to the
  /// notification re-check ("no meals logged" reminder); a callback keeps
  /// this core service free of notification/router imports. Null in tests.
  final void Function()? onMealPersisted;

  /// Label/menu policy, single definition. True when the turn is a label or
  /// menu analysis (by capture source, AI category, or intent) — those render
  /// in chat only and must never create scan_history/journal_logs records.
  static bool isLabelOrMenuTurn(AiAnalysisResult result, {String? source}) {
    final resolvedSource = (source ?? result.scan?.source ?? '').toUpperCase();
    final resolvedCategory = (result.scan?.category ?? '').toUpperCase();
    final intent = (result.intent ?? '').toUpperCase();
    return resolvedSource.contains('LABEL') ||
        resolvedCategory.contains('LABEL') ||
        intent.contains('LABEL') ||
        intent.contains('INGREDIENT') ||
        resolvedSource.contains('MENU') ||
        resolvedCategory.contains('MENU') ||
        intent.contains('MENU');
  }

  /// Consumption policy: a meal block is only logged as EATEN when the turn
  /// actually describes consumption. Questions *about* food ("is this
  /// healthy?", comparisons, swaps) must not manufacture meal logs.
  /// Empty intent (legacy blocks without one) still logs, as before.
  static bool isConsumptionIntent(String? intent, String resolvedSourceUpper) {
    final i = (intent ?? '').toUpperCase();
    return i.isEmpty || i == UserIntent.mealRating || i == UserIntent.mealRecognition || i == UserIntent.completeAnalysis || (resolvedSourceUpper.contains('FOOD') && i.contains('ANALYSIS'));
  }

  Future<PersistOutcome> persist(AiAnalysisResult result, {String? chatMessageId, String? imageUrl, String? source, Set<String>? persistedTagBlocks}) async {
    final tags = persistedTagBlocks ?? <String>{};

    // 1. Label/menu turns render in chat only — checked before validation
    // because they are chat-only by policy, not by data-quality failure
    // (J-2 step 7 would otherwise report them as validationFailed).
    if (isLabelOrMenuTurn(result, source: source)) {
      final diagnostic = AiResponseValidator.validate(result);
      AppLogger.ai('DomainEventPersister: label/menu turn — chat_history only');
      return PersistOutcome(
        result: result.copyWith(clearMeal: true, symptoms: const []),
        chatOnlyReason: ChatOnlyReason.labelMenu,
        validationReasons: diagnostic.reasons,
      );
    }

    // 2. Validate: malformed/low-confidence/non-food/contract-violating turns
    // degrade to chat-only instead of corrupting history.
    final validated = AiResponseValidator.validate(result);
    if (!validated.persistRecords) {
      AppLogger.ai('DomainEventPersister: chat-only (${validated.reasons.join('; ')})');
      return PersistOutcome(result: validated.result, chatOnlyReason: ChatOnlyReason.validationFailed, validationReasons: validated.reasons);
    }
    var updated = validated.result;

    var persistedScan = false;
    var persistedMeal = false;
    var persistedSymptoms = false;

    // 3. Scan record.
    if (updated.scan != null) {
      final scan = updated.scan!;
      final key = 'SCAN_${scan.productName}_${scan.score}';
      if (!tags.contains(key)) {
        if (scan.isLoggableProduct) {
          AppLogger.ai('DomainEventPersister: saving scan to scan_history — ${scan.productName}');
          final stableScanId = chatMessageId != null ? '${chatMessageId}_scan' : null;
          final resolvedImage = scan.userImageUrl ?? imageUrl;
          await _history.saveToScanHistory(
            scan.copyWith(scanId: stableScanId, chatMessageId: chatMessageId, userImageUrl: resolvedImage),
            userImageUrl: resolvedImage,
            scanId: stableScanId,
          );
          updated = updated.copyWith(
            scan: scan.copyWith(scanId: stableScanId, chatMessageId: chatMessageId, userImageUrl: resolvedImage),
          );
          persistedScan = true;
        } else {
          AppLogger.ai('DomainEventPersister: non-product scan skipped for history collection');
        }
        tags.add(key);
      }
    }

    // 4. Meal record (consumption-gated).
    final resolvedSource = (source ?? updated.scan?.source ?? '').toUpperCase();
    if (updated.meal != null && isConsumptionIntent(updated.intent, resolvedSource)) {
      final meal = updated.meal!;
      final key = 'MEAL_${meal.items.join('_')}_${meal.createdAt.millisecondsSinceEpoch}';
      if (!tags.contains(key)) {
        AppLogger.ai('DomainEventPersister: saving meal to journal_logs');
        final stableMealId = chatMessageId != null ? '${chatMessageId}_meal' : null;
        final id = await _history.logMeal(
          meal.copyWith(chatMessageId: chatMessageId, source: source),
          docId: stableMealId,
        );
        if (id != null) updated = updated.copyWith(meal: updated.meal!.copyWith(firestoreId: id));
        tags.add(key);
        persistedMeal = true;
        // A meal now exists today — re-evaluate so the evening "no meals
        // logged" reminder is silenced (deferred to tomorrow, not killed).
        onMealPersisted?.call();
      }
    }

    // 5. Symptom records.
    if (updated.symptoms.isNotEmpty) {
      final updatedSymptoms = <SymptomLog>[];
      for (var i = 0; i < updated.symptoms.length; i++) {
        var symptom = updated.symptoms[i];
        final key = 'SYMPTOM_${symptom.symptom}_${symptom.createdAt.millisecondsSinceEpoch}';
        if (!tags.contains(key)) {
          AppLogger.ai('DomainEventPersister: saving symptom — ${symptom.symptom}');
          final stableSymptomId = chatMessageId != null ? '${chatMessageId}_symptom_$i' : null;
          final resolvedFood = symptom.foodName ?? updated.scan?.productName ?? (updated.meal != null && updated.meal!.items.isNotEmpty ? updated.meal!.items.join(', ') : null);
          final resolvedImage = symptom.imageUrl ?? imageUrl ?? updated.scan?.userImageUrl ?? updated.scan?.imageUrl;
          symptom = symptom.copyWith(chatMessageId: chatMessageId, foodName: resolvedFood, imageUrl: resolvedImage);
          final id = await _history.logSymptom(symptom, docId: stableSymptomId);
          if (id != null) symptom = symptom.copyWith(firestoreId: id);
          tags.add(key);
          persistedSymptoms = true;
        }
        updatedSymptoms.add(symptom);
      }
      updated = updated.copyWith(symptoms: updatedSymptoms);
    }

    return PersistOutcome(result: updated, persistedScan: persistedScan, persistedMeal: persistedMeal, persistedSymptoms: persistedSymptoms, validationReasons: validated.reasons);
  }
}
