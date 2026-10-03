part of 'insight_bento_screens.dart';

/// Weekly recap presentation components.

class InsightBentoRecap extends StatelessWidget {
  const InsightBentoRecap({super.key, required this.recap, this.series = const [], this.seriesLabels = const [], this.insight});

  final WeeklyRecap recap;
  final List<double> series;
  final List<String> seriesLabels;
  final AIInsight? insight;

  @override
  Widget build(BuildContext context) {
    final trend = recap.gutScoreTrend;
    final chartSeries = (trend != null && trend.isNotEmpty) ? [for (final s in trend) s.toDouble()] : series;
    final scored = (trend ?? const <int>[]).where((s) => s > 0).toList();
    final trendAvg = scored.isEmpty ? null : (scored.reduce((a, b) => a + b) / scored.length).round();
    final avg = (recap.avgScore ?? trendAvg ?? insight?.gutScore ?? 0).clamp(0, 100);
    final src = insight;
    final delta = src == null ? null : BentoData.parseDelta(src.scoreDiff);
    final shown = chartSeries.length > 7 ? chartSeries.sublist(chartSeries.length - 7) : chartSeries;

    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16.w, 8.w, 16.w, 24.w),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          GutScoreCard(
            score: avg,
            delta: delta,
            series: chartSeries,
            labels: labels,
            title: AppStrings.bentoWeeklyEyebrow,
            subtitle: recap.scoreSub ?? AppStrings.last7Days,
            footLeft: '${AppStrings.bentoPositiveDays}: ${recap.scoreSub ?? ""}',
            footRight: '${AppStrings.bestDayLabel}: ${recap.bestDay ?? "—"}',
            showChevron: true,
            onTap: () {
              final targetInsight = insight ?? AIInsight(gutScore: avg, weeklyRecap: recap, updatedAt: DateTime.now());
              WhyScoreSheet.show(context, targetInsight);
            },
          ),
          Gap.h14,
          BentoGrid(children: _tiles(context, shown)),
        ]),
      ),
    );
  }

  List<BentoTile> _tiles(BuildContext context, List<double> shown) {
    final tiles = <BentoTile>[];
    final hl = recap.highlights;
    final src = insight;

    if (shown.length >= 2) {
      tiles.add(BentoTile(spanTwo: true, FoilSparkCard(values: shown)));
    }

    if (hl.isNotEmpty) {
      final firstItem = hl.first;
      final titleText = firstItem is RecapHighlight ? firstItem.text : firstItem.toString();
      tiles.add(
        BentoTile(
          spanTwo: true,
          InsightHighlightCard(
            accentColor: const Color(0xFF57B93B),
            backgroundColor: const Color(0xFFF0F8EA),
            emoji: '🌟',
            tag: AppStrings.bentoTopWin,
            meta: recap.foodsLogged == null ? null : AppStrings.bentoOfDays(recap.foodsLogged!, 7),
            title: titleText,
            body: recap.loggedSub,
            chart: shown.length >= 2 ? SparkArea(values: shown, color: const Color(0xFF57B93B), height: 38) : null,
            chartPainter: shown.length >= 2 ? null : HealingSparklinePainter(color: const Color(0xFF57B93B)),
          ),
        ),
      );
    }

    final trigger = src?.validTopTrigger;
    if (trigger != null) {
      tiles.add(
        BentoTile(
          InsightHighlightCard(
            accentColor: const Color(0xFFF08019),
            backgroundColor: const Color(0xFFFDF1E7),
            emoji: trigger.emoji.isNotEmpty ? trigger.emoji : '⚠️',
            tag: AppStrings.bentoCulprit,
            title: trigger.food,
            body: trigger.effects,

            footLeft: AppStrings.bentoWatchDays,
            onTap: src == null
                ? null
                : () => context.push(
                    AppRoutes.highlightDetail,
                    extra: HighlightDetailArgs(
                      tag: AppStrings.bentoCulprit,
                      emoji: trigger.emoji.isNotEmpty ? trigger.emoji : '⚠️',
                      title: trigger.food,
                      body: trigger.effects,
                      accentColor: 0xFFF08019,
                      backgroundColor: 0xFFFDF1E7,
                      chartType: 'trigger',
                      footLeft: AppStrings.bentoWatchDays,
                    ),
                  ),
          ),
        ),
      );
    }

    final healing = src?.topHealing;
    if (healing != null) {
      tiles.add(
        BentoTile(
          InsightHighlightCard(
            accentColor: const Color(0xFFEFB008),
            backgroundColor: const Color(0xFFFDF6E2),
            emoji: healing.emoji.isNotEmpty ? healing.emoji : '✨',
            tag: AppStrings.bentoRecovery,
            title: healing.food,
            body: healing.effects,

            footLeft: healing.timeframe,
            onTap: src == null
                ? null
                : () => context.push(
                    AppRoutes.highlightDetail,
                    extra: HighlightDetailArgs(
                      tag: AppStrings.bentoRecovery,
                      emoji: healing.emoji.isNotEmpty ? healing.emoji : '✨',
                      title: healing.food,
                      body: healing.effects,
                      accentColor: 0xFFEFB008,
                      backgroundColor: 0xFFFDF6E2,
                      chartType: 'working',
                      footLeft: healing.timeframe,
                    ),
                  ),
          ),
        ),
      );
    }

    for (final h in hl.skip(1).take(2)) {
      if (h is RecapHighlight) {
        final (accent, tone) = _pairForHighlightColor(h.color);
        tiles.add(BentoTile(InsightHighlightCard(accentColor: accent, backgroundColor: tone, emoji: _emojiForIcon(h.icon), tag: AppStrings.bentoRecovery, title: h.text)));
      } else {
        tiles.add(BentoTile(InsightHighlightCard(accentColor: const Color(0xFF57B93B), backgroundColor: const Color(0xFFF0F8EA), emoji: '🌿', tag: AppStrings.bentoRecovery, title: h.toString())));
      }
    }
    return tiles;
  }

  static (Color, Color) _pairForHighlightColor(String c) => switch (c.toLowerCase()) {
    'red' || 'coral' => (const Color(0xFFE11D48), const Color(0xFFFFF1F2)),
    'green' || 'mint' => (const Color(0xFF57B93B), const Color(0xFFF0F8EA)),
    'orange' || 'peach' => (const Color(0xFFF08019), const Color(0xFFFDF1E7)),
    'amber' || 'yellow' => (const Color(0xFFEFB008), const Color(0xFFFDF6E2)),
    _ => (const Color(0xFF8B5CF6), const Color(0xFFF5EEFC)),
  };

  static String _emojiForIcon(String icon) {
    switch (icon.toLowerCase()) {
      case 'flame':
        return '🔥';
      case 'moon':
        return '🌙';
      case 'droplet':
        return '💧';
      case 'zap':
        return '⚡';
      case 'leaf':
        return '🌿';
      default:
        return '✨';
    }
  }
}

