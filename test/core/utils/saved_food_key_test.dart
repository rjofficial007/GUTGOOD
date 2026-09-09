import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/utils/saved_food_key.dart';

void main() {
  group('savedFoodKey', () {
    test('barcodes key directly and win over the name', () {
      expect(savedFoodKey(barcode: '123456', productName: 'Anything'), 'b_123456');
      expect(savedFoodKey(barcode: '  123456  ', productName: 'Anything'), 'b_123456');
    });

    test('names hash case- and whitespace-insensitively', () {
      final a = savedFoodKey(productName: 'Chobani  Yogurt');
      final b = savedFoodKey(productName: '  chobani yogurt ');
      expect(a, b);
      expect(a, matches(RegExp(r'^n_[0-9a-f]{16}$')));
    });

    test('different names key differently; output is doc-id-safe', () {
      expect(savedFoodKey(productName: 'Pizza'), isNot(savedFoodKey(productName: 'Pasta')));
      expect(savedFoodKey(barcode: 'a/b', productName: 'x'), 'b_a_b');
      expect(savedFoodKey(productName: ''), matches(RegExp(r'^n_[0-9a-f]{16}$')));
    });
  });
}
