import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/widgets/journal_event_sheet.dart';

void main() {
  testWidgets('only an explicit confirmation returns an occurrence time', (tester) async {
    final initialTime = DateTime.now().subtract(const Duration(days: 2));
    ({DateTime occurredAt, String? mealId})? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => saved = await showJournalEventSheet(context, title: 'When did you eat this?', initialTime: initialTime),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(saved, isNull);
    await tester.tap(find.text('Confirm time'));
    await tester.pumpAndSettle();
    expect(saved?.occurredAt, initialTime);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('Confirm time'))).pop();
    await tester.pumpAndSettle();
    expect(saved, isNull, reason: 'Dismissing the time sheet must not confirm a guessed time.');
  });
}
