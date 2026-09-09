import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/services/off_service.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

Response<Map<String, dynamic>> _offResponse(Map<String, dynamic> product) => Response(
  requestOptions: RequestOptions(path: ''),
  data: {'status': 1, 'product': product},
);

void main() {
  late MockDio dio;
  late OffServiceImpl service;

  setUp(() {
    dio = MockDio();
    service = OffServiceImpl(dio: dio);
  });

  group('getProduct session memo (P0-3)', () {
    test('repeat lookup of the same barcode hits the network once', () async {
      when(() => dio.get(any(), queryParameters: any(named: 'queryParameters'))).thenAnswer((_) async => _offResponse({'product_name': 'Cache Cola', 'code': '999'}));

      final first = await service.getProduct('999');
      final second = await service.getProduct('999');

      expect(first, isNotNull);
      expect(second?.productName, first?.productName);
      verify(() => dio.get(any(), queryParameters: any(named: 'queryParameters'))).called(1);
    });

    test('different barcodes each hit the network', () async {
      when(() => dio.get(any(), queryParameters: any(named: 'queryParameters'))).thenAnswer((invocation) async {
        final url = invocation.positionalArguments.single as String;
        return _offResponse({'product_name': 'Product $url', 'code': url});
      });

      await service.getProduct('111');
      await service.getProduct('222');

      verify(() => dio.get(any(), queryParameters: any(named: 'queryParameters'))).called(2);
    });

    test('not-found results are NOT cached', () async {
      when(() => dio.get(any(), queryParameters: any(named: 'queryParameters'))).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: ''), data: {'status': 0}),
      );

      expect(await service.getProduct('000'), isNull);
      expect(await service.getProduct('000'), isNull);

      verify(() => dio.get(any(), queryParameters: any(named: 'queryParameters'))).called(2);
    });
  });
}
