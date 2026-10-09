import 'package:gutgood/core/ai/protocol/ai_analysis_result.dart';
import 'package:gutgood/core/ai/protocol/ai_constants.dart';
import 'package:gutgood/core/ai/validation/ai_response_validator.dart';
import 'package:gutgood/core/models/journal/food_event_linking.dart';
import 'package:gutgood/core/models/journal/meal_log.dart';
import 'package:gutgood/core/models/journal/symptom_log.dart';
import 'package:gutgood/core/models/scans/scan_result.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/history_firestore_service.dart';

/// Why a turn's records were deliberately kept out of permanent history.
enum ChatOnlyReason {
  /// The validator blocked persistence (low confidence, non-food verdict,
  /// unsupported envelope, model declined). Details in [PersistOutcome.validationReasons].
  validationFailed,

  /// Label/menu analysis without a scan: chat display only, by product policy.
  labelMenu,
}

/// Outcome of [DomainEventPersister.persist].
class PersistOutcome {
  const PersistOutcome({required this.result, this.persistedScan = false, this.persistedMeal = false, this.persistedSymptoms = false, this.chatOnlyReason, this.validationReasons = const [], this.persistenceFailures = const []});

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

  /// Record kinds whose write did not return a stable Firestore document ID.
  /// These remain absent from [persistedTagBlocks] so a later retry can try
  /// them again without duplicating successful writes.
  final List<String> persistenceFailures;

  bool get hasPersistedAnything => persistedScan || persistedMeal || persistedSymptoms;
}

