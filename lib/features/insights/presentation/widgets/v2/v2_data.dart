import 'package:flutter/material.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/utils/insight_presentation.dart';
import 'package:gutgood/core/utils/insight_values.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/v2_kit.dart';

/// Deterministic derivations backing the v2 cards.
///
/// Philosophy carried over from `BentoData`: the AI's v3 blocks
/// (`improving`/`watch`/`smartSwap`) win when present; every value they
/// provide has a deterministic fallback computed here from the fields legacy
/// docs already carry, so the UI renders identically before/after
/// regeneration and never blocks on the model.

/// One row of the "Recent timeline" inside the watch card.
class V2TimelineEntry {
  const V2TimelineEntry({required this.title, required this.subtitle, required this.trailing, required this.latest, this.imageName, this.imageUrl});

  final String title;
  final String subtitle;
  final String trailing;
  final bool latest;

  /// Food imagery for the log row (image-utils chain resolves the URL).
  final String? imageName;
  final String? imageUrl;
}

/// Fully resolved view-model for the "Something to Watch" card.
class V2WatchData {
  const V2WatchData({
    required this.title,
    required this.description,
    required this.meta,
    required this.reactionTime,
    required this.riskLevel,
    required this.windowLabel,
    required this.timeline,
    this.pattern,
    this.swapAfter,
    this.swapBenefit,
    this.swapTip,
    this.swapBeforeEmoji,
    this.swapAfterEmoji,
    this.pillImageName,
    this.pillImageUrl,
  });

  final String title;
  final String description;
  final String meta;

  /// Empty string = stat unknown (renders "—").
  final String reactionTime;
  final String riskLevel;
  final String windowLabel;
  final List<V2TimelineEntry> timeline;
  final BodyPattern? pattern;

  /// Non-null renders the smart-swap section.
  final String? swapAfter;
  final String? swapBenefit;
  final String? swapTip;
  final String? swapBeforeEmoji;
  final String? swapAfterEmoji;

  /// Primary food imagery for the pattern pill (scan/occurrence image first).
  final String? pillImageName;
  final String? pillImageUrl;
}

/// Fully resolved view-model for the "What's Improving" card.
class V2ImprovingData {
  const V2ImprovingData({
    required this.eyebrowSub,
    required this.headline,
    required this.description,
    required this.current,
    required this.lastWeek,
    required this.deltaPts,
    required this.streakDays,
    required this.streakGoal,
    required this.encouragement,
    required this.keyFoods,
  });

  final String eyebrowSub;
  final String headline;
  final String description;
  final int current;
  final int? lastWeek;
  final int deltaPts;
  final int streakDays;
  final int streakGoal;
  final String encouragement;
  final List<V2FoodItemData> keyFoods;
}

abstract final class V2Data {
  /// The v2 trend pill word for a signed point delta.
  static String trendWord(int? delta) {
    if (delta == null || delta == 0) return 'Holding steady';
    return delta > 0 ? 'Improving' : 'Needs care';
  }

  /// "High confidence" / "Moderate confidence" / "Early signals".
  static String confidenceWord(String confidenceLevel) => switch (confidenceLevel.toLowerCase()) {
    'high' => 'High confidence',
    'moderate' => 'Moderate confidence',
    _ => 'Early signals',
  };

  /// Parses a display delta ("+4", "-3") into a signed int.
  static int? parseDelta(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.replaceAll(RegExp(r'[^0-9+\-]'), '');
    if (cleaned.isEmpty || cleaned == '+' || cleaned == '-') return null;
    return int.tryParse(cleaned);
  }

  /// The score two points back in a chronological window — "Last week".
  static int? previousScore(List<double> series) {
    if (series.length < 2) return null;
    return series[series.length - 2].round();
  }

  /// Streak: the AI's `improving.streakDays`, else derived from how many
  /// consecutive positive score deltas the history ends with (min 1 when a
  /// feed exists at all).
  static int streakDays(AIInsight insight, List<AIInsight> history, {int? seriesDerivedDelta}) {
    final ai = insight.improving?.streakDays;
    if (ai != null && ai > 0) return ai.clamp(1, 30).toInt();
    if ((seriesDerivedDelta ?? 0) <= 0) return 0;
    final sorted = [...history]..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    if (sorted.length < 2) return 0;
    var streak = 1;
    for (var i = sorted.length - 1; i > 0; i--) {
      final d = parseDelta(sorted[i].scoreDiff) ?? 0;
      if (d > 0) {
        streak++;
      } else {
        break;
      }
    }
    return streak.clamp(1, 30).toInt();
  }

