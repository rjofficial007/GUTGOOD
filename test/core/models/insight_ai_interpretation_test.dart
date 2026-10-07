import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/models.dart';

void main() {
  test('optional AI interpretation round-trips without replacing deterministic findings', () {
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
        followUpQuestion: 'Would you note the dinner time next time?',
        generatedAt: generatedAt,
        promptVersion: 1,
        model: 'gpt-4o-mini',
      ),
    );

    final restored = AIInsight.fromMap(insight.toMap());

    expect(restored.detectedPatterns, [rulePattern]);
    expect(restored.aiInterpretation?.summary, insight.aiInterpretation?.summary);
    expect(restored.aiInterpretation?.followUpQuestion, insight.aiInterpretation?.followUpQuestion);
    expect(restored.aiInterpretation?.model, 'gpt-4o-mini');
  });
}