/// Single persistence router for AI turns (P1-4 fix).
///
/// `PersistAiResponseUseCase` (chat path) and `ScannerRepositoryImpl`
/// (scanner path) used to re-implement label/menu gating, stable IDs, and
/// meal/symptom writes independently — and had already diverged (chat gated
/// on confidence and consumption intent; scanner on neither). Both paths use
/// the same record-write policy. Every scan gets a scan-history record, but a
/// scan becomes a meal only after explicit consumption confirmation.
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
  /// menu analysis (by capture source, AI category, or intent). It applies only
  /// when no scan exists; actual scans are retained as analysis records.
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

  /// Consumption policy for an explicit meal block. Questions *about* food
  /// ("is this healthy?", comparisons, swaps) do not manufacture an explicit
  /// meal; a scan needs a separate consumption confirmation.
  /// Empty intent (legacy blocks without one) still logs, as before.
  static bool isConsumptionIntent(String? intent, String resolvedSourceUpper) {
    final i = (intent ?? '').toUpperCase();
    return i.isEmpty || i == UserIntent.mealRating || i == UserIntent.mealRecognition || i == UserIntent.completeAnalysis || (resolvedSourceUpper.contains('FOOD') && i.contains('ANALYSIS'));
  }

  String? _scanSource(ScanResult scan, String? source) {
    String? canonicalLabelOrMenu(String value) {
      final normalized = value.toLowerCase();
      if (normalized.contains('label')) return 'label';
      if (normalized.contains('menu')) return 'menu';
      return null;
    }

    final category = scan.category?.toLowerCase();
    final sourceKind = source == null || source.isEmpty ? null : canonicalLabelOrMenu(source);
    if (sourceKind != null) return sourceKind;
    final scanSourceKind = scan.source == null || scan.source!.isEmpty ? null : canonicalLabelOrMenu(scan.source!);
    if (scanSourceKind != null) return scanSourceKind;
    if (category == 'label' || category == 'menu') return category;
    final fallback = source ?? scan.source;
    return fallback != null && fallback.isNotEmpty ? fallback : null;
  }

  String? _scanCategory(ScanResult scan, String? source) {
    final category = scan.category?.trim();
    if (category != null && category.isNotEmpty) return category;
    final scanSource = _scanSource(scan, source);
    return scanSource == 'label' || scanSource == 'menu' ? scanSource : null;
  }

  double? _validScanConfidence(double? confidence) {
    if (confidence == null || confidence.isNaN || confidence < 0 || confidence > 1) return null;
    return confidence;
  }

  /// Builds the meal projection after the user confirms a scan was eaten.
  MealLog mealFromScan(
    ScanResult scan, {
    required String? chatMessageId,
    required String? source,
    required String? scanId,
    String? photoUrl,
    double? scanConfidence,
    String? scanVerdict,
  }) {
    final items = <String>[];
    if (scan.productName.trim().isNotEmpty) items.add(scan.productName.trim());
    for (final ingredient in scan.ingredients) {
      final name = ingredient.name.trim();
      if (name.isNotEmpty && !items.contains(name)) items.add(name);
    }
    if (items.isEmpty) items.add('Scanned food');

    return MealLog(
      items: items,
      notes: scan.impact,
      mealType: 'scan',
      photoUrl: photoUrl ?? scan.imageUrl ?? scan.userImageUrl,
      source: _scanSource(scan, source) ?? 'scan',
      scanId: scanId ?? scan.scanId,
      scanCategory: _scanCategory(scan, source),
      scanConfidence: _validScanConfidence(scanConfidence ?? scan.scanConfidence),
      scanVerdict: scanVerdict ?? scan.scanVerdict,
      consumptionConfirmed: scan.consumed == true,
      foodTags: scan.foodTags,
      chatMessageId: chatMessageId,
      createdAt: scan.createdAt,
    );
  }

  Future<MealLog?> persistConfirmedScanMeal(ScanResult scan, {required String chatMessageId, DateTime? occurredAt}) async {
    if (scan.consumed != true || occurredAt?.isAfter(DateTime.now()) == true) return null;
    final mealId = '${chatMessageId}_meal';
    final meal = mealFromScan(
      scan,
      chatMessageId: chatMessageId,
      source: scan.source,
      scanId: scan.scanId,
      photoUrl: scan.userImageUrl,
      scanConfidence: scan.scanConfidence,
      scanVerdict: scan.scanVerdict,
    ).copyWith(journalEntryId: mealId, createdAt: DateTime.now(), occurredAt: occurredAt, occurredAtProvenance: occurredAt == null ? null : OccurrenceProvenance.user);
    final id = await _history.logMeal(meal, docId: mealId);
    if (id == null) return null;
    onMealPersisted?.call();
    return meal.copyWith(firestoreId: id, journalEntryId: id);
  }

  /// Resolves the stable journal group before writing a symptom. Same-turn meal
  /// records and explicit links are authoritative. Clock-based linking requires
  /// user-confirmed times on both records; estimates must not invent relations.
  Future<String?> _resolveJournalEntryId(SymptomLog symptom, {MealLog? currentMeal}) async {
    final explicitId = symptom.journalEntryId ?? symptom.lastMealFirestoreId;
    if (explicitId != null && explicitId.trim().isNotEmpty) return explicitId;

    if (currentMeal != null) {
      // Same-turn records are an explicit relation even if the model's
      // per-record timestamps are slightly out of order.
      final currentId = currentMeal.journalEntryId?.trim();
      if (currentId != null && currentId.isNotEmpty) return currentId;
      final currentFirestoreId = currentMeal.firestoreId?.trim();
      if (currentFirestoreId != null && currentFirestoreId.isNotEmpty) return currentFirestoreId;
    }

    if (symptom.occurredAt == null || symptom.occurredAtProvenance != OccurrenceProvenance.user) return null;

    try {
      final meals = await _history.getRecentMealLogs(
        limit: 50,
        since: symptom.eventTime.subtract(journalSymptomMealLinkWindow),
        before: symptom.eventTime.add(const Duration(seconds: 1)),
      );
      final userTimedMeals = meals.where((meal) => meal.occurredAt != null && meal.occurredAtProvenance == OccurrenceProvenance.user);
      return nearestMealJournalEntryId(symptomTime: symptom.eventTime, meals: userTimedMeals);
    } catch (e) {
      // Linking is additive. A transient history read failure must not prevent
      // the user's symptom from being recorded.
      AppLogger.warning('DomainEventPersister: nearest meal lookup failed; saving standalone symptom', error: e);
      return null;
    }
  }

  Future<PersistOutcome> persist(AiAnalysisResult result, {String? chatMessageId, String? imageUrl, String? source, Set<String>? persistedTagBlocks}) async {
    final tags = persistedTagBlocks ?? <String>{};
    final persistenceFailures = <String>[];

    // 1. A label/menu response with no scan remains chat-only. Scan records
    // are retained for their analysis, independent of whether they were eaten.
    final hasScan = result.scan != null;
    if (!hasScan && isLabelOrMenuTurn(result, source: source)) {
      final diagnostic = AiResponseValidator.validate(result);
      AppLogger.ai('DomainEventPersister: label/menu turn — chat_history only');
      return PersistOutcome(
        result: result.copyWith(clearMeal: true, symptoms: const []),
        chatOnlyReason: ChatOnlyReason.labelMenu,
        validationReasons: diagnostic.reasons,
      );
    }

    // 2. Validate malformed fields, but keep every scan record even when the
    // AI marks the scan low-confidence, non-food, uncertain, or chat-only.
    final validated = AiResponseValidator.validate(result, preserveScanRecords: hasScan);
    if (!validated.persistRecords) {
      AppLogger.ai('DomainEventPersister: chat-only (${validated.reasons.join('; ')})');
      return PersistOutcome(result: validated.result, chatOnlyReason: ChatOnlyReason.validationFailed, validationReasons: validated.reasons);
    }
    var updated = validated.result;
    final scan = updated.scan;
    final stableScanId = scan == null
        ? null
        : (chatMessageId != null ? '${chatMessageId}_scan' : (scan.scanId ?? 'scan_${scan.createdAt.millisecondsSinceEpoch}_${scan.score}'));

    // Scan analysis alone does not establish that the food was eaten. Ignore
    // model-supplied meal blocks until the user confirms consumption.
    if (scan != null && scan.consumed != true) {
      final candidateTags = updated.meal?.foodTags ?? const <String>[];
      if (candidateTags.isNotEmpty) {
        updated = updated.copyWith(scan: scan.copyWith(foodTags: candidateTags));
      }
      updated = updated.copyWith(clearMeal: true);
    } else if (scan != null && updated.meal == null) {
      updated = updated.copyWith(
        meal: mealFromScan(
          scan,
          chatMessageId: chatMessageId,
          source: source,
          scanId: stableScanId,
          photoUrl: imageUrl,
          scanConfidence: updated.confidence,
          scanVerdict: updated.verdict,
        ),
      );
    }

    var persistedScan = false;
    var persistedMeal = false;
    var persistedSymptoms = false;

    // 3. Scan record.
    if (scan != null) {
      final key = 'SCAN_${stableScanId ?? '${scan.productName}_${scan.score}'}';
      final resolvedImage = scan.userImageUrl ?? imageUrl;
      final persistedScanData = scan.copyWith(
        scanId: stableScanId,
        chatMessageId: chatMessageId,
        userImageUrl: resolvedImage,
        source: _scanSource(scan, source),
        scanConfidence: _validScanConfidence(updated.confidence) ?? scan.scanConfidence,
        scanVerdict: updated.verdict ?? scan.scanVerdict,
        foodTags: updated.scan?.foodTags ?? scan.foodTags,
      );
      if (!tags.contains(key)) {
        AppLogger.ai('DomainEventPersister: saving scan to scan_history — ${scan.productName}');
        final didPersist = await _history.trySaveToScanHistory(persistedScanData, userImageUrl: resolvedImage, scanId: stableScanId);
        if (didPersist) {
          persistedScan = true;
          tags.add(key);
        } else {
          persistenceFailures.add('scan');
          AppLogger.warning('DomainEventPersister: scan write failed; leaving it retryable');
        }
      }
      // Keep the returned result hydrated even when this turn was already
      // persisted during an earlier streaming parse.
      updated = updated.copyWith(scan: persistedScanData);
    }

    // 4. Only confirmed scans become meals. Explicit meal blocks without a
    // scan retain the original intent gate.
    final resolvedSource = (source ?? updated.scan?.source ?? '').toUpperCase();
    final scanIsConsumedFood = updated.scan?.consumed == true;
    if (updated.meal != null && (scanIsConsumedFood || isConsumptionIntent(updated.intent, resolvedSource))) {
      var meal = updated.meal!;
      final key = scanIsConsumedFood && stableScanId != null && stableScanId.isNotEmpty
          ? 'MEAL_SCAN_$stableScanId'
          : (meal.scanId != null && meal.scanId!.isNotEmpty ? 'MEAL_SCAN_${meal.scanId}' : 'MEAL_${meal.items.join('_')}_${meal.createdAt.millisecondsSinceEpoch}');
      final stableMealId = chatMessageId != null
          ? '${chatMessageId}_meal'
          : (meal.journalEntryId ?? (stableScanId != null ? '${stableScanId}_meal' : null));
      meal = meal.copyWith(
        chatMessageId: chatMessageId ?? meal.chatMessageId,
        source: (updated.scan != null ? (_scanSource(updated.scan!, source) ?? 'scan') : source) ?? meal.source,
        // A scan owns the stable relation, even when the model supplied
        // stale/advisory identifiers on its meal block. This keeps scan,
        // meal, and same-turn symptoms on one idempotent journal event.
        journalEntryId: scanIsConsumedFood ? stableMealId : (meal.journalEntryId ?? stableMealId),
        scanId: scanIsConsumedFood ? stableScanId : (meal.scanId ?? stableScanId),
        scanCategory: meal.scanCategory ?? (updated.scan == null ? null : _scanCategory(updated.scan!, source)),
        scanConfidence: meal.scanConfidence ?? _validScanConfidence(updated.confidence),
        scanVerdict: meal.scanVerdict ?? updated.verdict,
      );
      if (!tags.contains(key)) {
        AppLogger.ai('DomainEventPersister: saving meal to journal_logs');
        final id = await _history.logMeal(meal, docId: stableMealId);
        if (id != null) {
          meal = meal.copyWith(firestoreId: id, journalEntryId: id);
          tags.add(key);
          persistedMeal = true;
          // A meal now exists today — re-evaluate so the evening "no meals
          // logged" reminder is silenced (deferred to tomorrow, not killed).
          onMealPersisted?.call();
        } else {
          persistenceFailures.add('meal');
          AppLogger.warning('DomainEventPersister: meal write returned no document ID; leaving it retryable');
        }
      } else if (meal.firestoreId == null && meal.journalEntryId != null) {
        // Keep same-turn symptoms linked on later streaming parses without
        // issuing a second Firestore write.
        meal = meal.copyWith(firestoreId: meal.journalEntryId);
      }
      updated = updated.copyWith(meal: meal);
    }

    // 5. Symptom records. Each symptom receives the same journalEntryId as
    // the current persisted meal, or an earlier meal matched from user-confirmed
    // times. A non-consumption meal block is not a journal relation.
    final mealForSymptomLink = updated.meal != null && (scanIsConsumedFood || isConsumptionIntent(updated.intent, resolvedSource)) ? updated.meal : null;
    if (updated.symptoms.isNotEmpty) {
      final updatedSymptoms = <SymptomLog>[];
      for (var i = 0; i < updated.symptoms.length; i++) {
        var symptom = updated.symptoms[i];
        final key = 'SYMPTOM_${i}_${symptom.symptom}_${symptom.createdAt.millisecondsSinceEpoch}';
        if (!tags.contains(key)) {
          AppLogger.ai('DomainEventPersister: saving symptom — ${symptom.symptom}');
          final stableSymptomId = chatMessageId != null ? '${chatMessageId}_symptom_$i' : null;
          final resolvedFood = symptom.foodName ?? updated.scan?.productName ?? (updated.meal != null && updated.meal!.items.isNotEmpty ? updated.meal!.items.join(', ') : null);
          final resolvedImage = symptom.imageUrl ?? imageUrl ?? updated.scan?.userImageUrl ?? updated.scan?.imageUrl;
          final journalEntryId = await _resolveJournalEntryId(symptom, currentMeal: mealForSymptomLink);
          symptom = symptom.copyWith(
            chatMessageId: chatMessageId,
            journalEntryId: journalEntryId,
            lastMealFirestoreId: journalEntryId,
            foodName: resolvedFood,
            imageUrl: resolvedImage,
          );
          final id = await _history.logSymptom(symptom, docId: stableSymptomId);
          if (id != null) {
            symptom = symptom.copyWith(firestoreId: id);
            tags.add(key);
            persistedSymptoms = true;
          } else {
            persistenceFailures.add('symptom:${symptom.symptom}');
            AppLogger.warning('DomainEventPersister: symptom write returned no document ID; leaving it retryable');
          }
        }
        updatedSymptoms.add(symptom);
      }
      updated = updated.copyWith(symptoms: updatedSymptoms);
    }

    return PersistOutcome(result: updated, persistedScan: persistedScan, persistedMeal: persistedMeal, persistedSymptoms: persistedSymptoms, validationReasons: validated.reasons, persistenceFailures: persistenceFailures);
  }
}
