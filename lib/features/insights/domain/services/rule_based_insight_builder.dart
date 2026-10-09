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

    // Food Impact is derived only from explicit meal-response occurrences
    // already counted by the rule engine. Keep each row tied to that evidence;
    // do not infer impact from scans or from meals with no reported response.
    final foodImpactEntries = <({String date, FoodImpact impact})>[];
    final seenOccurrences = <String>{};
    for (final pattern in patterns) {
      if (pattern.impactDirection != 'positive' && pattern.impactDirection != 'negative') continue;
      for (final occurrence in pattern.occurrences) {
        final sourceKey = occurrence.mealId != null && occurrence.symptomId != null
            ? '${occurrence.mealId}:${occurrence.symptomId}'
            : '${occurrence.date}:${occurrence.mealName}:${occurrence.reaction}:${pattern.type}';
        if (!seenOccurrences.add(sourceKey)) continue;
        foodImpactEntries.add((
          date: occurrence.date,
          impact: FoodImpact(
            food: occurrence.mealName.isNotEmpty ? occurrence.mealName : pattern.trigger,
            dateLabel: occurrence.dateLabel?.isNotEmpty == true ? occurrence.dateLabel! : occurrence.date,
            effect: 'Reported ${occurrence.reaction}',
            timeframeLabel: occurrence.timeAfter,
            emoji: '🍽️',
            impactType: pattern.impactDirection,
            imageUrl: occurrence.imageUrl,
            userImageUrl: occurrence.imageUrl,
          ),
        ));
      }
    }
    foodImpactEntries.sort((a, b) => b.date.compareTo(a.date));
    final recentFoodImpacts = foodImpactEntries.take(50).map((entry) => entry.impact).toList();
    final positiveCount = recentFoodImpacts.where((impact) => impact.impactType == 'positive').length;
    final negativeCount = recentFoodImpacts.where((impact) => impact.impactType == 'negative').length;
    final impactCount = positiveCount + negativeCount;

    return AIInsight(
      firestoreId: latestDocumentId,
      uid: uid,
      gutScore: gutScore,
      hasGutScore: hasGutScore,
      topInsight: topInsight,
      detectedPatterns: patterns,
      foodImpacts: recentFoodImpacts,
      foodImpactBalance: impactCount == 0
          ? null
          : FoodImpactBalance(
              positivePercent: (positiveCount * 100 / impactCount).round(),
              neutralPercent: 0,
              negativePercent: (negativeCount * 100 / impactCount).round(),
              periodLabel: 'Last 30 days · $impactCount meal-response observations',
            ),
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
