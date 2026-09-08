import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/off_product.dart';
import 'package:gutgood/core/utils/model_utils.dart';

void main() {
  group('ModelUtils.unscorableReason', () {
    test('returns null when there are no misc_tags', () {
      expect(ModelUtils.unscorableReason(null), isNull);
      expect(ModelUtils.unscorableReason([]), isNull);
    });

    test('returns null for tags unrelated to scoring', () {
      // A product can have plenty of misc_tags and still be perfectly scorable.
      expect(
        ModelUtils.unscorableReason([
          'en:ecoscore-not-computed',
          'en:main-countries-new-product',
        ]),
        isNull,
      );
    });

    test('names the missing nutrient', () {
      final reason = ModelUtils.unscorableReason([
        'en:nutriscore-not-computed',
        'en:nutriscore-missing-nutrition-data-sodium',
      ]);
      expect(reason, isNotNull);
      expect(reason, contains('sodium'));
      // It must read as an explanation, not as a code.
      expect(reason, isNot(contains('en:')));
      expect(reason, isNot(contains('nutriscore-missing')));
    });

    test('joins two missing nutrients naturally', () {
      final reason = ModelUtils.unscorableReason([
        'en:nutriscore-missing-nutrition-data-sodium',
        'en:nutriscore-missing-nutrition-data-sugars',
      ]);
      expect(reason, contains('sodium and sugar'));
    });

    test('de-duplicates repeated nutrients', () {
      final reason = ModelUtils.unscorableReason([
        'en:nutriscore-missing-nutrition-data-sodium',
        'en:nutriscore-missing-nutrition-data-sodium',
      ]);
      expect(reason, contains('missing sodium for this product'));
      expect(reason, isNot(contains('sodium and sodium')));
    });

    test('reports a missing category', () {
      final reason = ModelUtils.unscorableReason([
        'en:nutriscore-missing-category',
      ]);
      expect(reason, contains('category'));
    });

    test('falls back to a generic message when nothing specific is known', () {
      final reason = ModelUtils.unscorableReason([
        'en:nutrition-not-enough-data-to-compute-nutrition-score',
      ]);
      expect(reason, isNotNull);
      expect(reason, contains('enough nutrition data'));
    });

    test('a named nutrient beats the generic fallback', () {
      // Specificity matters: "not computed" alone tells the user nothing.
      final reason = ModelUtils.unscorableReason([
        'en:nutriscore-not-computed',
        'en:nutrition-not-enough-data-to-compute-nutrition-score',
        'en:nutriscore-missing-nutrition-data-sodium',
      ]);
      expect(reason, contains('sodium'));
    });

    test('invites the user to contribute the missing data', () {
      final reason = ModelUtils.unscorableReason([
        'en:nutriscore-missing-nutrition-data-sodium',
      ]);
      expect(reason!.toLowerCase(), contains('you could add it'));
    });
  });

  group('OffProduct.unscorableReason', () {
    test('delegates to the shared helper', () {
      final product = OffProduct(
        productName: 'Real Orange Juice',
        miscTags: const ['en:nutriscore-missing-nutrition-data-sodium'],
      );
      expect(product.unscorableReason, ModelUtils.unscorableReason(product.miscTags));
    });

    test('is null when OFF said nothing', () {
      const product = OffProduct(productName: 'Nutella');
      expect(product.unscorableReason, isNull);
    });

    test('survives the Firestore round-trip through toMap/fromMap', () {
      final original = OffProduct(
        productName: 'Real Orange Juice',
        barcode: '0180411000803',
        miscTags: const [
          'en:nutriscore-not-computed',
          'en:nutriscore-missing-nutrition-data-sodium',
        ],
      );
      final restored = OffProduct.fromMap(original.toMap());
      expect(restored.miscTags, original.miscTags);
      expect(restored.unscorableReason, original.unscorableReason);
    });
  });

  group('OffProduct equality', () {
    // Regression: props used to be [productName, barcode, score] only, so two
    // different barcode-less (photo) scans with the same name and score counted
    // as equal and the UI could skip rebuilding.
    test('distinguishes products that differ only outside name/barcode/score', () {
      const a = OffProduct(productName: 'Soup', score: 50, nutriscore: 'a');
      const b = OffProduct(productName: 'Soup', score: 50, nutriscore: 'e');
      expect(a, isNot(equals(b)));
    });

    test('distinguishes products that differ only by misc_tags', () {
      const a = OffProduct(productName: 'Soup', score: 50);
      const b = OffProduct(
        productName: 'Soup',
        score: 50,
        miscTags: ['en:nutriscore-missing-category'],
      );
      expect(a, isNot(equals(b)));
    });
  });
}
