import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/bento_data.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/bento_widgets.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/insight_bento_feed.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/pattern_style.dart';
import 'package:gutgood/features/insights/presentation/widgets/pattern_grid.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_theme.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/v2_kit.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// Screen 03 — the weekly recap, rebuilt on the pattern-card system.
class InsightBentoRecap extends StatelessWidget {
  const InsightBentoRecap({super.key, required this.recap, this.series = const [], this.seriesLabels = const [], this.insight});

  final WeeklyRecap recap;
  final List<double> series;
  final List<String> seriesLabels;
  final AIInsight? insight;

  @override
  Widget build(BuildContext context) {
    final avg = (recap.avgScore ?? insight?.gutScore ?? 0).clamp(0, 100);
    final src = insight;
    final delta = src == null ? null : BentoData.parseDelta(src.scoreDiff);
    final shown = series.length > 7 ? series.sublist(series.length - 7) : series;

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16.w, 8.w, 16.w, 24.w),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          GutScoreCard(
            score: avg,
            delta: delta,
            series: series,
            labels: seriesLabels,
            title: AppStrings.bentoWeeklyEyebrow,
            subtitle: AppStrings.last7Days,
            footLeft: '${AppStrings.bentoPositiveDays}: ${recap.scoreSub ?? ""}',
            footRight: '${AppStrings.bestDayLabel}: ${recap.bestDay ?? ""}',
            showChevron: false,
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
            meta: AppStrings.bentoOfDays(recap.foodsLogged ?? 5, 7),
            title: titleText,
            body: recap.loggedSub,
            chart: shown.length >= 2 ? SparkArea(values: shown, color: const Color(0xFF57B93B), height: 38) : null,
            chartPainter: shown.length >= 2 ? null : HealingSparklinePainter(color: const Color(0xFF57B93B)),
          ),
        ),
      );
    }

    final trigger = src?.topTrigger;
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
            chartPainter: TriggerSpikePainter(color: const Color(0xFFF08019)),
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
            chartPainter: WorkingBarsPainter(color: const Color(0xFFEFB008)),
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

enum HistorySort { newest, oldest, gains, drops }

/// Screen 04 — the insight history.
class InsightBentoHistory extends StatefulWidget {
  const InsightBentoHistory({super.key, required this.insights, required this.onTapInsight, this.onOpenRecap, this.onOpenSynthesis});

  final List<AIInsight> insights;
  final void Function(AIInsight) onTapInsight;
  final VoidCallback? onOpenRecap;
  final VoidCallback? onOpenSynthesis;

  @override
  State<InsightBentoHistory> createState() => _InsightBentoHistoryState();
}

class _InsightBentoHistoryState extends State<InsightBentoHistory> {
  int _tab = 0;
  String _query = '';
  bool _searching = false;
  HistorySort _sort = HistorySort.newest;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static int _deltaOf(AIInsight i) => BentoData.parseDelta(i.scoreDiff) ?? 0;

  static T? _firstOrNull<T>(List<T> xs, bool Function(T) test) {
    for (final x in xs) {
      if (test(x)) return x;
    }
    return null;
  }

