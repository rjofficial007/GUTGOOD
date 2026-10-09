import 'package:gutgood/core/models/insights/ai_insight.dart';
import 'package:gutgood/core/models/insights/ai_insight_details.dart';
import 'package:gutgood/core/models/insights/body_pattern.dart';
import 'package:gutgood/core/models/insights/insight_evidence.dart';
import 'package:gutgood/core/utils/insight_presentation.dart';

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
    final foodImpacts = _buildFoodImpacts(patterns);
    final foodImpactBalance = _buildFoodImpactBalance(foodImpacts);

    return AIInsight(
      firestoreId: latestDocumentId,
      uid: uid,
      gutScore: gutScore,
      hasGutScore: hasGutScore,
      topInsight: topInsight,
      detectedPatterns: patterns,
      foodImpacts: foodImpacts,
      foodImpactBalance: foodImpactBalance,
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

  static List<FoodImpact> _buildFoodImpacts(List<BodyPattern> patterns) {
    final rawImpacts = <({FoodImpact impact, String isoDate})>[];
    final seen = <String>{};

    for (final pattern in patterns) {
      final direction = pattern.impactDirection.toLowerCase().trim();
      final isPositive = direction == 'positive' ||
          const ['High Energy', 'Satiety', 'Better Sleep', 'Energized'].contains(pattern.reaction);
      final isNegative = direction == 'negative' ||
          const ['Bloating', 'Energy Drop', 'Headache', 'Indigestion', 'Restless Sleep', 'Sluggish', 'Heartburn/Indigestion', 'Skin Flare-up', 'Migraine', 'Severe Bloating'].contains(pattern.reaction) ||
          pattern.type == BodyPattern.typeBloating ||
          pattern.type == BodyPattern.typeHeadache ||
          pattern.type == BodyPattern.typeDigestion;

      final impactType = isPositive ? 'positive' : (isNegative ? 'negative' : direction);

      for (final occurrence in pattern.occurrences) {
        final mealName = occurrence.mealName.trim().isNotEmpty
            ? occurrence.mealName.trim()
            : pattern.trigger.trim();
        if (mealName.isEmpty) continue;

        final isoDate = occurrence.date.trim();
        final dateLabel = occurrence.dateLabel?.trim().isNotEmpty == true
            ? occurrence.dateLabel!.trim()
            : isoDate;
        final effect = occurrence.reaction.trim().isNotEmpty
            ? occurrence.reaction.trim()
            : pattern.reaction.trim();
        final timeframeLabel = occurrence.timeAfterLabel?.trim().isNotEmpty == true
            ? occurrence.timeAfterLabel!.trim()
            : (occurrence.timeAfter.trim().isNotEmpty ? occurrence.timeAfter.trim() : 'After meal');

        final mealId = occurrence.mealId?.trim();
        final symptomId = occurrence.symptomId?.trim();
        final key = (mealId != null && mealId.isNotEmpty && symptomId != null && symptomId.isNotEmpty)
            ? '${mealId}_$symptomId'
            : '${isoDate}_${mealName.toLowerCase()}_${effect.toLowerCase()}_${pattern.type}';

        if (!seen.add(key)) continue;

        rawImpacts.add((
          impact: FoodImpact(
            food: mealName,
            dateLabel: dateLabel,
            effect: effect,
            timeframeLabel: timeframeLabel,
            emoji: InsightPresentation.emojiForFood(mealName),
            impactType: impactType,
            imageUrl: occurrence.imageUrl,
            userImageUrl: occurrence.imageUrl,
          ),
          isoDate: isoDate,
        ));
      }
    }

    rawImpacts.sort((a, b) => b.isoDate.compareTo(a.isoDate));

    return rawImpacts.map((e) => e.impact).take(50).toList();
  }

  static FoodImpactBalance? _buildFoodImpactBalance(List<FoodImpact> foodImpacts) {
    if (foodImpacts.isEmpty) return null;

    var positiveCount = 0;
    var negativeCount = 0;

    for (final impact in foodImpacts) {
      final type = impact.impactType.toLowerCase().trim();
      if (type == 'positive' || type == 'healing' || type == 'good' || type == 'supportive') {
        positiveCount++;
      } else if (type == 'negative' || type == 'trigger' || type == 'bad' || type == 'watch') {
        negativeCount++;
      }
    }

    final total = positiveCount + negativeCount;
    if (total == 0) return null;

    final positivePercent = (positiveCount * 100 / total).round();
    final negativePercent = 100 - positivePercent;

    return FoodImpactBalance(
      positivePercent: positivePercent,
      neutralPercent: 0,
      negativePercent: negativePercent,
      periodLabel: '30-day window',
    );
  }
}
