import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:gutgood/core/constants/ai_constants.dart';
import 'package:gutgood/core/models/insights/ai_insight_details.dart';
import 'package:gutgood/core/models/insights/body_pattern.dart';
import 'package:gutgood/core/models/insights/food_swap.dart';
import 'package:gutgood/core/models/insights/insight_action.dart';
import 'package:gutgood/core/models/insights/insight_empty_state.dart';
import 'package:gutgood/core/models/insights/insight_evidence.dart';
import 'package:gutgood/core/models/insights/insight_v2_blocks.dart';
import 'package:gutgood/core/models/insights/recent_insight_item.dart';
import 'package:gutgood/core/utils/date_time_utils.dart';
import 'package:gutgood/core/utils/model_utils.dart';
import 'package:gutgood/core/utils/insight_values.dart';

/// Represents a holistic snapshot of a user's gut health trends and AI-driven discoveries.
///
/// This model is the core of the Insights experience. It aggregates data from
/// chat history, meal logs, and symptoms to provide actionable advice conforming
/// to the complete v2 data specification.
class AIInsight extends Equatable {
  const AIInsight({
    this.id,
    this.firestoreId,
    this.uid,
    required this.gutScore,
    this.hasGutScore = true,
    this.gutScoreSummary,
    this.scoreDiff,
    this.topInsight,
    this.healingGoal,
    this.healingFoods = const [],
    this.healingTrend,
    this.healingSummary,
    this.triggerSymptom,
    this.triggerFoods = const [],
    this.triggerTrend,
    this.triggerSummary,
    this.detectedPatterns = const [],
    this.topTrigger,
    this.topHealing,
    this.foodImpacts = const [],
    this.foodImpactBalance,
    this.weeklyRecap,
    this.weeklyRecapHistory = const [],
    this.type = 'Pattern',
    this.confidenceLevel = 'Moderate',
    this.triggerData,
    required this.updatedAt,
    this.schemaVersion = AiVersions.schemaVersion,
    this.periodFrom,
    this.periodTo,
    this.evidence,
    this.actions = const [],
    this.actionsList = const [],
    this.foodSwaps = const [],
    this.recentInsights = const [],
    this.emptyState,
    this.model,
    this.promptVersion,
    this.status = AIInsight.statusReady,
    this.expiresAt,
    this.origin,
    // v3 prompt blocks (v2 Real Tokens UI; tolerant reads, null on legacy docs).
    this.improving,
    this.watch,
    this.smartSwap,
  });

