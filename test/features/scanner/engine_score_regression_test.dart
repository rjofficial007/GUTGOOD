import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/ai_analysis_result.dart';
import 'package:gutgood/core/models/chat_message.dart';
import 'package:gutgood/core/models/off_product.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/services/ai_classifier_service.dart';
import 'package:gutgood/core/services/ai_service.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/domain_event_persister.dart';
import 'package:gutgood/core/services/firestore/chat_firestore_service.dart';
import 'package:gutgood/core/services/firestore/history_firestore_service.dart';
import 'package:gutgood/core/services/notification_service.dart';
import 'package:gutgood/core/services/off_service.dart';
import 'package:gutgood/core/services/streak_service.dart';
import 'package:gutgood/features/chat/domain/usecases/process_chat_tag_usecase.dart';
import 'package:gutgood/features/scanner/data/repositories/scanner_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class MockOffService extends Mock implements OffService {}

class MockAiService extends Mock implements AiService {}

class MockAiClassifierService extends Mock implements AiClassifierService {}

class MockProcessChatTagUseCase extends Mock implements ProcessChatTagUseCase {}

class MockChatFirestoreService extends Mock implements ChatFirestoreService {}

class MockHistoryFirestoreService extends Mock implements HistoryFirestoreService {}

class MockNotificationService extends Mock implements NotificationService {}

