import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/utils/narrative_text.dart';

void main() {
  test('replaces a model rating with the final engine rating instead of duplicating it', () {
    final text = NarrativeText.injectRating('**A balanced lunch!**\n\n**GutGood Rating: 42/100**\n\nThe meal includes protein and fiber.', 78);

    expect(text, contains('**GutGood Rating: 78/100'));
    expect(text, isNot(contains('42/100')));
    expect(RegExp('GutGood Rating:').allMatches(text), hasLength(1));
    expect(text.indexOf('GutGood Rating:'), greaterThan(text.indexOf('A balanced lunch!')));
  });
}
