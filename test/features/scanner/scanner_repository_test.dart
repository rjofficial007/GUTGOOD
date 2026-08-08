import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/chat_message.dart';
import 'package:gutgood/core/models/off_product.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/services/ai_service.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/firestore/chat_firestore_service.dart';
import 'package:gutgood/core/services/firestore/history_firestore_service.dart';
import 'package:gutgood/core/services/notification_service.dart';
import 'package:gutgood/core/services/off_service.dart';
import 'package:gutgood/features/scanner/data/repositories/scanner_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class MockOffService extends Mock implements OffService {}

class MockAiService extends Mock implements AiService {}

class MockChatFirestoreService extends Mock implements ChatFirestoreService {}

class MockHistoryFirestoreService extends Mock
    implements HistoryFirestoreService {}

class MockNotificationService extends Mock implements NotificationService {}

class MockAppStateService extends Mock implements AppStateService {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  late ScannerRepositoryImpl repository;
  late MockOffService mockOffService;
  late MockAiService mockAiService;
  late MockChatFirestoreService mockChatFirestoreService;
  late MockHistoryFirestoreService mockHistoryFirestoreService;
  late MockNotificationService mockNotificationService;
  late MockAppStateService mockAppStateService;
  late MockAnalyticsService mockAnalyticsService;

  setUpAll(() {
    registerFallbackValue(
      const ScanResult(
        productName: '',
        brand: '',
        score: 0,
        impactType: ImpactType.neutral,
        impact: '',
      ),
    );
    registerFallbackValue(
      ChatMessage(localId: '', role: '', text: '', time: DateTime.now()),
    );
  });

  setUp(() {
    mockOffService = MockOffService();
    mockAiService = MockAiService();
    mockChatFirestoreService = MockChatFirestoreService();
    mockHistoryFirestoreService = MockHistoryFirestoreService();
    mockNotificationService = MockNotificationService();
    mockAppStateService = MockAppStateService();
    mockAnalyticsService = MockAnalyticsService();

    repository = ScannerRepositoryImpl(
      offService: mockOffService,
      aiService: mockAiService,
      chatFirestoreService: mockChatFirestoreService,
      historyFirestoreService: mockHistoryFirestoreService,
      notificationService: mockNotificationService,
      appStateService: mockAppStateService,
      analyticsService: mockAnalyticsService,
    );
  });

  group('ScannerRepository', () {
    test('getProductByBarcode calls OffService', () async {
      const product = OffProduct(
        barcode: '123',
        productName: 'Test',
        brand: 'Brand',
      );
      when(
        () => mockOffService.getProduct('123'),
      ).thenAnswer((_) async => product);

      final result = await repository.getProductByBarcode('123');

      expect(result, product);
      verify(() => mockOffService.getProduct('123')).called(1);
    });

    test('saveScanResult saves to Firestore and notifies UI', () async {
      const result = ScanResult(
        productName: 'Test Product',
        brand: 'Brand',
        score: 80,
        impactType: ImpactType.positive,
        impact: 'Good',
      );

      when(
        () => mockChatFirestoreService.saveMessage(any()),
      ).thenAnswer((_) async => 'msg_id');
      when(
        () => mockHistoryFirestoreService.saveToScanHistory(
          any(),
          userImageUrl: any(named: 'userImageUrl'),
        ),
      ).thenAnswer((_) async => 'history_id');
      when(() => mockAppStateService.notifyChatUpdated()).thenAnswer((_) {});
      when(
        () => mockNotificationService.scheduleNoMealLoggedReminder(),
      ).thenAnswer((_) async {});
      when(
        () => mockNotificationService.schedulePostMealCheckIn(),
      ).thenAnswer((_) async {});

      await repository.saveScanResult(result);

      verify(() => mockChatFirestoreService.saveMessage(any())).called(1);
      verify(
        () => mockHistoryFirestoreService.saveToScanHistory(
          result,
          userImageUrl: any(named: 'userImageUrl'),
        ),
      ).called(1);
      verify(() => mockAppStateService.notifyChatUpdated()).called(1);
    });
  });
}
