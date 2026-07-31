import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:gutgood/core/utils/date_time_utils.dart';
import 'package:gutgood/core/utils/model_utils.dart';

import 'ai_insight_details.dart';

/// Represents a holistic snapshot of a user's gut health trends and AI-driven discoveries.
///
/// This model is the core of the [InsightsScreen]. It aggregates data from
/// chat history, meal logs, and symptoms to provide actionable advice.
class AIInsight extends Equatable {
  /// Local SQLite primary key.
  final int? id;

  /// Cloud Firestore unique identifier.
  final String? firestoreId;

  /// Identifier of the user who owns this insight.
  final String? uid;

  /// Aggregate gut health score (0-100) at the time of generation.
  final int gutScore;

  /// Descriptive difference from the previous score (e.g., "+4").
  final String? scoreDiff;

  /// Current active check-in streak.
  final int streak;

  /// The most critical discovery or suggestion for the user.
  final InsightSummary? topInsight;

  /// Primary health goal identified for this period.
  final String? healingGoal;

  /// List of foods that positively impacted gut health.
  final List<HealingFood> healingFoods;

  /// Narrative description of positive trends.
  final String? healingTrend;

  /// Primary symptom being tracked or addressed.
  final String? triggerSymptom;

  /// List of foods that negatively impacted gut health.
  final List<TriggerFood> triggerFoods;

  /// Narrative description of negative trends.
  final String? triggerTrend;

  /// List of recurring behavioral or dietary patterns.
  final List<DetectedPattern> detectedPatterns;

  /// Numerical representation of score trends for sparkline charts.
  final List<int> simpleTrend;

  /// Highlighted positive food encounter.
  final TopHighlight? topTrigger;

  /// Highlighted negative food encounter.
  final TopHighlight? topHealing;

  /// List of detailed food-to-body impact mappings.
  final List<FoodImpact> foodImpacts;

  /// Structured data for the [WeeklyRecapScreen].
  final WeeklyRecap? weeklyRecap;

  /// The type of analysis: 'Pattern', 'Ingredient', 'Behavioral', 'Goal'.
  final String type;

  /// Statistical confidence in this insight: 'High', 'Moderate', 'Low'.
  final String confidenceLevel;

  /// JSON encoded summary of the raw events that triggered this insight.
  final String? triggerData;

  /// The exact time this analysis was synthesized.
  final DateTime updatedAt;

  const AIInsight({
    this.id,
    this.firestoreId,
    this.uid,
    required this.gutScore,
    this.scoreDiff,
    required this.streak,
    this.topInsight,
    this.healingGoal,
    this.healingFoods = const [],
    this.healingTrend,
    this.triggerSymptom,
    this.triggerFoods = const [],
    this.triggerTrend,
    this.detectedPatterns = const [],
    this.simpleTrend = const [],
    this.topTrigger,
    this.topHealing,
    this.foodImpacts = const [],
    this.weeklyRecap,
    this.type = 'Pattern',
    this.confidenceLevel = 'Moderate',
    this.triggerData,
    required this.updatedAt,
  });

  factory AIInsight.fromMap(Map<String, dynamic> map) {
    final data = map['data'] is String ? jsonDecode(map['data'] as String) : map;
    final rawId = map['id'] ?? map['firestoreId'];

    return AIInsight(
      id: rawId is int ? rawId : null,
      firestoreId: rawId is String ? rawId : null,
      uid: map['uid'] as String?,
      gutScore: (data['gutScore'] as num?)?.toInt() ?? 0,
      scoreDiff: data['scoreDiff'],
      streak: (data['streak'] as num?)?.toInt() ?? 0,
      topInsight: ModelUtils.parseNestedModel<InsightSummary>(data['topInsight'], InsightSummary.fromMap),
      healingGoal: data['healingGoal'],
      healingFoods: ModelUtils.parseModelList<HealingFood>(data['healingFoods'], HealingFood.fromMap),
      healingTrend: data['healingTrend'],
      triggerSymptom: data['triggerSymptom'],
      triggerFoods: ModelUtils.parseModelList<TriggerFood>(data['triggerFoods'], TriggerFood.fromMap),
      triggerTrend: data['triggerTrend'],
      detectedPatterns: ModelUtils.parseModelList<DetectedPattern>(data['detectedPatterns'], DetectedPattern.fromMap),
      simpleTrend: ModelUtils.parseList<int>(data['simpleTrend']),
      topTrigger: _normalizeHighlight(ModelUtils.parseNestedModel<TopHighlight>(data['topTrigger'], TopHighlight.fromMap)),
      topHealing: _normalizeHighlight(ModelUtils.parseNestedModel<TopHighlight>(data['topHealing'], TopHighlight.fromMap)),
      foodImpacts: ModelUtils.parseModelList<FoodImpact>(data['foodImpacts'], FoodImpact.fromMap),
      weeklyRecap: ModelUtils.parseNestedModel<WeeklyRecap>(data['weeklyRecap'], WeeklyRecap.fromMap),
      type: data['type'] ?? 'Pattern',
      confidenceLevel: data['confidenceLevel'] ?? 'Moderate',
      triggerData: data['triggerData'],
      updatedAt: DateTimeUtils.parse(map['updatedAt']),
    );
  }

  static TopHighlight? _normalizeHighlight(TopHighlight? highlight) {
    if (highlight == null) return null;
    if (highlight.food == '---' || highlight.food.isEmpty || highlight.food.toLowerCase() == 'none' || highlight.food.toLowerCase() == 'n/a') {
      return null;
    }
    return highlight;
  }

  Map<String, dynamic> toMap() {
    return {
      'firestoreId': firestoreId,
      'gutScore': gutScore,
      'scoreDiff': scoreDiff,
      'streak': streak,
      'topInsight': topInsight?.toMap(),
      'healingGoal': healingGoal,
      'healingFoods': healingFoods.map((e) => e.toMap()).toList(),
      'healingTrend': healingTrend,
      'triggerSymptom': triggerSymptom,
      'triggerFoods': triggerFoods.map((e) => e.toMap()).toList(),
      'triggerTrend': triggerTrend,
      'detectedPatterns': detectedPatterns.map((e) => e.toMap()).toList(),
      'simpleTrend': simpleTrend,
      'topTrigger': topTrigger?.toMap(),
      'topHealing': topHealing?.toMap(),
      'foodImpacts': foodImpacts.map((e) => e.toMap()).toList(),
      'weeklyRecap': weeklyRecap?.toMap(),
      'type': type,
      'confidenceLevel': confidenceLevel,
      'triggerData': triggerData,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, firestoreId, gutScore, streak, type, confidenceLevel, updatedAt];
}
