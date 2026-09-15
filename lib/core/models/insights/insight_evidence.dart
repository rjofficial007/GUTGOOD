import 'package:equatable/equatable.dart';
import 'package:gutgood/core/models/insights/body_pattern.dart';
import 'package:gutgood/core/utils/model_utils.dart';

/// P2-10/§H: a citable reference to one engine-detected pattern — the "Why"
/// behind an insight. Compact on purpose: the full [BodyPattern] (occurrences,
/// factors) stays in `detectedPatterns`; refs carry what evidence rendering
/// and the v2 envelope need.
class PatternRef extends Equatable {
  const PatternRef({
    required this.type,
    required this.trigger,
    required this.reaction,
    required this.frequency,
    required this.confidence,
    required this.evidenceRatio,
    required this.positiveCount,
    required this.negativeCount,
    this.involvedFoods = const [],
  });

  factory PatternRef.fromBodyPattern(BodyPattern pattern) => PatternRef(
    type: pattern.type,
    trigger: pattern.trigger,
    reaction: pattern.reaction,
    frequency: pattern.frequency,
    confidence: pattern.confidence,
    evidenceRatio: pattern.evidenceRatio,
    positiveCount: pattern.positiveCount,
    negativeCount: pattern.negativeCount,
    involvedFoods: pattern.involvedFoods,
  );

  factory PatternRef.fromMap(Map<String, dynamic> map) => PatternRef(
    type: map['type']?.toString() ?? '',
    trigger: map['trigger']?.toString() ?? '',
    reaction: map['reaction']?.toString() ?? '',
    frequency: (map['frequency'] as num?)?.toInt() ?? 0,
    confidence: map['confidence']?.toString() ?? '',
    evidenceRatio: (map['evidenceRatio'] as num?)?.toDouble() ?? 0.0,
    positiveCount: (map['positiveCount'] as num?)?.toInt() ?? 0,
    negativeCount: (map['negativeCount'] as num?)?.toInt() ?? 0,
    involvedFoods: (map['involvedFoods'] as List?)?.cast<String>() ?? const [],
  );

  final String type;
  final String trigger;
  final String reaction;
  final int frequency;
  final String confidence;
  final double evidenceRatio;
  final int positiveCount;
  final int negativeCount;
  final List<String> involvedFoods;

  Map<String, dynamic> toMap() => {
    'type': type,
    'trigger': trigger,
    'reaction': reaction,
    'frequency': frequency,
    'confidence': confidence,
    'evidenceRatio': evidenceRatio,
    'positiveCount': positiveCount,
    'negativeCount': negativeCount,
    'involvedFoods': involvedFoods,
  };

  @override
  List<Object?> get props => [type, trigger, reaction, frequency, confidence, evidenceRatio, positiveCount, negativeCount, involvedFoods];
}

/// P2-10/§H: how much raw data the insight stands on (30-day window counts).
class SampleSizes extends Equatable {
  const SampleSizes({this.meals = 0, this.symptoms = 0, this.scans = 0});

  factory SampleSizes.fromMap(Map<String, dynamic> map) =>
      SampleSizes(meals: (map['meals'] as num?)?.toInt() ?? 0, symptoms: (map['symptoms'] as num?)?.toInt() ?? 0, scans: (map['scans'] as num?)?.toInt() ?? 0);

  final int meals;
  final int symptoms;
  final int scans;

  Map<String, dynamic> toMap() => {'meals': meals, 'symptoms': symptoms, 'scans': scans};

  @override
  List<Object?> get props => [meals, symptoms, scans];
}

/// P2-10/§H: the evidence block of an insight doc v2 — pattern refs plus the
/// sample behind them. Absent on legacy v1 docs (they predate evidence).
class InsightEvidence extends Equatable {
  const InsightEvidence({this.patternRefs = const [], this.sampleSizes = const SampleSizes(), this.spanDays = 0});

  factory InsightEvidence.fromMap(Map<String, dynamic> map) => InsightEvidence(
    patternRefs: ModelUtils.parseModelList<PatternRef>(map['patternRefs'], PatternRef.fromMap),
    sampleSizes: ModelUtils.parseNestedModel<SampleSizes>(map['sampleSizes'], SampleSizes.fromMap) ?? const SampleSizes(),
    spanDays: (map['spanDays'] as num?)?.toInt() ?? 0,
  );

  /// Rebuilds evidence from a legacy doc's own patterns (sample sizes unknown
  /// → zeros; callers with window counts should pass them explicitly).
  factory InsightEvidence.fromPatterns(List<BodyPattern> patterns, {SampleSizes sampleSizes = const SampleSizes()}) =>
      InsightEvidence(patternRefs: patterns.map(PatternRef.fromBodyPattern).toList(), sampleSizes: sampleSizes, spanDays: patterns.isEmpty ? 0 : patterns.first.timeframeDays);

  final List<PatternRef> patternRefs;
  final SampleSizes sampleSizes;
  final int spanDays;

  Map<String, dynamic> toMap() => {'patternRefs': patternRefs.map((e) => e.toMap()).toList(), 'sampleSizes': sampleSizes.toMap(), 'spanDays': spanDays};

  @override
  List<Object?> get props => [patternRefs, sampleSizes, spanDays];
}
