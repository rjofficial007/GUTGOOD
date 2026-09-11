import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/off_product.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/features/chat/presentation/providers/chat_composer_notifier.dart';

void main() {
  group('P2-11 grounded swaps', () {
    test('OffProduct.toSwap maps grounding fields with brand fallback', () {
      const product = OffProduct(
        productName: 'Oat Drink',
        brand: 'Oatly',
        imageUrl: 'https://img/oat.jpg',
        barcode: '12345678',
        nutriscore: 'a',
      );

      final swap = product.toSwap();

      expect(swap.title, 'Oat Drink');
      expect(swap.subtitle, 'Oatly');
      expect(swap.tag, 'BETTER CHOICE');
      expect(swap.imageKeyword, 'Oat Drink');
      expect(swap.imageUrl, 'https://img/oat.jpg');
      expect(swap.isBlackBadge, isTrue);
      expect(swap.barcode, '12345678');
      expect(swap.nutriscore, 'a');
    });

    test('OffProduct.toSwap falls back when brand is missing', () {
      const product = OffProduct(productName: 'Mystery Drink');

      final swap = product.toSwap();

      expect(swap.subtitle, 'Better Alternative');
      expect(swap.barcode, isNull);
      expect(swap.nutriscore, isNull);
    });

    test('ProductSwap.fromMap tolerates legacy maps without grounding keys', () {
      final swap = ProductSwap.fromMap(const {'title': 'Oat milk', 'subtitle': 'swap', 'imageKeyword': 'oat milk', 'tag': 'BETTER'});

      expect(swap.barcode, isNull);
      expect(swap.nutriscore, isNull);
    });

    test('ProductSwap grounding fields round-trip through toMap/fromMap', () {
      const swap = ProductSwap(title: 'Oat Drink', subtitle: 'Oatly', imageKeyword: 'Oat Drink', tag: 'BETTER CHOICE', barcode: '12345678', nutriscore: 'a');

      final roundTripped = ProductSwap.fromMap(swap.toMap());

      expect(roundTripped.barcode, '12345678');
      expect(roundTripped.nutriscore, 'a');
      expect(roundTripped, swap);
    });

    test('swapsGroundingFragment names grades/barcodes and instructs echo', () {
      const grounded = [
        ProductSwap(title: 'Oat Drink', subtitle: 'Oatly', imageKeyword: 'Oat Drink', tag: 'BETTER CHOICE', barcode: '12345678', nutriscore: 'a'),
        ProductSwap(title: 'Soya Drink', subtitle: 'Alpro', imageKeyword: 'Soya Drink', tag: 'BETTER CHOICE'),
      ];

      final fragment = swapsGroundingFragment('more swaps please', grounded);

      expect(fragment, startsWith('more swaps please'));
      expect(fragment, contains('Oat Drink (grade a, barcode 12345678)'));
      expect(fragment, contains('Soya Drink (grade ?, barcode ?)'));
      expect(fragment, contains('copy each "barcode" and "nutriscore"'));
      expect(fragment, contains('exactly 3'));
    });
  });
}
