import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/ai/protocol/ai_constants.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/utils/model_utils.dart';

ScanResult _testScan() => ScanResult(
  productName: 'Test Yogurt',
  brand: 'Test Brand',
  category: 'food',
  nutritionBasis: 'per_100g',
  barcode: '1234567890123',
  score: 72,
  impactType: ImpactType.positive,
  impact: 'Good stuff',
  nutriscore: 'B',
  nutriscoreScore: -2,
  isOrganic: true,
  scanConfidence: 0.91,
  scanVerdict: Verdict.food,
  createdAt: DateTime(2026, 5, 1),
  rawData: {
    'intent': 'COMPLETE_ANALYSIS',
    'meal': const {'summary': 'A test meal'},
    'padding': List.filled(20, 'x'),
  },
);

void main() {
  test('non-finite scan scores are rejected without throwing', () {
    for (final value in [double.nan, double.infinity, double.negativeInfinity, 'NaN', 'Infinity', null]) {
      expect(ModelUtils.parseScore(value), 0);
    }
  });
  test('an explicit zero food score survives persistence', () {
    final scan = _testScan().copyWith(score: 0);
    expect(ScanResult.fromMap(scan.toPersistenceMap()).score, 0);
  });
  test('consumption answer round-trips while unanswered scans remain pending', () {
    final pending = _testScan();
    final informational = pending.copyWith(consumed: false);

    expect(pending.needsConsumptionConfirmation, isTrue);
    expect(ScanResult.fromMap(pending.toPersistenceMap()).consumed, isNull);
    expect(ScanResult.fromMap(informational.toPersistenceMap()).consumed, isFalse);
  });
  test('scan persistence retains meal candidate food tags for later confirmation', () {
    final scan = _testScan().copyWith(foodTags: const ['dairy'], consumed: false);
    final persisted = scan.toPersistenceMap();

    expect(persisted['foodTags'], ['dairy']);
    expect(persisted['consumed'], isFalse);
    expect(ScanResult.fromMap(persisted).foodTags, ['dairy']);
  });
  test('barcode display prefers the catalog product image and photo scans prefer the captured image', () {
    final barcode = _testScan().copyWith(imageUrl: 'https://example.com/product.jpg', userImageUrl: 'https://example.com/barcode-photo.jpg');
    final photo = ScanResult(
      productName: 'Meal',
      brand: 'GutGood',
      category: 'food',
      source: 'food',
      score: 80,
      impactType: ImpactType.positive,
      impact: 'Good',
      imageUrl: 'https://example.com/catalog.jpg',
      userImageUrl: 'https://example.com/meal-photo.jpg',
      createdAt: DateTime(2026, 5, 1),
    );

    expect(barcode.displayImageUrl, 'https://example.com/product.jpg');
    expect(ScanResult.fromMap(barcode.toPersistenceMap()).displayImageUrl, 'https://example.com/product.jpg');
    final barcodeWithoutCatalogImage = ScanResult(
      productName: 'Meal',
      brand: 'Brand',
      barcode: '123456789',
      source: 'barcode',
      score: 80,
      impactType: ImpactType.neutral,
      impact: 'Okay',
      userImageUrl: 'https://example.com/barcode-photo.jpg',
      createdAt: DateTime(2026, 5, 1),
    );
    expect(barcodeWithoutCatalogImage.displayImageUrl, isNull);
    expect(photo.displayImageUrl, 'https://example.com/meal-photo.jpg');
    expect(ScanResult.fromMap(photo.toPersistenceMap()).displayImageUrl, 'https://example.com/meal-photo.jpg');
  });
  group('toPersistenceMap (P0-2)', () {
    test('strips the rawData blob but keeps every durable field', () {
      final persisted = _testScan().toPersistenceMap();

      expect(persisted.containsKey('rawData'), isFalse, reason: 'The decoded AI blob must never reach Firestore.');
      expect(persisted['productName'], 'Test Yogurt');
      expect(persisted['barcode'], '1234567890123');
      expect(persisted['nutriscore'], 'B');
      expect(persisted['nutriscoreScore'], -2);
      expect(persisted['isOrganic'], isTrue);
      expect(persisted['scanConfidence'], 0.91);
      expect(persisted['scanVerdict'], Verdict.food);
      expect(persisted['nutritionBasis'], 'per_100g');
      expect(persisted['rawDataHash'], _testScan().rawDataHash);
    });

    test('leaves the in-memory rawData untouched', () {
      final scan = _testScan()..toPersistenceMap();

      expect(scan.rawData, isNotNull);
      expect(scan.rawData!['intent'], 'COMPLETE_ANALYSIS');
    });

    test('toMap still carries rawData for in-memory/chat use', () {
      expect(_testScan().toMap()['rawData'], isNotNull);
    });

    test('stores scanner swaps using the shared FoodSwap model', () {
      final scan = _testScan().copyWith(
        swaps: const [
          ProductSwap(
            title: 'Plain Greek Yogurt',
            subtitle: 'More protein and no added sugar',
            imageKeyword: 'plain greek yogurt',
            imageUrl: 'https://example.com/yogurt.jpg',
            tag: 'HIGH PROTEIN',
            badge: 'BETTER OPTION',
            barcode: '9988776655443',
            nutriscore: 'A',
            benefits: ['More protein', 'No added sugar'],
          ),
        ],
      );

      final persisted = scan.toPersistenceMap();
      final foodSwap = persisted['foodSwap'] as Map<String, dynamic>;
      final alternative = (foodSwap['alternatives'] as List).single as Map<String, dynamic>;

      expect(persisted.containsKey('swaps'), isFalse);
      expect(foodSwap['source'], {'foodId': '1234567890123', 'name': 'Test Yogurt', 'imageUrl': null});
      expect(alternative['foodId'], '9988776655443');
      expect(alternative['barcode'], '9988776655443');
      expect(alternative['nutriscore'], 'A');
      expect(alternative['benefitTags'], ['More protein', 'No added sugar']);

      final hydrated = ScanResult.fromMap(persisted);
      expect(hydrated.foodSwap, isNotNull);
      expect(hydrated.nutritionBasis, 'per_100g');
      expect(hydrated.nutritionBasisLabel, 'Per 100 g');
      expect(hydrated.swaps.single.title, 'Plain Greek Yogurt');
      expect(hydrated.swaps.single.barcode, '9988776655443');
      expect(hydrated.swaps.single.nutriscore, 'A');
      expect(hydrated.swaps.single.benefits, ['More protein', 'No added sugar']);
    });

    test('normalizes legacy flat swap documents to FoodSwap', () {
      final legacy = _testScan().toPersistenceMap()
        ..['swaps'] = [const ProductSwap(title: 'Lactose Free Yogurt', subtitle: 'May be easier to tolerate', imageKeyword: 'lactose free yogurt', tag: 'GUT FRIENDLY').toMap()];

      final hydrated = ScanResult.fromMap(legacy);

      expect(hydrated.foodSwap?.alternatives.single.name, 'Lactose Free Yogurt');
      expect(hydrated.toPersistenceMap().containsKey('swaps'), isFalse);
      expect(hydrated.toPersistenceMap().containsKey('foodSwap'), isTrue);
    });

    test('copyWith keeps the shared model and legacy scan cards in sync', () {
      final scan = _testScan().copyWith(
        foodSwap: const FoodSwap(
          id: 'test-swap',
          source: SwapSource(foodId: 'source-id', name: 'Source food'),
          alternatives: [SwapAlternative(foodId: 'alt-id', name: 'Alternative', reason: 'Reason')],
        ),
      );

      expect(scan.swaps.single.title, 'Alternative');
      expect(scan.swaps.single.subtitle, 'Reason');
      expect(scan.toPersistenceMap()['foodSwap'], isNotNull);
    });
  });

  group('rawDataHash', () {
    test('is a stable 64-char lowercase hex fingerprint', () {
      final a = _testScan().rawDataHash!;
      final b = _testScan().rawDataHash!;

      expect(a, b);
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(a), isTrue);
    });

    test('is null without a raw payload', () {
      final scan = ScanResult(productName: 'x', brand: '', score: 50, impactType: ImpactType.neutral, impact: '', createdAt: DateTime.now());
      expect(scan.rawDataHash, isNull);
      expect(scan.toPersistenceMap()['rawDataHash'], isNull);
    });

    test('differs across different payloads', () {
      final a = _testScan();
      final b = _testScan().copyWith(rawData: const {'intent': 'SOMETHING_ELSE'});

      expect(a.rawDataHash, isNot(equals(b.rawDataHash)));
    });
  });

  group('fromMap without rawData (post-strip docs)', () {
    test('does not use AI-provided time as the scan save timestamp', () {
      final before = DateTime.now();
      final scan = ScanResult.fromMap(const {'productName': 'Timed Scan', 'time': '2026-10-06T18:12:00.000Z'});
      final after = DateTime.now();

      expect(scan.createdAt.isBefore(before), isFalse);
      expect(scan.createdAt.isAfter(after), isFalse);
    });

    test('parses stripped docs and preserves loggability + engine inputs', () {
      final stripped = _testScan().toPersistenceMap();
      final hydrated = ScanResult.fromMap(stripped);

      expect(hydrated.productName, 'Test Yogurt');
      expect(hydrated.nutriscoreScore, -2);
      expect(hydrated.isOrganic, isTrue);
      expect(hydrated.scanConfidence, 0.91);
      expect(hydrated.scanVerdict, Verdict.food);
      expect(hydrated.isLoggableProduct, _testScan().isLoggableProduct);
    });

    test('legacy docs with rawData still hydrate (meal fallback intact)', () {
      final legacy = _testScan().toMap();
      expect(legacy.containsKey('rawData'), isTrue);

      final hydrated = ScanResult.fromMap(legacy);
      expect(hydrated.rawData, isNotNull);
      expect(hydrated.isLoggableProduct, isTrue);
    });

    test('impact still falls back to the legacy rawData meal summary', () {
      final hydrated = ScanResult.fromMap({
        'productName': 'Legacy Meal',
        'brand': '',
        'score': 60,
        'impactType': 'neutral',
        'createdAt': DateTime(2026, 1, 1),
        'rawData': const {
          'meal': {'summary': 'Legacy summary here'},
        },
      });

      expect(hydrated.impact, 'Legacy summary here');
    });

    test('unknown organic status survives the round-trip as null', () {
      final persisted = _testScan().toPersistenceMap()..remove('isOrganic');

      expect(ScanResult.fromMap(persisted).isOrganic, isNull);
    });
  });
}
