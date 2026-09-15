import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/scans/nova_group.dart' as ng;

void main() {
  group('NovaGroup', () {
    test('parses group numbers correctly', () {
      expect(ng.NovaGroup.fromGroup(1), ng.NovaGroup.unprocessed);
      expect(ng.NovaGroup.fromGroup('2'), ng.NovaGroup.processedCulinary);
      expect(ng.NovaGroup.fromGroup(3), ng.NovaGroup.processed);
      expect(ng.NovaGroup.fromGroup('4'), ng.NovaGroup.ultraProcessed);
    });

    test('returns null for invalid groups', () {
      expect(ng.NovaGroup.fromGroup(0), isNull);
      expect(ng.NovaGroup.fromGroup(5), isNull);
      expect(ng.NovaGroup.fromGroup('bogus'), isNull);
      expect(ng.NovaGroup.fromGroup(null), isNull);
    });
  });
}