  List<AIInsight> get _newestFirst => [...widget.insights]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  bool _matches(AIInsight i) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final haystack = <String?>[
      i.topInsight?.title,
      i.topInsight?.description,
      i.healingGoal,
      i.triggerSymptom,
      i.topHealing?.food,
      i.topTrigger?.food,
      ...i.healingFoods.map((f) => f.name),
      ...i.triggerFoods.map((f) => f.name),
    ].whereType<String>().join(' ').toLowerCase();
    return haystack.contains(q);
  }

  List<AIInsight> get _visible {
    final byTab = switch (_tab) {
      1 => _newestFirst.where((i) => _deltaOf(i) > 0).toList(),
      2 => _newestFirst.where((i) => _deltaOf(i) < 0).toList(),
      _ => _newestFirst,
    };
    final list = byTab.where(_matches).toList();
    switch (_sort) {
      case HistorySort.newest:
        break;
      case HistorySort.oldest:
        list.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      case HistorySort.gains:
        list.sort((a, b) => _deltaOf(b).compareTo(_deltaOf(a)));
      case HistorySort.drops:
        list.sort((a, b) => _deltaOf(a).compareTo(_deltaOf(b)));
    }
    return list;
  }

  void _toggleSearch() => setState(() {
    _searching = !_searching;
    if (!_searching) {
      _query = '';
      _searchController.clear();
    }
  });

  void _clearFilters() => setState(() {
    _tab = 0;
    _sort = HistorySort.newest;
    _query = '';
    _searchController.clear();
  });

  @override
  Widget build(BuildContext context) {
    final all = _newestFirst;
    final wins = all.where((i) => _deltaOf(i) > 0).length;
    final watch = all.where((i) => _deltaOf(i) < 0).length;
    final rows = _visible;

    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.w),
          sliver: SliverToBoxAdapter(child: BentoGrid(children: _summaryTiles(all, wins, watch))),
        ),
        SliverToBoxAdapter(child: _controls(all.length, wins, watch)),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.w),
          sliver: SliverToBoxAdapter(child: rows.isEmpty ? _noResults() : _timeline(rows)),
        ),
      ],
    );
  }

  List<BentoTile> _summaryTiles(List<AIInsight> all, int wins, int watch) {
    if (all.isEmpty) return const [];
    final asc = all.reversed.toList();
    final first = asc.first;
    final last = asc.last;
    final tiles = <BentoTile>[];

    if (asc.length >= 2) {
      tiles.add(
        BentoTile(
          spanTwo: true,
          BentoCard(
            tone: BentoTone.white,
            spanTwo: true,
            tag: AppStrings.bentoScoreTrend,
            tagIcon: '📈',
            badge: AppStrings.bentoEntries(all.length),
            title: '${last.gutScore}',
            body: AppStrings.bentoNet(last.gutScore - first.gutScore),
            extra: FoilSparkCard(values: [for (final i in asc) i.gutScore.toDouble()], height: 44),
            footLeft: AppStrings.bentoRange(_dayLabel(first.updatedAt), _dayLabel(last.updatedAt)),
            footRight: widget.onOpenRecap == null ? null : '→',
            onTap: widget.onOpenRecap,
          ),
        ),
      );
    }

    if (asc.length >= 2) {
      var best = asc.first;
      var worst = asc.first;
      for (final i in asc) {
        if (i.gutScore > best.gutScore) best = i;
        if (i.gutScore < worst.gutScore) worst = i;
      }
      tiles.addAll([
        BentoTile(
          BentoCard(
            tone: BentoTone.mint,
            tag: AppStrings.bentoBestDay,
            tagIcon: '🏆',
            badge: AppStrings.bentoPts(_deltaOf(best)),
            title: '${best.gutScore}',
            body: _dayLabel(best.updatedAt),
            footLeft: best.topHealing?.food ?? AppStrings.bentoSeeAll,
            footRight: '→',
            onTap: () => widget.onTapInsight(best),
          ),
        ),
        BentoTile(
          BentoCard(
            tone: BentoTone.coral,
            tag: AppStrings.bentoBiggestDrop,
            tagIcon: '📉',
            badge: AppStrings.bentoPts(_deltaOf(worst)),
            title: '${worst.gutScore}',
            body: _dayLabel(worst.updatedAt),
            footLeft: worst.topTrigger?.food ?? AppStrings.bentoSeeAll,
            footRight: '→',
            onTap: () => widget.onTapInsight(worst),
          ),
        ),
      ]);
    }

    final neutral = all.length - wins - watch;
    tiles.add(
      BentoTile(
        spanTwo: true,
        BentoCard(
          tone: BentoTone.mint,
          spanTwo: true,
          tag: AppStrings.bentoWinRate,
          tagIcon: '🎯',
          badge: AppStrings.bentoWinPct((wins * 100 / all.length).round()),
          title: AppStrings.bentoWinsOf(wins, all.length),
          body: AppStrings.bentoWatchSteady(watch, neutral),
          extra: _ProportionBar(wins: wins, watch: watch, neutral: neutral),
        ),
      ),
    );

    final synthesis = _firstOrNull(all, (i) => i.topInsight != null);
    if (synthesis != null && widget.onOpenSynthesis != null) {
      final top = synthesis.topInsight!;
      tiles.add(
        BentoTile(
          spanTwo: true,
          BentoCard(
            tone: BentoTone.purple,
            spanTwo: true,
            tag: AppStrings.bentoSmartInsight,
            tagIcon: '🧠',
            badge: top.type,
            title: top.title,
            body: top.description,
            footLeft: AppStrings.bentoReadAnalysis,
            footRight: '→',
            onTap: widget.onOpenSynthesis,
          ),
        ),
      );
    }

    return tiles;
  }

  Widget _controls(int total, int wins, int watch) => Column(
    children: [
      BentoSegmentedTabs(
        tabs: ['${AppStrings.bentoAll} ($total)', '${AppStrings.bentoWins} ($wins)', '${AppStrings.bentoWatch} ($watch)'],
        selectedIndex: _tab,
        onChanged: (i) => setState(() => _tab = i),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(18.w, 2.w, 18.w, 8.w),
        child: Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleSearch,
              child: Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: Icon(_searching ? AppIcons.x : AppIcons.search, size: 16.w, color: context.bentoTheme.textTertiary),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  children: [
                    for (final s in HistorySort.values) ...[
                      if (s != HistorySort.values.first) Gap.w8,
                      _SortChip(
                        label: switch (s) {
                          HistorySort.newest => AppStrings.bentoSortNewest,
                          HistorySort.oldest => AppStrings.bentoSortOldest,
                          HistorySort.gains => AppStrings.bentoSortGains,
                          HistorySort.drops => AppStrings.bentoSortDrops,
                        },
                        selected: _sort == s,
                        onTap: () => setState(() => _sort = s),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      if (_searching)
        Padding(
          padding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 10.w),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: (v) => setState(() => _query = v),
            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 13.5.sp, color: context.bentoTheme.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              hintText: AppStrings.bentoSearchInsights,
              hintStyle: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 13.5.sp, color: context.bentoTheme.textQuaternary),
              prefixIcon: Icon(AppIcons.search, size: 16.w, color: context.bentoTheme.textTertiary),
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.w),
              filled: true,
              fillColor: context.bentoTheme.tileBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.w),
                borderSide: BorderSide(color: context.bentoTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.w),
                borderSide: BorderSide(color: context.bentoTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.w),
                borderSide: BorderSide(color: context.bentoTheme.textPrimary, width: 1.5),
              ),
            ),
          ),
        ),
    ],
  );

  Widget _timeline(List<AIInsight> rows) {
    if (_sort != HistorySort.newest && _sort != HistorySort.oldest) {
      return BentoGrid(children: [for (final i in rows) BentoTile(_dayCard(i))]);
    }

    final groups = <DateTime, List<AIInsight>>{};
    for (final r in rows) {
      final key = DateTime(r.updatedAt.year, r.updatedAt.month);
      (groups[key] ??= <AIInsight>[]).add(r);
    }
    final keys = groups.keys.toList()..sort((a, b) => _sort == HistorySort.newest ? b.compareTo(a) : a.compareTo(b));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final k in keys) ...[
          _MonthHeader(label: AppStrings.bentoMonthHeader(k), count: groups[k]!.length),
          Gap.h10,
          BentoGrid(children: [for (final i in groups[k]!) BentoTile(_dayCard(i))]),
          if (k != keys.last) Gap.h16,
        ],
      ],
    );
  }

  Widget _dayCard(AIInsight i) {
    final delta = _deltaOf(i);
    final positive = delta >= 0;
    return BentoCard(
      tone: positive ? BentoTone.mint : BentoTone.coral,
      tag: _dayLabel(i.updatedAt),
      tagIcon: positive ? '✨' : '⚠️',
      badge: delta == 0 ? null : AppStrings.bentoPts(delta),
      title: i.topInsight?.title ?? i.healingGoal ?? AppStrings.insights,
      body: i.topInsight?.description ?? i.triggerSymptom,
      footLeft: AppStrings.bentoScoreOf(i.gutScore),
      footRight: '→',
      onTap: () => widget.onTapInsight(i),
    );
  }

  Widget _noResults() => Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 32.w),
    decoration: BoxDecoration(
      color: context.bentoTheme.tileBackground,
      borderRadius: BorderRadius.circular(16.w),
      border: Border.all(color: context.bentoTheme.border),
    ),
    child: Column(
      children: [
        const Text('🔎', style: TextStyle(fontSize: 28, height: 1, fontFamily: InsightBentoTheme.fontFamily)),
        Gap.h12,
        Text(
          AppStrings.bentoNoMatches,
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 14.5.sp, fontWeight: FontWeight.w600, color: context.bentoTheme.textPrimary, height: 1.2),
        ),
        Gap.h6,
        Text(
          AppStrings.bentoNoMatchesDesc,
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.5.sp, color: context.bentoTheme.textTertiary, height: 1.45),
        ),
        Gap.h16,
        BentoCta(label: AppStrings.bentoClearFilters, onTap: _clearFilters),
      ],
    ),
  );

  static String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    return switch (today.difference(day).inDays) {
      0 => AppStrings.bentoToday,
      1 => AppStrings.bentoYesterday,
      _ => DateFormat('EEE d MMM').format(d),
    };
  }
}