  /// Resolves the "What's Improving" card. [series] is the ≤7-point
  /// chronological score window feeding the chart.
  static V2ImprovingData improving(AIInsight insight, List<double> series, List<AIInsight> history) {
    final current = insight.gutScore.clamp(0, 100).toInt();
    final last = previousScore(series);
    final ai = insight.improving;
    final deltaPts = last == null ? (parseDelta(insight.scoreDiff) ?? 0) : current - last;

    final keyFoods = <V2FoodItemData>[
      if (ai != null && ai.keyFoods.isNotEmpty)
        for (final k in ai.keyFoods.take(3))
          V2FoodItemData(
            name: k.name,
            count: k.count == null ? null : '${k.count}×',
            delta: k.delta == null || k.delta == 0 ? null : (k.delta! > 0 ? '+${k.delta}' : '${k.delta}'),
            deltaColor: (k.delta ?? 0) < 0 ? const Color(0xFFC4302B) : const Color(0xFF1F7A3D),
            emoji: (k.emoji?.isNotEmpty ?? false) ? k.emoji : InsightPresentation.emojiForFood(k.name),
            imageUrl: (k.imageUrl?.isNotEmpty ?? false) ? k.imageUrl : _impactImage(insight, k.name),
          )
      else if (insight.healingFoods.isNotEmpty)
        for (final f in insight.healingFoods.take(3))
          V2FoodItemData(
            name: f.name,
            count: _loggedCount(insight, f.name),
            emoji: f.emoji,
            imageUrl: (f.userImageUrl?.isNotEmpty ?? false)
                ? f.userImageUrl
                : (f.imageUrl?.isNotEmpty ?? false)
                ? f.imageUrl
                : _impactImage(insight, f.name),
            userImageUrl: f.userImageUrl,
          )
      else if (insight.healingSummary?.foods.isNotEmpty == true)
        for (final f in insight.healingSummary!.foods.take(3))
          V2FoodItemData(name: f.name, count: _loggedCount(insight, f.name), emoji: f.emoji, imageUrl: (f.imageUrl?.isNotEmpty ?? false) ? f.imageUrl : _impactImage(insight, f.name)),
    ];

    final topHealing =
        insight.topHealing ??
        (insight.healingFoods.isNotEmpty
            ? TopHighlight(food: insight.healingFoods.first.name, emoji: insight.healingFoods.first.emoji, impact: insight.healingFoods.first.effect)
            : (insight.healingSummary?.foods.isNotEmpty == true
                  ? TopHighlight(food: insight.healingSummary!.foods.first.name, emoji: insight.healingSummary!.foods.first.emoji, impact: insight.healingSummary!.foods.first.effect ?? '')
                  : null));

    final streakGoal = (ai?.streakGoalDays?.clamp(3, 14) ?? (ai?.streakDays != null ? (ai!.streakDays! + 2).clamp(4, 14) : 5)).toInt();

    return V2ImprovingData(
      eyebrowSub: 'Gut score • ${deltaPts >= 0 ? '+' : ''}$deltaPts pts this window',
      headline: (ai?.headline?.isNotEmpty ?? false)
          ? ai!.headline!
          : (topHealing != null && topHealing.food.isNotEmpty)
          ? '${topHealing.food}${topHealing.impact.isNotEmpty ? ' • ${topHealing.impact}' : ''}'
          : (insight.healingTrend?.isNotEmpty ?? false)
          ? insight.healingTrend!
          : 'Your gut score is on the move',
      description: (ai?.description?.isNotEmpty ?? false)
          ? ai!.description!
          : (topHealing != null && topHealing.impact.isNotEmpty)
          ? '${topHealing.food} is associated with positive gut responses.'
          : 'Keep logging meals and symptoms to track your gut health progress.',
      current: current,
      lastWeek: last,
      deltaPts: deltaPts,
      streakDays: streakDays(insight, history, seriesDerivedDelta: deltaPts),
      streakGoal: streakGoal,
      encouragement: (ai?.encouragement?.isNotEmpty ?? false) ? ai!.encouragement! : 'Keep it up — consistency builds clearer patterns.',
      keyFoods: keyFoods,
    );
  }

  /// How many times [food] appears in this insight's food impacts ("3×").
  static String? _loggedCount(AIInsight insight, String food) {
    final key = food.toLowerCase().trim();
    if (key.isEmpty) return null;
    var n = 0;
    for (final impact in insight.foodImpacts) {
      if (impact.food.toLowerCase().trim() == key) n++;
    }
    return n == 0 ? null : (n == 1 ? '1×' : '$n×');
  }

  /// Most recent scan image logged for [food] (user photo first).
  static String? _impactImage(AIInsight insight, String food) {
    final key = food.toLowerCase().trim();
    if (key.isEmpty) return null;
    for (final impact in insight.foodImpacts) {
      if (impact.food.toLowerCase().trim() == key) {
        final img = impact.userImageUrl ?? impact.imageUrl;
        if (img != null && img.isNotEmpty) return img;
      }
    }
    return null;
  }

  static String? _firstOccurrenceImage(BodyPattern pattern) {
    for (final o in pattern.occurrences) {
      final img = o.imageUrl;
      if (img != null && img.isNotEmpty) return img;
    }
    return null;
  }

  /// The strongest negative pattern (candidates arrive pre-sorted; first with
  /// a symptomatic majority wins, else the first at all).
  static BodyPattern? watchPattern(List<BodyPattern> patterns) {
    for (final p in patterns) {
      final text = '${p.reaction} ${p.description} ${p.trigger} ${p.type}';
      if (InsightValues.isPositiveReaction(text) || p.impactDirection == 'positive') continue;

      if (p.positiveCount > 0 || p.evidenceRatio >= 0.5) return p;
    }
    return null;
  }

