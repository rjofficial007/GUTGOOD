import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/models.dart';

void main() {
  test('daily interpretation date follows the local calendar day', () {
    final generatedAt = DateTime(2026, 10, 10, 23, 50).toUtc();
    final interpretation = InsightAiInterpretation(summary: 'A saved summary.', generatedAt: generatedAt, promptVersion: 2);
    final generatedLocalDate = generatedAt.toLocal();

    expect(interpretation.wasGeneratedOn(generatedLocalDate), isTrue);
    expect(interpretation.wasGeneratedOn(DateTime(generatedLocalDate.year, generatedLocalDate.month, generatedLocalDate.day + 1)), isFalse);
  });

  test('optional pattern interpretation round-trips without replacing deterministic findings', () {
    final generatedAt = DateTime.utc(2026, 6, 15, 10);
    final rulePattern = BodyPattern(
      type: BodyPattern.typeBloating,
      trigger: 'Late dinner',
      reaction: 'Bloating reported',
      frequency: 3,
      confidence: BodyPattern.confidenceMedium,
      description: 'Bloating was logged after these meals.',
      updatedAt: generatedAt.toIso8601String(),
    );
    final insight = AIInsight(
      firestoreId: 'rule_based_latest',
      uid: 'user-1',
      gutScore: 72,
      detectedPatterns: [rulePattern],
      updatedAt: generatedAt,
      origin: AIInsight.originRuleBased,
      aiInterpretation: InsightAiInterpretation(
        summary: 'These observations may share a timing context.',
        generatedAt: generatedAt,
        promptVersion: 1,
        model: 'gpt-4o-mini',
      ),
    );

    final restored = AIInsight.fromMap(insight.toMap());

    expect(restored.detectedPatterns, [rulePattern]);
    expect(restored.aiInterpretation?.summary, insight.aiInterpretation?.summary);
    expect(restored.aiInterpretation?.model, 'gpt-4o-mini');
  });
}
