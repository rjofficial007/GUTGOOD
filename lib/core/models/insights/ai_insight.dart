import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:gutgood/core/constants/ai_constants.dart';
import 'package:gutgood/core/models/insights/ai_insight_details.dart';
import 'package:gutgood/core/models/insights/body_pattern.dart';
import 'package:gutgood/core/models/insights/insight_evidence.dart';
import 'package:gutgood/core/utils/date_time_utils.dart';
import 'package:gutgood/core/utils/model_utils.dart';

/// Represents a holistic snapshot of a user's gut health trends and AI-driven discoveries.
///
/// This model is the core of the [InsightsScreen]. It aggregates data from
/// chat history, meal logs, and symptoms to provide actionable advice.
class AIInsight extends Equatable {
  const AIInsight({
    this.id,
    this.firestoreId,
    this.uid,
    required this.gutScore,
    this.scoreDiff,
    this.topInsight,
    this.healingGoal,
    this.healingFoods = const [],
    this.healingTrend,
    this.triggerSymptom,
    this.triggerFoods = const [],
    this.triggerTrend,
    this.detectedPatterns = const [],
    this.topTrigger,
    this.topHealing,
    this.foodImpacts = const [],
    this.weeklyRecap,
    this.type = 'Pattern',
    this.confidenceLevel = 'Moderate',
    this.triggerData,
    required this.updatedAt,
    this.schemaVersion = AiVersions.schemaVersion,
    // P2-10 v2 envelope (all tolerant reads; absent on legacy docs).
    this.periodFrom,
    this.periodTo,
    this.evidence,
    this.actions = const [],
    this.model,
    this.promptVersion,
    this.status = AIInsight.statusReady,
    this.expiresAt,
    this.origin,
  });

  factory AIInsight.fromMap(Map<String, dynamic> map) {
    final rawData = map['data'];
    final data = rawData is String ? jsonDecode(rawData) as Map<String, dynamic> : (rawData as Map<String, dynamic>? ?? map);
    final rawId = map['id'] ?? map['firestoreId'];
    final period = data['period'] as Map<String, dynamic>?;

    return AIInsight(
      id: rawId is int ? rawId : null,
      firestoreId: rawId is String ? rawId : null,
      uid: map['uid'] as String?,
      gutScore: (data['gutScore'] as num?)?.toInt() ?? 0,
      scoreDiff: data['scoreDiff'] as String?,
      topInsight: ModelUtils.parseNestedModel<InsightSummary>(data['topInsight'], InsightSummary.fromMap),
      healingGoal: data['healingGoal'] as String?,
      healingFoods: ModelUtils.parseModelList<HealingFood>(data['healingFoods'], HealingFood.fromMap),
      healingTrend: data['healingTrend'] as String?,
      triggerSymptom: data['triggerSymptom'] as String?,
      triggerFoods: ModelUtils.parseModelList<TriggerFood>(data['triggerFoods'], TriggerFood.fromMap),
      triggerTrend: data['triggerTrend'] as String?,
      detectedPatterns: ModelUtils.parseModelList<BodyPattern>(data['detectedPatterns'], BodyPattern.fromMap),
      topTrigger: _normalizeHighlight(ModelUtils.parseNestedModel<TopHighlight>(data['topTrigger'], TopHighlight.fromMap)),
      topHealing: _normalizeHighlight(ModelUtils.parseNestedModel<TopHighlight>(data['topHealing'], TopHighlight.fromMap)),
      foodImpacts: ModelUtils.parseModelList<FoodImpact>(data['foodImpacts'], FoodImpact.fromMap),
      weeklyRecap: ModelUtils.parseNestedModel<WeeklyRecap>(data['weeklyRecap'], WeeklyRecap.fromMap),
      type: (data['type'] as String?) ?? 'Pattern',
      confidenceLevel: (data['confidenceLevel'] as String?) ?? 'Moderate',
      triggerData: data['triggerData'] as String?,
      updatedAt: DateTimeUtils.parse(map['updatedAt']),
      schemaVersion: (map['v'] as num?)?.toInt() ?? AiVersions.schemaVersion,
      // Envelope dates stay null when absent — DateTimeUtils.parse(null)
      // returns now, which would fabricate provenance.
      periodFrom: period?['from'] == null ? null : DateTimeUtils.parse(period!['from']),
      periodTo: period?['to'] == null ? null : DateTimeUtils.parse(period!['to']),
      evidence: ModelUtils.parseNestedModel<InsightEvidence>(data['evidence'], InsightEvidence.fromMap),
      actions: (data['actions'] as List?)?.cast<String>() ?? const [],
      model: data['model'] as String?,
      promptVersion: (data['promptVersion'] as num?)?.toInt(),
      status: (data['status'] as String?) ?? AIInsight.statusReady,
      expiresAt: data['expiresAt'] == null ? null : DateTimeUtils.parse(data['expiresAt']),
      origin: data['origin'] as String?,
    );
  }

