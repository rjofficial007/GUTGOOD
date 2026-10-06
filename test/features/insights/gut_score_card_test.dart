import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/features/insights/presentation/widgets/gut_score_card.dart';

void main() {
  Widget createTestWidget(Widget child) => MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) {
          Responsive.init(context);
          return child;
        },
      ),
    ),
  );

  group('GutScoreCard Widget Tests', () {
    testWidgets('gaps compare the previous scored day and a real zero is included', (tester) async {
      await tester.pumpWidget(createTestWidget(const GutScoreCard(score: 35, series: [0, 70, 0, 0, 0, 0, 0], scoredDayIndices: [1, 4])));
      expect(find.text('↓ 70 vs previous scored day'), findsOneWidget);
      expect(find.textContaining('yesterday'), findsNothing);
    });
    testWidgets('renders hero score card with default title, score and band', (tester) async {
      await tester.pumpWidget(createTestWidget(const GutScoreCard(score: 85, delta: 5)));

      expect(find.text('85'), findsOneWidget);
      expect(find.text('/100'), findsOneWidget);
      expect(find.text('GUTGOOD SCORE'), findsOneWidget);
      expect(find.textContaining('5 pts'), findsOneWidget);
    });

    testWidgets('renders compact style variant correctly', (tester) async {
      await tester.pumpWidget(createTestWidget(const GutScoreCard.compact(score: 92, delta: 3)));

      expect(find.text('92'), findsOneWidget);
      expect(find.text('/100'), findsOneWidget);
      expect(find.text('EXCELLENT'), findsOneWidget);
      expect(find.text('↑3'), findsOneWidget);
    });

    testWidgets('renders gauge style variant correctly', (tester) async {
      await tester.pumpWidget(createTestWidget(const GutScoreCard.gauge(score: 65)));

      expect(find.text('65'), findsOneWidget);
      expect(find.text('SCORE'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
    });

    testWidgets('triggers onTap callback when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        createTestWidget(
          GutScoreCard(
            score: 78,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      );

      await tester.tap(find.byType(GutScoreCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
