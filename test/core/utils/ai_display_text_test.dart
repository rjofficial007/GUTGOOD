import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/utils/ai_display_text.dart';

void main() {
  test('removes the structured block and everything after it from displayed text', () {
    const response = 'Here is my take.\n\n[GUTGOOD_DATA] {"scan": {"score": 70}} [/GUTGOOD_DATA]';

    expect(stripAiStructuredDataForDisplay(response), 'Here is my take.');
  });

  test('keeps plain responses and removes legacy data tags', () {
    expect(stripAiStructuredDataForDisplay('A regular answer.'), 'A regular answer.');
    expect(stripAiStructuredDataForDisplay('A regular answer. [SCAN]{"score": 70}[/SCAN]'), 'A regular answer.');
  });
}
