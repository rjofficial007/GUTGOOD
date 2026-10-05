import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_feed/insight_ui_kit.dart';

void main() {
  test('uses the food name when an insight image URL is an example.com placeholder', () {
    final imageUrl = InsightUiKit.foodImageUrl(
      'Veggie Burger',
      imageUrl: 'https://example.com/veggie_burger.jpg',
    );

    expect(imageUrl, contains('Veggie%20Burger'));
    expect(imageUrl, isNot(contains('example.com')));
  });
}