  factory AIInsight.fromMap(Map<String, dynamic> map) {
    final rawData = map['data'];
    var decodedData = <String, dynamic>{};
    if (rawData is String) {
      try {
        final decoded = jsonDecode(rawData);
        decodedData = decoded is Map ? Map<String, dynamic>.from(decoded) : const {};
      } on FormatException {
        decodedData = <String, dynamic>{};
      }
    } else if (rawData is Map) {
      decodedData = Map<String, dynamic>.from(rawData);
    } else {
      decodedData = <String, dynamic>{};
    }
    final data = decodedData.isEmpty ? map : decodedData;
    final rawId = map['id'] ?? map['firestoreId'];
    final rawPeriod = data['period'];
    final period = rawPeriod is Map ? Map<String, dynamic>.from(rawPeriod) : null;

    final rawGutScore = data['gutScore'];
    final parsedScore = InsightValues.integer(rawGutScore is Map ? rawGutScore['score'] : rawGutScore);
    final hasScore = parsedScore != null && parsedScore >= 0 && parsedScore <= 100 && data['hasGutScore'] != false;

    final parsedGutScoreSummary = rawGutScore is Map
        ? GutScoreSummary.fromMap(Map<String, dynamic>.from(rawGutScore))
        : (data['gutScoreSummary'] is Map ? GutScoreSummary.fromMap(Map<String, dynamic>.from(data['gutScoreSummary'] as Map)) : null);

    final rawHealing = data['healing'];
    final parsedHealingSummary = rawHealing is Map ? HealingSummary.fromMap(Map<String, dynamic>.from(rawHealing)) : null;

    final rawTriggers = data['triggers'];
    final parsedTriggerSummary = rawTriggers is Map ? TriggerSummary.fromMap(Map<String, dynamic>.from(rawTriggers)) : null;

    final rawActions = data['actions'];
    final parsedActionStrings = <String>[];
    final parsedActionObjects = <InsightAction>[];

    if (rawActions is List) {
      for (final item in rawActions) {
        if (item is String) {
          parsedActionStrings.add(item);
          parsedActionObjects.add(InsightAction(id: 'act_${parsedActionObjects.length + 1}', title: item, description: item));
        } else if (item is Map) {
          final actionObj = InsightAction.fromMap(Map<String, dynamic>.from(item));
          parsedActionObjects.add(actionObj);
          parsedActionStrings.add(actionObj.title);
        }
      }
    }

    return AIInsight(
      id: rawId is int ? rawId : null,
      firestoreId: rawId is String ? rawId : null,
      uid: map['uid'] as String?,
      gutScore: hasScore ? parsedScore : 0,
      hasGutScore: hasScore,
      gutScoreSummary: parsedGutScoreSummary,
      scoreDiff: data['scoreDiff']?.toString(),
      topInsight: ModelUtils.parseNestedModel<InsightSummary>(data['topInsight'], InsightSummary.fromMap),
      healingGoal: data['healingGoal'] as String? ?? parsedHealingSummary?.goal,
      healingFoods: ModelUtils.parseModelList<HealingFood>(data['healingFoods'], HealingFood.fromMap),
      healingTrend: data['healingTrend'] as String? ?? parsedHealingSummary?.trend,
      healingSummary: parsedHealingSummary,
      triggerSymptom: data['triggerSymptom'] as String? ?? parsedTriggerSummary?.primarySymptom,
      triggerFoods: ModelUtils.parseModelList<TriggerFood>(data['triggerFoods'], TriggerFood.fromMap),
      triggerTrend: data['triggerTrend'] as String? ?? parsedTriggerSummary?.trend,
      triggerSummary: parsedTriggerSummary,
      detectedPatterns: ModelUtils.parseModelList<BodyPattern>(data['detectedPatterns'], BodyPattern.fromMap),
      topTrigger: _normalizeHighlight(ModelUtils.parseNestedModel<TopHighlight>(data['topTrigger'], TopHighlight.fromMap)),
      topHealing: _normalizeHighlight(ModelUtils.parseNestedModel<TopHighlight>(data['topHealing'], TopHighlight.fromMap)),
      foodImpacts: ModelUtils.parseModelList<FoodImpact>(data['foodImpacts'], FoodImpact.fromMap),
      foodImpactBalance: ModelUtils.parseNestedModel<FoodImpactBalance>(data['foodImpactBalance'], FoodImpactBalance.fromMap),
      weeklyRecap: ModelUtils.parseNestedModel<WeeklyRecap>(data['weeklyRecap'], WeeklyRecap.fromMap),
      weeklyRecapHistory: ModelUtils.parseModelList<WeeklyRecapHistoryItem>(data['weeklyRecapHistory'], WeeklyRecapHistoryItem.fromMap),
      type: (data['type'] as String?) ?? 'Pattern',
      confidenceLevel: (data['confidenceLevel'] as String?) ?? 'Moderate',
      triggerData: data['triggerData'] as String?,
      updatedAt: DateTimeUtils.parse(map['updatedAt']),
      schemaVersion: (map['v'] as num?)?.toInt() ?? AiVersions.schemaVersion,
      periodFrom: period?['from'] == null ? null : DateTimeUtils.parse(period!['from']).toUtc(),
      periodTo: period?['to'] == null ? null : DateTimeUtils.parse(period!['to']).toUtc(),
      evidence: ModelUtils.parseNestedModel<InsightEvidence>(data['evidence'], InsightEvidence.fromMap),
      actions: parsedActionStrings,
      actionsList: parsedActionObjects,
      foodSwaps: ModelUtils.parseModelList<FoodSwap>(data['foodSwaps'], FoodSwap.fromMap),
      recentInsights: ModelUtils.parseModelList<RecentInsightItem>(data['recentInsights'], RecentInsightItem.fromMap),
      emptyState: ModelUtils.parseNestedModel<InsightEmptyState>(data['emptyState'], InsightEmptyState.fromMap),
      model: data['model'] as String?,
      promptVersion: (data['promptVersion'] as num?)?.toInt(),
      status: (data['status'] as String?) ?? AIInsight.statusReady,
      expiresAt: data['expiresAt'] == null ? null : DateTimeUtils.parse(data['expiresAt']).toUtc(),
      origin: data['origin'] as String?,
      improving: ModelUtils.parseNestedModel<ImprovingBlock>(data['improving'], ImprovingBlock.fromMap),
      watch: ModelUtils.parseNestedModel<WatchBlock>(data['watch'], WatchBlock.fromMap),
      smartSwap: ModelUtils.parseNestedModel<SmartSwap>(data['smartSwap'], SmartSwap.fromMap),
    );
  }

