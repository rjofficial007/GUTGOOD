import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/ai_analysis_result.dart';
import 'package:gutgood/core/models/chat_message.dart';
import 'package:gutgood/core/models/off_product.dart';
import 'package:gutgood/core/models/scan_insight.dart';
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
}) =>
    ScannerRepositoryImpl(
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

ScanResult bareScan({int score = 50, ScanInsight? insight}) => ScanResult(
      productName: 'Grilled chicken salad',
      brand: '',
      score: score,
      impactType: ImpactType.neutral,
      impact: 'A balanced plate',
      createdAt: DateTime(2026, 1, 1),
      insight: insight,
    );

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

    when(() => mockAnalytics.logEvent(name: any(named: 'name'), parameters: any(named: 'parameters'))).thenAnswer((_) async {});
    when(() => mockAiService.lastPromptVersion).thenReturn(null);
    when(() => mockAiService.lastServedModel).thenReturn(null);
  });

  group('Vision path — engine must not flatten photo scans to a neutral 50', () {
    Future<ScanResult?> runVision(ScanResult modelScan) async {
      final repo = buildRepository(ai: mockAiService, classifier: mockClassifier, tagUseCase: mockTagUseCase, analytics: mockAnalytics);

      when(() => mockClassifier.classifyImage(imageBytes: any(named: 'imageBytes'), userText: any(named: 'userText'), modeHint: any(named: 'modeHint')))
          .thenAnswer((_) async => const AiClassificationResult(imageMode: 'FOOD', intent: 'COMPLETE_ANALYSIS', confidence: 1.0));
      when(() => mockAiService.generateContent(
            prompt: any(named: 'prompt'),
            systemInstruction: any(named: 'systemInstruction'),
            imageBytes: any(named: 'imageBytes'),
            usageType: any(named: 'usageType'),
            mode: any(named: 'mode'),
            promptVersion: any(named: 'promptVersion'),
          )).thenAnswer((_) async => 'analysis text');
      when(() => mockTagUseCase(any(), userText: any(named: 'userText'), source: any(named: 'source'), promptVersion: any(named: 'promptVersion'), servedModel: any(named: 'servedModel')))
          .thenReturn(AiAnalysisResult(text: 'analysis text', scan: modelScan));

      final result = await repo.analyzeImageWithAi(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        mode: 'FOOD',
        goals: const [],
        sensitivities: const [],
        lifestyle: const [],
        cyclePhase: 'none',
      );
      return result.scan;
    }

    test('a photo scan with no measurable nutrients keeps the model score instead of 50', () async {
      final scan = await runVision(bareScan(score: 82));

      expect(scan, isNotNull);
      expect(scan!.score, 82, reason: 'Engine has no inputs here; overriding a reasoned 82 with a flat 50 would make every photo scan look identical.');
    });

    test('a photo scan WITH extracted signals is still scored by the engine', () async {
      final scan = await runVision(
        bareScan(score: 20).copyWith(nutriscore: 'a', novaGroup: '1'),
      );

      expect(scan, isNotNull);
      expect(scan!.score, greaterThan(50), reason: 'Nutri-Score A / NOVA 1 must raise the score above the neutral baseline.');
      expect(scan.insight?.scoreFactors, isNotEmpty);
      expect(scan.insight?.scoreExplanation, contains('Score ${scan.score}'));
    });

    test('engine override preserves the model-authored insight layers', () async {
      final scan = await runVision(
        bareScan(score: 20).copyWith(
          nutriscore: 'a',
          insight: const ScanInsight(
            summary: 'Mostly whole foods.',
            positives: [InsightPositive(title: 'High in fibre')],
            concerns: [InsightConcern(title: 'Salty dressing', severity: ConcernSeverity.moderate)],
            warnings: ['Contains dairy'],
          ),
        ),
      );

      expect(scan!.insight?.summary, 'Mostly whole foods.');
      expect(scan.insight?.positives.single.title, 'High in fibre');
      expect(scan.insight?.concerns.single.title, 'Salty dressing');
      expect(scan.insight?.warnings, ['Contains dairy']);
      expect(scan.insight?.scoreFactors, isNotEmpty, reason: 'Engine factors are merged in, not swapped for the model layers.');
    });
  });

  group('Barcode path — engine scoring behaviour is unchanged', () {
    Future<ScanResult?> runBarcode({required OffProduct product, required ScanResult modelScan}) async {
      final repo = buildRepository(ai: mockAiService, classifier: mockClassifier, tagUseCase: mockTagUseCase, analytics: mockAnalytics);

      when(() => mockAiService.generateContent(
            prompt: any(named: 'prompt'),
            systemInstruction: any(named: 'systemInstruction'),
            imageBytes: any(named: 'imageBytes'),
            usageType: any(named: 'usageType'),
            mode: any(named: 'mode'),
            promptVersion: any(named: 'promptVersion'),
          )).thenAnswer((_) async => 'analysis text');
      when(() => mockTagUseCase(any(), source: any(named: 'source'), promptVersion: any(named: 'promptVersion'), servedModel: any(named: 'servedModel'))).thenReturn(AiAnalysisResult(text: 'analysis text', scan: modelScan));

      final result = await repo.analyzeProductWithAi(
        product: product,
        goals: const [],
        sensitivities: const [],
        lifestyle: const [],
        cyclePhase: 'none',
      );
      return result.scan;
    }

    test('Open Food Facts ground truth drives the score, not the model', () async {
      final scan = await runBarcode(
        product: const OffProduct(productName: 'Sugary cereal', nutriscore: 'e', novaGroup: 4),
        modelScan: bareScan(score: 95),
      );

      expect(scan!.score, lessThan(50), reason: 'Nutri-Score E / NOVA 4 must pull the score down regardless of what the model claimed.');
      expect(scan.insight?.scoreFactors, isNotEmpty);
    });

    test('an OFF product with no data still yields the neutral baseline (pre-existing behaviour)', () async {
      final scan = await runBarcode(
        product: const OffProduct(productName: 'Unknown item'),
        modelScan: bareScan(score: 88),
      );

      expect(scan!.score, 50, reason: 'Locking in baseline behaviour: no OFF data means no signal, so the engine stays neutral.');
    });
  });

  group('Hostile payloads must not throw or poison a Firestore write', () {
    test('malformed insight payloads parse to something safe', () {
      final insight = ScanInsight.fromMap({
        'summary': 42,
        'scoreFactors': ['not a map', null],
        'positives': [null, 'nope', {'detail': 'no title'}],
        'concerns': [{'title': null, 'severity': 'CATASTROPHIC'}],
        'warnings': [null, 7, '  ', 'Contains soy'],
        'nutritionInsights': 'not a list',
      });

      expect(insight.summary, '42');
      expect(insight.scoreFactors, isEmpty);
      expect(insight.positives, isEmpty, reason: 'Entries without a title would render as empty rows.');
      expect(insight.concerns, isEmpty);
      expect(insight.warnings, ['Contains soy']);
      expect(insight.nutritionInsights, isEmpty);
    });

    test('a parsed insight contains no nulls in arrays and survives jsonEncode (Firestore transport)', () {
      final insight = ScanInsight.fromMap({
        'summary': 'Balanced, with a sodium caveat.',
        'positives': [
          {'title': 'Fibre', 'detail': '6g'},
        ],
        'concerns': [
          {'title': 'Sodium', 'severity': 'important', 'detail': null},
        ],
        'warnings': ['Contains dairy'],
      });

      final scan = bareScan(insight: insight);
      final map = scan.toMap();

      void assertNoNullsInArrays(Object? node) {
        if (node is List) {
          for (final item in node) {
            expect(item, isNotNull, reason: 'Firestore rejects null elements inside arrays — this would fail the whole scan save.');
            assertNoNullsInArrays(item);
          }
        } else if (node is Map) {
          node.values.forEach(assertNoNullsInArrays);
        }
      }

      assertNoNullsInArrays(map['insight']);

      // Round-trip the insight subtree through JSON. (The full toMap() cannot
      // be jsonEncoded — it deliberately carries a Firestore Timestamp in
      // `createdAt` — but note nothing in the app jsonEncodes a whole scan, so
      // that is pre-existing and unrelated to insights.)
      final revivedInsight = ScanInsight.fromMap(jsonDecode(jsonEncode(insight.toMap())) as Map<String, dynamic>);
      expect(revivedInsight.summary, 'Balanced, with a sodium caveat.');
      expect(revivedInsight.concerns.single.severity, ConcernSeverity.important);
      expect(revivedInsight.warnings, ['Contains dairy']);

      // And the same payload read back off a Firestore-style map.
      final revived = ScanResult.fromMap(map);
      expect(revived.insight, insight);
    });

    test('scans saved before insights existed still parse to a null insight', () {
      final legacy = ScanResult.fromMap({
        'productName': 'Old scan',
        'brand': 'Legacy',
        'score': 74,
        'impactType': 'positive',
        'impact': 'Fine',
        'createdAt': '2026-01-01T00:00:00.000',
      });

      expect(legacy.insight, isNull);
      expect(legacy.score, 74);
      expect(legacy.rankedConcernTitlesForTest, isEmpty);
    });

    test('copyWith never silently drops an existing insight', () {
      final scan = bareScan(insight: const ScanInsight(summary: 'Keep me'));
      final renamed = scan.copyWith(productName: 'Renamed');

      expect(renamed.insight?.summary, 'Keep me', reason: 'Every unrelated copyWith call in the app would otherwise wipe the insight.');
    });
  });
}

/// Not part of the app — a test-only helper so the legacy-scan case can assert
/// the UI-facing concern list without importing the widget tree.
extension ScanResultTestHelpers on ScanResult {
  List<String> get rankedConcernTitlesForTest => insight?.rankedConcerns.map((c) => c.title).toList() ?? const [];
}
