import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_feed/insight_ui_kit.dart';

void main() {
  Widget host(List<double> values) => MaterialApp(
    home: Scaffold(
      body: InsightTrendChart(values: values),
    ),
  );

  testWidgets('treats zero weekly values as unscored gaps', (tester) async {
    await tester.pumpWidget(host(const [0, 70, 0, 0, 0, 0, 0]));

    expect(find.text('No score history yet'), findsNothing);
    expect(find.bySemanticsLabel('Gut scores out of 100, in recording order: 70'), findsOneWidget);
  });

  testWidgets('shows no history when every weekly value is unscored', (tester) async {
    await tester.pumpWidget(host(const [0, 0, 0, 0, 0, 0, 0]));

    expect(find.text('No score history yet'), findsOneWidget);
    expect(find.bySemanticsLabel('No recorded scores'), findsOneWidget);
  });
}