  /// Minimum-evidence doctrine (§H): full insight with pattern claims.
  static const String statusReady = 'ready';

  /// Minimum-evidence doctrine (§H): digest with score-trend only — zero
  /// pattern claims, explicit "not enough data yet" state.
  static const String statusInsufficientData = 'insufficient_data';

  /// Writer provenance, stamped on every insight doc. On-device generation
  /// is the only pipeline; the field stays so future writers remain
  /// comparable (retired server values may appear on old docs).
  static const String originClient = 'client';

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
  final List<BodyPattern> detectedPatterns;

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

  /// Durable-doc schema version (§17), stamped as `v`.
  final int schemaVersion;

  /// P2-10 v2 envelope: the data window this insight covers (30d, `period.from/to`).
  final DateTime? periodFrom;
  final DateTime? periodTo;

  /// P2-10 v2 envelope: citable evidence (pattern refs + sample sizes). Null
  /// on legacy docs (they predate evidence; nothing recomputes it).
  final InsightEvidence? evidence;

  /// P2-10 v2 envelope: recommended actions (stamped from topInsight.nextSteps).
  final List<String> actions;

  /// P2-10 v2 envelope: serving model id (RemoteConfig `openai_model`).
  final String? model;

  /// P2-10 v2 envelope: insights-prompt version ([AiVersions.insightPromptVersion]).
  final int? promptVersion;

  /// P2-10 v2 envelope: [statusReady] or [statusInsufficientData].
  final String status;

  /// P2-10 v2 envelope: regeneration horizon (stale reads stay servable).
  final DateTime? expiresAt;

  /// L-6 writer provenance (one of the `origin*` constants; null on legacy docs).
  final String? origin;

  static TopHighlight? _normalizeHighlight(TopHighlight? highlight) {
    if (highlight == null) return null;
    if (highlight.food == '---' || highlight.food.isEmpty || highlight.food.toLowerCase() == 'none' || highlight.food.toLowerCase() == 'n/a') {
      return null;
    }
    return highlight;
  }

  Map<String, dynamic> toMap() => {
    'v': schemaVersion,
    'firestoreId': firestoreId,
    'gutScore': gutScore,
    'scoreDiff': scoreDiff,
    'topInsight': topInsight?.toMap(),
    'healingGoal': healingGoal,
    'healingFoods': healingFoods.map((e) => e.toMap()).toList(),
    'healingTrend': healingTrend,
    'triggerSymptom': triggerSymptom,
    'triggerFoods': triggerFoods.map((e) => e.toMap()).toList(),
    'triggerTrend': triggerTrend,
    'detectedPatterns': detectedPatterns.map((e) => e.toMap()).toList(),
    'topTrigger': topTrigger?.toMap(),
    'topHealing': topHealing?.toMap(),
    'foodImpacts': foodImpacts.map((e) => e.toMap()).toList(),
    'weeklyRecap': weeklyRecap?.toMap(),
    'type': type,
    'confidenceLevel': confidenceLevel,
    'triggerData': triggerData,
    'updatedAt': DateTimeUtils.toTimestamp(updatedAt),
    'period': (periodFrom == null && periodTo == null)
        ? null
        : {'from': periodFrom == null ? null : DateTimeUtils.toTimestamp(periodFrom!), 'to': periodTo == null ? null : DateTimeUtils.toTimestamp(periodTo!)},
    'evidence': evidence?.toMap(),
    'actions': actions,
    'model': model,
    'promptVersion': promptVersion,
    'status': status,
    'expiresAt': expiresAt == null ? null : DateTimeUtils.toTimestamp(expiresAt!),
    'origin': origin,
  };

