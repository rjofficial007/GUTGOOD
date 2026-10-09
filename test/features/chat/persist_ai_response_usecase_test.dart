import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/streak_service.dart';
import 'package:gutgood/features/chat/application/usecases/persist_ai_response_usecase.dart';
import 'package:gutgood/infrastructure/firebase/firestore/history_firestore_service.dart';
import 'package:mocktail/mocktail.dart';

class MockHistoryFirestoreService extends Mock implements HistoryFirestoreService {}

class MockAppStateService extends Mock implements AppStateService {}

class MockStreakService extends Mock implements StreakService {}

void main() {
  late PersistAiResponseUseCase useCase;
  late MockHistoryFirestoreService mockFirestoreService;
  late MockAppStateService mockAppStateService;
  late MockStreakService mockStreakService;

  setUpAll(() {
    registerFallbackValue(SymptomLog(symptom: '', severity: 0, createdAt: DateTime.now()));
    registerFallbackValue(MealLog(items: const [], createdAt: DateTime.now()));
    registerFallbackValue(ScanResult(productName: '', brand: '', score: 0, impactType: ImpactType.neutral, impact: '', createdAt: DateTime.now()));
  });

  setUp(() {
    mockFirestoreService = MockHistoryFirestoreService();
    mockAppStateService = MockAppStateService();
    mockStreakService = MockStreakService();
    useCase = PersistAiResponseUseCase(firestoreService: mockFirestoreService, appStateService: mockAppStateService, streakService: mockStreakService);
    when(() => mockFirestoreService.logMeal(any(), docId: any(named: 'docId'))).thenAnswer((_) async => 'meal_id');
    when(() => mockFirestoreService.logSymptom(any(), docId: any(named: 'docId'))).thenAnswer((_) async => 'symptom_id');
    when(
      () => mockFirestoreService.getRecentMealLogs(
        limit: any(named: 'limit'),
        since: any(named: 'since'),
        before: any(named: 'before'),
      ),
    ).thenAnswer((_) async => const []);
    when(
      () => mockFirestoreService.trySaveToScanHistory(
        any(),
        userImageUrl: any(named: 'userImageUrl'),
        scanId: any(named: 'scanId'),
      ),
    ).thenAnswer((_) async => true);
  });

  group('PersistAiResponseUseCase', () {
    test('persists scan and symptoms without logging an unconfirmed scan as a meal', () async {
      final now = DateTime.now();
      final result = AiAnalysisResult(
        text: 'Analysis',
        scan: ScanResult(productName: 'Food', brand: 'Brand', score: 80, impactType: ImpactType.positive, impact: 'Good', category: 'food', createdAt: now),
        meal: MealLog(items: const ['Food'], createdAt: now),
        symptoms: [SymptomLog(symptom: 'Bloating', severity: 2, createdAt: now)],
      );

      when(
        () => mockFirestoreService.trySaveToScanHistory(
          any(),
          userImageUrl: any(named: 'userImageUrl'),
          scanId: any(named: 'scanId'),
        ),
      ).thenAnswer((_) async => true);
      when(() => mockFirestoreService.logMeal(any(), docId: any(named: 'docId'))).thenAnswer((_) async => 'meal_id');
      when(() => mockFirestoreService.logSymptom(any(), docId: any(named: 'docId'))).thenAnswer((_) async => 'symptom_id');
      when(() => mockStreakService.markActivityToday()).thenAnswer((_) async => {});
      when(() => mockAppStateService.notifyChatUpdated()).thenAnswer((_) {});

      final persistedTags = <String>{};
      await useCase.call(result, persistedTagBlocks: persistedTags);

      verify(
        () => mockFirestoreService.trySaveToScanHistory(
          any(),
          userImageUrl: any(named: 'userImageUrl'),
          scanId: any(named: 'scanId'),
        ),
      ).called(1);
      verifyNever(() => mockFirestoreService.logMeal(any(), docId: any(named: 'docId')));
      verify(() => mockFirestoreService.logSymptom(any(), docId: any(named: 'docId'))).called(1);
      verify(() => mockStreakService.markActivityToday()).called(1);
    });

    test('should handle duplicates using persistedTagBlocks', () async {
      final now = DateTime.now();
      final result = AiAnalysisResult(
        text: 'Analysis',
        symptoms: [SymptomLog(symptom: 'Bloating', severity: 2, createdAt: now)],
      );

      when(() => mockFirestoreService.logSymptom(any(), docId: any(named: 'docId'))).thenAnswer((_) async => 'symptom_id');
      when(() => mockStreakService.markActivityToday()).thenAnswer((_) async => {});
      when(() => mockAppStateService.notifyChatUpdated()).thenAnswer((_) {});

      final persistedTags = <String>{};

      // First call
      await useCase.call(result, persistedTagBlocks: persistedTags);
      verify(() => mockFirestoreService.logSymptom(any(), docId: any(named: 'docId'))).called(1);

      // Second call with same tags
      await useCase.call(result, persistedTagBlocks: persistedTags);
      verifyNever(() => mockFirestoreService.logSymptom(any(), docId: any(named: 'docId')));
    });

    test('retains a label scan without counting it as a consumed food', () async {
      final now = DateTime.now();
      final labelResult = AiAnalysisResult(
        text: 'Label Analysis',
        intent: 'INGREDIENT_ANALYSIS',
        scan: ScanResult(productName: 'Processed Snack', brand: 'Brand', score: 60, impactType: ImpactType.neutral, impact: 'Ok', category: 'label', createdAt: now),
        meal: MealLog(items: const ['Processed Snack'], createdAt: now),
      );

      when(() => mockStreakService.markActivityToday()).thenAnswer((_) async => {});
      when(() => mockAppStateService.notifyChatUpdated()).thenAnswer((_) {});

      final persistedTags = <String>{};
      final output = await useCase.call(labelResult, source: 'label', chatMessageId: 'label-turn', persistedTagBlocks: persistedTags);

      expect(output.meal, isNull);
      verify(
        () => mockFirestoreService.trySaveToScanHistory(
          any(),
          userImageUrl: any(named: 'userImageUrl'),
          scanId: 'label-turn_scan',
        ),
      ).called(1);
      verifyNever(() => mockFirestoreService.logMeal(any(), docId: 'label-turn_meal'));
    });

    test('should persist a scan even when AI reports low confidence', () async {
      final now = DateTime.now();
      final lowConfidenceResult = AiAnalysisResult(
        text: 'Analysis',
        scan: ScanResult(productName: 'Blurry Food', brand: 'Brand', score: 80, impactType: ImpactType.positive, impact: 'Good', category: 'food', createdAt: now),
        meal: MealLog(items: const ['Blurry Food'], createdAt: now),
        symptoms: [SymptomLog(symptom: 'Bloating', severity: 2, createdAt: now)],
        confidence: 0.3,
      );

      when(() => mockStreakService.markActivityToday()).thenAnswer((_) async => {});
      when(() => mockAppStateService.notifyChatUpdated()).thenAnswer((_) {});

      final persistedTags = <String>{};
      final output = await useCase.call(lowConfidenceResult, chatMessageId: 'low-confidence-turn', persistedTagBlocks: persistedTags);

      expect(output, isNot(equals(lowConfidenceResult)));
      expect(output.meal, isNull);
      verify(
        () => mockFirestoreService.trySaveToScanHistory(
          any(),
          userImageUrl: any(named: 'userImageUrl'),
          scanId: 'low-confidence-turn_scan',
        ),
      ).called(1);
      verifyNever(() => mockFirestoreService.logMeal(any(), docId: 'low-confidence-turn_meal'));
      verify(() => mockFirestoreService.logSymptom(any(), docId: 'low-confidence-turn_symptom_0')).called(1);
      verify(() => mockStreakService.markActivityToday()).called(1);
    });

    test('should persist as normal when AI confidence is above threshold', () async {
      final now = DateTime.now();
      final highConfidenceResult = AiAnalysisResult(
        text: 'Analysis',
        scan: ScanResult(productName: 'Clear Food', brand: 'Brand', score: 80, impactType: ImpactType.positive, impact: 'Good', category: 'food', createdAt: now),
        confidence: 0.9,
      );

      when(
        () => mockFirestoreService.trySaveToScanHistory(
          any(),
          userImageUrl: any(named: 'userImageUrl'),
          scanId: any(named: 'scanId'),
        ),
      ).thenAnswer((_) async => true);
      when(() => mockStreakService.markActivityToday()).thenAnswer((_) async => {});
      when(() => mockAppStateService.notifyChatUpdated()).thenAnswer((_) {});

      final persistedTags = <String>{};
      await useCase.call(highConfidenceResult, persistedTagBlocks: persistedTags);

      verify(
        () => mockFirestoreService.trySaveToScanHistory(
          any(),
          userImageUrl: any(named: 'userImageUrl'),
          scanId: any(named: 'scanId'),
        ),
      ).called(1);
    });
  });
}
