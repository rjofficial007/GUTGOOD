import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/services/gut_score_calculator_service.dart';
import 'package:gutgood/features/insights/application/usecases/generate_insight_usecase.dart';
import 'package:gutgood/features/insights/data/services/pattern_engine_service.dart';
import 'package:gutgood/features/insights/domain/repositories/insight_repository.dart';
import 'package:gutgood/features/insights/domain/services/rule_based_insight_builder.dart';
import 'package:gutgood/infrastructure/firebase/firestore/auth_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/gut_score_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/notification_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockInsightRepository extends Mock implements InsightRepository {}

class MockAuthFirestoreService extends Mock implements AuthFirestoreService {}

class MockPatternEngineService extends Mock implements PatternEngineService {}

class MockNotificationService extends Mock implements NotificationService {}

class MockGutScoreFirestoreService extends Mock implements GutScoreFirestoreService {}

ScanResult _scan(String id, int score, DateTime at) =>
    ScanResult(productName: 'Scanned oats', brand: 'Brand', scanId: id, score: score, impactType: ImpactType.positive, impact: 'Good', category: 'food', createdAt: at);

BodyPattern _pattern() => const BodyPattern(
  type: BodyPattern.typeBloating,
  trigger: 'Oats',
  reaction: 'Bloating',
  frequency: 3,
  confidence: BodyPattern.confidenceMedium,
  confidenceScore: 0,
  description: 'Bloating was logged after meals containing Oats.',
  updatedAt: '2026-09-09T00:00:00.000Z',
  totalSimilarMeals: 8,
  timeframeDays: 30,
  evidenceRatio: 0,
  positiveCount: 3,
  negativeCount: 0,
  occurrences: [
    PatternOccurrence(date: '2026-09-01', mealName: 'Oats', reaction: 'Bloating', timeAfter: '2 h'),
    PatternOccurrence(date: '2026-09-05', mealName: 'Oats', reaction: 'Bloating', timeAfter: '1 h'),
    PatternOccurrence(date: '2026-09-09', mealName: 'Oats', reaction: 'Bloating', timeAfter: '2 h'),
  ],
);

