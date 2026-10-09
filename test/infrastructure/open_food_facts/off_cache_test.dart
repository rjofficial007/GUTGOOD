import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/infrastructure/open_food_facts/off_service.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late OffServiceImpl service;
  late List<String> fetchLog;
  late Map<String, OffProduct?> canned;

  /// Product fetches now go through the official `openfoodfacts` SDK, so the
  /// memo tests inject a fake [OffProductFetcher] instead of mocking HTTP.
  OffProductFetcher fakeFetcher() => (barcode) async {
    fetchLog.add(barcode);
    return canned[barcode];
  };

  setUp(() {
    fetchLog = [];
    canned = {};
    service = OffServiceImpl(dio: MockDio(), productFetcher: fakeFetcher());
  });

  group('getProduct session memo (P0-3)', () {
    test('repeat lookup of the same barcode hits the fetch once', () async {
      canned['0999000111222'] = const OffProduct(productName: 'Cache Cola', barcode: '0999000111222');

      final first = await service.getProduct('999000111222');
      final second = await service.getProduct('999000111222');

      expect(first, isNotNull);
      expect(second?.productName, first?.productName);
      expect(fetchLog, ['0999000111222']);
    });

    test('different barcodes each hit the fetch', () async {
      canned['111000'] = const OffProduct(productName: 'Product 111', barcode: '111000');
      canned['222000'] = const OffProduct(productName: 'Product 222', barcode: '222000');

      await service.getProduct('111000');
      await service.getProduct('222000');

      expect(fetchLog, ['111000', '222000']);
    });

    test('not-found results are NOT cached', () async {
      canned['000000'] = null;

      expect(await service.getProduct('000000'), isNull);
      expect(await service.getProduct('000000'), isNull);

      expect(fetchLog, ['000000', '000000']);
    });

    test('invalid barcodes never reach the fetcher (smooth-app normalization)', () async {
      // < 4 chars after cleanup ⇒ silently ignored by the SDK path.
      expect(await service.getProduct('123'), isNull);
      expect(await service.getProduct('--'), isNull);
      expect(fetchLog, isEmpty);
    });

    test('12-digit UPC-A is normalized before fetch and cache', () async {
      canned['0049000130443'] = const OffProduct(productName: 'Upc Cola', barcode: '0049000130443');

      final product = await service.getProduct('049000130443');

      expect(product?.barcode, '0049000130443');
      // The fetcher (and the memo key) see the normalized EAN-13 form.
      expect(fetchLog, ['0049000130443']);
    });
  });
}
