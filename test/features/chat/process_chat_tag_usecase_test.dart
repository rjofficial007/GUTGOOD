import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/symptom_log.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/firestore/history_firestore_service.dart';
import 'package:gutgood/core/services/notification_service.dart';
import 'package:gutgood/features/chat/domain/usecases/process_chat_tag_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockHistoryFirestoreService extends Mock
    implements HistoryFirestoreService {}

class MockNotificationService extends Mock implements NotificationService {}

class MockAppStateService extends Mock implements AppStateService {}

void main() {
  late ProcessChatTagUseCase useCase;
  late MockHistoryFirestoreService mockFirestoreService;
  late MockNotificationService mockNotificationService;
  late MockAppStateService mockAppStateService;

  setUpAll(() {
    registerFallbackValue(
      SymptomLog(symptom: '', severity: 0, time: DateTime.now()),
    );
    registerFallbackValue(MealLog(items: const [], time: DateTime.now()));
    registerFallbackValue(
      const ScanResult(
        productName: '',
        brand: '',
        score: 0,
        impactType: ImpactType.neutral,
        impact: '',
      ),
    );
  });

  setUp(() {
    mockFirestoreService = MockHistoryFirestoreService();
    mockNotificationService = MockNotificationService();
    mockAppStateService = MockAppStateService();
    useCase = ProcessChatTagUseCase(
      firestoreService: mockFirestoreService,
      notificationService: mockNotificationService,
      appStateService: mockAppStateService,
    );
  });

  group('ProcessChatTagUseCase', () {
    test('should extract and persist symptom when [SYMPTOM] tag is present', () {
      const text =
          'I feel bad [SYMPTOM]{"symptom": "Bloating", "severity": 3, "time": "2023-01-01T12:00:00Z"}[/SYMPTOM]';

      when(
        () => mockFirestoreService.logSymptom(any()),
      ).thenAnswer((_) async => 'symptom_id');
      when(() => mockAppStateService.notifyChatUpdated()).thenAnswer((_) {});

      final result = useCase.call(text);

      expect(result.text, 'I feel bad');
      expect(result.symptomMentions, const ['Bloating']);
      verify(() => mockFirestoreService.logSymptom(any())).called(1);
      verify(() => mockAppStateService.notifyChatUpdated()).called(1);
    });

    test('should extract and persist meal when [MEAL] tag is present', () {
      const text =
          'Had lunch [MEAL]{"items": ["Apple", "Banana"], "tags": ["fruit"], "time": "2023-01-01T12:00:00Z"}[/MEAL]';

      when(
        () => mockFirestoreService.logMeal(any()),
      ).thenAnswer((_) async => 'meal_id');
      when(
        () => mockNotificationService.schedulePostMealCheckIn(),
      ).thenAnswer((_) async {});
      when(
        () => mockNotificationService.scheduleNoMealLoggedReminder(),
      ).thenAnswer((_) async {});
      when(() => mockAppStateService.notifyChatUpdated()).thenAnswer((_) {});

      final result = useCase.call(text);

      expect(result.text, 'Had lunch');
      expect(result.foodMentions, const ['Apple', 'Banana']);
      verify(() => mockFirestoreService.logMeal(any())).called(1);
      verify(() => mockNotificationService.schedulePostMealCheckIn()).called(1);
      verify(() => mockAppStateService.notifyChatUpdated()).called(1);
    });

    test(
      'should extract scan and schedule reminders when [SCAN] tag is present',
      () {
        const text =
            'Check this [SCAN]{"productName": "Oats", "brand": "Quaker", "score": 90, "impact": "Great"}[/SCAN]';

        when(
          () => mockFirestoreService.saveToScanHistory(
            any(),
            userImageUrl: any(named: 'userImageUrl'),
          ),
        ).thenAnswer((_) async => {});
        when(() => mockAppStateService.notifyChatUpdated()).thenAnswer((_) {});

        final result = useCase.call(text);

        expect(result.text, 'Check this');
        expect(result.scanData?.productName, 'Oats');
        verify(
          () => mockFirestoreService.saveToScanHistory(
            any(),
            userImageUrl: any(named: 'userImageUrl'),
          ),
        ).called(1);
        verify(() => mockAppStateService.notifyChatUpdated()).called(1);
      },
    );

    test('should return original text if no tags are present', () {
      const text = 'Hello world';
      final result = useCase.call(text);
      expect(result.text, 'Hello world');
      verifyZeroInteractions(mockFirestoreService);
    });
  });
}
