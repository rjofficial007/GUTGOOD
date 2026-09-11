import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/ai_insight_details.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/utils/insight_presentation.dart';

/// Derives the bento screens' content from the existing insight models.
///
/// Everything here reads the same `AIInsight`/`BodyPattern` data the previous
/// Insights UI consumed — the redesign changes presentation, not the pipeline.
abstract final class BentoData {
  /// Score bands drive the hero's status pill, matching the mock's
  /// "STEADY BALANCE" / "STRONG GAIN" copy.
  static String statusForScore(int score, {int? delta}) {
    if (delta != null && delta >= 8) return 'Strong gain';
    if (score >= 75) return 'Thriving';
    if (score >= 55) return 'Steady balance';
    if (score >= 35) return 'Finding rhythm';
    return 'Building up';
  }

  /// The mock stores `scoreDiff` as a display string ("+6", "-3"); the delta
  /// pill needs the signed magnitude, so parse defensively.
  static int? parseDelta(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.replaceAll(RegExp(r'[^0-9+\-]'), '');
    if (cleaned.isEmpty || cleaned == '+' || cleaned == '-') return null;
    return int.tryParse(cleaned);
  }

  /// A signed point delta rendered the way the mock does: `↑ 6 pts`.
  static String? deltaLabel(String? raw) {
    final d = parseDelta(raw);
    if (d == null || d == 0) return null;
    return '${d > 0 ? '↑' : '↓'} ${d.abs()} pts';
  }

  /// `94% match` from a 0..1 confidence/evidence ratio.
  static String? matchLabel(double? ratio) {
    if (ratio == null || ratio <= 0) return null;
    final pct = (ratio.clamp(0.0, 1.0) * 100).round();
    if (pct <= 0) return null;
    return '$pct% match';
  }

  /// Sentence used for the pattern hero bento, mirroring the mock's
  /// "Fast food dinners trigger headaches 3.5 hrs later."
  static String patternHeadline(BodyPattern p) {
    final trigger = p.trigger.trim();
    final reaction = p.reaction.trim();
    if (trigger.isEmpty && reaction.isEmpty) return p.description;
    if (trigger.isEmpty) return reaction;
    if (reaction.isEmpty) return trigger;
    return '${_upper(trigger)} shows up on days you report ${_lower(reaction)}.';
  }

  static String _upper(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
  static String _lower(String s) =>
      s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);

  /// Groups `foodImpacts` by lowercased name (the app's existing rule) and
  /// falls back to the healing/trigger food lists, as before.
  static List<BentoFood> topFoods(AIInsight data, {int limit = 8}) {
    final impacts = data.foodImpacts;
    if (impacts.isNotEmpty) {
      final counts = <String, int>{};
      final firstSeen = <String, FoodImpact>{};
      for (final impact in impacts) {
        final key = impact.food.toLowerCase().trim();
        if (key.isEmpty) continue;
        counts[key] = (counts[key] ?? 0) + 1;
        firstSeen.putIfAbsent(key, () => impact);
      }
      final entries = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return [
        for (final e in entries.take(limit))
          BentoFood(
            name: firstSeen[e.key]!.food,
            stat: e.value == 1 ? '1 log' : '${e.value} logs',
            isPositive:
                firstSeen[e.key]!.impactType.toLowerCase() != 'negative',
            emoji: InsightPresentation.emojiForFood(firstSeen[e.key]!.food),
            imageUrl: firstSeen[e.key]!.imageUrl,
            count: e.value,
          ),
      ];
    }
    return [
      for (final f in data.healingFoods)
        BentoFood(
          name: f.name,
          stat: f.effect,
          isPositive: true,
          emoji: f.emoji,
          imageUrl: f.imageUrl,
        ),
      for (final f in data.triggerFoods)
        BentoFood(
          name: f.name,
          stat: f.effect,
          isPositive: false,
          emoji: f.emoji,
          imageUrl: f.imageUrl,
        ),
    ].take(limit).toList();
  }

  /// Count of foods the user has logged this period — the "14 LOGGED" figure.
  static int loggedFoodCount(AIInsight data) {
    final unique = <String>{
      for (final f in data.foodImpacts) f.food.toLowerCase().trim(),
    }..remove('');
    if (unique.isNotEmpty) return unique.length;
    return data.healingFoods.length + data.triggerFoods.length;
  }
}

/// One food entry for the bento grids.
class BentoFood {
  const BentoFood({
    required this.name,
    required this.stat,
    required this.isPositive,
    required this.emoji,
    this.imageUrl,
    this.count = 1,
  });

  final String name;
  final String stat;
  final bool isPositive;
  final String emoji;
  final String? imageUrl;
  final int count;
}
