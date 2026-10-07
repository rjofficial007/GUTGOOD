import 'dart:convert';

import 'package:gutgood/core/ai/client/ai_client.dart';
import 'package:gutgood/core/ai/protocol/ai_constants.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/features/insights/domain/repositories/insight_repository.dart';

/// Generates an optional AI explanation only for complex, rule-detected
/// observations. It is invoked explicitly by the user, never by refresh.
class GenerateInsightAiInterpretationUseCase {
  const GenerateInsightAiInterpretationUseCase({required AiClient aiClient, required InsightRepository insightRepository})
    : _aiClient = aiClient,
      _insightRepository = insightRepository;

  final AiClient _aiClient;
  final InsightRepository _insightRepository;

  static List<BodyPattern> eligiblePatterns(AIInsight insight) {
    if (insight.origin != AIInsight.originRuleBased || insight.status != AIInsight.statusReady) return const [];

    final candidates = insight.detectedPatterns
        .where((pattern) => pattern.frequency >= 2 && pattern.type.trim().isNotEmpty && pattern.trigger.trim().isNotEmpty && pattern.reaction.trim().isNotEmpty)
        .toList()
      ..sort((a, b) {
        if (a.frequency != b.frequency) return b.frequency.compareTo(a.frequency);
        return a.type.compareTo(b.type);
      });

    // Prefer one high-evidence example from each area before adding extra
    // examples, so the capped payload still contains cross-area context.
    final selected = <BodyPattern>[];
    final selectedAreas = <String>{};
    for (final pattern in candidates) {
      if (selectedAreas.add(pattern.type.trim().toLowerCase())) selected.add(pattern);
      if (selected.length == 5) return selected;
    }
    for (final pattern in candidates) {
      if (selected.length == 5) break;
      if (!selected.contains(pattern)) selected.add(pattern);
    }
    return selected;
  }

  static bool canExplain(AIInsight insight) => eligiblePatterns(insight).map((pattern) => pattern.type.trim().toLowerCase()).toSet().length >= 2;

  Future<InsightAiInterpretation> execute(AIInsight insight) async {
    final existing = insight.aiInterpretation;
    if (existing != null) return existing;

    if (!canExplain(insight)) {
      throw StateError('AI explanation requires rule-based observations from at least two different areas.');
    }
    if (insight.firestoreId != 'rule_based_latest' || insight.uid == null || insight.uid!.isEmpty || insight.periodTo == null) {
      throw StateError('Only the current saved rule-based Insight can be explained.');
    }

    final patterns = eligiblePatterns(insight);
    final evidencePayload = {
      'window_days': insight.evidence?.spanDays ?? 30,
      'patterns': patterns
          .map(
            (pattern) => {
              'area': pattern.type,
              'logged_trigger_or_context': pattern.trigger,
              'reported_response': pattern.reaction,
              'matching_observations': pattern.frequency,
              'evidence_tier': pattern.evidenceLabel,
              'rule_summary': pattern.description,
              if (pattern.typicalTiming != null) 'typical_timing': pattern.typicalTiming,
              if (pattern.typicalDelay != null) 'typical_delay': pattern.typicalDelay,
              if (pattern.involvedFoods.isNotEmpty) 'involved_foods': pattern.involvedFoods.take(6).toList(),
              if (pattern.commonFactors.isNotEmpty) 'common_logged_factors': pattern.commonFactors.map((factor) => factor.label).take(5).toList(),
            },
          )
          .toList(),
    };

    final responseText = await _aiClient.generateContent(
      systemInstruction: _systemInstruction,
      prompt: 'The user asked for help interpreting connections between these rule-detected observations from their logs. Return the required JSON only.\n\nEvidence:\n${jsonEncode(evidencePayload)}',
      usageType: 'system',
      mode: 'json',
      promptVersion: AiVersions.insightInterpretationPromptVersion,
    );

    if (_aiClient.lastResponseTruncated) {
      throw const FormatException('The AI explanation was incomplete.');
    }

    final decoded = jsonDecode(responseText);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('The AI explanation was not valid JSON.');
    }

    final summary = _boundedText(decoded['summary'], maxLength: 700);
    final followUpQuestion = _boundedText(decoded['followUpQuestion'], maxLength: 220);
    if (summary.isEmpty || followUpQuestion.isEmpty) {
      throw const FormatException('The AI explanation was missing required content.');
    }

    final interpretation = InsightAiInterpretation(
      summary: summary,
      followUpQuestion: followUpQuestion,
      generatedAt: DateTime.now().toUtc(),
      promptVersion: AiVersions.insightInterpretationPromptVersion,
      model: _aiClient.lastServedModel,
    );

    final saved = await _insightRepository.saveAiInterpretation(insight, interpretation);
    if (!saved) {
      throw StateError('The Insight changed before the explanation could be saved.');
    }
    return interpretation;
  }

  static String _boundedText(Object? value, {required int maxLength}) {
    if (value is! String) return '';
    final text = value.trim();
    if (text.isEmpty) return '';
    return text.length <= maxLength ? text : text.substring(0, maxLength).trimRight();
  }

  static const String _systemInstruction = '''You are an evidence-grounded wellness explainer, not a clinician. The input contains observations detected by GutGood's deterministic rules from user logs; they are reported associations, not medically verified facts.

Your only job is to write a short, cautious explanation of a possible connection across the supplied areas and one neutral follow-up question that could help the user log useful context next time. This synthesis is the only AI-generated part of the Insight.

Never invent a pattern, food, symptom, count, timing, or user history. Do not change or recalculate rule results. Do not claim a food caused a symptom, infer an allergy or disease, diagnose, prescribe treatment, or recommend eliminating foods. Distinguish logged association from possibility. If the observations do not support a meaningful connection, say so plainly instead of forcing one.

Return valid JSON only with exactly these string fields:
{"summary":"Two or three concise sentences.","followUpQuestion":"One neutral, non-leading question."}''';
}
