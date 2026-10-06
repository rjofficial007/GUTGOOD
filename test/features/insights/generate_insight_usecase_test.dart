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
import 'package:gutgood/infrastructure/firebase/firestore/gut_score_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/notification_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockInsightRepository extends Mock implements InsightRepository {}

class MockAuthFirestoreService extends Mock implements AuthFirestoreService {}

class MockAiClient extends Mock implements AiClient {}

class MockPatternEngineService extends Mock implements PatternEngineService {}

class MockNotificationService extends Mock implements NotificationService {}

class MockGutScoreFirestoreService extends Mock implements GutScoreFirestoreService {}

ScanResult _scan(String id, int score, DateTime at) =>
    ScanResult(productName: 'Scanned oats', brand: 'Brand', scanId: id, score: score, impactType: ImpactType.positive, impact: 'Good', category: 'food', createdAt: at);

void main() {
  late MockInsightRepository repository;
  late MockAuthFirestoreService auth;
  late MockPatternEngineService patternEngine;
  late MockNotificationService notifications;
  late MockGutScoreFirestoreService scoreStore;
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
    registerFallbackValue(
      GutScoreRecord(
        id: '',
        uid: '',
        type: 'weekly',
        scansCount: 0,
        mealsCount: 0,
        symptomsCount: 0,
        periodFrom: DateTime(2026, 1, 1),
        periodTo: DateTime(2026, 1, 7),
        createdAt: DateTime(2026, 1, 1),
      ),
    );
  });

  setUp(() {
    now = DateTime.now();
    repository = MockInsightRepository();
    auth = MockAuthFirestoreService();
    patternEngine = MockPatternEngineService();
    notifications = MockNotificationService();
    scoreStore = MockGutScoreFirestoreService();
    generatedInsight = AIInsight(
      gutScore: 0,
      hasGutScore: false,
      model: 'test-model',
      topInsight: const InsightSummary(
        title: 'Food and symptom snapshot',
        description: 'You logged food and reported a symptom today.',
        type: 'progress',
        nextSteps: ['Record when the symptom starts.'],
      ),
      updatedAt: now,
    );

    when(() => auth.getUserMetadata()).thenAnswer((_) async => UserProfile(uid: 'user', createdAt: now, updatedAt: now));
    when(() => repository.getLatestInsight()).thenAnswer((_) async => null);
    when(() => patternEngine.runAnalysis()).thenAnswer((_) async => const []);
    when(() => repository.getInsightHistory()).thenAnswer((_) async => const []);
    when(() => repository.getLatestPatterns()).thenAnswer((_) async => const []);
    when(() => repository.getRecentChat(any())).thenAnswer((_) async => const []);
    when(() => repository.saveInsight(any())).thenAnswer((_) async {});
    when(() => repository.saveHealthAlert(any())).thenAnswer((_) async {});
    when(
      () => repository.analyzeGutHealth(
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
      ),
    ).thenAnswer((_) async => generatedInsight);
    when(() => notifications.showInsightGeneratedNotification()).thenAnswer((_) async {});
    when(() => scoreStore.saveGutScore(any())).thenAnswer((_) async {});
    when(() => scoreStore.getLatestGutScore()).thenAnswer((_) async => null);
  });

  Future<GenerateInsightUseCase> createUseCase() async {
    SharedPreferences.setMockInitialValues({'${StorageKeys.lastInsightRun}_user': now.toUtc().toIso8601String()});
    final prefs = await SharedPreferences.getInstance();
    final currentWeekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday % 7));
    final previousWeekAt = currentWeekStart.subtract(const Duration(days: 6)).add(const Duration(hours: 9));
    final meals = [
      MealLog(items: const ['Previous oats'], scanId: 'scan-1', journalEntryId: 'scan-1_meal', createdAt: previousWeekAt),
      MealLog(items: const ['Previous rice'], createdAt: previousWeekAt.add(const Duration(hours: 1))),
      MealLog(items: const ['Previous dal'], createdAt: previousWeekAt.add(const Duration(hours: 2))),
      MealLog(items: const ['Today oats'], scanId: 'current-scan', journalEntryId: 'current-scan_meal', createdAt: now),
      MealLog(items: const ['Today rice'], createdAt: now),
      MealLog(items: const ['Today dal'], createdAt: now),
    ];
    final scans = [_scan('scan-1', 80, previousWeekAt), _scan('legacy-scan', 70, previousWeekAt), _scan('current-scan', 85, now)];
    final symptoms = [
      SymptomLog(symptom: 'Previous bloating', severity: 3, createdAt: previousWeekAt.add(const Duration(hours: 3))),
      SymptomLog(symptom: 'Today bloating', severity: 3, createdAt: now.subtract(const Duration(minutes: 1))),
    ];

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
      gutScoreFirestoreService: scoreStore,
    );
  }

  test('force refresh bypasses the same-day guard and saves a deduplicated insight', () async {
    final useCase = await createUseCase();

    await useCase.execute();
    verifyNever(
      () => repository.analyzeGutHealth(
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
      ),
    );

    await useCase.execute(force: true);

    verify(
      () => repository.analyzeGutHealth(
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
      ),
    ).called(1);
    final saved = verify(() => repository.saveInsight(captureAny())).captured.last as AIInsight;
    expect(saved.status, AIInsight.statusReady);
    expect(saved.gutScore, 84);
    verifyNever(() => scoreStore.saveGutScore(any()));
    // The recap uses the completed previous week, while the current-week logs
    // remain part of the broader insight evidence envelope.
    expect(saved.weeklyRecap?.foodsLogged, 4);
    expect(saved.weeklyRecap?.periodTo, isNotNull);
    expect(saved.evidence?.sampleSizes.meals, 6);
    expect(saved.evidence?.sampleSizes.scans, 1);
    expect(saved.evidence?.sampleSizes.symptoms, 2);
    verify(() => patternEngine.runAnalysis()).called(1);
    verify(() => notifications.showInsightGeneratedNotification()).called(1);
  });

  test('saves an evidence-backed weekly recap even when daily AI threshold is not met', () async {
    final useCase = await createUseCase();
    final weekStart = GutScoreCalculatorService.startOfLocalWeek(now);
    final priorWeekAt = weekStart.subtract(const Duration(days: 1)).add(const Duration(hours: 9));
    when(() => repository.getRecentMeals(any())).thenAnswer((_) async => [MealLog(items: const ['Oats'], createdAt: priorWeekAt)]);
    when(() => repository.getRecentSymptoms(any())).thenAnswer((_) async => const []);
    when(() => repository.getRecentScans(any())).thenAnswer((_) async => [_scan('weekly', 80, priorWeekAt)]);

    await useCase.execute(force: true);

    final saved = verify(() => repository.saveInsight(captureAny())).captured.single as AIInsight;
    expect(saved.weeklyRecap?.foodsLogged, 2);
    expect(saved.weeklyRecap?.periodFrom, isNotNull);
    expect(saved.hasGutScore, isFalse);
    verifyNever(
      () => repository.analyzeGutHealth(
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
      ),
    );
  });

  test('a slow model uses a newer authoritative score without rewriting it', () async {
    final useCase = await createUseCase();
    final updatedAt = now.add(const Duration(seconds: 5));
    final record = const GutScoreCalculatorService().calculateWeeklyRecord(uid: 'user', asOf: updatedAt, scans: [_scan('newer', 93, now)], meals: const [], symptoms: const []);
    when(() => scoreStore.getLatestGutScore()).thenAnswer((_) async => record);

    await useCase.execute(force: true);

    final saved = verify(() => repository.saveInsight(captureAny())).captured.last as AIInsight;
    expect(saved.gutScore, 95);
    expect(saved.hasGutScore, isTrue);
    verifyNever(() => scoreStore.saveGutScore(any()));
  });

  test('an account change during generation cancels the insight save', () async {
    final useCase = await createUseCase();
    var metadataReads = 0;
    when(() => auth.getUserMetadata()).thenAnswer((_) async => UserProfile(uid: metadataReads++ == 0 ? 'user' : 'other', createdAt: now, updatedAt: now));
    await useCase.execute(force: true);
    verifyNever(() => repository.saveInsight(any()));
    verifyNever(() => notifications.showInsightGeneratedNotification());
  });

  test('generation retains the authoritative score even when its record predates the model run', () async {
    final useCase = await createUseCase();
    final recordedAt = now.subtract(const Duration(seconds: 1));
    final record = const GutScoreCalculatorService().calculateWeeklyRecord(uid: 'user', asOf: recordedAt, scans: [_scan('stored', 93, recordedAt)], meals: const [], symptoms: const []);
    when(() => scoreStore.getLatestGutScore()).thenAnswer((_) async => record);
    await useCase.execute(force: true);
    final saved = verify(() => repository.saveInsight(captureAny())).captured.last as AIInsight;
    expect(saved.gutScore, record.gutScore);
    verifyNever(() => scoreStore.saveGutScore(any()));
  });

  test('a recap refresh also cancels when the active user changes', () async {
    final useCase = await createUseCase();
    var metadataReads = 0;
    when(() => auth.getUserMetadata()).thenAnswer((_) async => UserProfile(uid: metadataReads++ == 0 ? 'user' : 'other', createdAt: now, updatedAt: now));
    when(() => repository.getRecentMeals(any())).thenAnswer((_) async => const []);
    when(() => repository.getRecentSymptoms(any())).thenAnswer((_) async => const []);
    when(() => repository.getLatestInsight()).thenAnswer((_) async => generatedInsight);
    await useCase.execute(force: true);
    verifyNever(() => repository.saveInsight(any()));
  });
}