class _ProportionBar extends StatelessWidget {
  const _ProportionBar({required this.wins, required this.watch, required this.neutral});
  final int wins;
  final int watch;
  final int neutral;
  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final total = wins + watch + neutral;
    if (total == 0) return const SizedBox.shrink();
    return Container(
      margin: EdgeInsets.only(top: 10.w),
      height: 8.w,
      decoration: BoxDecoration(color: t.tileBackground, borderRadius: BorderRadius.circular(100)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: Row(
          children: [
            if (wins > 0)
              Expanded(
                flex: wins,
                child: ColoredBox(color: t.positive),
              ),
            if (neutral > 0)
              Expanded(
                flex: neutral,
                child: ColoredBox(color: t.textQuaternary),
              ),
            if (watch > 0)
              Expanded(
                flex: watch,
                child: ColoredBox(color: t.negative),
              ),
          ],
        ),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.label, required this.count});
  final String label;
  final int count;
  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    return Padding(
      padding: EdgeInsets.only(left: 2.w),
      child: Row(
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: t.textTertiary, height: 1.2),
            ),
          ),
          Gap.w8,
          Text(
            AppStrings.bentoEntries(count),
            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 10.sp, color: t.textQuaternary, height: 1.2),
          ),
          Gap.w10,
          Expanded(child: Container(height: 1, color: t.border)),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.w),
        decoration: BoxDecoration(
          color: selected ? t.textPrimary : t.tileBackground,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: selected ? t.textPrimary : t.border),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w600, color: selected ? t.cardBackground : t.textTertiary, height: 1.2),
        ),
      ),
    );
  }
}

/// Screen 05 — pattern anatomy (overhauled to match patterns.html rich UI).
class InsightBentoPattern extends StatelessWidget {
  const InsightBentoPattern({super.key, required this.pattern});
  final BodyPattern pattern;

