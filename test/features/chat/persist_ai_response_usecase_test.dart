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
    registerFallbackValue(SymptomLog(symptom: '', severity: 0, time: DateTime.now()));
    registerFallbackValue(MealLog(items: const [], time: DateTime.now()));
    registerFallbackValue(const ScanResult(productName: '', brand: '', score: 0, impactType: ImpactType.neutral, impact: ''));
  });

  setUp(() {
    mockFirestoreService = MockHistoryFirestoreService();
    mockLogRepository = MockLogRepository();
    mockAppStateService = MockAppStateService();
    mockStreakService = MockStreakService();
    useCase = PersistAiResponseUseCase(
      firestoreService: mockFirestoreService,
      logRepository: mockLogRepository,
      appStateService: mockAppStateService,
      streakService: mockStreakService,
    );
  });

  group('PersistAiResponseUseCase', () {
    test('should persist everything in the result', () async {
      final now = DateTime.now();
      final result = AiAnalysisResult(
        text: 'Analysis',
        scan: ScanResult(productName: 'Food', brand: 'Brand', score: 80, impactType: ImpactType.positive, impact: 'Good', category: 'food', time: now),
        meal: MealLog(items: ['Food'], time: now),
        symptoms: [SymptomLog(symptom: 'Bloating', severity: 2, time: now)],
      );

      when(() => mockFirestoreService.saveToScanHistory(any(), userImageUrl: any(named: 'userImageUrl'), scanId: any(named: 'scanId'))).thenAnswer((_) async => {});
      when(() => mockLogRepository.logMeal(any())).thenAnswer((_) async => {});
      when(() => mockLogRepository.logSymptom(any())).thenAnswer((_) async => {});
      when(() => mockStreakService.markActivityToday()).thenAnswer((_) async => {});
      when(() => mockAppStateService.notifyChatUpdated()).thenAnswer((_) {});

      final persistedTags = <String>{};
      await useCase.call(result, persistedTagBlocks: persistedTags);

      verify(() => mockFirestoreService.saveToScanHistory(any(), userImageUrl: any(named: 'userImageUrl'), scanId: any(named: 'scanId'))).called(1);
      // Auto-log meal from scan happens if source/imageUrl suggests it's a food photo.
      // In this test, we have BOTH a scan and a meal in the result.
      // Our logic says: if meal is present AND !persistedTagBlocks.contains('__MEAL_LOGGED_IN_TURN__'), persist meal.
      verify(() => mockLogRepository.logMeal(any())).called(1);
      verify(() => mockLogRepository.logSymptom(any())).called(1);
      verify(() => mockStreakService.markActivityToday()).called(1);
    });

    test('should handle duplicates using persistedTagBlocks', () async {
      final now = DateTime.now();
      final result = AiAnalysisResult(
        text: 'Analysis',
        symptoms: [SymptomLog(symptom: 'Bloating', severity: 2, time: now)],
      );

      when(() => mockLogRepository.logSymptom(any())).thenAnswer((_) async => {});
      when(() => mockStreakService.markActivityToday()).thenAnswer((_) async => {});
      when(() => mockAppStateService.notifyChatUpdated()).thenAnswer((_) {});

      final persistedTags = <String>{};
      
      // First call
      await useCase.call(result, persistedTagBlocks: persistedTags);
      verify(() => mockLogRepository.logSymptom(any())).called(1);

      // Second call with same tags
      await useCase.call(result, persistedTagBlocks: persistedTags);
      verifyNever(() => mockLogRepository.logSymptom(any()));
    });
  });
}
