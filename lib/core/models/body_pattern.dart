import 'package:equatable/equatable.dart';
import 'package:gutgood/core/models/pattern_occurrence.dart';
import 'package:gutgood/core/utils/model_utils.dart';

class BodyPattern extends Equatable {
  const BodyPattern({
    required this.type,
    required this.trigger,
    required this.reaction,
    required this.frequency,
    required this.confidence,
    required this.description,
    this.involvedFoods = const [],
    this.recommendation,
    required this.updatedAt,
    this.occurrences = const [],
    this.commonFactors = const [],
    this.totalSimilarMeals = 0,
    this.timeframeDays = 30,
    this.evidenceRatio = 0.0,
    this.positiveCount = 0,
    this.negativeCount = 0,
  });

  factory BodyPattern.fromMap(Map<String, dynamic> map) => BodyPattern(
    type: (map['type'] ?? map['category'] ?? '').toString(),
    trigger: (map['trigger'] ?? map['title'] ?? map['name'] ?? '').toString(),
    reaction: (map['reaction'] ?? map['effect'] ?? '').toString(),
    frequency: (map['frequency'] as num?)?.toInt() ?? 1,
    confidence: (map['confidence'] ?? map['strength'] ?? 'Moderate').toString(),
    description: (map['description'] ?? map['observation'] ?? '').toString(),
    involvedFoods: (map['involvedFoods'] as List?)?.cast<String>() ?? const [],
    recommendation: (map['recommendation'] ?? (map['nextSteps'] is List ? (map['nextSteps'] as List).firstOrNull : null))?.toString(),
    updatedAt: map['updatedAt'] ?? DateTime.now().toIso8601String(),
    occurrences: ModelUtils.parseModelList<PatternOccurrence>(map['occurrences'], PatternOccurrence.fromMap),
    commonFactors: ModelUtils.parseModelList<CommonFactor>(map['commonFactors'], CommonFactor.fromMap),
    totalSimilarMeals: (map['totalSimilarMeals'] as num?)?.toInt() ?? 0,
    timeframeDays: (map['timeframeDays'] as num?)?.toInt() ?? 30,
    evidenceRatio: (map['evidenceRatio'] as num?)?.toDouble() ?? 0.0,
    positiveCount: (map['positiveCount'] as num?)?.toInt() ?? 0,
    negativeCount: (map['negativeCount'] as num?)?.toInt() ?? 0,
  );

  final String type;
  final String trigger;
  final String reaction;
  final int frequency;
  final String confidence;
  final String description;
  final List<String> involvedFoods;
  final String? recommendation;
  final String updatedAt;

  // New fields for detailed view
  final List<PatternOccurrence> occurrences;
  final List<CommonFactor> commonFactors;
  final int totalSimilarMeals;
  final int timeframeDays;

  // Statistical Evidence
  final double evidenceRatio; // e.g. 0.8 means 80% of meals with this food were symptomatic
  final int positiveCount; // symptomatic occurrences
  final int negativeCount; // asymptomatic occurrences

  // Insight Categories
  static const String typeBloating = 'bloating';
  static const String typeEnergy = 'energy';
  static const String typeHeadache = 'headache';
  static const String typeDigestion = 'digestion';
  static const String typeFullness = 'fullness';
  static const String typeSleep = 'sleep';

  // Confidence Levels
  static const String confidenceLow = 'Low';
  static const String confidenceModerate = 'Moderate';
  static const String confidenceMedium = 'Medium';
  static const String confidenceHigh = 'High';

  Map<String, dynamic> toMap() => {
    'type': type,
    'trigger': trigger,
    'reaction': reaction,
    'frequency': frequency,
    'confidence': confidence,
    'description': description,
    'involvedFoods': involvedFoods,
    'recommendation': recommendation,
    'updatedAt': updatedAt,
    'occurrences': occurrences.map((e) => e.toMap()).toList(),
    'commonFactors': commonFactors.map((e) => e.toMap()).toList(),
    'totalSimilarMeals': totalSimilarMeals,
    'timeframeDays': timeframeDays,
    'evidenceRatio': evidenceRatio,
    'positiveCount': positiveCount,
    'negativeCount': negativeCount,
  };

  @override
  List<Object?> get props => [
    type,
    trigger,
    reaction,
    frequency,
    confidence,
    description,
    involvedFoods,
    recommendation,
    updatedAt,
    occurrences,
    commonFactors,
    totalSimilarMeals,
    timeframeDays,
    evidenceRatio,
    positiveCount,
    negativeCount,
  ];
}
