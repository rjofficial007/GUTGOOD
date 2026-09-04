import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/ai_analysis_result.dart';
import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/symptom_log.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/firestore/history_firestore_service.dart';
import 'package:gutgood/core/services/streak_service.dart';
import 'package:gutgood/features/chat/domain/usecases/persist_ai_response_usecase.dart';
import 'package:gutgood/features/logs/domain/repositories/log_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockHistoryFirestoreService extends Mock implements HistoryFirestoreService {}

class MockLogRepository extends Mock implements LogRepository {}

class MockAppStateService extends Mock implements AppStateService {}

class MockStreakService extends Mock implements StreakService {}

void main() {
  late PersistAiResponseUseCase useCase;
  late MockHistoryFirestoreService mockFirestoreService;
  late MockLogRepository mockLogRepository;
  late MockAppStateService mockAppStateService;
  late MockStreakService mockStreakService;

  setUpAll(() {
    registerFallbackValue(SymptomLog(symptom: '', severity: 0, createdAt: DateTime.now()));
    registerFallbackValue(MealLog(items: const [], createdAt: DateTime.now()));
    registerFallbackValue(ScanResult(productName: '', brand: '', score: 0, impactType: ImpactType.neutral, impact: '', createdAt: DateTime.now()));
  });

  setUp(() {
    mockFirestoreService = MockHistoryFirestoreService();
    mockLogRepository = MockLogRepository();
    mockAppStateService = MockAppStateService();
    mockStreakService = MockStreakService();
    useCase = PersistAiResponseUseCase(firestoreService: mockFirestoreService, appStateService: mockAppStateService, streakService: mockStreakService);
  });

  group('PersistAiResponseUseCase', () {
    test('should persist everything in the result', () async {
      final now = DateTime.now();
      final result = AiAnalysisResult(
        text: 'Analysis',
        scan: ScanResult(productName: 'Food', brand: 'Brand', score: 80, impactType: ImpactType.positive, impact: 'Good', category: 'food', createdAt: now),
        meal: MealLog(items: const ['Food'], createdAt: now),
        symptoms: [SymptomLog(symptom: 'Bloating', severity: 2, createdAt: now)],
      );

      when(
        () => mockFirestoreService.saveToScanHistory(
          any(),
          userImageUrl: any(named: 'userImageUrl'),
          scanId: any(named: 'scanId'),
        ),
      ).thenAnswer((_) async => {});
      when(() => mockFirestoreService.logMeal(any(), docId: any(named: 'docId'))).thenAnswer((_) async => 'meal_id');
      when(() => mockFirestoreService.logSymptom(any(), docId: any(named: 'docId'))).thenAnswer((_) async => 'symptom_id');
      when(() => mockStreakService.markActivityToday()).thenAnswer((_) async => {});
      when(() => mockAppStateService.notifyChatUpdated()).thenAnswer((_) {});

      final persistedTags = <String>{};
      await useCase.call(result, persistedTagBlocks: persistedTags);

      verify(
        () => mockFirestoreService.saveToScanHistory(
          any(),
          userImageUrl: any(named: 'userImageUrl'),
          scanId: any(named: 'scanId'),
        ),
      ).called(1);
      verify(() => mockFirestoreService.logMeal(any(), docId: any(named: 'docId'))).called(1);
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

    test('should save label/menu scans ONLY to chat history and skip scan_history/journal_logs', () async {
      final now = DateTime.now();
      final labelResult = AiAnalysisResult(
        text: 'Label Analysis',
        intent: 'INGREDIENT_ANALYSIS',
        scan: ScanResult(productName: 'Processed Snack', brand: 'Brand', score: 60, impactType: ImpactType.neutral, impact: 'Ok', category: 'label', createdAt: now),
        meal: MealLog(items: const ['Processed Snack'], createdAt: now),
      );

      when(() => mockStreakService.markActivityToday()).thenAnswer((_) async => {});

      final persistedTags = <String>{};
      final output = await useCase.call(labelResult, source: 'label', persistedTagBlocks: persistedTags);

      expect(output.meal, isNull);
      verifyNever(() => mockFirestoreService.saveLabelScan(any(), userImageUrl: any(named: 'userImageUrl'), scanId: any(named: 'scanId')));
      verifyNever(() => mockFirestoreService.logMeal(any(), docId: any(named: 'docId')));
    });

    test('should skip persistence entirely when AI reports low confidence', () async {
      final now = DateTime.now();
      final lowConfidenceResult = AiAnalysisResult(
        text: 'Analysis',
        scan: ScanResult(productName: 'Blurry Food', brand: 'Brand', score: 80, impactType: ImpactType.positive, impact: 'Good', category: 'food', createdAt: now),
        meal: MealLog(items: const ['Blurry Food'], createdAt: now),
        symptoms: [SymptomLog(symptom: 'Bloating', severity: 2, createdAt: now)],
        confidence: 0.3,
      );

      final persistedTags = <String>{};
      final output = await useCase.call(lowConfidenceResult, persistedTagBlocks: persistedTags);

      expect(output, equals(lowConfidenceResult));
      verifyNever(() => mockFirestoreService.saveToScanHistory(any(), userImageUrl: any(named: 'userImageUrl'), scanId: any(named: 'scanId')));
      verifyNever(() => mockFirestoreService.logMeal(any(), docId: any(named: 'docId')));
      verifyNever(() => mockFirestoreService.logSymptom(any(), docId: any(named: 'docId')));
      verifyNever(() => mockStreakService.markActivityToday());
    });

    test('should persist as normal when AI confidence is above threshold', () async {
      final now = DateTime.now();
      final highConfidenceResult = AiAnalysisResult(
        text: 'Analysis',
        scan: ScanResult(productName: 'Clear Food', brand: 'Brand', score: 80, impactType: ImpactType.positive, impact: 'Good', category: 'food', createdAt: now),
        confidence: 0.9,
      );

      when(
        () => mockFirestoreService.saveToScanHistory(
          any(),
          userImageUrl: any(named: 'userImageUrl'),
          scanId: any(named: 'scanId'),
        ),
      ).thenAnswer((_) async => {});
      when(() => mockStreakService.markActivityToday()).thenAnswer((_) async => {});
      when(() => mockAppStateService.notifyChatUpdated()).thenAnswer((_) {});

      final persistedTags = <String>{};
      await useCase.call(highConfidenceResult, persistedTagBlocks: persistedTags);

      verify(
        () => mockFirestoreService.saveToScanHistory(
          any(),
          userImageUrl: any(named: 'userImageUrl'),
          scanId: any(named: 'scanId'),
        ),
      ).called(1);
    });
  });
}