  /// JSON-safe variant of [toMap] for navigation extras (route codec):
  /// identical but with ISO-8601 dates instead of Firestore Timestamps.
  /// Round-trips through [AIInsight.fromMap].
  Map<String, dynamic> toJsonMap() {
    final map = toMap();
    map['updatedAt'] = updatedAt.toIso8601String();
    map['period'] = (periodFrom == null && periodTo == null) ? null : {'from': periodFrom?.toIso8601String(), 'to': periodTo?.toIso8601String()};
    map['expiresAt'] = expiresAt?.toIso8601String();
    return map;
  }

  AIInsight copyWith({
    int? id,
    String? firestoreId,
    String? uid,
    int? gutScore,
    String? scoreDiff,
    InsightSummary? topInsight,
    String? healingGoal,
    List<HealingFood>? healingFoods,
    String? healingTrend,
    String? triggerSymptom,
    List<TriggerFood>? triggerFoods,
    String? triggerTrend,
    List<BodyPattern>? detectedPatterns,
    TopHighlight? topTrigger,
    TopHighlight? topHealing,
    List<FoodImpact>? foodImpacts,
    WeeklyRecap? weeklyRecap,
    String? type,
    String? confidenceLevel,
    String? triggerData,
    DateTime? updatedAt,
    int? schemaVersion,
    DateTime? periodFrom,
    DateTime? periodTo,
    InsightEvidence? evidence,
    List<String>? actions,
    String? model,
    int? promptVersion,
    String? status,
    DateTime? expiresAt,
    String? origin,
  }) => AIInsight(
    id: id ?? this.id,
    firestoreId: firestoreId ?? this.firestoreId,
    uid: uid ?? this.uid,
    gutScore: gutScore ?? this.gutScore,
    scoreDiff: scoreDiff ?? this.scoreDiff,
    topInsight: topInsight ?? this.topInsight,
    healingGoal: healingGoal ?? this.healingGoal,
    healingFoods: healingFoods ?? this.healingFoods,
    healingTrend: healingTrend ?? this.healingTrend,
    triggerSymptom: triggerSymptom ?? this.triggerSymptom,
    triggerFoods: triggerFoods ?? this.triggerFoods,
    triggerTrend: triggerTrend ?? this.triggerTrend,
    detectedPatterns: detectedPatterns ?? this.detectedPatterns,
    topTrigger: topTrigger ?? this.topTrigger,
    topHealing: topHealing ?? this.topHealing,
    foodImpacts: foodImpacts ?? this.foodImpacts,
    weeklyRecap: weeklyRecap ?? this.weeklyRecap,
    type: type ?? this.type,
    confidenceLevel: confidenceLevel ?? this.confidenceLevel,
    triggerData: triggerData ?? this.triggerData,
    updatedAt: updatedAt ?? this.updatedAt,
    schemaVersion: schemaVersion ?? this.schemaVersion,
    periodFrom: periodFrom ?? this.periodFrom,
    periodTo: periodTo ?? this.periodTo,
    evidence: evidence ?? this.evidence,
    actions: actions ?? this.actions,
    model: model ?? this.model,
    promptVersion: promptVersion ?? this.promptVersion,
    status: status ?? this.status,
    expiresAt: expiresAt ?? this.expiresAt,
    origin: origin ?? this.origin,
  );

  @override
  List<Object?> get props => [id, firestoreId, gutScore, type, confidenceLevel, status, updatedAt];
}
