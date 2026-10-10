import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/utils/responsive.dart';

void main() {
  testWidgets('short iPhone keeps the existing compact text scale', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(size: Size(375, 667)),
          child: Builder(
            builder: (context) {
              Responsive.init(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(Responsive.scaleText, closeTo(667 / 852, 0.001));
    expect(Responsive.sp(11), closeTo(11 * 667 / 852, 0.01));
  });
}
