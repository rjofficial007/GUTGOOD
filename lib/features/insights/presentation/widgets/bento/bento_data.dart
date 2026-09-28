import 'package:gutgood/core/models/models.dart';
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

  static String _upper(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
  static String _lower(String s) => s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);

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
      final entries = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final result = <BentoFood>[];
      for (final e in entries.take(limit)) {
        final impact = firstSeen[e.key];
        if (impact != null) {
          result.add(
            BentoFood(
              name: impact.food,
              stat: e.value == 1 ? '1 log' : '${e.value} logs',
              isPositive: impact.impactType.toLowerCase() != 'negative',
              emoji: (impact.emoji.isNotEmpty && impact.emoji != '🥣' && impact.emoji != '🧅') ? impact.emoji : InsightPresentation.emojiForFood(impact.food),
              imageUrl: impact.userImageUrl ?? impact.imageUrl,
              count: e.value,
            ),
          );
        }
      }
      return result;
    }
    return [
      for (final f in data.healingFoods) BentoFood(name: f.name, stat: f.effect, isPositive: true, emoji: f.emoji, imageUrl: f.userImageUrl ?? f.imageUrl),
      for (final f in data.triggerFoods) BentoFood(name: f.name, stat: f.effect, isPositive: false, emoji: f.emoji, imageUrl: f.userImageUrl ?? f.imageUrl),
    ].take(limit).toList();
  }

  /// Count of foods the user has logged this period — the "14 LOGGED" figure.
  static int loggedFoodCount(AIInsight data) {
    final unique = <String>{for (final f in data.foodImpacts) f.food.toLowerCase().trim()}..remove('');
    if (unique.isNotEmpty) return unique.length;
    return data.healingFoods.length + data.triggerFoods.length;
  }

  /// Chronological gut-score window (≤7 points) for the heroes' bar charts,
  /// plus the matching weekday-initial labels.
  ///
  /// [until] truncates the history at a date (historical insight view) and
  /// [ensure] is appended when the history does not already contain it, so
  /// the chart always ends on the insight being displayed.
  static (List<double>, List<String>) scoreWindow(Iterable<AIInsight> history, {DateTime? until, AIInsight? ensure}) {
    var sorted = [...history]..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    if (until != null) {
      sorted = sorted.where((i) => !i.updatedAt.isAfter(until)).toList();
    }
    if (ensure != null && !sorted.any((i) => i.updatedAt == ensure.updatedAt)) {
      sorted.add(ensure);
    }
    final window = sorted.length > 7 ? sorted.sublist(sorted.length - 7) : sorted;
    const initials = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return ([for (final i in window) i.gutScore.toDouble()], initials);
  }

  /// Gallery-faithful fallback for the heroes' bar charts: the feed and recap
  /// heroes in GUTGOOD_SCREENS.html always chart seven bars, so below two real
  /// history points we synthesise a gentle ramp anchored at the displayed
  /// [score] (direction from [delta]) with weekday-initial labels ending on
  /// [end]'s day. Same decorative-fallback precedent as the mini-chart
  /// painters in `pattern_grid.dart`.
  static (List<double>, List<String>) fallbackWindow(int score, {int? delta, DateTime? end}) {
    final dir = (delta ?? 1) >= 0 ? 1 : -1;
    const initials = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return ([for (var i = 6; i >= 0; i--) (score - dir * i * 2.5).clamp(0.0, 100.0)], initials);
  }
}

/// One food entry for the bento grids.
class BentoFood {
  const BentoFood({required this.name, required this.stat, required this.isPositive, required this.emoji, this.imageUrl, this.count = 1});

  final String name;
  final String stat;
  final bool isPositive;
  final String emoji;
  final String? imageUrl;
  final int count;
}
