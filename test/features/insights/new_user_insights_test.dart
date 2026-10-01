import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/app_theme.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/features/insights/presentation/pages/insights_screen.dart';
import 'package:gutgood/features/insights/presentation/pages/smart_insight_detail_screen.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/insight_bento_feed.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/v2_feed.dart';
import 'package:provider/provider.dart';

class FakeInsightsNotifier extends ChangeNotifier implements InsightsNotifier {
  FakeInsightsNotifier({
    this.fakeLatestInsight,
    this.fakeIsSufficient = false,
    this.fakeIsLoading = false,
    this.fakeIsGenerating = false,
    this.fakeTotalMeals = 0,
    this.fakeTotalSymptoms = 0,
    this.fakeTotalScans = 0,
  });

  final AIInsight? fakeLatestInsight;
  final bool fakeIsSufficient;
  final bool fakeIsLoading;
  final bool fakeIsGenerating;
  final int fakeTotalMeals;
  final int fakeTotalSymptoms;
  final int fakeTotalScans;

  @override
  String? get errorMessage => null;

  @override
  Future<void> retry() async {}

  @override
  AIInsight? get latestInsight => fakeLatestInsight;

  @override
  GutScoreRecord? get latestScoreRecord => null;

  @override
  bool get isSufficient => fakeIsSufficient;

  @override
  bool get isLoading => fakeIsLoading;

  @override
  bool get isGenerating => fakeIsGenerating;

  @override
  int get totalMeals => fakeTotalMeals;

  @override
  int get totalSymptoms => fakeTotalSymptoms;

  @override
  int get totalScans => fakeTotalScans;

  @override
  int get totalFoodScans => fakeTotalScans + fakeTotalMeals;

  @override
  int get todayMeals => fakeTotalMeals;

  @override
  int get todaySymptoms => fakeTotalSymptoms;

  @override
  int get todayScans => fakeTotalScans;

  @override
  int get todayFoodScans => fakeTotalScans + fakeTotalMeals;

  @override
  List<AIInsight> get insightHistory => fakeLatestInsight != null ? [fakeLatestInsight!] : [];

  @override
  List<BodyPattern> get prioritizedPatterns => fakeLatestInsight?.detectedPatterns ?? [];

  @override
  List<HealthAlert> get healthAlerts => [];

  @override
  GutExperiment? get activeExperiment => null;

  @override
  Future<void> generateNewInsight() async {}

  @override
  Future<void> markAllAlertsAsRead() async {}

  @override
  Future<void> startExperiment(InsightAction action, {int targetDays = 7, String? triggerFood}) async {}

  @override
  Future<void> recordDailyCheckIn({required bool adhered, required bool hadSymptoms, String? notes}) async {}

  @override
  Future<void> completeActiveExperiment({String? outcomeSummary}) async {}

  @override
  Future<void> cancelActiveExperiment() async {}
}

