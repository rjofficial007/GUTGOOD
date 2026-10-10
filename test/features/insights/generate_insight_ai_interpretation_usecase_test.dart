import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/ai/client/ai_client.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/features/insights/application/usecases/generate_insight_ai_interpretation_usecase.dart';
import 'package:gutgood/features/insights/domain/repositories/insight_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockAiClient extends Mock implements AiClient {}

class MockInsightRepository extends Mock implements InsightRepository {}

void main() {
  test('returns today’s saved summary without making another AI request', () async {
    final saved = InsightAiInterpretation(summary: 'Saved for today.', generatedAt: DateTime.now(), promptVersion: 2);
    final insight = AIInsight(
      firestoreId: 'rule_based_latest',
      uid: 'user-1',
      gutScore: 70,
      detectedPatterns: const [],
      updatedAt: DateTime.now(),
      origin: AIInsight.originRuleBased,
      aiInterpretation: saved,
    );
    final useCase = GenerateInsightAiInterpretationUseCase(aiClient: MockAiClient(), insightRepository: MockInsightRepository());

    expect(await useCase.execute(insight), same(saved));
  });

  group('GenerateInsightAiInterpretationUseCase eligibility', () {
    test('allows only a multi-area rule-based snapshot with repeated observations', () {
      final insight = _insight(patterns: [_pattern('bloating'), _pattern('sleep')]);

      expect(GenerateInsightAiInterpretationUseCase.canExplain(insight), isTrue);
    });

    test('does not call for one area, one-off observations, or legacy AI snapshots', () {
      final oneArea = _insight(patterns: [_pattern('bloating'), _pattern('bloating')]);
      final oneOff = _insight(patterns: [_pattern('bloating'), _pattern('sleep', frequency: 1)]);
      final legacy = _insight(patterns: [_pattern('bloating'), _pattern('sleep')], origin: AIInsight.originClient);

      expect(GenerateInsightAiInterpretationUseCase.canExplain(oneArea), isFalse);
      expect(GenerateInsightAiInterpretationUseCase.canExplain(oneOff), isFalse);
      expect(GenerateInsightAiInterpretationUseCase.canExplain(legacy), isFalse);
    });

    test('caps AI evidence to the five most frequent eligible patterns', () {
      final patterns = [
        _pattern('sleep', frequency: 2),
        _pattern('bloating', frequency: 3),
        _pattern('energy', frequency: 4),
        _pattern('headache', frequency: 5),
        _pattern('digestion', frequency: 6),
        _pattern('fullness', frequency: 7),
      ];

      final eligible = GenerateInsightAiInterpretationUseCase.eligiblePatterns(_insight(patterns: patterns));

      expect(eligible, hasLength(5));
      expect(eligible.first.frequency, 7);
    });
  });
}

AIInsight _insight({required List<BodyPattern> patterns, String origin = AIInsight.originRuleBased}) => AIInsight(
  firestoreId: 'rule_based_latest',
  uid: 'user-1',
  gutScore: 70,
  detectedPatterns: patterns,
  updatedAt: DateTime.utc(2026, 1, 1),
  status: AIInsight.statusReady,
  origin: origin,
);

BodyPattern _pattern(String type, {int frequency = 2}) => BodyPattern(
  type: type,
  trigger: '$type context',
  reaction: '$type response',
  frequency: frequency,
  confidence: frequency >= 3 ? 'Medium' : 'Low',
  description: '$frequency logged observations',
  updatedAt: DateTime.utc(2026, 1, 1).toIso8601String(),
);
