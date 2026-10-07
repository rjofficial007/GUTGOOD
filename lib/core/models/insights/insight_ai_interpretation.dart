import 'package:equatable/equatable.dart';
import 'package:gutgood/core/utils/date_time_utils.dart';

/// Optional AI-authored interpretation of already rule-detected patterns.
///
/// It never replaces the deterministic evidence in the parent Insight snapshot.
class InsightAiInterpretation extends Equatable {
  const InsightAiInterpretation({
    required this.summary,
    required this.followUpQuestion,
    required this.generatedAt,
    required this.promptVersion,
    this.model,
  });

  factory InsightAiInterpretation.fromMap(Map<String, dynamic> map) => InsightAiInterpretation(
    summary: map['summary']?.toString() ?? '',
    followUpQuestion: map['followUpQuestion']?.toString() ?? '',
    generatedAt: DateTimeUtils.parse(map['generatedAt']),
    promptVersion: (map['promptVersion'] as num?)?.toInt() ?? 1,
    model: map['model']?.toString(),
  );

  /// Cautious synthesis of multiple existing rule-based observations.
  final String summary;

  /// One neutral question that could help the user add useful context to future logs.
  final String followUpQuestion;

  final DateTime generatedAt;
  final int promptVersion;
  final String? model;

  Map<String, dynamic> toMap() => {
    'summary': summary,
    'followUpQuestion': followUpQuestion,
    'generatedAt': DateTimeUtils.toTimestamp(generatedAt),
    'promptVersion': promptVersion,
    'model': model,
  };

  @override
  List<Object?> get props => [summary, followUpQuestion, generatedAt, promptVersion, model];
}