  static const String statusReady = 'ready';
  static const String statusInsufficientData = 'insufficient_data';
  static const String originClient = 'client';

  final int? id;
  final String? firestoreId;
  final String? uid;
  final int gutScore;
  final bool hasGutScore;
  final GutScoreSummary? gutScoreSummary;
  final String? scoreDiff;
  final InsightSummary? topInsight;
  final String? healingGoal;
  final List<HealingFood> healingFoods;
  final String? healingTrend;
  final HealingSummary? healingSummary;
  final String? triggerSymptom;
  final List<TriggerFood> triggerFoods;
  final String? triggerTrend;
  final TriggerSummary? triggerSummary;
  final List<BodyPattern> detectedPatterns;
  final TopHighlight? topTrigger;
  final TopHighlight? topHealing;
  final List<FoodImpact> foodImpacts;
  final FoodImpactBalance? foodImpactBalance;
  final WeeklyRecap? weeklyRecap;
  final List<WeeklyRecapHistoryItem> weeklyRecapHistory;
  final String type;
  final String confidenceLevel;
  final String? triggerData;
  final DateTime updatedAt;
  final int schemaVersion;
  final DateTime? periodFrom;
  final DateTime? periodTo;
  final InsightEvidence? evidence;
  final List<String> actions;
  final List<InsightAction> actionsList;
  final List<FoodSwap> foodSwaps;
  final List<RecentInsightItem> recentInsights;
  final InsightEmptyState? emptyState;
  final String? model;
  final int? promptVersion;
  final String status;
  final DateTime? expiresAt;
  final String? origin;
  final ImprovingBlock? improving;
  final WatchBlock? watch;
  final SmartSwap? smartSwap;

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
    'gutScore': hasGutScore ? (gutScoreSummary?.toMap() ?? gutScore) : null,
    'hasGutScore': hasGutScore,
    'scoreDiff': scoreDiff,
    'topInsight': topInsight?.toMap(),
    'healingGoal': healingGoal,
    'healingFoods': healingFoods.map((e) => e.toMap()).toList(),
    'healingTrend': healingTrend,
    'healing': healingSummary?.toMap(),
    'triggerSymptom': triggerSymptom,
    'triggerFoods': triggerFoods.map((e) => e.toMap()).toList(),
    'triggerTrend': triggerTrend,
    'triggers': triggerSummary?.toMap(),
    'detectedPatterns': detectedPatterns.map((e) => e.toMap()).toList(),
    'topTrigger': topTrigger?.toMap(),
    'topHealing': topHealing?.toMap(),
    'foodImpacts': foodImpacts.map((e) => e.toMap()).toList(),
    'foodImpactBalance': foodImpactBalance?.toMap(),
    'weeklyRecap': weeklyRecap?.toMap(),
    'weeklyRecapHistory': weeklyRecapHistory.map((e) => e.toMap()).toList(),
    'type': type,
    'confidenceLevel': confidenceLevel,
    'triggerData': triggerData,
    'updatedAt': DateTimeUtils.toTimestamp(updatedAt),
    'period': (periodFrom == null && periodTo == null)
        ? null
        : {'from': periodFrom == null ? null : DateTimeUtils.toTimestamp(periodFrom!), 'to': periodTo == null ? null : DateTimeUtils.toTimestamp(periodTo!)},
    'evidence': evidence?.toMap(),
    'actions': actionsList.isNotEmpty ? actionsList.map((e) => e.toMap()).toList() : actions,
    'foodSwaps': foodSwaps.map((e) => e.toMap()).toList(),
    'recentInsights': recentInsights.map((e) => e.toMap()).toList(),
    'emptyState': emptyState?.toMap(),
    'model': model,
    'promptVersion': promptVersion,
    'status': status,
    'expiresAt': expiresAt == null ? null : DateTimeUtils.toTimestamp(expiresAt!),
    'origin': origin,
    'improving': improving?.toMap(),
    'watch': watch?.toMap(),
    'smartSwap': smartSwap?.toMap(),
  };

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
    bool? hasGutScore,
    GutScoreSummary? gutScoreSummary,
    String? scoreDiff,
    InsightSummary? topInsight,
    String? healingGoal,
    List<HealingFood>? healingFoods,
    String? healingTrend,
    HealingSummary? healingSummary,
    String? triggerSymptom,
    List<TriggerFood>? triggerFoods,
    String? triggerTrend,
    TriggerSummary? triggerSummary,
    List<BodyPattern>? detectedPatterns,
    TopHighlight? topTrigger,
    TopHighlight? topHealing,
    List<FoodImpact>? foodImpacts,
    FoodImpactBalance? foodImpactBalance,
    WeeklyRecap? weeklyRecap,
    List<WeeklyRecapHistoryItem>? weeklyRecapHistory,
    String? type,
    String? confidenceLevel,
    String? triggerData,
    DateTime? updatedAt,
    int? schemaVersion,
    DateTime? periodFrom,
    DateTime? periodTo,
    InsightEvidence? evidence,
    List<String>? actions,
    List<InsightAction>? actionsList,
    List<FoodSwap>? foodSwaps,
    List<RecentInsightItem>? recentInsights,
    InsightEmptyState? emptyState,
    String? model,
    int? promptVersion,
    String? status,
    DateTime? expiresAt,
    String? origin,
    ImprovingBlock? improving,
    WatchBlock? watch,
    SmartSwap? smartSwap,
  }) => AIInsight(
    id: id ?? this.id,
    firestoreId: firestoreId ?? this.firestoreId,
    uid: uid ?? this.uid,
    gutScore: gutScore ?? this.gutScore,
    hasGutScore: hasGutScore ?? (gutScore != null ? true : this.hasGutScore),
    gutScoreSummary: gutScoreSummary ?? this.gutScoreSummary,
    scoreDiff: scoreDiff ?? this.scoreDiff,
    topInsight: topInsight ?? this.topInsight,
    healingGoal: healingGoal ?? this.healingGoal,
    healingFoods: healingFoods ?? this.healingFoods,
    healingTrend: healingTrend ?? this.healingTrend,
    healingSummary: healingSummary ?? this.healingSummary,
    triggerSymptom: triggerSymptom ?? this.triggerSymptom,
    triggerFoods: triggerFoods ?? this.triggerFoods,
    triggerTrend: triggerTrend ?? this.triggerTrend,
    triggerSummary: triggerSummary ?? this.triggerSummary,
    detectedPatterns: detectedPatterns ?? this.detectedPatterns,
    topTrigger: topTrigger ?? this.topTrigger,
    topHealing: topHealing ?? this.topHealing,
    foodImpacts: foodImpacts ?? this.foodImpacts,
    foodImpactBalance: foodImpactBalance ?? this.foodImpactBalance,
    weeklyRecap: weeklyRecap ?? this.weeklyRecap,
    weeklyRecapHistory: weeklyRecapHistory ?? this.weeklyRecapHistory,
    type: type ?? this.type,
    confidenceLevel: confidenceLevel ?? this.confidenceLevel,
    triggerData: triggerData ?? this.triggerData,
    updatedAt: updatedAt ?? this.updatedAt,
    schemaVersion: schemaVersion ?? this.schemaVersion,
    periodFrom: periodFrom ?? this.periodFrom,
    periodTo: periodTo ?? this.periodTo,
    evidence: evidence ?? this.evidence,
    actions: actions ?? this.actions,
    actionsList: actionsList ?? this.actionsList,
    foodSwaps: foodSwaps ?? this.foodSwaps,
    recentInsights: recentInsights ?? this.recentInsights,
    emptyState: emptyState ?? this.emptyState,
    model: model ?? this.model,
    promptVersion: promptVersion ?? this.promptVersion,
    status: status ?? this.status,
    expiresAt: expiresAt ?? this.expiresAt,
    origin: origin ?? this.origin,
    improving: improving ?? this.improving,
    watch: watch ?? this.watch,
    smartSwap: smartSwap ?? this.smartSwap,
  );

  @override
  List<Object?> get props => [id, firestoreId, gutScore, hasGutScore, type, confidenceLevel, status, updatedAt];
}