class MockAppStateService extends Mock implements AppStateService {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockStreakService extends Mock implements StreakService {}

/// Builds a repository wired entirely to mocks.
ScannerRepositoryImpl buildRepository({
  required MockAiService ai,
  required MockAiClassifierService classifier,
  required MockProcessChatTagUseCase tagUseCase,
  required MockAnalyticsService analytics,
}) => ScannerRepositoryImpl(
  offService: MockOffService(),
  aiService: ai,
  aiClassifierService: classifier,
  chatFirestoreService: MockChatFirestoreService(),
  historyFirestoreService: MockHistoryFirestoreService(),
  notificationService: MockNotificationService(),
  appStateService: MockAppStateService(),
  analyticsService: analytics,
  streakService: MockStreakService(),
  processChatTagUseCase: tagUseCase,
  eventPersister: DomainEventPersister(historyFirestoreService: MockHistoryFirestoreService()),
);

ScanResult bareScan({int score = 50}) =>
    ScanResult(productName: 'Grilled chicken salad', brand: '', score: score, impactType: ImpactType.neutral, impact: 'A balanced plate', createdAt: DateTime(2026, 1, 1));

void main() {
  late MockAiService mockAiService;
  late MockAiClassifierService mockClassifier;
  late MockProcessChatTagUseCase mockTagUseCase;
  late MockAnalyticsService mockAnalytics;

  setUpAll(() {
    registerFallbackValue(ScanResult(productName: '', brand: '', score: 0, impactType: ImpactType.neutral, impact: '', createdAt: DateTime.now()));
    registerFallbackValue(ChatMessage(localId: '', role: '', text: '', createdAt: DateTime.now()));
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    mockAiService = MockAiService();
    mockClassifier = MockAiClassifierService();
    mockTagUseCase = MockProcessChatTagUseCase();
    mockAnalytics = MockAnalyticsService();

    when(
      () => mockAnalytics.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockAiService.lastPromptVersion).thenReturn(null);
    when(() => mockAiService.lastServedModel).thenReturn(null);
  });

  group('Vision path — engine must not flatten photo scans to a neutral 50', () {
    Future<ScanResult?> runVision(ScanResult modelScan) async {
      final repo = buildRepository(ai: mockAiService, classifier: mockClassifier, tagUseCase: mockTagUseCase, analytics: mockAnalytics);

      when(
        () => mockClassifier.classifyImage(
          imageBytes: any(named: 'imageBytes'),
          userText: any(named: 'userText'),
          modeHint: any(named: 'modeHint'),
        ),
      ).thenAnswer((_) async => const AiClassificationResult(imageMode: 'FOOD', intent: 'COMPLETE_ANALYSIS', confidence: 1.0));
      when(
        () => mockAiService.generateContent(
          prompt: any(named: 'prompt'),
          systemInstruction: any(named: 'systemInstruction'),
          imageBytes: any(named: 'imageBytes'),
          usageType: any(named: 'usageType'),
          mode: any(named: 'mode'),
          promptVersion: any(named: 'promptVersion'),
        ),
      ).thenAnswer((_) async => 'analysis text');
      when(
        () => mockTagUseCase(
          any(),
          userText: any(named: 'userText'),
          source: any(named: 'source'),
          promptVersion: any(named: 'promptVersion'),
          servedModel: any(named: 'servedModel'),
        ),
      ).thenReturn(AiAnalysisResult(text: 'analysis text', scan: modelScan));

      final result = await repo.analyzeImageWithAi(imageBytes: Uint8List.fromList([1, 2, 3]), mode: 'FOOD', goals: const [], sensitivities: const [], lifestyle: const [], cyclePhase: 'none');
      return result.scan;
    }

    test('a photo scan with no measurable nutrients keeps the model score instead of 50', () async {
      final scan = await runVision(bareScan(score: 82));

      expect(scan, isNotNull);
      expect(scan!.score, 82, reason: 'Engine has no inputs here; overriding a reasoned 82 with a flat 50 would make every photo scan look identical.');
    });

    test('a photo scan WITH extracted signals is still scored by the engine', () async {
      final scan = await runVision(bareScan(score: 20).copyWith(nutriscore: 'a', novaGroup: '1'));

      expect(scan, isNotNull);
      expect(scan!.score, greaterThan(50), reason: 'Nutri-Score A / NOVA 1 must raise the score above the neutral baseline.');
    });

    test('engine override preserves the model-authored narrative', () async {
      final scan = await runVision(bareScan(score: 20).copyWith(nutriscore: 'a', impact: 'Mostly whole foods. High in fibre.'));

      expect(scan!.impact, 'Mostly whole foods. High in fibre.');
      expect(scan.score, greaterThan(50));
    });
  });

  group('Barcode path — engine scoring behaviour is unchanged', () {
    Future<ScanResult?> runBarcode({required OffProduct product, required ScanResult modelScan}) async {
      final repo = buildRepository(ai: mockAiService, classifier: mockClassifier, tagUseCase: mockTagUseCase, analytics: mockAnalytics);

      when(
        () => mockAiService.generateContent(
          prompt: any(named: 'prompt'),
          systemInstruction: any(named: 'systemInstruction'),
          imageBytes: any(named: 'imageBytes'),
          usageType: any(named: 'usageType'),
          mode: any(named: 'mode'),
          promptVersion: any(named: 'promptVersion'),
        ),
      ).thenAnswer((_) async => 'analysis text');
      when(
        () => mockTagUseCase(
          any(),
          source: any(named: 'source'),
          promptVersion: any(named: 'promptVersion'),
          servedModel: any(named: 'servedModel'),
        ),
      ).thenReturn(AiAnalysisResult(text: 'analysis text', scan: modelScan));

      final result = await repo.analyzeProductWithAi(product: product, goals: const [], sensitivities: const [], lifestyle: const [], cyclePhase: 'none');
      return result.scan;
    }

    test('Open Food Facts ground truth drives the score, not the model', () async {
      final scan = await runBarcode(
        product: const OffProduct(productName: 'Sugary cereal', nutriscore: 'e', novaGroup: 4),
        modelScan: bareScan(score: 95),
      );

      expect(scan!.score, lessThan(50), reason: 'Nutri-Score E / NOVA 4 must pull the score down regardless of what the model claimed.');
    });

    test('an OFF product with no data still yields the neutral baseline (pre-existing behaviour)', () async {
      final scan = await runBarcode(
        product: const OffProduct(productName: 'Unknown item'),
        modelScan: bareScan(score: 88),
      );

      expect(scan!.score, 50, reason: 'Locking in baseline behaviour: no OFF data means no signal, so the engine stays neutral.');
    });
  });

  group('Legacy compatibility — old scans parse correctly', () {
    test('scans saved before schema v2 still parse correctly', () {
      final legacy = ScanResult.fromMap(const {'productName': 'Old scan', 'brand': 'Legacy', 'score': 74, 'impactType': 'positive', 'impact': 'Fine', 'createdAt': '2026-01-01T00:00:00.000'});

      expect(legacy.score, 74);
    });

    test('copyWith works correctly', () {
      final scan = bareScan(score: 80);
      final renamed = scan.copyWith(productName: 'Renamed');

      expect(renamed.productName, 'Renamed');
      expect(renamed.score, 80);
    });
  });
}
