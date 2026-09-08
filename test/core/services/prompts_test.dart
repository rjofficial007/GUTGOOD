import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/services/prompts.dart';

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
  });

  group('Prompts.chatSystemInstruction — size & cacheability contract', () {
    /// Mirrors the server-side cap in functions/src/config.ts.
    const int maxSystemChars = 24000;

    /// Marker separating the cacheable static block from per-user/per-request
    /// values (see the ORDERING CONTRACT comment in prompts.dart).
    const String dynamicMarker = '=================== DYNAMIC CONTEXT (not cacheable) ===================';

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
        reason: 'ai_proxy slices the system instruction to MAX_SYSTEM_CHARS. Anything above it is silently truncated, '
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
}