void main() {
  Widget buildTestableWidget(InsightsNotifier notifier) => MaterialApp(
    theme: AppTheme.lightTheme,
    home: Builder(
      builder: (context) {
        Responsive.init(context);
        return ChangeNotifierProvider<InsightsNotifier>.value(value: notifier, child: const InsightsScreen());
      },
    ),
  );

  testWidgets('New user with no insight shows learning grid without mock data', (WidgetTester tester) async {
    final notifier = FakeInsightsNotifier(fakeLatestInsight: null, fakeIsSufficient: false);

    await tester.pumpWidget(buildTestableWidget(notifier));
    await tester.pumpAndSettle();

    // Should render InsightBentoLearning
    expect(find.byType(InsightBentoLearning), findsOneWidget);
    expect(find.textContaining('Your food'), findsWidgets);
    expect(find.text('0 / 3'), findsOneWidget);

    // Should NOT show mock gut score 78 or mock trigger texts
    expect(find.text('78'), findsNothing);
    expect(find.textContaining('Fried Foods → Bloating'), findsNothing);
  });

  testWidgets('Existing user with real insight shows V2InsightsFeed with real score', (WidgetTester tester) async {
    final realInsight = AIInsight(gutScore: 85, scoreDiff: '+5', updatedAt: DateTime.now());

    final notifier = FakeInsightsNotifier(fakeLatestInsight: realInsight, fakeIsSufficient: true);

    await tester.pumpWidget(buildTestableWidget(notifier));
    await tester.pumpAndSettle();

    // Should NOT show InsightBentoLearning
    expect(find.byType(InsightBentoLearning), findsNothing);
    expect(find.byType(V2InsightsFeed), findsOneWidget);

    // Should display real score 85
    expect(find.text('85'), findsAtLeastNWidgets(1));
  });
  final baseline = AIInsight.fromMap({
    'status': 'ready',
    'topInsight': {
      'title': 'Exploring Energy Levels After Meals',
      'description': 'You logged chicken and broccoli and reported feeling energetic. Repeated associations are not established.',
      'kind': 'progress',
      'strength': 'Medium',
      'involvedFoods': ['roasted chicken', 'broccoli'],
      'nextSteps': ['Record meal timing and how you feel.'],
    },
    'healing': null,
    'triggers': null,
    'detectedPatterns': [],
    'foodImpactBalance': null,
    'foodImpacts': [],
    'foodSwaps': [],
    'actions': [
      {'id': 'action_1', 'title': 'Monitor Meal Combinations', 'description': 'Log meals and reported energy.'},
    ],
  });

  for (final dark in [false, true]) {
    testWidgets('baseline has useful empty states in all four tabs (${dark ? 'dark' : 'light'})', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final notifier = FakeInsightsNotifier(fakeLatestInsight: baseline, fakeIsSufficient: true);
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
          home: Builder(
            builder: (context) {
              Responsive.init(context);
              return ChangeNotifierProvider<InsightsNotifier>.value(value: notifier, child: const InsightsScreen());
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Your Journal Snapshot'), findsOneWidget);
      expect(find.text('Your baseline is taking shape'), findsOneWidget);
      expect(find.text('Monitor Meal Combinations'), findsOneWidget);
      expect(find.text('85'), findsNothing);
      for (final entry in {'Patterns': 'No repeated patterns yet', 'Food Impact': 'Food effects are still unknown', 'Weekly Recap': 'Your weekly recap is taking shape'}.entries) {
        await tester.ensureVisible(find.text(entry.key));
        await tester.tap(find.text(entry.key));
        await tester.pumpAndSettle();
        expect(find.text(entry.value), findsOneWidget);
        expect(find.text('Log a meal or symptom'), findsOneWidget);
        expect(find.text('Logged meals consistently this week.'), findsNothing);
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('new users can access every tab before generating an insight', (tester) async {
    await tester.pumpWidget(buildTestableWidget(FakeInsightsNotifier()));
    await tester.pumpAndSettle();
    for (final tab in ['Patterns', 'Food Impact', 'Weekly Recap', 'For You']) {
      await tester.ensureVisible(find.text(tab));
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      expect(find.byType(V2InsightsFeed), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    expect(find.text('0 / 3'), findsOneWidget);
  });

  testWidgets('empty tabs fit narrow screens with large text and navigate to logging', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = GoRouter(
      initialLocation: '/insights',
      routes: [
        GoRoute(
          path: '/insights',
          builder: (_, _) => Builder(
            builder: (context) {
              Responsive.init(context);
              return const Scaffold(
                body: CustomScrollView(slivers: [V2InsightsFeed(data: null, patterns: [])]),
              );
            },
          ),
        ),
        GoRoute(
          path: AppRoutes.chat,
          builder: (_, _) => const Scaffold(body: Text('Journal destination')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final tab in ['For You', 'Patterns', 'Weekly Recap', 'Food Impact']) {
      await tester.ensureVisible(find.text(tab));
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await tester.ensureVisible(find.text('Log a meal or symptom'));
    await tester.tap(find.text('Log a meal or symptom'));
    await tester.pumpAndSettle();
    expect(find.text('Journal destination'), findsOneWidget);
  });

  testWidgets('baseline detail never displays pattern confidence or evidence metrics', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) {
            Responsive.init(context);
            return ChangeNotifierProvider<InsightsNotifier>.value(
              value: FakeInsightsNotifier(fakeLatestInsight: baseline),
              child: SmartInsightDetailScreen(insight: baseline.topInsight!),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('BASELINE SUMMARY'), findsOneWidget);
    expect(find.textContaining('CONFIDENCE'), findsNothing);
    expect(find.text('The Evidence'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