void main() {
  late MockInsightRepository repository;
  late MockAuthFirestoreService auth;
  late MockPatternEngineService patternEngine;
  late MockNotificationService notifications;
  late MockGutScoreFirestoreService scoreStore;
  late DateTime now;
  late List<MealLog> meals;
  late List<SymptomLog> symptoms;
  late List<ScanResult> scans;

  setUpAll(() {
    registerFallbackValue(DateTime(2026, 1, 1));
    registerFallbackValue(const <String>[]);
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

    final currentWeekStart = GutScoreCalculatorService.startOfLocalWeek(now);
    final previousWeekAt = currentWeekStart.subtract(const Duration(days: 3)).add(const Duration(hours: 9));
    meals = [
      MealLog(items: const ['Oats'], scanId: 'scan-1', journalEntryId: 'scan-1_meal', createdAt: previousWeekAt),
      MealLog(items: const ['Rice'], createdAt: previousWeekAt.add(const Duration(hours: 1))),
      MealLog(items: const ['Dal'], createdAt: now.subtract(const Duration(hours: 2))),
      MealLog(items: const ['Scanned oats'], scanId: 'current-scan', journalEntryId: 'current-scan_meal', createdAt: now),
    ];
    scans = [_scan('scan-1', 80, previousWeekAt), _scan('legacy-scan', 70, previousWeekAt), _scan('current-scan', 85, now)];
    symptoms = [SymptomLog(symptom: 'Bloating', severity: 3, createdAt: previousWeekAt.add(const Duration(hours: 2)))];

    final profile = UserProfile(uid: 'user', createdAt: now, updatedAt: now);
    when(() => auth.getUserMetadata()).thenAnswer((_) async => profile);
    when(() => repository.getLatestPatterns()).thenAnswer((_) async => const []);
    when(() => repository.getRecentMeals(any())).thenAnswer((_) async => meals);
    when(() => repository.getRecentSymptoms(any())).thenAnswer((_) async => symptoms);
    when(() => repository.getRecentScans(any())).thenAnswer((_) async => scans);
    when(() => repository.saveInsight(any())).thenAnswer((_) async {});
    when(() => repository.saveHealthAlert(any())).thenAnswer((_) async {});
    when(() => patternEngine.runAnalysis(mealData: any(named: 'mealData'), symptomData: any(named: 'symptomData'), scanData: any(named: 'scanData'))).thenAnswer((_) async => const []);
    when(() => notifications.showInsightGeneratedNotification()).thenAnswer((_) async {});
    when(() => scoreStore.getLatestGutScore()).thenAnswer((_) async => null);
  });

  Future<GenerateInsightUseCase> createUseCase({String? lastRun}) async {
    SharedPreferences.setMockInitialValues({'last_insight_run_user': ?lastRun});
    final prefs = await SharedPreferences.getInstance();
    return GenerateInsightUseCase(
      insightRepository: repository,
      authFirestoreService: auth,
      prefs: prefs,
      notificationService: notifications,
      patternEngineService: patternEngine,
      gutScoreCalculatorService: const GutScoreCalculatorService(),
      gutScoreFirestoreService: scoreStore,
    );
  }

  test('refreshes despite a legacy same-day generation timestamp', () async {
    final useCase = await createUseCase(lastRun: now.toUtc().toIso8601String());

    await useCase.execute();

    final saved = verify(() => repository.saveInsight(captureAny())).captured.single as AIInsight;
    expect(saved.firestoreId, RuleBasedInsightBuilder.latestDocumentId);
    expect(saved.origin, AIInsight.originRuleBased);
    expect(saved.type, 'Rule-based');
    expect(saved.status, AIInsight.statusReady);
    expect(saved.evidence?.sampleSizes.meals, meals.length);
    expect(saved.evidence?.sampleSizes.symptoms, symptoms.length);
    // The scan-backed meal is counted once; only the standalone scan remains.
    expect(saved.evidence?.sampleSizes.scans, 1);
    expect(saved.weeklyRecap, isNotNull);
    expect(saved.hasGutScore, isTrue);
    expect(saved.topInsight, isNull);

    verify(() => patternEngine.runAnalysis(mealData: any(named: 'mealData'), symptomData: any(named: 'symptomData'), scanData: any(named: 'scanData'))).called(1);
    verifyNever(() => scoreStore.saveGutScore(any()));
  });

  test('composes a user-facing observation from detected rules without confidence percentages', () async {
    when(() => patternEngine.runAnalysis(mealData: any(named: 'mealData'), symptomData: any(named: 'symptomData'), scanData: any(named: 'scanData'))).thenAnswer((_) async => [_pattern()]);
    final useCase = await createUseCase();

    await useCase.execute();

    final saved = verify(() => repository.saveInsight(captureAny())).captured.single as AIInsight;
    expect(saved.detectedPatterns.single.trigger, 'Oats');
    expect(saved.topInsight?.title, 'Bloating reported after Oats');
    expect(saved.topInsight?.strength, 'Repeated observation');
    expect(saved.topInsight?.evidenceRatio, isNull);
    expect(saved.topInsight?.description, contains('not proof of cause'));
    verify(() => repository.saveHealthAlert(any())).called(1);
    verify(() => notifications.showInsightGeneratedNotification()).called(1);
  });

  test('does not send insight notifications when the user disabled them', () async {
    final profile = UserProfile(
      uid: 'user',
      createdAt: now,
      updatedAt: now,
      notificationPreferences: const {'enableAll': 0, 'insightUpdates': 1},
    );
    when(() => auth.getUserMetadata()).thenAnswer((_) async => profile);
    when(() => patternEngine.runAnalysis(mealData: any(named: 'mealData'), symptomData: any(named: 'symptomData'), scanData: any(named: 'scanData'))).thenAnswer((_) async => [_pattern()]);
    final useCase = await createUseCase();

    await useCase.execute();

    verify(() => repository.saveInsight(any())).called(1);
    verifyNever(() => repository.saveHealthAlert(any()));
    verifyNever(() => notifications.showInsightGeneratedNotification());
  });

  test('saves an insufficient-data status when there are no recent journal records', () async {
    meals = const [];
    symptoms = const [];
    scans = const [];
    when(() => repository.getRecentMeals(any())).thenAnswer((_) async => const []);
    when(() => repository.getRecentSymptoms(any())).thenAnswer((_) async => const []);
    when(() => repository.getRecentScans(any())).thenAnswer((_) async => const []);
    final useCase = await createUseCase();

    await useCase.execute();

    final saved = verify(() => repository.saveInsight(captureAny())).captured.single as AIInsight;
    expect(saved.status, AIInsight.statusInsufficientData);
    expect(saved.detectedPatterns, isEmpty);
    expect(saved.hasGutScore, isFalse);
  });

  test('an account change during generation cancels the insight save', () async {
    var metadataReads = 0;
    when(() => auth.getUserMetadata()).thenAnswer((_) async => UserProfile(uid: metadataReads++ == 0 ? 'user' : 'other', createdAt: now, updatedAt: now));
    final useCase = await createUseCase();

    await useCase.execute(force: true);

    verifyNever(() => repository.saveInsight(any()));
    verifyNever(() => notifications.showInsightGeneratedNotification());
  });

  test('Insights-disabled profiles are not read, analyzed, or saved', () async {
    final profile = UserProfile(uid: 'user', createdAt: now, updatedAt: now, insightsDisabled: true);
    when(() => auth.getUserMetadata()).thenAnswer((_) async => profile);
    final useCase = await createUseCase();

    await useCase.execute();

    verifyNever(() => repository.getRecentMeals(any()));
    verifyNever(() => patternEngine.runAnalysis(mealData: any(named: 'mealData'), symptomData: any(named: 'symptomData'), scanData: any(named: 'scanData')));
    verifyNever(() => repository.saveInsight(any()));
  });
}
