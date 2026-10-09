import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/utils/image_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/features/insights/presentation/widgets/arc_pattern_card.dart';
import 'package:gutgood/features/insights/presentation/widgets/pattern_grid.dart';

void main() {
  setUp(() => usePexelsFoodImages.value = false);
  tearDown(() => usePexelsFoodImages.value = true);
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
    testWidgets('renders matched-log count and a descriptive evidence tier, not a confidence percentage', (tester) async {
      await tester.pumpWidget(createTestWidget(ArcPatternCard(pattern: testPattern)));

      expect(find.text('Sodium'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('Matched log entries'), findsOneWidget);
      expect(find.text('Repeated observation'), findsOneWidget);
      expect(find.text('85% match'), findsNothing);
      expect(find.text('Confidence level'), findsNothing);
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
      expect(find.text('Matched log entries'), findsOneWidget);
      expect(find.text('Repeated observation'), findsOneWidget);
    });

    testWidgets('renders the pattern as a banner with its signal and action', (tester) async {
      await tester.pumpWidget(createTestWidget(PatternCard(pattern: testPattern)));

      expect(find.text('HEADACHE PATTERN'), findsOneWidget);
      expect(find.text('Sodium'), findsOneWidget);
      expect(find.text('Followed by Headache'), findsOneWidget);
      expect(find.text('Explore pattern'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