  @override
  Widget build(BuildContext context) {
    final accent = _getAccent(pattern.type);
    final confidence = (pattern.evidenceRatio.clamp(0.0, 1.0) * 100).round();
    final swaps = pattern.involvedFoods.take(2).toList();

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16.w, 4.w, 16.w, 30.w),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // 1. Hero Mascot Card
          Gap.h10,
          _HeroMascotCard(pattern: pattern, accent: accent),
          Gap.h16,
          // 2. Meta Pills
          Row(
            children: [
              _MetaPill(label: 'Seen ${pattern.frequency} times · ${pattern.timeframeDays} days', color: accent, filled: false),
              Gap.w8,
              _MetaPill(label: '${pattern.confidence} · $confidence%', color: accent, filled: true),
            ],
          ),
          Gap.h16,
          // 3. Metrics Grid
          Row(
            children: [
              _MetricCard(value: '${pattern.frequency} / ${pattern.totalSimilarMeals}', label: AppStrings.bentoEpisodes.toUpperCase(), color: accent),
              Gap.w10,
              _MetricCard(value: '~2 hrs', label: AppStrings.bentoOnsetLag.toUpperCase(), color: accent),
              Gap.w10,
              _MetricCard(value: '$confidence%', label: AppStrings.bentoConfidence.toUpperCase(), color: accent),
            ],
          ),
          Gap.h16,
          // 4. Biological Root
          _SectionCard(
            title: AppStrings.bentoBiologicalRoot,
            color: accent,
            child: Text(
              pattern.description,
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 13.sp, color: PatternSurface.isDark(context) ? const Color(0xFFC3C9D4) : const Color(0xFF3A3F47), height: 1.55),
            ),
          ),
          Gap.h16,
          // 5. Swaps
          if (swaps.isNotEmpty)
            _SectionCard(
              title: AppStrings.bentoSwap.toUpperCase(),
              color: accent,
              child: Column(
                children: [
                  for (var i = 0; i < swaps.length; i++) ...[
                    _SwapRow(food: swaps[i], color: accent, pts: 6 - i * 2),
                    if (i < swaps.length - 1) Divider(color: accent.withValues(alpha: 0.1), height: 1),
                  ],
                ],
              ),
            ),
          Gap.h16,
          // 6. Recent Episodes
          if (pattern.occurrences.isNotEmpty)
            _SectionCard(
              title: 'RECENT EPISODES',
              color: accent,
              child: Column(
                children: [for (final o in pattern.occurrences.take(4)) _EpisodeRow(occurrence: o, color: accent)],
              ),
            ),
          Gap.h16,
          // 7. Common Factors
          if (pattern.commonFactors.isNotEmpty)
            _SectionCard(
              title: 'COMMON FACTORS',
              color: accent,
              child: Wrap(
                spacing: 6.w,
                runSpacing: 6.w,
                children: [
                  for (final f in pattern.commonFactors)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.w),
                      decoration: BoxDecoration(color: accent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(999)),
                      child: Text(
                        f.label,
                        style: TextStyle(
                          fontFamily: InsightBentoTheme.fontFamily,
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w600,
                          color: PatternSurface.isDark(context) ? accent : _getTextAccent(pattern.type),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Gap.h16,
          // 8. Recommendation
          _RecommendationCard(pattern: pattern, accent: accent),
          Gap.h14,
          // 9. Summary Text
          Center(
            child: Text(
              '${pattern.positiveCount} symptomatic · ${pattern.negativeCount} without symptoms',
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.5.sp, color: PatternSurface.isDark(context) ? const Color(0xFF8D96A5) : const Color(0xFF71767F)),
            ),
          ),
          Gap.h14,
          // 10. CTA
          BentoCta(label: 'Apply this swap', onTap: () {}),
          Gap.h10,
          Center(
            child: Text(
              'Based on your logs · last ${pattern.timeframeDays} days',
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 10.5.sp, color: PatternSurface.isDark(context) ? const Color(0xFF6E7683) : const Color(0xFF9AA0A8)),
            ),
          ),
        ]),
      ),
    );
  }

  Color _getAccent(String type) => switch (type) {
    BodyPattern.typeBloating => const Color(0xFF8B5CF6),
    BodyPattern.typeEnergy => const Color(0xFF57B93B),
    BodyPattern.typeHeadache => const Color(0xFFF08019),
    BodyPattern.typeDigestion => const Color(0xFF14A38F),
    BodyPattern.typeFullness => const Color(0xFFEFB008),
    BodyPattern.typeSleep => const Color(0xFF6B74E8),
    _ => const Color(0xFF8B5CF6),
  };

  Color _getTextAccent(String type) => switch (type) {
    BodyPattern.typeBloating => const Color(0xFF563999),
    BodyPattern.typeEnergy => const Color(0xFF367325),
    BodyPattern.typeHeadache => const Color(0xFF954F10),
    BodyPattern.typeDigestion => const Color(0xFF0C6559),
    BodyPattern.typeFullness => const Color(0xFF946D05),
    BodyPattern.typeSleep => const Color(0xFF424890),
    _ => const Color(0xFF563999),
  };
}

