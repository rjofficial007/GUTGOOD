import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/app/theme/app_theme.dart';
import 'package:gutgood/core/models/insights/ai_insight.dart';
import 'package:gutgood/core/models/insights/ai_insight_details.dart';
import 'package:gutgood/core/models/insights/insight_evidence.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_feed/insights_feed.dart';
import 'package:gutgood/features/insights/presentation/widgets/why_score_sheet.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockInsightsNotifier extends Mock implements InsightsNotifier {}

class MockProfileNotifier extends Mock implements ProfileNotifier {}

void main() {
  Widget host(Widget child) => MaterialApp(
    theme: AppTheme.lightTheme,
    home: Builder(
      builder: (context) {
        Responsive.init(context);
        return child;
      },
    ),
  );

  testWidgets('uses the centered empty state for Patterns and keeps the learning banner', (tester) async {
    final insight = AIInsight(gutScore: 70, updatedAt: DateTime.now());

    await tester.pumpWidget(
      host(
        Scaffold(
          body: CustomScrollView(
            slivers: [InsightsFeed(data: insight, patterns: const [], series: const [0, 70, 0, 0, 0, 0, 0])],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Patterns'));
    await tester.pumpAndSettle();

    expect(find.text('Your meals.\nYour reactions.\nYour patterns.'), findsOneWidget);
    expect(find.text('Keep logging your food scans and symptoms to discover recurring body patterns and tailored triggers.'), findsOneWidget);
    expect(find.text('Patterns get smarter over time'), findsOneWidget);
    expect(find.text('Scan food'), findsNothing);
    expect(find.text('Track symptoms'), findsNothing);
  });

  testWidgets('labels a one-scored-day recap as only scored day', (tester) async {
    final insight = AIInsight(
      gutScore: 70,
      updatedAt: DateTime.now(),
      evidence: const InsightEvidence(sampleSizes: SampleSizes(meals: 1)),
      weeklyRecap: WeeklyRecap(
        gutScoreTrend: const [0, 70, 0, 0, 0, 0, 0],
        bestDay: 'Mon',
        dateRange: 'This Week',
        foodsLogged: 1,
        loggedSub: 'meal',
        avgScore: 70,
        scoreSub: '1 of 7 days scored',
        periodFrom: DateTime(2026, 9, 27),
        periodTo: DateTime(2026, 10, 3, 23, 59, 59),
      ),
    );

    await tester.pumpWidget(host(Scaffold(body: SingleChildScrollView(child: WeeklyRecapView(data: insight)))));
    await tester.pumpAndSettle();

    expect(find.text('Only Scored Day'), findsOneWidget);
    expect(find.text('meal'), findsOneWidget);
  });

  testWidgets('uses the screenshot-style empty state before a completed recap exists', (tester) async {
    final insight = AIInsight(
      gutScore: 70,
      updatedAt: DateTime.now(),
      weeklyRecap: const WeeklyRecap(gutScoreTrend: [0, 70, 0, 0, 0, 0, 0]),
    );

    await tester.pumpWidget(host(Scaffold(body: SingleChildScrollView(child: WeeklyRecapView(data: insight)))));
    await tester.pumpAndSettle();

    expect(find.text('Your week.\nYour score.\nYour recap.'), findsOneWidget);
    expect(find.text('Keep logging meals and symptoms this week. Your Sunday–Saturday recap will appear here on Saturday.'), findsOneWidget);
    expect(find.text('Your weekly recap gets clearer over time'), findsOneWidget);
    expect(find.text('Scan food'), findsNothing);
    expect(find.text('Track symptoms'), findsNothing);
  });

  test('makes the current Sunday–Saturday recap available on Saturday', () {
    final saturday = DateTime(2026, 10, 10, 12);
    final recap = WeeklyRecap(
      foodsLogged: 2,
      periodFrom: DateTime(2026, 10, 4),
      periodTo: DateTime(2026, 10, 10, 23, 59, 59),
    );

    expect(isWeeklyRecapAvailable(recap, at: saturday), isTrue);
    expect(isWeeklyRecapAvailable(recap, at: DateTime(2026, 10, 9, 12)), isFalse);
  });

  testWidgets('labels a single current score as a baseline', (tester) async {
    final insight = AIInsight(gutScore: 70, updatedAt: DateTime.now());

    await tester.pumpWidget(
      host(
        Scaffold(
          body: CustomScrollView(
            slivers: [InsightsFeed(data: insight, patterns: const [], series: const [0, 70, 0, 0, 0, 0, 0])],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BASELINE SCORE'), findsOneWidget);
    expect(find.text('Starting baseline'), findsOneWidget);
  });

  testWidgets('current insight score falls back to the profile score while its record stream loads', (tester) async {
    final insight = AIInsight(gutScore: 70, updatedAt: DateTime.now());
    final insights = MockInsightsNotifier();
    final profile = MockProfileNotifier();
    when(() => insights.latestScoreRecord).thenReturn(null);
    when(() => profile.gutScore).thenReturn(74);

    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider<InsightsNotifier>.value(value: insights), ChangeNotifierProvider<ProfileNotifier>.value(value: profile)],
        child: MaterialApp(home: Builder(builder: (context) => Text('${WhyScoreSheet.resolveScore(context, insight)}'))),
      ),
    );

    expect(find.text('74'), findsOneWidget);
  });

  testWidgets('uses neutral copy and styling when no trigger exists', (tester) async {
    final insight = AIInsight(gutScore: 70, updatedAt: DateTime.now());

    await tester.pumpWidget(
      host(
        Scaffold(
          body: CustomScrollView(
            slivers: [
              InsightsFeed(data: insight, patterns: const [], series: const [0, 70, 0, 0, 0, 0, 0]),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pattern Check'), findsOneWidget);
    expect(find.text('No triggers yet'), findsOneWidget);
    final header = tester.widget<Text>(find.text('Pattern Check'));
    expect(header.style?.color, const Color(0xFF334155));
  });

  testWidgets('uses the screenshot-style empty state for Food Impact without evidence', (tester) async {
    final insight = AIInsight(gutScore: 70, updatedAt: DateTime.now());

    await tester.pumpWidget(
      host(
        Scaffold(
          body: CustomScrollView(
            slivers: [InsightsFeed(data: insight, patterns: const [], series: const [0, 70, 0, 0, 0, 0, 0])],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Food Impact'));
    await tester.pumpAndSettle();

    expect(find.text('Your food.\nYour gut.\nYour impact.'), findsOneWidget);
    expect(find.text('Keep scanning foods and logging meals and symptoms to understand how they affect your gut.'), findsOneWidget);
    expect(find.text('Food impacts get clearer over time'), findsOneWidget);
    expect(find.text('Scan food'), findsNothing);
    expect(find.text('Track symptoms'), findsNothing);
  });

  testWidgets('labels a single top insight as an early observation', (tester) async {
    final insight = AIInsight(
      gutScore: 70,
      updatedAt: DateTime.now(),
      topInsight: const InsightSummary(
        title: 'Energy after oats',
        description: 'One observation so far.',
        type: 'Pattern',
        frequency: 1,
      ),
    );

    await tester.pumpWidget(
      host(
        Scaffold(
          body: CustomScrollView(
            slivers: [InsightsFeed(data: insight, patterns: const [], series: const [0, 70, 0, 0, 0, 0, 0])],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Early observation · 1 observation'), findsOneWidget);
  });
}
