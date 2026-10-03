part of 'insight_bento_screens.dart';

/// Insight history presentation components.

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