class _HeroMascotCard extends StatelessWidget {
  const _HeroMascotCard({required this.pattern, required this.accent});
  final BodyPattern pattern;
  final Color accent;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 92.w,
        height: 92.w,
        decoration: BoxDecoration(color: PatternSurface.card(context), borderRadius: BorderRadius.circular(24.w), boxShadow: PatternSurface.softShadow(context)),
        child: Center(child: Icon(_getIcon(pattern.type), size: 48, color: accent)),
      ),
      Gap.w14,
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${pattern.type} pattern'.toUpperCase(),
              style: TextStyle(
                fontFamily: InsightBentoTheme.fontFamily,
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
                color: PatternSurface.isDark(context) ? accent : _getTextAccent(pattern.type),
              ),
            ),
            Gap.h4,
            Text(
              '${pattern.trigger} \u{2192} ${pattern.reaction}',
              style: TextStyle(
                fontFamily: InsightBentoTheme.fontFamily,
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: PatternSurface.isDark(context) ? const Color(0xFFF5F7FA) : const Color(0xFF1F2430),
                height: 1.22,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  IconData _getIcon(String type) => switch (type) {
    BodyPattern.typeBloating => AppIcons.wind,
    BodyPattern.typeEnergy => AppIcons.zap,
    BodyPattern.typeHeadache => AppIcons.brain,
    BodyPattern.typeDigestion => AppIcons.leaf,
    BodyPattern.typeFullness => AppIcons.chartPie,
    BodyPattern.typeSleep => AppIcons.moon,
    _ => AppIcons.sparkles,
  };

  Color _getTextAccent(String type) => switch (type) {
    BodyPattern.typeBloating => const Color(0xFF563999),
    BodyPattern.typeEnergy => const Color(0xFF367325),
    BodyPattern.typeHeadache => const Color(0xFF954F10),
    BodyPattern.typeDigestion => const Color(0xFF0C6559),
    BodyPattern.typeFullness => const Color(0xFF946D05),
    BodyPattern.typeSleep => const Color(0xFF424890),
    _ => const Color(0xFF563999),
  };
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label, required this.color, required this.filled});
  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.w),
    decoration: BoxDecoration(
      color: filled ? color : PatternSurface.chipBackground(context),
      borderRadius: BorderRadius.circular(999),
      border: filled ? null : Border.all(color: color.withValues(alpha: 0.5)),
    ),
    child: Text(
      label,
      style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.5.sp, fontWeight: filled ? FontWeight.w700 : FontWeight.w600, color: filled ? Colors.white : color),
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 12.w, horizontal: 6.w),
      decoration: BoxDecoration(color: PatternSurface.card(context), borderRadius: BorderRadius.circular(16.w), boxShadow: PatternSurface.softShadow(context)),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 16.sp, fontWeight: FontWeight.w800, color: color),
          ),
          Gap.h4,
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 9.5.sp, color: PatternSurface.isDark(context) ? const Color(0xFF8D96A5) : const Color(0xFF71767F), letterSpacing: 0.5),
          ),
        ],
      ),
    ),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.color, required this.child});
  final String title;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(16.w),
    decoration: BoxDecoration(color: PatternSurface.card(context), borderRadius: BorderRadius.circular(18.w), boxShadow: PatternSurface.softShadow(context)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4.w,
              height: 15.w,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
            ),
            Gap.w10,
            Text(
              title.toUpperCase(),
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: color),
            ),
          ],
        ),
        Gap.h10,
        child,
      ],
    ),
  );
}

class _SwapRow extends StatelessWidget {
  const _SwapRow({required this.food, required this.color, required this.pts});
  final String food;
  final Color color;
  final int pts;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 10.w),
    child: Row(
      children: [
        Expanded(
          child: Text(
            food,
            style: TextStyle(
              fontFamily: InsightBentoTheme.fontFamily,
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: PatternSurface.isDark(context) ? const Color(0xFFF5F7FA) : const Color(0xFF1F2430),
            ),
          ),
        ),
        Icon(Icons.arrow_forward, size: 16, color: color),
        Gap.w8,
        Expanded(
          child: Text(
            'Alternative',
            textAlign: TextAlign.end,
            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 13.sp, fontWeight: FontWeight.w700, color: color),
          ),
        ),
        Gap.w8,
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.w),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8.w)),
          child: Text(
            '+$pts pts',
            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: color),
          ),
        ),
      ],
    ),
  );
}

class _EpisodeRow extends StatelessWidget {
  const _EpisodeRow({required this.occurrence, required this.color});
  final PatternOccurrence occurrence;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 8.w),
    child: Row(
      children: [
        SizedBox(
          width: 40.w,
          child: Text(
            _formatDate(occurrence.date),
            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w800, color: color),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                occurrence.mealName,
                style: TextStyle(
                  fontFamily: InsightBentoTheme.fontFamily,
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                  color: PatternSurface.isDark(context) ? const Color(0xFFF5F7FA) : const Color(0xFF1F2430),
                ),
              ),
              Text(
                '${occurrence.reaction} \u00b7 ${occurrence.timeAfter}',
                style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.sp, color: PatternSurface.isDark(context) ? const Color(0xFF8D96A5) : const Color(0xFF71767F)),
              ),
            ],
          ),
        ),
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ],
    ),
  );

  String _formatDate(String raw) {
    if (raw.isEmpty) return '???';
    try {
      final date = DateTime.parse(raw);
      return DateFormat('EEE').format(date);
    } catch (_) {
      return raw.length > 3 ? raw.substring(0, 3) : raw;
    }
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.pattern, required this.accent});
  final BodyPattern pattern;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(16.w),
    decoration: BoxDecoration(
      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [accent, accent.withValues(alpha: 0.8)]),
      borderRadius: BorderRadius.circular(18.w),
      boxShadow: [BoxShadow(color: const Color(0xFF141828).withValues(alpha: 0.07), blurRadius: 26.w, offset: Offset(0, 10.w))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECOMMENDATION',
          style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: Colors.white.withValues(alpha: 0.9)),
        ),
        Gap.h8,
        Text(
          pattern.recommendation ?? 'Try reducing intake of triggers.',
          style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 13.5.sp, color: Colors.white, height: 1.5),
        ),
      ],
    ),
  );
}

