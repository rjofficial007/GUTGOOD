import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/models.dart';

ScanResult _testScan() => ScanResult(
  productName: 'Test Yogurt',
  brand: 'Test Brand',
  category: 'food',
  barcode: '1234567890123',
  score: 72,
  impactType: ImpactType.positive,
  impact: 'Good stuff',
  nutriscore: 'B',
  nutriscoreScore: -2,
  isOrganic: true,
  createdAt: DateTime(2026, 5, 1),
  rawData: {
    'intent': 'COMPLETE_ANALYSIS',
    'meal': const {'summary': 'A test meal'},
    'padding': List.filled(20, 'x'),
  },
);

void main() {
  group('toPersistenceMap (P0-2)', () {
    test('strips the rawData blob but keeps every durable field', () {
      final persisted = _testScan().toPersistenceMap();

      expect(persisted.containsKey('rawData'), isFalse, reason: 'The decoded AI blob must never reach Firestore.');
      expect(persisted['productName'], 'Test Yogurt');
      expect(persisted['barcode'], '1234567890123');
      expect(persisted['nutriscore'], 'B');
      expect(persisted['nutriscoreScore'], -2);
      expect(persisted['isOrganic'], isTrue);
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
    test('parses stripped docs and preserves loggability + engine inputs', () {
      final stripped = _testScan().toPersistenceMap();
      final hydrated = ScanResult.fromMap(stripped);

      expect(hydrated.productName, 'Test Yogurt');
      expect(hydrated.nutriscoreScore, -2);
      expect(hydrated.isOrganic, isTrue);
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
