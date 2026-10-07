import 'package:gutgood/core/models/insights/ai_insight.dart';
import 'package:gutgood/core/models/insights/ai_insight_details.dart';
import 'package:gutgood/core/models/insights/body_pattern.dart';
import 'package:gutgood/core/models/insights/insight_evidence.dart';

/// Builds the durable Insights snapshot from deterministic calculations only.
/// No model, prompt, or network service is involved.
class RuleBasedInsightBuilder {
  const RuleBasedInsightBuilder();

  static const latestDocumentId = 'rule_based_latest';

  AIInsight build({
    required String? uid,
    required List<BodyPattern> patterns,
    required SampleSizes sampleSizes,
    required WeeklyRecap weeklyRecap,
    required int gutScore,
    required bool hasGutScore,
    required DateTime periodFrom,
    required DateTime periodTo,
    required DateTime updatedAt,
  }) {
    final topPattern = patterns.isEmpty ? null : patterns.first;
    final nextSteps = topPattern == null
        ? const <String>[]
        : <String>[
            'Keep logging meals you actually ate and how you feel afterward. A timing association does not establish cause.',
          ];

    final topInsight = topPattern == null
        ? null
        : InsightSummary(
            title: '${topPattern.reaction} reported after ${topPattern.trigger}',
            description: '${topPattern.frequency} logged meal-and-response observations matched this timing rule. This is an association in your logs, not proof of cause.',
            type: 'pattern',
            domain: topPattern.type,
            observation: topPattern.description,
            involvedFoods: topPattern.involvedFoods,
            strength: topPattern.evidenceLabel,
            nextSteps: nextSteps,
            frequency: topPattern.frequency,
          );

    final hasRecentEvidence = sampleSizes.meals + sampleSizes.scans + sampleSizes.symptoms > 0;

    return AIInsight(
      firestoreId: latestDocumentId,
      uid: uid,
      gutScore: gutScore,
      hasGutScore: hasGutScore,
      topInsight: topInsight,
      detectedPatterns: patterns,
      weeklyRecap: weeklyRecap,
      type: 'Rule-based',
      confidenceLevel: topPattern?.evidenceLabel ?? 'Building baseline',
      updatedAt: updatedAt,
      periodFrom: periodFrom,
      periodTo: periodTo,
      evidence: InsightEvidence.fromPatterns(patterns, sampleSizes: sampleSizes),
      actions: nextSteps,
      status: hasRecentEvidence ? AIInsight.statusReady : AIInsight.statusInsufficientData,
      origin: AIInsight.originRuleBased,
    );
  }
}
