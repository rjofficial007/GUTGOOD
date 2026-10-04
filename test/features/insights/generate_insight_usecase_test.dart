import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/ai/client/ai_client.dart';
import 'package:gutgood/core/constants/storage_keys.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/services/gut_score_calculator_service.dart';
import 'package:gutgood/features/insights/application/usecases/generate_insight_usecase.dart';
import 'package:gutgood/features/insights/application/usecases/summarize_journal_usecase.dart';
import 'package:gutgood/features/insights/data/services/pattern_engine_service.dart';
import 'package:gutgood/features/insights/domain/repositories/insight_repository.dart';
import 'package:gutgood/features/insights/domain/usecases/build_unified_journal_usecase.dart';
import 'package:gutgood/features/insights/domain/usecases/check_insight_threshold_usecase.dart';
import 'package:gutgood/infrastructure/firebase/firestore/auth_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/notification_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockInsightRepository extends Mock implements InsightRepository {}

class MockAuthFirestoreService extends Mock implements AuthFirestoreService {}

class MockAiClient extends Mock implements AiClient {}

class MockPatternEngineService extends Mock implements PatternEngineService {}

class MockNotificationService extends Mock implements NotificationService {}

ScanResult _scan(String id, int score, DateTime at) => ScanResult(
  productName: 'Scanned oats',
  brand: 'Brand',
  scanId: id,
  score: score,
  impactType: ImpactType.positive,
  impact: 'Good',
  category: 'food',
  createdAt: at,
);

