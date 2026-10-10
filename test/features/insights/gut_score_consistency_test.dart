import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/app/theme/app_theme.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/profile_header.dart';
import 'package:gutgood/features/insights/presentation/pages/highlight_detail_screen.dart';
import 'package:gutgood/features/insights/presentation/widgets/gut_score_card.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_feed/insights_feed.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_score_card.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:provider/provider.dart';

class ScoreProfile extends ChangeNotifier implements ProfileNotifier {
  ScoreProfile(this.record);
  GutScoreRecord record;
  @override
  GutScoreRecord get latestScoreRecord => record;
  @override
  int get gutScore => record.gutScore;
  @override
  bool get hasGutScore => record.hasScore;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final now = DateTime.now();
  GutScoreRecord record(int score, {bool hasData = true}) => GutScoreRecord(
    id: 'current',
    uid: 'user',
    type: 'weekly',
    scansCount: hasData ? 1 : 0,
    mealsCount: 2,
    symptomsCount: 1,
    dailyScores: [
      for (var i = 0; i < 7; i++)
        if (i == now.weekday % 7) score else 0,
    ],
    scoredDayIndices: [if (hasData) now.weekday % 7],
    periodFrom: DateTime(now.year, now.month, now.day - now.weekday % 7),
    periodTo: now,
    createdAt: now,
  );
  final snapshot = AIInsight(
    gutScore: 74,
    updatedAt: now,
    weeklyRecap: WeeklyRecap(
      avgScore: 31,
      gutScoreTrend: const [31, 0, 0, 0, 0, 0, 0],
      foodsLogged: 12,
      periodFrom: DateTime(2026, 9, 27),
      periodTo: DateTime(2026, 10, 3, 23, 59, 59),
    ),
  );
  Widget host(Widget child, {ScoreProfile? profile}) =>
      ChangeNotifierProvider<ProfileNotifier>.value(
        value: profile ?? ScoreProfile(record(70)),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) {
              Responsive.init(context);
              return child;
            },
          ),
        ),
      );

  testWidgets('Profile renders the gut score instead of average food quality', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        Scaffold(
          body: ProfileHeader(
            name: 'User',
            email: '',
            isPremium: false,
            onImageTap: () {},
            streak: 0,
            gutScore: 70,
            avgFoodScore: 74,
          ),
        ),
      ),
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is RichText && widget.text.toPlainText() == '70/100',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is RichText && widget.text.toPlainText() == '74/100',
      ),
      findsNothing,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'For You and its open score sheet react to the same current record',
    (tester) async {
      final profile = ScoreProfile(record(70));
      await tester.pumpWidget(
        host(
          Scaffold(
            body: CustomScrollView(
              slivers: [InsightsFeed(data: snapshot, patterns: const [])],
            ),
          ),
          profile: profile,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<GutScoreCard>(find.byType(GutScoreCard)).score, 70);
      await tester.tap(find.byType(GutScoreCard));
      await tester.pumpAndSettle();
      expect(find.text('Why 70?'), findsOneWidget);
      expect(find.text('1 of 7 days scored'), findsOneWidget);
      expect(find.text('2 meal logs and 1 food scan'), findsOneWidget);
      expect(find.textContaining('12 meals'), findsNothing);
      profile
        ..record = record(82)
        ..notifyListeners();
      await tester.pumpAndSettle();
      expect(find.text('Why 82?'), findsOneWidget);
      expect(tester.widget<GutScoreCard>(find.byType(GutScoreCard)).score, 82);
    },
  );

  testWidgets(
    'Weekly Recap shows its weekly average and Progress uses the current score',
    (tester) async {
      final profile = ScoreProfile(record(70));
      await tester.pumpWidget(
        host(
          Scaffold(
            body: SingleChildScrollView(child: WeeklyRecapView(data: snapshot)),
          ),
          profile: profile,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Your Weekly Recap'), findsOneWidget);
      expect(find.text('31'), findsOneWidget);
      await tester.pumpWidget(
        host(
          const HighlightDetailScreen(
            args: HighlightDetailArgs(
              tag: 'Progress',
              emoji: '🌱',
              title: 'Your progress',
              accentColor: 0xFF1F7A3D,
              backgroundColor: 0xFFE7F6E7,
              chartType: 'healing',
              chartValues: [31],
            ),
          ),
          profile: profile,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('70'), findsOneWidget);
      expect(find.text('31'), findsNothing);
    },
  );

  testWidgets(
    'a real zero is shown and an empty record suppresses the stale score',
    (tester) async {
      final profile = ScoreProfile(record(0));
      await tester.pumpWidget(
        host(
          Scaffold(
            body: CustomScrollView(
              slivers: [InsightsFeed(data: snapshot, patterns: const [])],
            ),
          ),
          profile: profile,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<GutScoreCard>(find.byType(GutScoreCard)).score, 0);
      await tester.tap(find.byType(GutScoreCard));
      await tester.pumpAndSettle();
      expect(find.text('Why 0?'), findsOneWidget);
      expect(find.text('1 of 7 days scored'), findsOneWidget);
      profile
        ..record = record(0, hasData: false)
        ..notifyListeners();
      await tester.pumpAndSettle();
      expect(find.text('Score unavailable'), findsOneWidget);
      expect(find.byType(InsightScoreCard), findsOneWidget);
      expect(find.byType(GutScoreCard), findsNothing);
    },
  );
}
