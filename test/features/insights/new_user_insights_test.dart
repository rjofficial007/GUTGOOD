import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/app/theme/app_theme.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/features/insights/presentation/pages/highlight_detail_screen.dart';
import 'package:gutgood/features/insights/presentation/pages/insights_screen.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/insight_bento_feed.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_feed/insights_feed.dart';
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
  bool get isGeneratingAiInterpretation => false;

  @override
  String? get aiInterpretationError => null;

  @override
  InsightAiInterpretation? aiInterpretationFor(AIInsight insight) => insight.aiInterpretation;

  @override
  int get totalMeals => fakeTotalMeals;

  @override
  int get totalSymptoms => fakeTotalSymptoms;

  @override
  int get totalScans => fakeTotalScans;

  @override
  int get totalFoodScans => fakeTotalMeals;

  @override
  int get todayMeals => fakeTotalMeals;

  @override
  int get todaySymptoms => fakeTotalSymptoms;

  @override
  int get todayScans => fakeTotalScans;

  @override
  int get todayFoodScans => fakeTotalMeals;

  @override
  List<AIInsight> get insightHistory => fakeLatestInsight != null ? [fakeLatestInsight!] : [];

  @override
  List<BodyPattern> get prioritizedPatterns => fakeLatestInsight?.detectedPatterns ?? [];

  @override
  List<HealthAlert> get healthAlerts => [];

  @override
  GutExperiment? get activeExperiment => null;

  @override
  Future<void> generateNewInsight({bool force = false}) async {}

  @override
  Future<void> generateAiInterpretation(AIInsight insight) async {}

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

  testWidgets('Existing user with real insight shows InsightsFeed with real score', (WidgetTester tester) async {
    final realInsight = AIInsight(gutScore: 85, scoreDiff: '+5', updatedAt: DateTime.now());

    final notifier = FakeInsightsNotifier(fakeLatestInsight: realInsight, fakeIsSufficient: true);

    await tester.pumpWidget(buildTestableWidget(notifier));
    await tester.pumpAndSettle();

    // Should NOT show InsightBentoLearning
    expect(find.byType(InsightBentoLearning), findsNothing);
    expect(find.byType(InsightsFeed), findsOneWidget);

    // Should display real score 85
    expect(find.text('85'), findsAtLeastNWidgets(1));
  });

  testWidgets('Empty contributing foods shows guidance instead of example foods', (WidgetTester tester) async {
    const args = HighlightDetailArgs(
      tag: 'Improving',
      title: 'Food and symptom snapshot',
      accentColor: 0xFF1F7A3D,
      backgroundColor: 0xFFE7F6E7,
      chartType: 'healing',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) {
            Responsive.init(context);
            return const HighlightDetailScreen(args: args);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No recurring pattern yet'), findsOneWidget);
    expect(find.text('Vegetable Fiber'), findsNothing);
    expect(find.text('Fermented Foods'), findsNothing);
    expect(find.text('High Impact'), findsNothing);
  });
}
