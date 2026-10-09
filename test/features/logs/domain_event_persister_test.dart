import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/ai/protocol/ai_constants.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/features/logs/data/services/domain_event_persister.dart';
import 'package:gutgood/infrastructure/firebase/firestore/history_firestore_service.dart';
import 'package:mocktail/mocktail.dart';

class MockHistoryFirestoreService extends Mock implements HistoryFirestoreService {}

ScanResult _scan() =>
    ScanResult(productName: 'Persist Yogurt', brand: 'Persist Brand', category: 'food', barcode: '999000111', score: 70, impactType: ImpactType.positive, impact: 'Good', createdAt: DateTime.now());

ScanResult _menuScan() =>
    ScanResult(productName: 'Restaurant Menu', brand: 'Persist Brand', category: 'menu', source: 'menu', score: 70, impactType: ImpactType.neutral, impact: 'Menu analysis', createdAt: DateTime.now());

MealLog _meal() => MealLog(items: const ['Dal', 'Rice'], mealType: 'dinner', createdAt: DateTime.now());

SymptomLog _symptom() => SymptomLog(symptom: 'Bloating', severity: 6, createdAt: DateTime.now());

void main() {
  late MockHistoryFirestoreService history;
  late DomainEventPersister persister;

  setUpAll(() {
    registerFallbackValue(ScanResult(productName: '', brand: '', score: 0, impactType: ImpactType.neutral, impact: '', createdAt: DateTime.now()));
    registerFallbackValue(MealLog(items: const [], createdAt: DateTime.now()));
    registerFallbackValue(SymptomLog(symptom: '', createdAt: DateTime.now()));
  });

  setUp(() {
    history = MockHistoryFirestoreService();
    persister = DomainEventPersister(historyFirestoreService: history);

    when(
      () => history.trySaveToScanHistory(
        any(),
        userImageUrl: any(named: 'userImageUrl'),
        scanId: any(named: 'scanId'),
      ),
    ).thenAnswer((_) async => true);
    when(() => history.logMeal(any(), docId: any(named: 'docId'))).thenAnswer((_) async => 'meal-id');
    when(() => history.logSymptom(any(), docId: any(named: 'docId'))).thenAnswer((_) async => 'sym-id');
  });

  group('DomainEventPersister', () {
    test('confirmed scan timing is user-provided and future times are rejected', () async {
      final occurredAt = DateTime.now().subtract(const Duration(hours: 2));
      final meal = await persister.persistConfirmedScanMeal(_scan().copyWith(consumed: true), chatMessageId: 'confirmed', occurredAt: occurredAt);
      expect(meal?.occurredAt, occurredAt);
      expect(meal?.occurredAtProvenance, OccurrenceProvenance.user);
      expect(meal?.consumptionConfirmed, isTrue);
      expect(await persister.persistConfirmedScanMeal(_scan().copyWith(consumed: true), chatMessageId: 'future', occurredAt: DateTime.now().add(const Duration(hours: 1))), isNull);
      verifyNever(() => history.logMeal(any(), docId: 'future_meal'));
    });

    test('label/menu scan is retained without becoming a consumed meal', () async {
      final result = AiAnalysisResult(text: 'label', intent: UserIntent.ingredientAnalysis, scan: _menuScan(), symptoms: [_symptom()]);

      final outcome = await persister.persist(result, chatMessageId: 'msg1', persistedTagBlocks: <String>{});

      expect(outcome.chatOnlyReason, isNull);
      expect(outcome.persistedScan, isTrue);
      expect(outcome.persistedMeal, isFalse);
      expect(outcome.persistedSymptoms, isTrue);
      expect(outcome.result.meal, isNull);
      expect(outcome.result.symptoms.single.journalEntryId, isNull);
      verify(
        () => history.trySaveToScanHistory(
          any(),
          userImageUrl: any(named: 'userImageUrl'),
          scanId: 'msg1_scan',
        ),
      ).called(1);
      verifyNever(() => history.logMeal(any(), docId: any(named: 'docId')));
      verify(() => history.logSymptom(any(), docId: 'msg1_symptom_0')).called(1);
    });

    test('label/menu response without a scan remains chat-only', () async {
      final outcome = await persister.persist(
        AiAnalysisResult(text: 'label', intent: UserIntent.ingredientAnalysis, meal: _meal(), symptoms: [_symptom()]),
        chatMessageId: 'msg1',
        persistedTagBlocks: <String>{},
      );

      expect(outcome.chatOnlyReason, ChatOnlyReason.labelMenu);
      expect(outcome.hasPersistedAnything, isFalse);
      expect(outcome.result.meal, isNull);
      expect(outcome.result.symptoms, isEmpty);
      verifyNever(() => history.logMeal(any(), docId: any(named: 'docId')));
      verifyNever(() => history.logSymptom(any(), docId: any(named: 'docId')));
    });

    test('low-confidence scan still creates a scan-history record only', () async {
      final result = AiAnalysisResult(text: 'x', scan: _scan(), confidence: 0.2);

      final outcome = await persister.persist(result, chatMessageId: 'msg1', persistedTagBlocks: <String>{});

      expect(outcome.chatOnlyReason, isNull);
      expect(outcome.persistedScan, isTrue);
      expect(outcome.persistedMeal, isFalse);
      expect(outcome.validationReasons.join(' '), contains('confidence'));
      final persistedScan = verify(
        () => history.trySaveToScanHistory(
          captureAny(),
          userImageUrl: any(named: 'userImageUrl'),
          scanId: 'msg1_scan',
        ),
      ).captured.single as ScanResult;
      expect(persistedScan.scanConfidence, 0.2);
      verifyNever(() => history.logMeal(any(), docId: any(named: 'docId')));
    });

    test('non-food verdict scan remains in scan history without a meal', () async {
      final result = AiAnalysisResult(text: 'x', scan: _scan(), verdict: Verdict.nonFood);

      final outcome = await persister.persist(result, chatMessageId: 'msg1', persistedTagBlocks: <String>{});

      expect(outcome.chatOnlyReason, isNull);
      expect(outcome.persistedScan, isTrue);
      expect(outcome.persistedMeal, isFalse);
      expect(outcome.validationReasons.join(' '), contains('non_food'));
      final persistedScan = verify(
        () => history.trySaveToScanHistory(
          captureAny(),
          userImageUrl: any(named: 'userImageUrl'),
          scanId: 'msg1_scan',
        ),
      ).captured.single as ScanResult;
      expect(persistedScan.scanVerdict, Verdict.nonFood);
      verifyNever(() => history.logMeal(any(), docId: any(named: 'docId')));
    });

    test('uncertain scans remain scan history until the user confirms them', () async {
      final outcome = await persister.persist(
        AiAnalysisResult(text: 'x', scan: _scan(), verdict: Verdict.uncertain),
        chatMessageId: 'uncertain-msg',
        persistedTagBlocks: <String>{},
      );

      expect(outcome.persistedScan, isTrue);
      expect(outcome.persistedMeal, isFalse);
      verifyNever(() => history.logMeal(any(), docId: any(named: 'docId')));
    });

    test('model-supplied meal blocks do not count before scan confirmation', () async {
      final result = AiAnalysisResult(text: 'x', intent: UserIntent.healthAssessment, scan: _scan(), meal: _meal(), confidence: 0.88, verdict: Verdict.food);

      final outcome = await persister.persist(result, chatMessageId: 'msg1', persistedTagBlocks: <String>{});

      expect(outcome.persistedScan, isTrue);
      expect(outcome.persistedMeal, isFalse);
      expect(outcome.result.meal, isNull);
      final persistedScan = verify(
        () => history.trySaveToScanHistory(
          captureAny(),
          userImageUrl: any(named: 'userImageUrl'),
          scanId: 'msg1_scan',
        ),
      ).captured.single as ScanResult;
      expect(persistedScan.scanConfidence, 0.88);
      expect(persistedScan.scanVerdict, Verdict.food);
      verifyNever(() => history.logMeal(any(), docId: any(named: 'docId')));
    });

    test('confirmed scan creates one meal projection', () async {
      final outcome = await persister.persist(
        AiAnalysisResult(text: 'x', scan: _scan().copyWith(consumed: true, foodTags: const ['dairy']), confidence: 0.88, verdict: Verdict.food),
        chatMessageId: 'confirmed-msg',
        persistedTagBlocks: <String>{},
      );

      expect(outcome.persistedScan, isTrue);
      expect(outcome.persistedMeal, isTrue);
      final meal = verify(() => history.logMeal(captureAny(), docId: 'confirmed-msg_meal')).captured.single as MealLog;
      expect(meal.scanId, 'confirmed-msg_scan');
      expect(meal.scanCategory, 'food');
      expect(meal.consumptionConfirmed, isTrue);
      expect(meal.foodTags, ['dairy']);
    });

    test('failed scan writes are reported without creating a meal', () async {
      when(
        () => history.trySaveToScanHistory(
          any(),
          userImageUrl: any(named: 'userImageUrl'),
          scanId: any(named: 'scanId'),
        ),
      ).thenAnswer((_) async => false);

      final outcome = await persister.persist(
        AiAnalysisResult(text: 'x', scan: _scan()),
        chatMessageId: 'failed-scan',
        persistedTagBlocks: <String>{},
      );

      expect(outcome.persistedScan, isFalse);
      expect(outcome.persistedMeal, isFalse);
      expect(outcome.persistenceFailures, ['scan']);
      verify(() => history.trySaveToScanHistory(any(), userImageUrl: any(named: 'userImageUrl'), scanId: 'failed-scan_scan')).called(1);
    });

    test('failed meal writes are not reported as persisted and remain retryable', () async {
      when(() => history.logMeal(any(), docId: any(named: 'docId'))).thenAnswer((_) async => null);

      final outcome = await persister.persist(
        AiAnalysisResult(text: 'x', meal: _meal()),
        chatMessageId: 'failed-meal',
        persistedTagBlocks: <String>{},
      );

      expect(outcome.persistedMeal, isFalse);
      expect(outcome.hasPersistedAnything, isFalse);
      expect(outcome.persistenceFailures, ['meal']);
      verify(() => history.logMeal(any(), docId: 'failed-meal_meal')).called(1);
    });

    test('failed symptom writes are not reported as persisted and remain retryable', () async {
      when(
        () => history.getRecentMealLogs(
          limit: any(named: 'limit'),
          since: any(named: 'since'),
          before: any(named: 'before'),
        ),
      ).thenAnswer((_) async => const []);
      when(() => history.logSymptom(any(), docId: any(named: 'docId'))).thenAnswer((_) async => null);

      final outcome = await persister.persist(
        AiAnalysisResult(text: 'x', symptoms: [_symptom()]),
        chatMessageId: 'failed-symptom',
        persistedTagBlocks: <String>{},
      );

      expect(outcome.persistedSymptoms, isFalse);
      expect(outcome.hasPersistedAnything, isFalse);
      expect(outcome.persistenceFailures, ['symptom:Bloating']);
      verify(() => history.logSymptom(any(), docId: 'failed-symptom_symptom_0')).called(1);
    });

    test('consumption intent persists meal + symptoms with stable IDs and hydration', () async {
      final result = AiAnalysisResult(text: 'x', intent: UserIntent.completeAnalysis, meal: _meal(), symptoms: [_symptom(), _symptom().copyWith(symptom: 'Gas')]);

      final outcome = await persister.persist(result, chatMessageId: 'msg1', persistedTagBlocks: <String>{});

      expect(outcome.persistedMeal, isTrue);
      expect(outcome.persistedSymptoms, isTrue);
      verify(() => history.logMeal(any(), docId: 'msg1_meal')).called(1);
      final symptom = verify(() => history.logSymptom(captureAny(), docId: 'msg1_symptom_0')).captured.single as SymptomLog;
      expect(symptom.journalEntryId, 'meal-id');
      expect(symptom.lastMealFirestoreId, 'meal-id');
      final secondSymptom = verify(() => history.logSymptom(captureAny(), docId: 'msg1_symptom_1')).captured.single as SymptomLog;
      expect(secondSymptom.journalEntryId, 'meal-id');
      expect(outcome.result.symptoms.every((s) => s.journalEntryId == 'meal-id'), isTrue);
      expect(outcome.result.meal!.firestoreId, 'meal-id');
      expect(outcome.result.meal!.journalEntryId, 'meal-id');
      expect(outcome.result.symptoms.first.firestoreId, 'sym-id');
    });

    test('unconfirmed timestamps do not auto-link a symptom to a nearby meal', () async {
      final mealTime = DateTime.now().subtract(const Duration(hours: 1));
      when(
        () => history.getRecentMealLogs(
          limit: any(named: 'limit'),
          since: any(named: 'since'),
          before: any(named: 'before'),
        ),
      ).thenAnswer((_) async => [MealLog(firestoreId: 'nearest-meal', items: const ['Oats'], createdAt: mealTime)]);

      final outcome = await persister.persist(
        AiAnalysisResult(text: 'x', symptoms: [SymptomLog(symptom: 'Bloating', createdAt: DateTime.now())]),
        chatMessageId: 'msg1',
        persistedTagBlocks: <String>{},
      );

      expect(outcome.result.symptoms.single.journalEntryId, isNull);
      final symptom = verify(() => history.logSymptom(captureAny(), docId: 'msg1_symptom_0')).captured.single as SymptomLog;
      expect(symptom.journalEntryId, isNull);
      expect(symptom.lastMealFirestoreId, isNull);
      verifyNever(() => history.getRecentMealLogs(limit: any(named: 'limit'), since: any(named: 'since'), before: any(named: 'before')));
    });

    test('user-confirmed timestamps can link to the nearest earlier meal', () async {
      final symptomTime = DateTime.now();
      final mealTime = symptomTime.subtract(const Duration(hours: 1));
      when(
        () => history.getRecentMealLogs(
          limit: any(named: 'limit'),
          since: any(named: 'since'),
          before: any(named: 'before'),
        ),
      ).thenAnswer((_) async => [MealLog(firestoreId: 'nearest-meal', items: const ['Oats'], createdAt: mealTime, occurredAt: mealTime, occurredAtProvenance: OccurrenceProvenance.user)]);

      final outcome = await persister.persist(
        AiAnalysisResult(
          text: 'x',
          symptoms: [SymptomLog(symptom: 'Bloating', createdAt: symptomTime, occurredAt: symptomTime, occurredAtProvenance: OccurrenceProvenance.user)],
        ),
        chatMessageId: 'msg1',
        persistedTagBlocks: <String>{},
      );

      expect(outcome.result.symptoms.single.journalEntryId, 'nearest-meal');
    });

    test('symptom remains standalone when no earlier meal is within four hours', () async {
      when(
        () => history.getRecentMealLogs(
          limit: any(named: 'limit'),
          since: any(named: 'since'),
          before: any(named: 'before'),
        ),
      ).thenAnswer((_) async => const []);

      final outcome = await persister.persist(
        AiAnalysisResult(text: 'x', symptoms: [SymptomLog(symptom: 'Bloating', createdAt: DateTime.now())]),
        chatMessageId: 'msg1',
        persistedTagBlocks: <String>{},
      );

      expect(outcome.result.symptoms.single.journalEntryId, isNull);
      expect(outcome.result.symptoms.single.lastMealFirestoreId, isNull);
      verify(() => history.logSymptom(any(), docId: 'msg1_symptom_0')).called(1);
    });

    test('dedup set prevents double writes for the same turn', () async {
      final tags = <String>{};
      final first = AiAnalysisResult(text: 'x', scan: _scan());

      await persister.persist(first, chatMessageId: 'msg1', persistedTagBlocks: tags);
      // Same product+score rebuilt (e.g. streaming re-parse) hits the same key.
      await persister.persist(
        AiAnalysisResult(text: 'x', scan: _scan()),
        chatMessageId: 'msg1',
        persistedTagBlocks: tags,
      );

      verify(
        () => history.trySaveToScanHistory(
          any(),
          userImageUrl: any(named: 'userImageUrl'),
          scanId: any(named: 'scanId'),
        ),
      ).called(1);
      verifyNever(() => history.logMeal(any(), docId: any(named: 'docId')));
    });

    test('isLabelOrMenuTurn unifies source, category, and intent signals', () {
      final bySource = AiAnalysisResult(
        text: 'x',
        scan: _scan().copyWith(source: 'menu'),
      );
      final byCategory = AiAnalysisResult(
        text: 'x',
        scan: _scan().copyWith(category: 'label'),
      );
      const byIntent = AiAnalysisResult(text: 'x', intent: UserIntent.menuRecommendation);
      final normal = AiAnalysisResult(text: 'x', intent: UserIntent.mealRating, scan: _scan());

      expect(DomainEventPersister.isLabelOrMenuTurn(bySource), isTrue);
      expect(DomainEventPersister.isLabelOrMenuTurn(byCategory), isTrue);
      expect(DomainEventPersister.isLabelOrMenuTurn(byIntent), isTrue);
      expect(DomainEventPersister.isLabelOrMenuTurn(normal), isFalse);
    });
  });
}
