import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/ai/classification/ai_classifier_service.dart';
import 'package:gutgood/core/ai/client/ai_client.dart';
import 'package:gutgood/core/ai/protocol/ai_analysis_result.dart';
import 'package:gutgood/core/models/chat/chat_message.dart';
import 'package:gutgood/core/models/journal/meal_log.dart';
import 'package:gutgood/core/models/journal/symptom_log.dart';
import 'package:gutgood/core/models/scans/off_product.dart';
import 'package:gutgood/core/models/scans/scan_result.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/streak_service.dart';
import 'package:gutgood/features/chat/domain/usecases/process_chat_tag_usecase.dart';
import 'package:gutgood/features/logs/data/services/domain_event_persister.dart';
import 'package:gutgood/features/scanner/data/repositories/scanner_repository_impl.dart';
import 'package:gutgood/infrastructure/firebase/analytics_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/chat_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/history_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/notification_service.dart';
import 'package:gutgood/infrastructure/open_food_facts/off_service.dart';
import 'package:mocktail/mocktail.dart';

class MockOffService extends Mock implements OffService {}

class MockAiService extends Mock implements AiClient {}

class MockAiClassifierService extends Mock implements AiClassifierService {}

class MockProcessChatTagUseCase extends Mock implements ProcessChatTagUseCase {}

class MockChatFirestoreService extends Mock implements ChatFirestoreService {}

class MockHistoryFirestoreService extends Mock implements HistoryFirestoreService {}

class MockNotificationService extends Mock implements NotificationService {}

class MockAppStateService extends Mock implements AppStateService {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockStreakService extends Mock implements StreakService {}

void main() {
  late ScannerRepositoryImpl repository;
  late MockOffService mockOffService;
  late MockAiService mockAiService;
  late MockAiClassifierService mockAiClassifierService;
  late MockProcessChatTagUseCase mockProcessChatTagUseCase;
  late MockChatFirestoreService mockChatFirestoreService;
  late MockHistoryFirestoreService mockHistoryFirestoreService;
  late MockNotificationService mockNotificationService;
  late MockAppStateService mockAppStateService;
  late MockAnalyticsService mockAnalyticsService;
  late MockStreakService mockStreakService;

  setUpAll(() {
    registerFallbackValue(ScanResult(productName: '', brand: '', score: 0, impactType: ImpactType.neutral, impact: '', createdAt: DateTime.now()));
    registerFallbackValue(MealLog(items: const [], createdAt: DateTime.now()));
    registerFallbackValue(SymptomLog(symptom: '', createdAt: DateTime.now()));
    registerFallbackValue(ChatMessage(localId: '', role: '', text: '', createdAt: DateTime.now()));
  });

  setUp(() {
    mockOffService = MockOffService();
    mockAiService = MockAiService();
    mockAiClassifierService = MockAiClassifierService();
    mockProcessChatTagUseCase = MockProcessChatTagUseCase();
    mockChatFirestoreService = MockChatFirestoreService();
    mockHistoryFirestoreService = MockHistoryFirestoreService();
    mockNotificationService = MockNotificationService();
    mockAppStateService = MockAppStateService();
    mockAnalyticsService = MockAnalyticsService();
    mockStreakService = MockStreakService();

    repository = ScannerRepositoryImpl(
      offService: mockOffService,
      aiService: mockAiService,
      aiClassifierService: mockAiClassifierService,
      chatFirestoreService: mockChatFirestoreService,
      historyFirestoreService: mockHistoryFirestoreService,
      notificationService: mockNotificationService,
      appStateService: mockAppStateService,
      analyticsService: mockAnalyticsService,
      streakService: mockStreakService,
      processChatTagUseCase: mockProcessChatTagUseCase,
      eventPersister: DomainEventPersister(historyFirestoreService: mockHistoryFirestoreService),
    );
  });

  group('ScannerRepository', () {
    test('getProductByBarcode calls OffService', () async {
      const product = OffProduct(barcode: '123', productName: 'Test', brand: 'Brand');
      when(() => mockOffService.getProduct('123')).thenAnswer((_) async => product);

      final result = await repository.getProductByBarcode('123');

      expect(result, product);
      verify(() => mockOffService.getProduct('123')).called(1);
    });

    test('savePersonalizedInsightRequest persists the user message before analysis', () async {
      final request = ChatMessage(
        localId: 'scan_request',
        role: 'user',
        text: 'Get personalized insight for Test Product.',
        imageUrl: 'https://example.com/product.jpg',
        source: 'barcode',
        createdAt: DateTime.now(),
      );
      when(() => mockChatFirestoreService.saveMessage(request)).thenAnswer((_) async => 'scan_request');
      when(() => mockAppStateService.notifyChatUpdated()).thenAnswer((_) {});

      final saved = await repository.savePersonalizedInsightRequest(request);

      expect(saved, isTrue);
      verify(() => mockChatFirestoreService.saveMessage(request)).called(1);
      verify(() => mockAppStateService.notifyChatUpdated()).called(1);
    });

    test('saveScanResult saves the scan and chat response without logging an unconfirmed meal', () async {
      final scanResult = ScanResult(productName: 'Test Product', brand: 'Brand', score: 80, impactType: ImpactType.positive, impact: 'Good', createdAt: DateTime.now());
      final result = AiAnalysisResult(text: 'Analysis', scan: scanResult);

      when(() => mockChatFirestoreService.saveMessage(any())).thenAnswer((_) async => 'msg_id');
      when(
        () => mockHistoryFirestoreService.trySaveToScanHistory(
          any(),
          userImageUrl: any(named: 'userImageUrl'),
          scanId: any(named: 'scanId'),
        ),
      ).thenAnswer((_) async => true);
      when(() => mockAppStateService.notifyChatUpdated()).thenAnswer((_) {});
      when(() => mockNotificationService.scheduleNoMealLoggedReminder()).thenAnswer((_) async {});
      when(() => mockNotificationService.schedulePostMealCheckIn()).thenAnswer((_) async {});
      when(() => mockStreakService.markActivityToday()).thenAnswer((_) async {});

      await repository.saveScanResult(result);

      verify(() => mockChatFirestoreService.saveMessage(any())).called(1);
      verify(
        () => mockHistoryFirestoreService.trySaveToScanHistory(
          any(),
          userImageUrl: any(named: 'userImageUrl'),
          scanId: any(named: 'scanId'),
        ),
      ).called(1);
      verifyNever(() => mockHistoryFirestoreService.logMeal(any(), docId: any(named: 'docId')));
      verify(() => mockAppStateService.notifyChatUpdated()).called(1);
    });
  });
}
