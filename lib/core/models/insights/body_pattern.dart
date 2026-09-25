import 'package:equatable/equatable.dart';
import 'package:gutgood/core/constants/ai_constants.dart';
import 'package:gutgood/core/models/insights/pattern_occurrence.dart';
import 'package:gutgood/core/utils/insight_values.dart';
import 'package:gutgood/core/utils/model_utils.dart';

class BodyPattern extends Equatable {
  const BodyPattern({
    this.id,
    required this.type,
    required this.trigger,
    required this.reaction,
    required this.frequency,
    required this.confidence,
    required this.description,
    this.confidenceScore = 0.85,
    this.involvedFoods = const [],
    this.relatedFoodIds = const [],
    this.recommendation,
    required this.updatedAt,
    this.occurrences = const [],
    this.commonFactors = const [],
    this.totalSimilarMeals = 0,
    this.timeframeDays = 30,
    this.typicalTiming,
    this.typicalDelay,
    this.impactDirection = 'negative',
    this.impactLevel = 'high',
    this.evidenceRatio = 0.0,
    this.positiveCount = 0,
    this.negativeCount = 0,
    this.schemaVersion = AiVersions.schemaVersion,
  });

  factory BodyPattern.fromMap(Map<String, dynamic> map) {
    final typeStr = (map['domain'] ?? map['type'] ?? map['category'] ?? '').toString();
    return BodyPattern(
      id: map['id']?.toString(),
      type: typeStr,
      trigger: (map['trigger'] ?? map['title'] ?? map['name'] ?? '').toString(),
      reaction: (map['reaction'] ?? map['effect'] ?? '').toString(),
      frequency: InsightValues.integer(map['frequency']) ?? 1,
      confidence: (map['confidence'] ?? map['strength'] ?? '').toString(),
      confidenceScore: InsightValues.number(map['confidenceScore'])?.toDouble() ?? 0.85,
      description: (map['description'] ?? map['observation'] ?? '').toString(),
      involvedFoods: (map['involvedFoods'] as List?)?.whereType<String>().toList() ?? const [],
      relatedFoodIds: (map['relatedFoodIds'] as List?)?.whereType<String>().toList() ??
          (map['involvedFoods'] as List?)?.cast<String>() ??
          const [],
      recommendation: (map['recommendation'] ??
              (map['nextSteps'] is List ? (map['nextSteps'] as List).firstOrNull : null))
          ?.toString(),
      updatedAt: map['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
      occurrences: ModelUtils.parseModelList<PatternOccurrence>(
          map['occurrences'], PatternOccurrence.fromMap),
      commonFactors: ModelUtils.parseModelList<CommonFactor>(
          map['commonFactors'], CommonFactor.fromMap),
      totalSimilarMeals: InsightValues.integer(map['totalSimilarMeals']) ?? 0,
      timeframeDays: InsightValues.integer(map['timeframeDays']) ?? 30,
      typicalTiming: map['typicalTiming']?.toString(),
      typicalDelay: map['typicalDelay']?.toString(),
      impactDirection: map['impactDirection']?.toString() ?? 'unknown',
      impactLevel: map['impactLevel']?.toString() ?? 'unknown',
      evidenceRatio: InsightValues.number(map['evidenceRatio'])?.toDouble() ?? 0.0,
      positiveCount: InsightValues.integer(map['positiveCount']) ?? 0,
      negativeCount: InsightValues.integer(map['negativeCount']) ?? 0,
      schemaVersion: InsightValues.integer(map['v']) ?? AiVersions.schemaVersion,
    );
  }

  final String? id;

  /// Pattern domain (e.g., digestion, energy, sleep, mood, appetite).
  final String type;
  final String trigger;
  final String reaction;
  final int frequency;
  final String confidence;
  final double confidenceScore;
  final String description;
  final List<String> involvedFoods;
  final List<String> relatedFoodIds;
  final String? recommendation;
  final String updatedAt;

  // Detailed view fields
  final List<PatternOccurrence> occurrences;
  final List<CommonFactor> commonFactors;
  final int totalSimilarMeals;
  final int timeframeDays;
  final String? typicalTiming;
  final String? typicalDelay;
  final String impactDirection;
  final String impactLevel;

  // Statistical Evidence
  final double evidenceRatio; // e.g. 0.8 means 80% of meals with this food were symptomatic
  final int positiveCount; // symptomatic occurrences
  final int negativeCount; // asymptomatic occurrences

  /// Durable-doc schema version (§17), stamped as `v`.
  final int schemaVersion;

  // Domain Alias
  String get domain => type;

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
        'v': schemaVersion,
        'id': id,
        'domain': domain,
        'type': type,
        'trigger': trigger,
        'reaction': reaction,
        'frequency': frequency,
        'confidence': confidence,
        'confidenceScore': confidenceScore,
        'description': description,
        'involvedFoods': involvedFoods,
        'relatedFoodIds': relatedFoodIds,
        'recommendation': recommendation,
        'updatedAt': updatedAt,
        'occurrences': occurrences.map((e) => e.toMap()).toList(),
        'commonFactors': commonFactors.map((e) => e.toMap()).toList(),
        'totalSimilarMeals': totalSimilarMeals,
        'timeframeDays': timeframeDays,
        'typicalTiming': typicalTiming,
        'typicalDelay': typicalDelay,
        'impactDirection': impactDirection,
        'impactLevel': impactLevel,
        'evidenceRatio': evidenceRatio,
        'positiveCount': positiveCount,
        'negativeCount': negativeCount,
      };

  @override
  List<Object?> get props => [
        id,
        type,
        trigger,
        reaction,
        frequency,
        confidence,
        confidenceScore,
        description,
        involvedFoods,
        relatedFoodIds,
        recommendation,
        updatedAt,
        occurrences,
        commonFactors,
        totalSimilarMeals,
        timeframeDays,
        typicalTiming,
        typicalDelay,
        impactDirection,
        impactLevel,
        evidenceRatio,
        positiveCount,
        negativeCount,
      ];
}
