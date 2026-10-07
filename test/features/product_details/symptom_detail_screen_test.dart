import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/app/theme/app_theme.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/features/product_details/presentation/pages/symptom_detail_screen.dart';

void main() {
  Future<void> pumpSymptom(WidgetTester tester, SymptomLog symptom) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) {
            Responsive.init(context);
            return SymptomDetailScreen(symptom: symptom);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('does not display an invented zero severity when it was not reported', (tester) async {
    await pumpSymptom(tester, SymptomLog(symptom: 'Bloating', createdAt: DateTime(2026, 10, 7)));

    expect(find.textContaining('0/10'), findsNothing);
    expect(find.text('Severity'), findsNothing);
    expect(find.text('Severity Level'), findsNothing);
    expect(find.text('MILD REACTION'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('preserves an explicitly reported severity', (tester) async {
    await pumpSymptom(tester, SymptomLog(symptom: 'Bloating', severity: 5, createdAt: DateTime(2026, 10, 7)));

    expect(find.textContaining('5/10'), findsWidgets);
    expect(find.text('Severity Level'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
