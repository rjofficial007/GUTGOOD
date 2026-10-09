import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/ai/prompts/mode_prompts/image_classification_prompt.dart';
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

    test('includes the controlled journal tag and optional time rules for structured meal turns', () {
      final instruction = Prompts.chatSystemInstruction(userGoals: const [], userSensitivities: const [], intent: 'COMPLETE_ANALYSIS', mode: 'FOOD');

      expect(instruction, contains('"foodTags": ["dairy"]'));
      expect(instruction, contains('processed_meat'));
      expect(instruction, contains('Use [] only when none of the tags can be supported'));
      expect(instruction, contains('Do not emit meal.occurredAtProvenance'));
      expect(instruction, contains('only when the user explicitly gives the time'));
      expect(instruction, isNot(contains('time: ALWAYS ISO 8601')));
      expect(instruction, contains('symptoms[].sleep'));
    });

    test('shares swap relevance and evidence rules across chat and barcode prompts', () {
      final chatInstruction = Prompts.chatSystemInstruction(userGoals: const [], userSensitivities: const [], intent: 'MEAL_SWAPS', mode: 'FOOD');
      final barcodeInstruction = Prompts.barcodeAnalysisSystemInstruction;

      for (final instruction in [chatInstruction, barcodeInstruction]) {
        expect(instruction, contains('replaces=scan.productName'));
        expect(instruction, contains('same dish family (pizza→pizza; burger/fast food→complete main)'));
        expect(instruction, contains('No sides or ingredients as meal swaps'));
        expect(instruction, contains('unsupported health, calorie, weight-loss, symptom or disease claims'));
        expect(instruction, contains('Never estimate or compare bases'));
      }
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

  test('structured vision and barcode prompts include swap rules; text modes omit the schema', () {
    for (final mode in ['FOOD', 'BARCODE']) {
      final prompt = Prompts.visionAnalysisSystemInstruction(mode: mode, userGoals: [], userSensitivities: [], cyclePhase: 'Luteal');
      expect(prompt, contains('SCHEMA TYPE RULES'));
      expect(prompt, contains('"structuredBenefits"'));
        expect(prompt, contains('swaps: four supported or []'));
        expect(prompt, contains('same dish family (pizza→pizza; burger/fast food→complete main)'));
      expect(prompt, contains('"impacts": [{"title"'));
    }
    for (final mode in ['LABEL', 'MENU']) {
      final prompt = Prompts.visionAnalysisSystemInstruction(mode: mode, userGoals: [], userSensitivities: [], cyclePhase: 'Luteal');
      expect(prompt, isNot(contains('"cycleInsight"')));
      expect(prompt, isNot(contains('"swaps":')));
      expect(prompt, isNot(contains('you MUST populate')));
      expect(prompt, isNot(contains('SCHEMA TYPE RULES')));
    }
  });

  test('score prose and structured nutrition rules match the app-calculated display', () {
    final rating = Prompts.chatSystemInstruction(userGoals: const [], userSensitivities: const [], intent: 'MEAL_RATING', mode: 'FOOD');
    final fullAnalysis = Prompts.chatSystemInstruction(userGoals: const [], userSensitivities: const [], intent: 'COMPLETE_ANALYSIS', mode: 'FOOD');

    expect(rating, contains('2. Rating: **GutGood Rating: X/100**'));
    expect(fullAnalysis, contains('2. Rating: **GutGood Rating: X/100**'));
    expect(rating, contains('This value MUST match scan.score'));
    expect(rating, contains('scan.score: integer 0-100 fallback only'));
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
  });
}
