import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/ai/prompts/mode_prompts/image_classification_prompt.dart';
import 'package:gutgood/core/ai/prompts/mode_prompts/insights_prompt.dart';
import 'package:gutgood/core/ai/prompts/mode_prompts/intent_detection_prompt.dart';
import 'package:gutgood/core/ai/prompts/prompt_catalog.dart';
import 'package:gutgood/core/ai/protocol/ai_constants.dart';

void main() {
  group('Prompts.chatSystemInstruction', () {
    test('injects the [GUTGOOD_DATA] JSON schema body exactly once for normal (non label/menu) turns', () {
      final instruction = Prompts.chatSystemInstruction(userGoals: const [], userSensitivities: const [], intent: 'COMPLETE_ANALYSIS', mode: 'FOOD');

      // "cycleInsight" only appears inside SchemaDefinitions.unifiedDataSchema
      // itself (never in prose/instructions that merely reference the
      // [GUTGOOD_DATA] tag by name), so it's a reliable marker for how many
      // times the actual ~100-line JSON schema was interpolated.
      final schemaBodyOccurrences = 'cycleInsight'.allMatches(instruction).length;
      expect(
        schemaBodyOccurrences,
        1,
        reason: 'The unified data JSON schema body must only be injected once per system prompt to avoid wasting tokens / confusing the model with a duplicated instruction.',
      );
    });

    test('does NOT inject the [GUTGOOD_DATA] JSON schema body for label/menu turns', () {
      final instruction = Prompts.chatSystemInstruction(userGoals: const [], userSensitivities: const [], intent: 'INGREDIENT_ANALYSIS', mode: 'INGREDIENTS_LABEL');

      expect(instruction.contains('cycleInsight'), isFalse);
    });

    test('renders pinned entities in the dynamic section; omits the block when empty', () {
      final withPins = Prompts.chatSystemInstruction(
        userGoals: const [],
        userSensitivities: const [],
        intent: 'COMPLETE_ANALYSIS',
        mode: 'FOOD',
        historySummary: 'old news',
        pinnedEntities: 'foods: Pizza',
      );

      expect(withPins, contains('PINNED ENTITIES'));
      expect(withPins, contains('foods: Pizza'));
      // After the dynamic-context marker (cacheable prefix untouched).
      expect(withPins.indexOf('PINNED ENTITIES'), greaterThan(withPins.indexOf('DYNAMIC CONTEXT')));

      final withoutPins = Prompts.chatSystemInstruction(userGoals: const [], userSensitivities: const [], intent: 'COMPLETE_ANALYSIS', mode: 'FOOD');

      expect(withoutPins, isNot(contains('PINNED ENTITIES')));
    });
  });

  group('Prompts.chatSystemInstruction — size & cacheability contract', () {
    /// Mirrors the server-side cap in functions/src/config.ts.
    const maxSystemChars = 24000;

    /// Marker separating the cacheable static block from per-user/per-request
    /// values (see the ORDERING CONTRACT comment in prompts.dart).
    const dynamicMarker = '=================== DYNAMIC CONTEXT (not cacheable) ===================';

    String buildWorstCaseProfile() => Prompts.chatSystemInstruction(
      userGoals: List.generate(8, (i) => 'Reduce bloating and improve steady energy levels throughout the day (goal ${i + 1})'),
      userSensitivities: List.generate(8, (i) => 'High FODMAP foods and artificial sweeteners that trigger symptoms (sensitivity ${i + 1})'),
      userLifestyle: List.generate(6, (i) => 'Vegetarian, high stress job, gym four times a week, irregular sleep (lifestyle ${i + 1})'),
      cyclePhase: 'Luteal',
      communicationStyle: 'Direct & Scientific, with clinical language and precise recommendations',
      historySummary:
          'Over the past month the user logged 96 meals and 44 symptom entries. Recurring theme: bloating and low energy within two to four hours of dairy-heavy dinners (reported 11 times). '
          'The user trialled oat milk on Sep 2 and reported improved morning energy for five consecutive days. They scanned 21 packaged products, mostly high-NOVA afternoon snacks, and '
          'consistently skipped logging at weekends, which leaves a gap in the pattern evidence every Saturday and Sunday.',
      currentTime: DateTime.now().toIso8601String(),
      mode: 'FOOD',
      intent: 'COMPLETE_ANALYSIS',
    );

    test('stays under the server-side MAX_SYSTEM_CHARS cap for a worst-case profile', () {
      final instruction = buildWorstCaseProfile();

      expect(
        instruction.length,
        lessThan(maxSystemChars),
        reason:
            'ai_proxy slices the system instruction to MAX_SYSTEM_CHARS. Anything above it is silently truncated, '
            'cutting SCHEMA TYPE RULES / EVIDENCE-AWARE REASONING mid-sentence and producing malformed [GUTGOOD_DATA].',
      );
    });

    test('places a cacheable static block before any per-user or per-request value', () {
      final instruction = Prompts.chatSystemInstruction(userGoals: const [], userSensitivities: const [], mode: 'FOOD', intent: 'COMPLETE_ANALYSIS');

      expect(instruction.contains(dynamicMarker), isTrue, reason: 'The dynamic-context marker is part of the ordering contract; keep it in sync with prompts.dart.');

      final staticPrefix = instruction.substring(0, instruction.indexOf(dynamicMarker));

      // OpenAI prompt caching only discounts identical prefixes of ~1024+ tokens.
      expect(staticPrefix.length, greaterThan(4096), reason: 'The static prefix must exceed ~1024 tokens, otherwise every request pays full price for the schema.');

      // Anything that changes per user or per request must live below the marker.
      for (final leak in const ['CURRENT TIME', 'Health Goals', 'Current Cycle Phase', 'RECENT HISTORY SUMMARY']) {
        expect(staticPrefix.contains(leak), isFalse, reason: '"$leak" is dynamic and must not appear above the cacheable prefix.');
      }
    });
  });

  group('Classifier vocabulary consistency', () {
    test('intent detection prompt lists every canonical UserIntent token', () {
      final instruction = IntentDetectionPrompt.instruction;
      for (final intent in UserIntent.all) {
        expect(instruction.contains(intent), isTrue, reason: 'Intent "$intent" must be a documented category so the classifier can return it.');
      }
    });

    test('intent detection rules never recommend an invalid (non-vocabulary) token', () {
      final instruction = IntentDetectionPrompt.instruction;
      // Historical failure: the STRICT RULES ordered the model to return tokens
      // outside UserIntent.all, which _canonicalIntent silently downgraded to
      // COMPLETE_ANALYSIS. The rules may cite them as INVALID examples, but must
      // never present one as the token to use/return.
      for (final recommendation in const ['use `meal_overview`', 'use `menu`', 'use `full_analysis`', 'use `health_assessment`', 'return `meal_overview`', 'return `menu`', 'return `full_analysis`']) {
        expect(instruction.contains(recommendation), isFalse, reason: '"$recommendation" is not a UserIntent token and must not be recommended.');
      }
    });

    test('image classification prompt covers every canonical UserIntent token', () {
      const instruction = ImageClassificationPrompt.instruction;
      for (final intent in UserIntent.all) {
        expect(instruction.contains(intent), isTrue, reason: 'Intent "$intent" must be classifiable from photo turns too (e.g. symptom photos).');
      }
    });

    test('image classification prompt covers every canonical ImageMode token', () {
      const instruction = ImageClassificationPrompt.instruction;
      for (final mode in ImageMode.all) {
        expect(instruction.contains(mode), isTrue, reason: 'ImageMode "$mode" must be a documented category.');
      }
    });

    test('insights prompt defines the ZERO PATTERN CASE it references', () {
      const instruction = InsightsPrompt.instruction;
      expect(instruction.contains('ZERO PATTERN CASE'), isTrue, reason: 'The checklist references a ZERO PATTERN CASE; without a definition the model invents patterns from thin data.');
      expect(instruction, contains('Return status "ready"'));
      expect(instruction, contains('Generate a concise personalized topInsight'));
      expect(instruction, contains('one occurrence is not enough to identify a cause'));
      expect(instruction, contains('Do not create a detectedPattern, trigger, healing food'));
      expect(instruction, contains('Never infer fat content'));
      expect(instruction.contains('COMMON FACTORS MUST NOT BE EMPTY'), isFalse);
    });

    test('insights prompt v2 asks for data only (P2-10: Dart owns presentation)', () {
      const instruction = InsightsPrompt.instruction;
      expect(instruction.contains('REQUIRED single food emoji'), isFalse, reason: 'Emoji is write-only busywork; the model must not emit it.');
      expect(instruction.contains('NO PRESENTATION'), isTrue, reason: 'The schema must carry an explicit no-emoji/no-icon/no-color rule.');
      expect(instruction.contains('High|Medium|Low'), isTrue, reason: 'Pattern confidence must mirror the engine vocabulary.');
    });

    test('food swaps classify alternatives by their own type for useful filters', () {
      const instruction = InsightsPrompt.instruction;
      expect(instruction, contains('FOOD SWAPS AND FILTER CATEGORIES'));
      expect(instruction, contains('grilled chicken → `Protein`'));
      expect(instruction, contains('plant-based patty → `Plant-Based`'));
      expect(instruction, contains('whole-grain bun → `Grains & Bread`'));
      expect(instruction, isNot(contains('Burgers & Sandwiches|Bowls|Breakfast|Sides')));
    });
  });
}
