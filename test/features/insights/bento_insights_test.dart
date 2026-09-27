import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/theme/app_theme.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/bento_data.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/bento_widgets.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/insight_bento_feed.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/insight_bento_screens.dart';

/// Pumps a bento sliver inside a themed app with the responsive scale
/// initialised the way `main.dart` does it.
Future<void> pumpBento(WidgetTester tester, Widget sliver, {Brightness brightness = Brightness.light}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: brightness == Brightness.light ? AppTheme.lightTheme : AppTheme.darkTheme,
      home: Builder(
        builder: (context) {
          Responsive.init(context);
          return Scaffold(body: CustomScrollView(slivers: [sliver]));
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

AIInsight buildInsight({int gutScore = 50, String? scoreDiff = '+6'}) => AIInsight(
  gutScore: gutScore,
  scoreDiff: scoreDiff,
  updatedAt: DateTime.utc(2026, 8, 31),
  healingGoal: 'Reduce late sodium',
  triggerSymptom: 'headaches',
  healingTrend: '+18%',
  triggerTrend: '3 LOGS',
  topHealing: const TopHighlight(food: 'Chia seeds', effects: 'Boosted soluble fiber to 28g/day.', timeframe: 'This week', frequency: '5x', emoji: '🥑'),
  topTrigger: const TopHighlight(food: 'Late Iced Coffee', effects: 'Delayed deep sleep by 38m.', timeframe: 'Past 3 PM', frequency: '3x', emoji: '☕'),
  healingFoods: const [
    HealingFood(name: 'Chia seeds', effect: 'Fiber', emoji: '🥑'),
    HealingFood(name: 'Salmon', effect: 'Omega-3', emoji: '🐟'),
  ],
  triggerFoods: const [TriggerFood(name: 'French Fries', effect: 'Sodium', emoji: '🍟')],
  foodImpacts: const [
    FoodImpact(food: 'Berry Oatmeal', dateLabel: 'Mon', effect: 'Booster', timeframeLabel: 'AM', emoji: '🫐', impactType: 'positive'),
    FoodImpact(food: 'Herb Chicken', dateLabel: 'Tue', effect: 'Clean', timeframeLabel: 'PM', emoji: '🍗', impactType: 'positive'),
    FoodImpact(food: 'French Fries', dateLabel: 'Wed', effect: 'Trigger', timeframeLabel: 'PM', emoji: '🍟', impactType: 'negative'),
    FoodImpact(food: 'Crisp Apple', dateLabel: 'Thu', effect: 'Prebiotic', timeframeLabel: 'AM', emoji: '🍎', impactType: 'positive'),
  ],
  weeklyRecap: const WeeklyRecap(
    dateRange: 'Aug 24–31',
    avgScore: 50,
    scoreSub: '68% (4 days)',
    bestDay: 'Saturday',
    foodsLogged: 4,
    loggedSub: 'Oats & berries delivered 28g/day soluble fiber.',
    highlights: [RecapHighlight(icon: 'sparkles', text: 'Morning polyphenols boosted gut barrier', color: 'green')],
  ),
);

const BodyPattern kPattern = BodyPattern(
  type: 'Sodium',
  trigger: 'Fast food dinners',
  reaction: 'headaches',
  frequency: 4,
  confidence: 'High',
  description: '1,650mg sodium past 7 PM sparks vascular tension.',
  involvedFoods: ['Chicken Bowl', 'Apple & Nuts'],
  recommendation: 'Potassium balances sodium.',
  updatedAt: '2026-08-31',
  totalSimilarMeals: 5,
  evidenceRatio: 0.94,
);

void main() {
  group('InsightBentoTheme', () {
    test('resolves from the app themes for both brightnesses', () {
      final light = AppTheme.lightTheme.extension<InsightBentoTheme>();
      final dark = AppTheme.darkTheme.extension<InsightBentoTheme>();
      expect(light, isNotNull);
      expect(dark, isNotNull);
      // Light values are transcribed verbatim from v4.html.
      expect(light!.bento(BentoTone.peach).gradientStart, const Color(0xFFFFF7ED));
      expect(light.bento(BentoTone.coral).tagForeground, const Color(0xFF9F1239));
      expect(light.screenBackground, const Color(0xFFF8F9FA));
      // Dark variants must differ from light for every tone.
      for (final tone in BentoTone.values) {
        expect(light.bento(tone).gradientStart, isNot(dark!.bento(tone).gradientStart), reason: 'tone $tone');
        expect(light.bento(tone).tagForeground, isNot(dark.bento(tone).tagForeground), reason: 'tone $tone');
      }
    });

    test('dark keeps the two-stop ramp instead of collapsing it', () {
      final dark = AppTheme.darkTheme.extension<InsightBentoTheme>()!;
      for (final tone in BentoTone.values.where((t) => t != BentoTone.white)) {
        expect(dark.bento(tone).gradientStart, isNot(dark.bento(tone).gradientEnd), reason: '$tone lost its gradient ramp');
      }
    });

    test('every tone exposes fully opaque slots for both brightnesses', () {
      for (final theme in [AppTheme.lightTheme.extension<InsightBentoTheme>()!, AppTheme.darkTheme.extension<InsightBentoTheme>()!]) {
        for (final tone in BentoTone.values) {
          final p = theme.bento(tone);
          expect(p.gradientStart.a, 1.0, reason: '$tone gradientStart');
          expect(p.border.a, 1.0, reason: '$tone border');
          expect(p.tagBackground.a, 1.0, reason: '$tone tagBackground');
        }
      }
    });
  });

  group('BentoData', () {
    test('parses the display-string scoreDiff into a signed delta', () {
      expect(BentoData.parseDelta('+6'), 6);
      expect(BentoData.parseDelta('-3'), -3);
      expect(BentoData.parseDelta('up 12'), 12);
      expect(BentoData.parseDelta(null), isNull);
      expect(BentoData.parseDelta(''), isNull);
      expect(BentoData.deltaLabel('+6'), '↑ 6 pts');
      expect(BentoData.deltaLabel('-3'), '↓ 3 pts');
      expect(BentoData.deltaLabel('0'), isNull);
    });

    test('bands the score into a status label', () {
      expect(BentoData.statusForScore(80), 'Thriving');
      expect(BentoData.statusForScore(60), 'Steady balance');
      expect(BentoData.statusForScore(40), 'Finding rhythm');
      expect(BentoData.statusForScore(10), 'Building up');
      expect(BentoData.statusForScore(40, delta: 9), 'Strong gain');
    });

    test('groups foodImpacts by lowercased name, highest count first', () {
      final foods = BentoData.topFoods(buildInsight());
      expect(foods, isNotEmpty);
      expect(foods.map((f) => f.name), contains('Berry Oatmeal'));
      expect(foods.firstWhere((f) => f.name == 'French Fries').isPositive, isFalse);
      expect(BentoData.loggedFoodCount(buildInsight()), 4);
    });
  });

  group('Screen 01 — bento feed', () {
    testWidgets('renders the score hero and every bento section', (tester) async {
      await pumpBento(tester, InsightBentoFeed(data: buildInsight(), patterns: const [kPattern]));
      expect(tester.takeException(), isNull);
      expect(find.text('50'), findsOneWidget);
      expect(find.text('GUTGOOD SCORE'), findsOneWidget);
      expect(find.textContaining('6 pts'), findsOneWidget);
      expect(find.textContaining('Fast food dinners'), findsOneWidget);
      expect(find.textContaining('94% match'), findsOneWidget);
      // Card titles keep their casing; only tags are uppercased.
      expect(find.text('Late Iced Coffee'), findsOneWidget);
      expect(find.textContaining('TO WATCH'), findsOneWidget);
      expect(find.textContaining(RegExp('Top Foods This Week', caseSensitive: false)), findsOneWidget);
    });

    testWidgets('renders in dark mode with the derived palette', (tester) async {
      await pumpBento(
        tester,
        InsightBentoFeed(data: buildInsight(), patterns: const [kPattern]),
        brightness: Brightness.dark,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('50'), findsOneWidget);
    });

    testWidgets('survives an empty insight with no patterns', (tester) async {
      await pumpBento(
        tester,
        InsightBentoFeed(
          data: AIInsight(gutScore: 0, updatedAt: DateTime.utc(2026)),
          patterns: const [],
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('0'), findsOneWidget);
    });
  });

  group('Screen 02 — learning grid', () {
    testWidgets('shows the progress card and unlock cards', (tester) async {
      await pumpBento(tester, const InsightBentoLearning(meals: 1, symptoms: 0, scans: 1));
      expect(tester.takeException(), isNull);
      expect(find.textContaining('BUILDING YOUR BASELINE'), findsOneWidget);
      expect(find.text('Log to Unlock AI Insights'), findsOneWidget);
      expect(find.text('FOOD SCANS'), findsOneWidget);
      expect(find.text('SYMPTOM LOGS'), findsOneWidget);
      expect(find.text('2 / 3'), findsOneWidget);
    });

    testWidgets('clamps at zero logs cleanly', (tester) async {
      await pumpBento(tester, const InsightBentoLearning(meals: 0, symptoms: 0, scans: 0));
      expect(tester.takeException(), isNull);
      expect(find.text('0 / 3'), findsOneWidget);
      expect(find.text('0 / 1'), findsOneWidget);
    });
  });

  group('Screen 03 — weekly recap', () {
    testWidgets('draws the sparkline from real history', (tester) async {
      await pumpBento(tester, InsightBentoRecap(recap: buildInsight().weeklyRecap!, series: const [30, 45, 40, 55, 62, 68, 50]));
      expect(tester.takeException(), isNull);
      expect(find.text('50'), findsOneWidget);
      expect(find.byType(FoilSparkCard), findsOneWidget);
      expect(find.textContaining('TOP WIN'), findsOneWidget);
    });

    testWidgets('omits the sparkline when there is only one data point', (tester) async {
      await pumpBento(tester, InsightBentoRecap(recap: buildInsight().weeklyRecap!, series: const [50]));
      expect(tester.takeException(), isNull);
      expect(find.byType(FoilSparkCard), findsNothing);
    });
  });

  group('Screen 05 — pattern anatomy', () {
    testWidgets('renders the tick fan with real episode counts', (tester) async {
      await pumpBento(tester, const InsightBentoPattern(pattern: kPattern));
      expect(tester.takeException(), isNull);
      expect(find.textContaining('High · 94%'), findsOneWidget);
      expect(find.text('4 / 5'), findsOneWidget);
      expect(find.textContaining('BIOLOGICAL ROOT'), findsOneWidget);
      expect(find.text('Chicken Bowl'), findsOneWidget);
      expect(find.text('Apple & Nuts'), findsOneWidget);
    });
  });

  group('Screen 06 — trigger synergy', () {
    testWidgets('ranks drivers and shows the rescue protocol', (tester) async {
      const summary = InsightSummary(
        title: 'Fast Food + Late Dining + Low Water = 100% Flare',
        description: 'Combined factors eliminate renal clearance buffering.',
        type: 'Synergy',
        observation: '500ml pre-hydrate, eat before 6:30 PM, add potassium',
        involvedFoods: ['Fast Food', 'Late Dining', 'Low Water'],
      );
      await pumpBento(tester, const InsightBentoSynergy(summary: summary, patterns: [kPattern, kPattern]));
      expect(tester.takeException(), isNull);
      expect(find.textContaining('2× RISK'), findsOneWidget);
      expect(find.textContaining('Driver 1'), findsOneWidget);
      expect(find.textContaining('RESCUE PROTOCOL'), findsOneWidget);
    });
  });

  group('Screen 07 — food intelligence', () {
    testWidgets('counts boosters vs watch items from real food impacts', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) {
              // main.dart initialises the responsive scale before any screen builds.
              Responsive.init(context);
              return FoodIntelligenceScreen(insight: buildInsight());
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('TOP FOODS THIS WEEK'), findsWidgets);
      expect(find.text('Berry Oatmeal'), findsOneWidget);
      expect(find.text('French Fries'), findsOneWidget);
    });
  });

  group('Bento primitives', () {
    testWidgets('score track clamps out-of-range progress instead of throwing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) {
              Responsive.init(context);
              return const Scaffold(body: Column(children: [ScoreTrack(progress: 5), ScoreTrack(progress: -2)]));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('grid lays span-2 tiles across both columns', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) {
              Responsive.init(context);
              return const Scaffold(
                body: SizedBox(
                  width: 360,
                  child: BentoGrid(
                    children: [
                      BentoTile(BentoCard(title: 'One')),
                      BentoTile(BentoCard(title: 'Two')),
                      BentoTile(BentoCard(title: 'Wide', spanTwo: true), spanTwo: true),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final one = tester.getRect(find.text('One'));
      final two = tester.getRect(find.text('Two'));
      final wide = tester.getRect(find.text('Wide'));
      // 1x1 tiles share a row; the span-2 tile starts below both.
      expect(one.top, two.top);
      expect(wide.top, greaterThan(one.top));
      expect(one.width, lessThan(two.width * 1.01));
    });

    testWidgets('emoji art falls back to a plate when there is no art at all', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) {
              Responsive.init(context);
              return const Scaffold(body: FoodArt(emoji: '', size: 28));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
