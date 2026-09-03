import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/empty_state_widget.dart';
import 'package:gutgood/core/widgets/gut_button.dart';
import 'package:gutgood/core/widgets/gut_shimmer_skeleton.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            Responsive.init(context);
            return child;
          },
        ),
      ),
    );
  }

  group('EmptyStateWidget Tests', () {
    testWidgets('renders title, description, and icon correctly', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const EmptyStateWidget(
            icon: Icons.inbox,
            title: 'No Data Found',
            description: 'There are no items to display.',
          ),
        ),
      );

      expect(find.text('No Data Found'), findsOneWidget);
      expect(find.text('There are no items to display.'), findsOneWidget);
      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });

    testWidgets('renders action button and triggers callback on press', (tester) async {
      bool actionClicked = false;

      await tester.pumpWidget(
        createTestWidget(
          EmptyStateWidget(
            icon: Icons.refresh,
            title: 'Error Occurred',
            description: 'Something went wrong.',
            actionLabel: 'Retry Action',
            onActionPressed: () {
              actionClicked = true;
            },
          ),
        ),
      );

      expect(find.text('RETRY ACTION'), findsOneWidget);

      await tester.tap(find.byType(GutButton));
      await tester.pumpAndSettle();

      expect(actionClicked, isTrue);
    });
  });

  group('GutShimmerSkeleton Tests', () {
    testWidgets('renders shimmer container with specified dimensions', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const GutShimmerSkeleton(
            width: 200,
            height: 100,
            borderRadius: 16,
          ),
        ),
      );

      expect(find.byType(GutShimmerSkeleton), findsOneWidget);
    });
  });
}