class InsightBentoSynergy extends StatelessWidget {
  const InsightBentoSynergy({super.key, required this.summary, this.patterns = const []});
  final InsightSummary summary;
  final List<BodyPattern> patterns;

  static const Color _coral = Color(0xFFE11D48);
  static const Color _coralDeep = Color(0xFF9F1239);
  static const Color _coralTone = Color(0xFFFFF1F2);
  static const Color _teal = Color(0xFF14A38F);
  static const Color _tealTone = Color(0xFFE9F6F3);

  @override
  Widget build(BuildContext context) {
    final drivers = patterns.take(3).toList();
    final episodes = drivers.fold<int>(0, (sum, p) => sum + p.frequency);
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16.w, 8.w, 16.w, 24.w),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // The multiplier hero at hero scale: coral wash, ⚠️ tile, filled
          // "N× RISK" pill, headline + description, spike chart, episode count.
          PatternHeroCard(
            accent: _coral,
            deep: _coralDeep,
            tone: _coralTone,
            emoji: '⚠️',
            title: AppStrings.bentoMultiplier,
            sub: summary.type.isNotEmpty ? summary.type : null,
            pill: AppStrings.bentoRiskPill(drivers.length),
            headline: summary.title,
            description: summary.description,
            chart: SizedBox(
              height: 44.w,
              width: double.infinity,
              child: CustomPaint(
                size: Size.infinite,
                painter: TriggerSpikePainter(color: _coral),
              ),
            ),
            footLeft: AppStrings.bentoBasedOnEpisodes(episodes),
            showChevron: false,
          ),
          Gap.h12,
          BentoGrid(
            children: [
              // Ranked drivers wear their pattern identity (accent/tone/icon)
              // and chart their real per-day episode counts when available.
              for (var i = 0; i < drivers.length; i++)
                BentoTile(
                  InsightHighlightCard(
                    accentColor: patternAccent(drivers[i].type),
                    backgroundColor: patternTone(drivers[i].type),
                    icon: patternIcon(drivers[i].type),
                    tag: patternName(drivers[i].type),
                    meta: drivers[i].evidenceRatio > 0 ? '${(drivers[i].evidenceRatio.clamp(0.0, 1.0) * 100).round()}%' : null,
                    title: drivers[i].trigger,
                    body: drivers[i].description,
                    chartPainter: WorkingBarsPainter(color: patternAccent(drivers[i].type), values: patternSeries(drivers[i])),
                    footLeft: '${AppStrings.bentoDriver} ${i + 1}',
                    onTap: () => context.push(AppRoutes.patternDetail, extra: drivers[i]),
                  ),
                ),
              if ((summary.observation ?? '').isNotEmpty)
                BentoTile(
                  spanTwo: true,
                  InsightHighlightCard(
                    accentColor: _teal,
                    backgroundColor: _tealTone,
                    icon: AppIcons.zap,
                    tag: AppStrings.bentoRescueProtocol,
                    title: summary.observation!,
                    body: summary.strength,
                    chartPainter: HealingSparklinePainter(color: _teal),
                  ),
                ),
            ],
          ),
        ]),
      ),
    );
  }
}

class FoodIntelligenceScreen extends StatefulWidget {
  const FoodIntelligenceScreen({super.key, this.insight});

  final AIInsight? insight;

  @override
  State<FoodIntelligenceScreen> createState() => _FoodIntelligenceScreenState();
}

