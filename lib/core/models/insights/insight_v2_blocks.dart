import 'package:equatable/equatable.dart';
import 'package:gutgood/core/utils/insight_values.dart';
import 'package:gutgood/core/utils/model_utils.dart';

/// v3 prompt blocks backing the "v2 Real Tokens" Insights UI.
///
/// All three blocks are **optional and tolerant**: legacy docs parse with
/// them null and the v2 widgets fall back to deterministic derivations from
/// the existing fields (healingFoods, detectedPatterns, score history), so
/// the UI never blocks on regeneration.
///
/// Emitted by insights-prompt v3; see
/// `lib/core/services/prompts/mode_prompts/insights_prompt.dart`.

/// `improving` — powers the home feed's "What's Improving" card.
class ImprovingBlock extends Equatable {
  const ImprovingBlock({this.headline, this.description, this.streakDays, this.streakGoalDays, this.encouragement, this.keyFoods = const []});

  factory ImprovingBlock.fromMap(Map<String, dynamic> map) => ImprovingBlock(
    headline: map['headline']?.toString(),
    description: map['description']?.toString(),
    streakDays: InsightValues.integer(map['streakDays']),
    streakGoalDays: InsightValues.integer(map['streakGoalDays']),
    encouragement: map['encouragement']?.toString(),
    keyFoods: ModelUtils.parseModelList<KeyFoodDriver>(map['keyFoods'], KeyFoodDriver.fromMap),
  );

  /// One-liner under the card eyebrow ("Gut barrier score is up!").
  final String? headline;

  /// Supporting sentence ("Consistent vegetable fiber intake…").
  final String? description;

  /// Consecutive good-log days (0–30). UI clamps and derives fallbacks.
  final int? streakDays;

  /// Target the streak bar visualises (default 5 in the UI).
  final int? streakGoalDays;

  /// Rec-card copy ("Keep it up — 3 more days to beat your best streak.").
  final String? encouragement;

  /// Up to three foods driving the trend.
  final List<KeyFoodDriver> keyFoods;

  Map<String, dynamic> toMap() => {
    'headline': headline,
    'description': description,
    'streakDays': streakDays,
    'streakGoalDays': streakGoalDays,
    'encouragement': encouragement,
    'keyFoods': keyFoods.map((e) => e.toMap()).toList(),
  };

  @override
  List<Object?> get props => [headline, description, streakDays, streakGoalDays, encouragement, keyFoods];
}

/// One food in [ImprovingBlock.keyFoods].
class KeyFoodDriver extends Equatable {
  const KeyFoodDriver({required this.name, this.count, this.delta, this.emoji, this.imageUrl});

  factory KeyFoodDriver.fromMap(Map<String, dynamic> map) {
    final name = (map['name'] ?? map['food'] ?? '').toString();
    return KeyFoodDriver(
      name: name,
      count: InsightValues.integer(map['count']),
      delta: InsightValues.integer(map['delta']),
      emoji: map['emoji']?.toString(),
      imageUrl: (map['userImageUrl'] ?? map['imageUrl'])?.toString(),
    );
  }

  final String name;
  final int? count;

  /// Score contribution ("+3"), already sign-bearing.
  final int? delta;
  final String? emoji;
  final String? imageUrl;

  Map<String, dynamic> toMap() => {'name': name, 'count': count, 'delta': delta, 'emoji': emoji, 'imageUrl': imageUrl};

  @override
  List<Object?> get props => [name, count, delta, emoji, imageUrl];
}

/// `watch` — reaction timing/risk for the "Something to Watch" card stats.
class WatchBlock extends Equatable {
  const WatchBlock({this.reactionTime, this.riskLevel, this.windowDays});

  factory WatchBlock.fromMap(Map<String, dynamic> map) =>
      WatchBlock(reactionTime: map['reactionTime']?.toString(), riskLevel: map['riskLevel']?.toString(), windowDays: InsightValues.integer(map['windowDays']));

  /// Human delay ("1.5–2h", "~45m").
  final String? reactionTime;

  /// 'Low' | 'Medium' | 'High' — clamped by the UI.
  final String? riskLevel;

  /// Analysis window the stats refer to (default 7 in the UI).
  final int? windowDays;

  Map<String, dynamic> toMap() => {'reactionTime': reactionTime, 'riskLevel': riskLevel, 'windowDays': windowDays};

  @override
  List<Object?> get props => [reactionTime, riskLevel, windowDays];
}

/// `smartSwap` — the Before → After swap under "Something to Watch".
class SmartSwap extends Equatable {
  const SmartSwap({required this.after, this.benefit, this.tip, this.beforeEmoji, this.afterEmoji});

  factory SmartSwap.fromMap(Map<String, dynamic> map) => SmartSwap(
    after: map['after']?.toString() ?? '',
    benefit: map['benefit']?.toString(),
    tip: map['tip']?.toString(),
    beforeEmoji: map['beforeEmoji']?.toString(),
    afterEmoji: map['afterEmoji']?.toString(),
  );

  /// The swap's `before` is the watched trigger food itself; only the
  /// alternative is required.
  final String after;

  /// Short quantified benefit ("73% less risk", "Half the refined oils").
  final String? benefit;

  /// One-sentence encouragement for the dark rec card.
  final String? tip;
  final String? beforeEmoji;
  final String? afterEmoji;

  Map<String, dynamic> toMap() => {'after': after, 'benefit': benefit, 'tip': tip, 'beforeEmoji': beforeEmoji, 'afterEmoji': afterEmoji};

  @override
  List<Object?> get props => [after, benefit, tip, beforeEmoji, afterEmoji];
}
