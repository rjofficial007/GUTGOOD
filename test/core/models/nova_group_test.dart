import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/nova_group.dart';

void main() {
  group('NovaGroup', () {
    test('parses group numbers correctly', () {
      expect(NovaGroup.fromGroup(1), NovaGroup.unprocessed);
      expect(NovaGroup.fromGroup('2'), NovaGroup.processedCulinary);
      expect(NovaGroup.fromGroup(3), NovaGroup.processed);
      expect(NovaGroup.fromGroup('4'), NovaGroup.ultraProcessed);
      expect(NovaGroup.fromGroup(null), isNull);
      expect(NovaGroup.fromGroup('invalid'), isNull);
    });

    test('group labels match NOVA specification', () {
      expect(NovaGroup.unprocessed.label, 'Unprocessed');
      expect(NovaGroup.ultraProcessed.label, 'Ultra-Processed');
    });
  });
}
