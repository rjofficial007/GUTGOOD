import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/app/theme/app_theme.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/features/insights/presentation/pages/swap_detail_screen.dart' as shared;
import 'package:gutgood/features/product_details/presentation/pages/swap_detail_screen.dart';

void main() {
  Future<void> pumpSwap(WidgetTester tester, ProductSwap swap) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: Builder(builder: (context) {
        Responsive.init(context);
        return SwapDetailScreen(swap: swap);
      }),
    ));
  }

  testWidgets('scan route displays the shared comparison and nutrition basis', (tester) async {
    await pumpSwap(tester, ProductSwap.fromMap(const {
      'name': 'Plain yogurt',
      'imageUrl': 'https://images.test/yogurt.jpg',
      'reason': 'An alternative without added sugar',
      'whyBetterOption': 'Less added sugar on the supplied labels.',
      'structuredBenefits': [
        {'title': 'No added sugar', 'description': 'From the product label', 'icon': 'leaf'},
      ],
      'nutrition': {'calories': 65, 'protein': '4 g', 'basis': 'per 100 g'},
    }));
    expect(find.byType(shared.SwapDetailScreen), findsOneWidget);
    expect(find.text('Less added sugar on the supplied labels.'), findsOneWidget);
    expect(find.text('From the product label'), findsOneWidget);
    expect(find.text('per 100 g'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing nutrition and benefits do not create health claims', (tester) async {
    await pumpSwap(tester, const ProductSwap(
      title: 'Oats', subtitle: 'An alternative breakfast', imageKeyword: 'oats',
      imageUrl: 'https://images.test/oats.jpg', tag: 'ALTERNATIVE',
    ));
    expect(find.text('Nutrition Highlights'), findsNothing);
    expect(find.text('Supports gut barrier health and easier digestion'), findsNothing);
    expect(find.text('An alternative breakfast'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
