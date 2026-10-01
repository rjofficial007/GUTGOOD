import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/constants/storage_keys.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/services/ai_service.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/crashlytics_service.dart';
import 'package:gutgood/core/services/firestore/chat_firestore_service.dart';
import 'package:gutgood/core/services/firestore/history_firestore_service.dart';
import 'package:gutgood/core/services/firestore/insight_firestore_service.dart';
import 'package:gutgood/features/auth/domain/repositories/auth_repository.dart';
import 'package:gutgood/features/insights/data/repositories/insight_repository_impl.dart';
import 'package:gutgood/features/insights/domain/repositories/insight_repository.dart';
import 'package:gutgood/features/insights/domain/usecases/build_unified_journal_usecase.dart';
import 'package:gutgood/features/insights/domain/usecases/generate_insight_usecase.dart';
import 'package:gutgood/features/insights/domain/usecases/summarize_journal_usecase.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Ai extends Mock implements AiService {}

class _Analytics extends Mock implements AnalyticsService {}

class _Crashlytics extends Mock implements CrashlyticsService {}

class _History extends Mock implements HistoryFirestoreService {}

class _Insights extends Mock implements InsightFirestoreService {}

class _Chat extends Mock implements ChatFirestoreService {}

class _Repository extends Mock implements InsightRepository {}
class _Auth extends Mock implements AuthRepository {}
class _Generate extends Mock implements GenerateInsightUseCase {}

void main() {
  late _Ai ai;
  late _Insights cloud;
  late SharedPreferences prefs;
  late InsightRepositoryImpl repository;
  final now = DateTime(2026, 10, 1, 18);
  final snapshot = AIInsight(gutScore: 42, updatedAt: now);

  setUpAll(() {
    registerFallbackValue(now);
    registerFallbackValue(snapshot);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({StorageKeys.gutgoodInsightsCache: 'previous snapshot'});
    prefs = await SharedPreferences.getInstance();
    ai = _Ai();
    cloud = _Insights();
    final analytics = _Analytics();
    final history = _History();
    when(
      () => analytics.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});
    when(() => history.getRecentScans(since: any(named: 'since'))).thenAnswer((_) async => []);
    repository = InsightRepositoryImpl(
      historyFirestoreService: history,
      insightFirestoreService: cloud,
      chatFirestoreService: _Chat(),
      aiService: ai,
      prefs: prefs,
      analyticsService: analytics,
      crashlyticsService: _Crashlytics(),
    );
  });

  for (final hasPreviousInsight in [false, true]) {
    testWidgets('daily counts arriving after dashboard still trigger generation (previous insight: $hasPreviousInsight)', (tester) async {
      final repo = _Repository();
      final auth = _Auth();
      final generate = _Generate();
      final analytics = _Analytics();
      final meals = Completer<List<MealLog>>();
      when(() => auth.authStateChanges).thenAnswer((_) => const Stream.empty());
      when(repo.getDashboardStateStream).thenAnswer((_) => Stream.value(InsightsDashboardState(latestInsight: hasPreviousInsight ? snapshot : null)));
      when(repo.getInsightHistory).thenAnswer((_) async => []);
      when(repo.getActiveExperiment).thenAnswer((_) async => null);
      when(repo.getActiveExperimentStream).thenAnswer((_) => const Stream.empty());
      when(() => repo.getRecentMeals(any())).thenAnswer((_) => meals.future);
      when(() => repo.getRecentSymptoms(any())).thenAnswer((_) async => [SymptomLog(symptom: 'Bloating', createdAt: DateTime.now())]);
      when(() => repo.getRecentScans(any())).thenAnswer((_) async => []);
      when(() => analytics.logEvent(name: any(named: 'name'), parameters: any(named: 'parameters'))).thenAnswer((_) async {});
      when(generate.execute).thenAnswer((_) async {});
      final notifier = InsightsNotifier(repo, AppStateServiceImpl(), auth, analytics, generate);
      await tester.pump(const Duration(milliseconds: 600));
      verifyNever(generate.execute);
      meals.complete(List.generate(3, (_) => MealLog(items: const ['Oats'], createdAt: DateTime.now())));
      await tester.pump();
      verify(generate.execute).called(1);
      notifier.dispose();
    });
  }

  test('journal uses occurrence order, and short historical context is retained', () async {
    final journal = const BuildUnifiedJournalUseCase().execute(
      meals: [
        MealLog(items: const ['Oats'], createdAt: now, occurredAt: DateTime(2026, 10, 1, 8)),
      ],
      symptoms: [SymptomLog(symptom: 'Bloating', createdAt: now.subtract(const Duration(hours: 1)), occurredAt: DateTime(2026, 10, 1, 10))],
      scans: [],
    );
    expect(journal.indexOf('ATE:'), lessThan(journal.indexOf('FEELING:')));
    expect(journal, contains('2026-10-01 08:00: ATE:'));
    expect(await SummarizeJournalUseCase(aiService: ai).execute(journal), journal);
    verifyZeroInteractions(ai);
  });

  test('failed persistence preserves the previous cached insight and throws', () async {
    when(() => cloud.saveInsights(any())).thenAnswer((_) async => null);
    await expectLater(repository.saveInsight(snapshot), throwsStateError);
    expect(prefs.getString(StorageKeys.gutgoodInsightsCache), 'previous snapshot');
  });

  test('successful persistence caches the final deterministic score', () async {
    when(() => cloud.saveInsights(any())).thenAnswer((_) async => 'saved');
    await repository.saveInsight(snapshot);
    final cached = jsonDecode(prefs.getString(StorageKeys.gutgoodInsightsCache)!) as Map<String, dynamic>;
    expect(AIInsight.fromMap(cached).gutScore, 42);
  });

  for (final badResponse in [
    '{"status": "ready", BROKEN}',
    jsonEncode({
      'status': 'ready',
      'topInsight': {
        'title': 'Snapshot',
        'description': 'Oats logged.',
        'nextSteps': ['Track timing'],
        'involvedFoods': 'wrong type',
      },
    }),
  ]) {
    test('invalid JSON or nested model shape retries before accepting an insight: $badResponse', () async {
      final responses = [
        badResponse,
        jsonEncode({
          'status': 'ready',
          'topInsight': {
            'kind': 'progress',
            'title': 'First logs',
            'description': 'Oats and bloating logged.',
            'nextSteps': ['Record symptom timing.'],
          },
          'detectedPatterns': [
            {'trigger': 'Invented', 'frequency': 99},
          ],
        }),
      ];
      var calls = 0;
      when(
        () => ai.generateContent(
          prompt: any(named: 'prompt'),
          promptVersion: any(named: 'promptVersion'),
        ),
      ).thenAnswer((_) async => responses[calls++]);
      final insight = await repository.analyzeGutHealth(
        goals: [],
        sensitivities: [],
        lifestyle: [],
        cyclePhase: 'Not specified',
        chatSummary: null,
        chatHistory: [],
        recentJournalText: 'Oats and bloating logged.',
        historicalJournalSummary: null,
        scoreHistory: null,
        patternCandidates: [],
      );
      expect(calls, 2);
      expect(insight.topInsight?.type, 'progress');
      expect(insight.detectedPatterns, isEmpty);
      expect(prefs.getString(StorageKeys.gutgoodInsightsCache), 'previous snapshot');
    });
  }
}
