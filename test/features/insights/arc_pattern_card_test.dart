import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/features/insights/presentation/widgets/arc_pattern_card.dart';

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

  final testPattern = BodyPattern(
    type: BodyPattern.typeHeadache,
    trigger: 'Sodium',
    reaction: 'Headache',
    frequency: 5,
    confidence: 'High',
    description: 'High sodium dinners trigger headaches.',
    evidenceRatio: 0.85,
    updatedAt: DateTime.utc(2026, 8, 31).toIso8601String(),
  );

  group('ArcPatternCard Widget Tests', () {
    testWidgets('renders pattern title, percentage and confidence pill', (tester) async {
      await tester.pumpWidget(createTestWidget(ArcPatternCard(pattern: testPattern)));

      expect(find.text('Sodium'), findsOneWidget);
      expect(find.text('85% match'), findsOneWidget);
      expect(find.text('Confidence level'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
    });

    testWidgets('triggers onTap callback when card is tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        createTestWidget(
          ArcPatternCard(
            pattern: testPattern,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      );

      await tester.tap(find.byType(ArcPatternCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('renders PatternCarouselWidget with page indicator', (tester) async {
      await tester.pumpWidget(createTestWidget(PatternCarouselWidget(patterns: [testPattern])));

      expect(find.byType(ArcPatternCard), findsOneWidget);
      expect(find.text('Sodium'), findsOneWidget);
      expect(find.text('85% match'), findsOneWidget);
    });
  });
}