class _FoodIntelligenceScreenState extends State<FoodIntelligenceScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final v2 = context.v2Theme;
    final activeInsight = widget.insight ?? _getLatestInsight(context);
    final items = _buildFoodItems(activeInsight);

    final healingCount = items.where((i) => i.category == 'healing').length;
    final goodCount = items.where((i) => i.category == 'good').length;
    final watchCount = items.where((i) => i.category == 'watch').length;
    final totalCount = items.length;

    final filteredItems = switch (_selectedFilter) {
      'Healing' => items.where((i) => i.category == 'healing').toList(),
      'Good' => items.where((i) => i.category == 'good').toList(),
      'Watch' => items.where((i) => i.category == 'watch').toList(),
      _ => items,
    };

    final positiveRatio = totalCount > 0 ? (((healingCount + goodCount) / totalCount) * 100).round() : 72;

    return Scaffold(
      backgroundColor: v2.scaffold,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Same GutSliverAppBar as other detail screens
          GutSliverAppBar(title: 'TOP FOODS THIS WEEK', centerTitle: true, showBrandingIcon: false, backgroundColor: v2.scaffold),

          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 4.w, 16.w, 24.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Gap.h10,

                // 1. BANNER: Foods shaping your week
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4FAF5),
                    borderRadius: BorderRadius.circular(20.w),
                    border: Border.all(color: const Color(0xFFDCFCE7), width: 1.w),
                  ),
                  child: Row(
                    children: [
                      // Icon + Column
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32.w,
                              height: 32.w,
                              decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: Icon(LucideIcons.trendingUp, size: 16.w, color: const Color(0xFF15803D)),
                            ),
                            Gap.w10,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Foods shaping your week',
                                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                                  ),
                                  Gap.h3,
                                  Text(
                                    'Your top foods are making a real difference. Most of your choices this week are supporting a happier, healthier gut!',
                                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: const Color(0xFF475569), height: 1.25),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Gap.w10,

                      // Right Positive Ratio Badge Card
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(color: const Color(0xFFE7F6E7), borderRadius: BorderRadius.circular(16.w)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.leaf, size: 12.w, color: const Color(0xFF15803D)),
                                Gap.w4,
                                Text(
                                  '$positiveRatio%',
                                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 16.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                            Gap.h2,
                            Text(
                              'of your top foods\nare positive',
                              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.sp, color: const Color(0xFF334155), height: 1.15),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Gap.h20,

                // 2. FILTER CATEGORY CHIPS
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _FilterChip(label: 'All ($totalCount)', isSelected: _selectedFilter == 'All', onTap: () => setState(() => _selectedFilter = 'All')),
                      Gap.w6,
                      _FilterChip(
                        label: 'Healing ($healingCount)',
                        icon: LucideIcons.leaf,
                        iconColor: const Color(0xFF15803D),
                        isSelected: _selectedFilter == 'Healing',
                        onTap: () => setState(() => _selectedFilter = 'Healing'),
                      ),
                      Gap.w6,
                      _FilterChip(
                        label: 'Good ($goodCount)',
                        icon: LucideIcons.leaf,
                        iconColor: const Color(0xFF15803D),
                        isSelected: _selectedFilter == 'Good',
                        onTap: () => setState(() => _selectedFilter = 'Good'),
                      ),
                      Gap.w6,
                      _FilterChip(
                        label: 'Watch ($watchCount)',
                        icon: LucideIcons.alertTriangle,
                        iconColor: const Color(0xFFDC2626),
                        isSelected: _selectedFilter == 'Watch',
                        onTap: () => setState(() => _selectedFilter = 'Watch'),
                      ),
                    ],
                  ),
                ),

                // 3. FOOD CARDS GRID (2 Columns)
                if (filteredItems.isEmpty) ...[
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(top: 20.w),
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.w),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Icon(LucideIcons.apple, size: 28.w, color: const Color(0xFF64748B)),
                        Gap.h8,
                        Text(
                          _selectedFilter == 'All' ? 'No Food Intelligence Items Yet' : 'No $_selectedFilter Foods Recorded Yet',
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                        ),
                        Gap.h4,
                        Text(
                          'Keep logging your meals and food scans to discover which foods support or affect your gut.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, color: const Color(0xFF64748B), height: 1.35),
                        ),
                        Gap.h12,
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF15803D),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.w)),
                          ),
                          icon: Icon(LucideIcons.plus, size: 16.w),
                          label: const Text('Log a Meal'),
                          onPressed: () => context.push(AppRoutes.scannerPath('meal')),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10.w, crossAxisSpacing: 10.w, childAspectRatio: 1.0),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final food = filteredItems[index];
                      return _TopFoodGridCard(item: food);
                    },
                  ),
                ],
                Gap.h10,

                // 4. BOTTOM ENCOURAGEMENT CARD ("Keep Building Good Habits")
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4FAF5),
                    borderRadius: BorderRadius.circular(16.w),
                    border: Border.all(color: const Color(0xFFDCFCE7), width: 1.w),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28.w,
                        height: 28.w,
                        decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Icon(LucideIcons.sprout, size: 14.w, color: const Color(0xFF15803D)),
                      ),
                      Gap.w8,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Keep Building Good Habits',
                              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                            ),
                            Gap.h2,
                            Text(
                              'Small, consistent choices add up to a healthier gut.',
                              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: const Color(0xFF475569)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Gap.h12,
              ]),
            ),
          ),
        ],
      ),
    );
  }

  static AIInsight? _getLatestInsight(BuildContext context) {
    try {
      return context.read<InsightsNotifier>().latestInsight;
    } on ProviderNotFoundException {
      return null;
    }
  }

  List<_TopFoodDetailItem> _buildFoodItems(AIInsight? insight) {
    if (insight == null) return const <_TopFoodDetailItem>[];
    final list = <_TopFoodDetailItem>[];
    final seen = <String>{};

    int countOccurrences(String foodName) {
      final key = foodName.toLowerCase().trim();
      if (key.isEmpty) return 0;
      var n = 0;
      for (final impact in insight.foodImpacts) {
        if (impact.food.toLowerCase().trim() == key) n++;
      }
      return n;
    }

    // 1. Healing Foods
    for (final f in insight.healingFoods) {
      final key = f.name.toLowerCase().trim();
      if (key.isEmpty || !seen.add(key)) continue;
      final occurrences = countOccurrences(f.name);
      final countStr = occurrences > 0 ? '${occurrences}x' : '1x';
      final desc = f.effect.isNotEmpty ? f.effect : 'Supports microbiome diversity and gut balance.';
      list.add(_TopFoodDetailItem(name: f.name, countText: countStr, description: desc, impactLabel: 'High Impact', isPositive: true, category: 'healing', imageKeyword: f.name, isFavorite: true));
    }

    // 2. Food Impacts (Positive)
    for (final fi in insight.foodImpacts.where((i) => i.impactType == 'positive')) {
      final key = fi.food.toLowerCase().trim();
      if (key.isEmpty || !seen.add(key)) continue;
      final occurrences = countOccurrences(fi.food);
      final countStr = occurrences > 0 ? '${occurrences}x' : '1x';
      final desc = fi.effect.isNotEmpty ? fi.effect : 'Observed positive effect on gut health.';
      list.add(_TopFoodDetailItem(name: fi.food, countText: countStr, description: desc, impactLabel: 'Good', isPositive: true, category: 'good', imageKeyword: fi.food, isFavorite: false));
    }

    // 3. Trigger Foods
    for (final f in insight.triggerFoods) {
      final key = f.name.toLowerCase().trim();
      if (key.isEmpty || !seen.add(key)) continue;
      final occurrences = countOccurrences(f.name);
      final countStr = occurrences > 0 ? '${occurrences}x' : '1x';
      final desc = f.effect.isNotEmpty ? f.effect : 'Associated with digestive symptoms.';
      list.add(_TopFoodDetailItem(name: f.name, countText: countStr, description: desc, impactLabel: 'Watch', isPositive: false, category: 'watch', imageKeyword: f.name, isFavorite: false));
    }

    // 4. Food Impacts (Negative)
    for (final fi in insight.foodImpacts.where((i) => i.impactType == 'negative')) {
      final key = fi.food.toLowerCase().trim();
      if (key.isEmpty || !seen.add(key)) continue;
      final occurrences = countOccurrences(fi.food);
      final countStr = occurrences > 0 ? '${occurrences}x' : '1x';
      final desc = fi.effect.isNotEmpty ? fi.effect : 'Associated with digestive discomfort.';
      list.add(_TopFoodDetailItem(name: fi.food, countText: countStr, description: desc, impactLabel: 'Watch', isPositive: false, category: 'watch', imageKeyword: fi.food, isFavorite: false));
    }

    return list;
  }
}

