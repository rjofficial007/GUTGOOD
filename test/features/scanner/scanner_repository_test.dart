import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/ai/classification/ai_classifier_service.dart';
import 'package:gutgood/core/ai/client/ai_client.dart';
import 'package:gutgood/core/ai/protocol/ai_analysis_result.dart';
import 'package:gutgood/core/models/chat/chat_message.dart';
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

    test('saveScanResult saves to Firestore and notifies UI', () async {
      final scanResult = ScanResult(productName: 'Test Product', brand: 'Brand', score: 80, impactType: ImpactType.positive, impact: 'Good', createdAt: DateTime.now());
      final result = AiAnalysisResult(text: 'Analysis', scan: scanResult);

      when(() => mockChatFirestoreService.saveMessage(any())).thenAnswer((_) async => 'msg_id');
      when(
        () => mockHistoryFirestoreService.saveToScanHistory(
          any(),
          userImageUrl: any(named: 'userImageUrl'),
          scanId: any(named: 'scanId'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockAppStateService.notifyChatUpdated()).thenAnswer((_) {});
      when(() => mockNotificationService.scheduleNoMealLoggedReminder()).thenAnswer((_) async {});
      when(() => mockNotificationService.schedulePostMealCheckIn()).thenAnswer((_) async {});
      when(() => mockStreakService.markActivityToday()).thenAnswer((_) async {});

      await repository.saveScanResult(result);

      verify(() => mockChatFirestoreService.saveMessage(any())).called(2);
      verify(
        () => mockHistoryFirestoreService.saveToScanHistory(
          any(),
          userImageUrl: any(named: 'userImageUrl'),
          scanId: any(named: 'scanId'),
        ),
      ).called(1);
      verify(() => mockAppStateService.notifyChatUpdated()).called(1);
    });
  });
}
