import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/utils/insight_values.dart';

void main() {
  test('treats unavailable insight placeholders as missing display values', () {
    for (final value in const ['N/A', ' not available ', '—', '']) {
      expect(InsightValues.text(value, fallback: 'Building your baseline'), 'Building your baseline');
    }
    expect(InsightValues.text('Improving'), 'Improving');
  });
}