void main() {
  late MockInsightRepository repository;
  late MockAuthFirestoreService auth;
  late MockPatternEngineService patternEngine;
  late MockNotificationService notifications;
  late AIInsight generatedInsight;
  late DateTime now;

  setUpAll(() {
    registerFallbackValue(DateTime(2026, 1, 1));
    registerFallbackValue('fallback');
    registerFallbackValue(0);
    registerFallbackValue(const <String>[]);
    registerFallbackValue(const <ChatMessage>[]);
    registerFallbackValue(const <BodyPattern>[]);
    registerFallbackValue(const <MealLog>[]);
    registerFallbackValue(const <SymptomLog>[]);
    registerFallbackValue(const <ScanResult>[]);
    registerFallbackValue(AIInsight(gutScore: 0, updatedAt: DateTime(2026, 1, 1)));
    registerFallbackValue(HealthAlert(id: '', title: '', message: '', type: '', createdAt: DateTime(2026, 1, 1)));
  });

  setUp(() {
    now = DateTime.now();
    repository = MockInsightRepository();
    auth = MockAuthFirestoreService();
    patternEngine = MockPatternEngineService();
    notifications = MockNotificationService();
    generatedInsight = AIInsight(
      gutScore: 0,
      hasGutScore: false,
      topInsight: const InsightSummary(
        title: 'Food and symptom snapshot',
        description: 'You logged food and reported a symptom today.',
        type: 'progress',
        nextSteps: ['Record when the symptom starts.'],
      ),
      updatedAt: now,
    );

    when(() => auth.getUserMetadata()).thenAnswer((_) async => null);
    when(() => patternEngine.runAnalysis()).thenAnswer((_) async => const []);
    when(() => repository.getInsightHistory()).thenAnswer((_) async => const []);
    when(() => repository.getLatestPatterns()).thenAnswer((_) async => const []);
    when(() => repository.getRecentChat(any())).thenAnswer((_) async => const []);
    when(() => repository.saveInsight(any())).thenAnswer((_) async {});
    when(() => repository.saveHealthAlert(any())).thenAnswer((_) async {});
    when(() => repository.analyzeGutHealth(
          goals: any(named: 'goals'),
          sensitivities: any(named: 'sensitivities'),
          lifestyle: any(named: 'lifestyle'),
          cyclePhase: any(named: 'cyclePhase'),
          chatSummary: any(named: 'chatSummary'),
          chatHistory: any(named: 'chatHistory'),
          recentJournalText: any(named: 'recentJournalText'),
          historicalJournalSummary: any(named: 'historicalJournalSummary'),
          scoreHistory: any(named: 'scoreHistory'),
          patternCandidates: any(named: 'patternCandidates'),
          lastScore: any(named: 'lastScore'),
        )).thenAnswer((_) async => generatedInsight);
    when(() => notifications.showInsightGeneratedNotification()).thenAnswer((_) async {});
  });

  Future<GenerateInsightUseCase> createUseCase() async {
    SharedPreferences.setMockInitialValues({StorageKeys.lastInsightRun: now.toUtc().toIso8601String()});
    final prefs = await SharedPreferences.getInstance();
    final meals = [
      MealLog(items: const ['Oats'], scanId: 'scan-1', journalEntryId: 'scan-1_meal', createdAt: now),
      MealLog(items: const ['Rice'], createdAt: now),
      MealLog(items: const ['Dal'], createdAt: now),
    ];
    final scans = [_scan('scan-1', 80, now), _scan('legacy-scan', 70, now)];
    final symptoms = [SymptomLog(symptom: 'Bloating', severity: 3, createdAt: now.add(const Duration(hours: 1)))];

    when(() => repository.getRecentMeals(any())).thenAnswer((_) async => meals);
    when(() => repository.getRecentSymptoms(any())).thenAnswer((_) async => symptoms);
    when(() => repository.getRecentScans(any())).thenAnswer((_) async => scans);

    return GenerateInsightUseCase(
      insightRepository: repository,
      authFirestoreService: auth,
      checkThreshold: const CheckInsightThresholdUseCase(),
      buildJournal: const BuildUnifiedJournalUseCase(),
      summarizeJournal: SummarizeJournalUseCase(aiService: MockAiClient()),
      prefs: prefs,
      notificationService: notifications,
      patternEngineService: patternEngine,
      gutScoreCalculatorService: const GutScoreCalculatorService(),
    );
  }

  test('force refresh bypasses the same-day guard and saves a deduplicated insight', () async {
    final useCase = await createUseCase();

    await useCase.execute();
    verifyNever(() => repository.analyzeGutHealth(
          goals: any(named: 'goals'),
          sensitivities: any(named: 'sensitivities'),
          lifestyle: any(named: 'lifestyle'),
          cyclePhase: any(named: 'cyclePhase'),
          chatSummary: any(named: 'chatSummary'),
          chatHistory: any(named: 'chatHistory'),
          recentJournalText: any(named: 'recentJournalText'),
          historicalJournalSummary: any(named: 'historicalJournalSummary'),
          scoreHistory: any(named: 'scoreHistory'),
          patternCandidates: any(named: 'patternCandidates'),
          lastScore: any(named: 'lastScore'),
        ));

    await useCase.execute(force: true);

    verify(() => repository.analyzeGutHealth(
          goals: any(named: 'goals'),
          sensitivities: any(named: 'sensitivities'),
          lifestyle: any(named: 'lifestyle'),
          cyclePhase: any(named: 'cyclePhase'),
          chatSummary: any(named: 'chatSummary'),
          chatHistory: any(named: 'chatHistory'),
          recentJournalText: any(named: 'recentJournalText'),
          historicalJournalSummary: any(named: 'historicalJournalSummary'),
          scoreHistory: any(named: 'scoreHistory'),
          patternCandidates: any(named: 'patternCandidates'),
          lastScore: any(named: 'lastScore'),
        )).called(1);
    final saved = verify(() => repository.saveInsight(captureAny())).captured.single as AIInsight;

    expect(saved.status, AIInsight.statusReady);
    expect(saved.weeklyRecap?.foodsLogged, 4);
    expect(saved.evidence?.sampleSizes.meals, 3);
    expect(saved.evidence?.sampleSizes.scans, 1);
    expect(saved.evidence?.sampleSizes.symptoms, 1);
    verify(() => patternEngine.runAnalysis()).called(1);
    verify(() => notifications.showInsightGeneratedNotification()).called(1);
  });
}
