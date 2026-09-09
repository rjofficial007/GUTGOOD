import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/constants/ai_constants.dart';
import 'package:gutgood/core/models/ai_analysis_result.dart';
import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/symptom_log.dart';
import 'package:gutgood/core/services/domain_event_persister.dart';
import 'package:gutgood/core/services/firestore/history_firestore_service.dart';
import 'package:mocktail/mocktail.dart';

class MockHistoryFirestoreService extends Mock implements HistoryFirestoreService {}

ScanResult _scan() => ScanResult(
  productName: 'Persist Yogurt',
  brand: 'Persist Brand',
  category: 'food',
  barcode: '999000111',
  score: 70,
  impactType: ImpactType.positive,
  impact: 'Good',
  createdAt: DateTime.now(),
);

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

    when(() => history.saveToScanHistory(any(), userImageUrl: any(named: 'userImageUrl'), scanId: any(named: 'scanId'))).thenAnswer((_) async {});
    when(() => history.logMeal(any(), docId: any(named: 'docId'))).thenAnswer((_) async => 'meal-id');
    when(() => history.logSymptom(any(), docId: any(named: 'docId'))).thenAnswer((_) async => 'sym-id');
  });

  group('DomainEventPersister', () {
    test('label intent goes chat-only: no writes, records cleared', () async {
      final result = AiAnalysisResult(text: 'label', intent: UserIntent.ingredientAnalysis, scan: _scan(), meal: _meal(), symptoms: [_symptom()]);

      final outcome = await persister.persist(result, chatMessageId: 'msg1', persistedTagBlocks: <String>{});

      expect(outcome.chatOnlyReason, ChatOnlyReason.labelMenu);
      expect(outcome.hasPersistedAnything, isFalse);
      expect(outcome.result.meal, isNull);
      expect(outcome.result.symptoms, isEmpty);
      verifyNever(() => history.saveToScanHistory(any(), userImageUrl: any(named: 'userImageUrl'), scanId: any(named: 'scanId')));
      verifyNever(() => history.logMeal(any(), docId: any(named: 'docId')));
      verifyNever(() => history.logSymptom(any(), docId: any(named: 'docId')));
    });

    test('low confidence goes chat-only without writes', () async {
      final result = AiAnalysisResult(text: 'x', scan: _scan(), confidence: 0.2);

      final outcome = await persister.persist(result, chatMessageId: 'msg1', persistedTagBlocks: <String>{});

      expect(outcome.chatOnlyReason, ChatOnlyReason.validationFailed);
      expect(outcome.validationReasons.join(' '), contains('confidence'));
      verifyNever(() => history.saveToScanHistory(any(), userImageUrl: any(named: 'userImageUrl'), scanId: any(named: 'scanId')));
    });

    test('non_food verdict goes chat-only without writes', () async {
      final result = AiAnalysisResult(text: 'x', scan: _scan(), verdict: Verdict.nonFood);

      final outcome = await persister.persist(result, chatMessageId: 'msg1', persistedTagBlocks: <String>{});

      expect(outcome.chatOnlyReason, ChatOnlyReason.validationFailed);
      verifyNever(() => history.saveToScanHistory(any(), userImageUrl: any(named: 'userImageUrl'), scanId: any(named: 'scanId')));
    });

    test('consumption gate: question-about-food persists scan but NOT a phantom meal', () async {
      final result = AiAnalysisResult(text: 'x', intent: UserIntent.healthAssessment, scan: _scan(), meal: _meal());

      final outcome = await persister.persist(result, chatMessageId: 'msg1', persistedTagBlocks: <String>{});

      expect(outcome.persistedScan, isTrue);
      expect(outcome.persistedMeal, isFalse);
      verify(() => history.saveToScanHistory(any(), userImageUrl: any(named: 'userImageUrl'), scanId: 'msg1_scan')).called(1);
      verifyNever(() => history.logMeal(any(), docId: any(named: 'docId')));
    });

    test('consumption intent persists meal + symptoms with stable IDs and hydration', () async {
      final result = AiAnalysisResult(text: 'x', intent: UserIntent.completeAnalysis, meal: _meal(), symptoms: [_symptom()]);

      final outcome = await persister.persist(result, chatMessageId: 'msg1', persistedTagBlocks: <String>{});

      expect(outcome.persistedMeal, isTrue);
      expect(outcome.persistedSymptoms, isTrue);
      verify(() => history.logMeal(any(), docId: 'msg1_meal')).called(1);
      verify(() => history.logSymptom(any(), docId: 'msg1_symptom_0')).called(1);
      expect(outcome.result.meal!.firestoreId, 'meal-id');
      expect(outcome.result.symptoms.first.firestoreId, 'sym-id');
    });

    test('dedup set prevents double writes for the same turn', () async {
      final tags = <String>{};
      final first = AiAnalysisResult(text: 'x', scan: _scan());

      await persister.persist(first, chatMessageId: 'msg1', persistedTagBlocks: tags);
      // Same product+score rebuilt (e.g. streaming re-parse) hits the same key.
      await persister.persist(AiAnalysisResult(text: 'x', scan: _scan()), chatMessageId: 'msg1', persistedTagBlocks: tags);

      verify(() => history.saveToScanHistory(any(), userImageUrl: any(named: 'userImageUrl'), scanId: any(named: 'scanId'))).called(1);
    });

    test('isLabelOrMenuTurn unifies source, category, and intent signals', () {
      final bySource = AiAnalysisResult(text: 'x', scan: _scan().copyWith(source: 'menu'));
      final byCategory = AiAnalysisResult(text: 'x', scan: _scan().copyWith(category: 'label'));
      final byIntent = AiAnalysisResult(text: 'x', intent: UserIntent.menuRecommendation);
      final normal = AiAnalysisResult(text: 'x', intent: UserIntent.mealRating, scan: _scan());

      expect(DomainEventPersister.isLabelOrMenuTurn(bySource), isTrue);
      expect(DomainEventPersister.isLabelOrMenuTurn(byCategory), isTrue);
      expect(DomainEventPersister.isLabelOrMenuTurn(byIntent), isTrue);
      expect(DomainEventPersister.isLabelOrMenuTurn(normal), isFalse);
    });
  });
}
