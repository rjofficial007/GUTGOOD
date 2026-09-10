import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/utils/barcode_validator.dart';

void main() {
  group('BarcodeValidator.normalizeForScan (smooth-app parity)', () {
    test('passes EAN-13 through unchanged', () {
      expect(BarcodeValidator.normalizeForScan('5449000000996'), '5449000000996');
    });

    test('promotes 12-digit UPC-A to EAN-13 with a leading zero', () {
      expect(BarcodeValidator.normalizeForScan('049000130443'), '0049000130443');
    });

    test('strips dashes and trims whitespace', () {
      expect(BarcodeValidator.normalizeForScan(' 5-449-000-000-996 '), '5449000000996');
    });

    test('keeps short-but-valid codes (EAN-8)', () {
      expect(BarcodeValidator.normalizeForScan('96385074'), '96385074');
    });

    test('rejects codes shorter than 4 characters', () {
      expect(BarcodeValidator.normalizeForScan('123'), isNull);
      expect(BarcodeValidator.normalizeForScan('1'), isNull);
    });

    test('rejects null and empty input', () {
      expect(BarcodeValidator.normalizeForScan(null), isNull);
      expect(BarcodeValidator.normalizeForScan(''), isNull);
      expect(BarcodeValidator.normalizeForScan('   '), isNull);
      expect(BarcodeValidator.normalizeForScan('--'), isNull);
    });
  });
}
