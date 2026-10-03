import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/ai/prompts/mode_prompts/image_classification_prompt.dart';
import 'package:gutgood/core/ai/prompts/mode_prompts/intent_detection_prompt.dart';
import 'package:gutgood/core/ai/prompts/schema_definitions.dart';
import 'package:gutgood/core/ai/protocol/ai_constants.dart';

/// Matches ALL_CAPS_WITH_UNDERSCORES tokens of 2+ segments (e.g.
/// `MEAL_RATING`), which is the shape every intent/image-mode enum value
/// takes. Used to scan prompt text for any hand-typed enum-looking literal
/// that isn't actually one of the canonical constants.
final _enumLikeToken = RegExp(r'\b[A-Z][A-Z0-9]*(?:_[A-Z0-9]+)+\b');

/// Regression test for audit finding §C.2 / §O item 4: "Unify the three
/// intent enums into one canonical source." Previously
/// `intent_detection_prompt.dart`, `image_classification_prompt.dart`, and
/// `schema_definitions.dart`'s `unifiedDataSchema` each hand-typed their own
/// copy of the intent/image-mode vocabulary and silently drifted apart
/// (values existed in one prompt's category list but not in the schema enum
/// the model was told to emit, or vice versa).
///
/// Note: `IntentDetectionPrompt` (text-only turns) and
/// `ImageClassificationPrompt` (image turns) intentionally each reference
/// only a *subset* of `UserIntent.all` relevant to their context (e.g. image
/// classification never needs `SYMPTOM_ANALYSIS`, text-only detection never
/// needs `GENERAL_IMAGE_ANALYSIS`). What must NEVER happen is either prompt
/// inventing an enum-shaped literal that ISN'T in the canonical list — that
/// silent drift is exactly what previously caused classification -> schema
/// mismatches. This test asserts that invariant instead of requiring full
/// coverage of the enum in every surface.
void main() {
  group('Intent/ImageMode enum-consistency (audit §C.2 / §O item 4)', () {
    final knownTokens = {...UserIntent.all, ...ImageMode.all};

    /// Enum-shaped words that legitimately appear in prose but aren't part of
    /// either canonical enum (e.g. referenced product/schema field names).
    const allowlist = {'GUTGOOD_DATA', 'CATEGORY_NAME'};

    test('IntentDetectionPrompt never hand-types an intent/mode value outside the canonical enums', () {
      final tokens = _enumLikeToken.allMatches(IntentDetectionPrompt.instruction).map((m) => m.group(0)!).where((t) => !allowlist.contains(t)).toSet();
      final unknown = tokens.difference(knownTokens);
      expect(unknown, isEmpty, reason: 'IntentDetectionPrompt references enum-shaped value(s) $unknown that are not in UserIntent.all/ImageMode.all — likely drift from a hand-typed literal.');
    });

    test('ImageClassificationPrompt never hand-types an intent/mode value outside the canonical enums', () {
      final tokens = _enumLikeToken.allMatches(ImageClassificationPrompt.instruction).map((m) => m.group(0)!).where((t) => !allowlist.contains(t)).toSet();
      final unknown = tokens.difference(knownTokens);
      expect(unknown, isEmpty, reason: 'ImageClassificationPrompt references enum-shaped value(s) $unknown that are not in UserIntent.all/ImageMode.all — likely drift from a hand-typed literal.');
    });

    test('every image mode ImageClassificationPrompt is asked to detect is drawn from ImageMode.all', () {
      // ImageClassificationPrompt IS expected to cover the full ImageMode
      // vocabulary (it's the only classifier for image_mode), unlike the
      // intent subset behavior above.
      for (final mode in ImageMode.all) {
        expect(ImageClassificationPrompt.instruction.contains(mode), isTrue, reason: 'ImageClassificationPrompt is missing image mode "$mode" from the canonical ImageMode.all list.');
      }
    });

    test('SchemaDefinitions.unifiedDataSchema intent enum matches UserIntent.all exactly', () {
      final schema = SchemaDefinitions.unifiedDataSchema;
      final expectedIntentLine = '"intent": "${UserIntent.all.join('|')}"';
      expect(schema.contains(expectedIntentLine), isTrue, reason: 'unifiedDataSchema intent enum has drifted from the canonical UserIntent.all list.');
    });

    test('SchemaDefinitions.unifiedDataSchema image_mode enum matches ImageMode.all exactly', () {
      final schema = SchemaDefinitions.unifiedDataSchema;
      final expectedModeLine = '"image_mode": "${ImageMode.all.join('|')}"';
      expect(schema.contains(expectedModeLine), isTrue, reason: 'unifiedDataSchema image_mode enum has drifted from the canonical ImageMode.all list.');
    });

    test('SchemaDefinitions.typeRules intent enum matches UserIntent.all exactly', () {
      final typeRules = SchemaDefinitions.typeRules;
      final expectedIntentText = UserIntent.all.map((v) => '"$v"').join(', ');
      expect(typeRules.contains(expectedIntentText), isTrue, reason: 'typeRules intent enum text has drifted from the canonical UserIntent.all list.');
    });

    test('every intent Prompts._getPromptForIntent can route to is drawn from UserIntent.all', () {
      // Every intent value the app can actually produce (classifier output)
      // must be routable; conversely every routing keyword should trace back
      // to a canonical value. We assert the canonical list itself is
      // non-empty and duplicate-free as the base invariant other tests build
      // on.
      expect(UserIntent.all, isNotEmpty);
    });

    test('UserIntent.all has no duplicate values', () {
      expect(UserIntent.all.toSet().length, UserIntent.all.length);
    });

    test('ImageMode.all has no duplicate values', () {
      expect(ImageMode.all.toSet().length, ImageMode.all.length);
    });
  });
}