  /// Reaction delay: AI `watch.reactionTime`, else the modal `timeAfter`
  /// across the pattern's occurrences, else "—".
  static String reactionTime(AIInsight insight, BodyPattern? pattern) {
    final ai = insight.watch?.reactionTime;
    if (ai != null && ai.isNotEmpty && ai.toLowerCase() != 'n/a' && ai != '—') return ai;
    if (pattern == null || pattern.occurrences.isEmpty) return 'Still learning your patterns';
    final counts = <String, int>{};
    for (final o in pattern.occurrences) {
      final t = o.timeAfter.trim();
      if (t.isNotEmpty && t.toLowerCase() != 'n/a' && t != '—') counts[t] = (counts[t] ?? 0) + 1;
    }
    if (counts.isEmpty) return 'Still learning your patterns';
    final best = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return best.key;
  }

  /// Risk level: AI `watch.riskLevel`, else banded off the evidence ratio.
  static String riskLevel(AIInsight insight, BodyPattern? pattern) {
    final ai = insight.watch?.riskLevel;
    if (ai != null && ai.isNotEmpty) return ai;
    if (pattern == null) return 'Unknown';
    final ratio = pattern.evidenceRatio;
    if (ratio.isFinite && ratio > 0) {
      if (ratio >= 0.8) return 'High';
      if (ratio >= 0.5) return 'Medium';
      return 'Low';
    }
    final total = pattern.positiveCount + pattern.negativeCount;
    if (total == 0) return 'Unknown';
    final measuredRatio = pattern.positiveCount / total;
    if (measuredRatio >= 0.8) return 'High';
    if (measuredRatio >= 0.5) return 'Medium';
    return 'Low';
  }

  /// Resolves the "Something to Watch" card; null hides the whole card.
  static V2WatchData? watch(AIInsight insight, List<BodyPattern> patterns) {
    final pattern = watchPattern(patterns);
    if (pattern == null) return null;

    final trigger = pattern.trigger.trim();
    final reaction = pattern.reaction.trim();
    final title = (trigger.isEmpty && reaction.isEmpty)
        ? (pattern.description.isNotEmpty ? pattern.description : 'Pattern detected')
        : reaction.isEmpty
        ? trigger
        : trigger.isEmpty
        ? reaction
        : '$trigger → $reaction';

    final windowDays = insight.watch?.windowDays ?? pattern.timeframeDays;
    final occurrences = [...pattern.occurrences]..sort((a, b) => b.date.compareTo(a.date));
    final timeline = <V2TimelineEntry>[
      for (var i = 0; i < occurrences.take(3).length; i++)
        V2TimelineEntry(
          title: '${occurrences[i].date} • ${occurrences[i].mealName}',
          subtitle: occurrences[i].reaction,
          trailing: i == 0 ? 'Latest' : '-$i${i == 1 ? 'd' : 'ds'}',
          latest: i == 0,
          imageName: occurrences[i].mealName,
          imageUrl: occurrences[i].imageUrl,
        ),
    ];

    final swap = insight.smartSwap;
    final swapAfter = (swap == null || swap.after.trim().isEmpty) ? null : swap.after.trim();
    final beforeName = _primaryTriggerFood(insight, pattern);

    return V2WatchData(
      title: title,
      description: pattern.description.isNotEmpty ? pattern.description : 'This combination keeps repeating in your logs.',
      meta: 'Pattern • ${pattern.frequency}× in ${windowDays}d',
      reactionTime: reactionTime(insight, pattern),
      riskLevel: riskLevel(insight, pattern),
      windowLabel: windowDays <= 0 ? '—' : '${windowDays}d',
      timeline: timeline,
      pattern: pattern,
      swapAfter: swapAfter,
      swapBenefit: swap?.benefit,
      swapTip: swap?.tip,
      swapBeforeEmoji: swap?.beforeEmoji ?? (beforeName == null ? null : InsightPresentation.emojiForFood(beforeName)),
      swapAfterEmoji: swap?.afterEmoji,
      pillImageName: beforeName ?? (pattern.occurrences.isNotEmpty ? pattern.occurrences.first.mealName : null),
      pillImageUrl: _firstOccurrenceImage(pattern),
    );
  }

  static String? _primaryTriggerFood(AIInsight insight, BodyPattern pattern) {
    if (pattern.involvedFoods.isNotEmpty) return pattern.involvedFoods.first;
    if (insight.triggerFoods.isNotEmpty) return insight.triggerFoods.first.name;
    if (insight.topTrigger != null && insight.topTrigger!.food.isNotEmpty) {
      return insight.topTrigger!.food;
    }
    return null;
  }

  /// Pills for the pattern pill row: name, "⏱ delay • n occurrences".
  static String patternPillSub(V2WatchData watch) => '⏱ ${watch.reactionTime} • ${watch.timeline.length} occurrence${watch.timeline.length == 1 ? '' : 's'}';
}
