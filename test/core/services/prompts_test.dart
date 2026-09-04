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
}
