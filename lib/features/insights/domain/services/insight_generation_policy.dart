import 'package:gutgood/core/ai/protocol/ai_constants.dart';
import 'package:gutgood/core/models/models.dart';

/// Applies the deterministic envelope rules to an AI-generated insight.
///
/// This policy is intentionally independent of Flutter, Firebase, persistence
/// SDKs, and other infrastructure so it can be reused and tested in isolation.
AIInsight stampInsightEnvelope(
  AIInsight insight, {
  required List<BodyPattern> candidates,
  required DateTime periodFrom,
  required DateTime periodTo,
  required SampleSizes sampleSizes,
  required String model,
  required int promptVersion,
  required DateTime expiresAt,
  int? exactGutScore,
  bool? hasGutScore,
  int? avgScanScore,
  List<int>? weeklyTrend,
  WeeklyRecap? weeklyRecap,
}) {
  final totalFood = sampleSizes.meals + sampleSizes.scans;
  final isInsufficient = totalFood < 3 || sampleSizes.symptoms < 1;
  final status = isInsufficient ? AIInsight.statusInsufficientData : AIInsight.statusReady;

  final updatedScore = exactGutScore ?? insight.gutScore;
  final updatedRecap = weeklyRecap ?? insight.weeklyRecap;
  // Prefer the deterministic weekly trend on the recap; if the caller passed
  // [weeklyTrend] and the recap is missing it, fold it in so Insight screens
  // always see the same 7-day series as gut_scores.dailyScores.
  final recapWithTrend = updatedRecap == null
      ? null
      : (weeklyTrend != null && (updatedRecap.gutScoreTrend == null || updatedRecap.gutScoreTrend!.isEmpty) ? updatedRecap.copyWith(gutScoreTrend: weeklyTrend) : updatedRecap);

  // hasGutScore: explicit flag from calculator wins; otherwise keep prior.
  // Score 0 with hasGutScore=true means "scored but zero"; false means unknown.
  final resolvedHasScore = hasGutScore ?? insight.hasGutScore;

  return insight.copyWith(
    gutScore: updatedScore,
    hasGutScore: resolvedHasScore,
    weeklyRecap: recapWithTrend ?? updatedRecap,
    periodFrom: periodFrom,
    periodTo: periodTo,
    evidence: InsightEvidence.fromPatterns(candidates, sampleSizes: sampleSizes),
    status: status,
    actions: insight.actions.isNotEmpty ? insight.actions : (insight.topInsight?.nextSteps ?? const []),
    schemaVersion: AiVersions.schemaVersion,
    model: model,
    promptVersion: promptVersion,
    expiresAt: expiresAt,
    origin: AIInsight.originClient,
  );
}

/// Takes the [limit] most recent messages from a newest-first list.
List<ChatMessage> takeRecentChat(List<ChatMessage> newestFirst, [int limit = 10]) => newestFirst.length > limit ? newestFirst.sublist(0, limit) : newestFirst;