class _TopFoodDetailItem {
  const _TopFoodDetailItem({
    required this.name,
    required this.countText,
    required this.description,
    required this.impactLabel,
    required this.isPositive,
    required this.category,
    required this.imageKeyword,
    this.isFavorite = false,
  });

  final String name;
  final String countText;
  final String description;
  final String impactLabel;
  final bool isPositive;
  final String category;
  final String imageKeyword;
  final bool isFavorite;
}

class _TopFoodGridCard extends StatelessWidget {
  const _TopFoodGridCard({required this.item});

  final _TopFoodDetailItem item;

  @override
  Widget build(BuildContext context) {
    final imageUrl = V2Kit.foodImageUrl(item.imageKeyword);

    final (badgeBg, badgeFg, badgeIcon) = item.isPositive
        ? (const Color(0xFFDCFCE7), const Color(0xFF15803D), LucideIcons.leaf)
        : (const Color(0xFFFEE2E2), const Color(0xFF991B1B), LucideIcons.alertTriangle);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.w),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.04), blurRadius: 8.w, offset: const Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Full Cover Image
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(color: const Color(0xFFF1F5F9)),
            errorWidget: (_, _, _) => Container(
              color: badgeBg,
              child: Icon(badgeIcon, color: badgeFg, size: 28),
            ),
          ),

          // 2. Gradient Overlay for Crisp Stacked Text Contrast
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withValues(alpha: 0.2), Colors.black.withValues(alpha: 0.35), Colors.black.withValues(alpha: 0.88)],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // 3. Top Floating Badges
          Positioned(
            top: 8.w,
            left: 8.w,
            right: 8.w,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Impact Badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.5.w),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(10.w),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4.w)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badgeIcon, size: 9.w, color: badgeFg),
                      Gap.w3,
                      Text(
                        item.impactLabel,
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w700, color: badgeFg),
                      ),
                    ],
                  ),
                ),

                // Frequency Count Badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.5.w),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.65), borderRadius: BorderRadius.circular(10.w)),
                  child: Text(
                    item.countText,
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // 4. Stacked Text Content at Bottom
          Positioned(
            left: 10.w,
            right: 10.w,
            bottom: 10.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.2),
                ),
                Gap.h3,
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.85), height: 1.25),
                ),
                Gap.h6,
                Row(
                  children: [
                    Icon(item.isPositive ? LucideIcons.salad : LucideIcons.info, size: 9.5.w, color: item.isPositive ? const Color(0xFF86EFAC) : const Color(0xFFFECACA)),
                    Gap.w3,
                    Text(
                      item.isPositive ? 'Gut Friendly' : 'Monitor Reaction',
                      style: TextStyle(
                        fontFamily: InsightV2Theme.fontFamily,
                        fontSize: 8.5.sp,
                        fontWeight: FontWeight.w700,
                        color: item.isPositive ? const Color(0xFF86EFAC) : const Color(0xFFFECACA),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.isSelected, required this.onTap, this.icon, this.iconColor});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.w),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16.w),
          border: Border.all(color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 10.w, color: isSelected ? Colors.white : (iconColor ?? const Color(0xFF0F172A))), Gap.w4],
            Text(
              label,
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : const Color(0xFF0F172A)),
            ),
          ],
        ),
      ),
    );
  }
}
