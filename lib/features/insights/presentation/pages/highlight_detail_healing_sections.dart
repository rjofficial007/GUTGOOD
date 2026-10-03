part of 'highlight_detail_screen.dart';

/// Healing and progress sections for the highlight detail page.

extension HighlightHealingSections on HighlightDetailScreen {
  Widget _buildHealingTrendDetail(BuildContext context) {
    final theme = context.insightTheme;
    final insight = _highlightInsightOf(context);

    // Dynamic Series Resolution
    var series = args.chartValues;
    if (series.isEmpty && insight?.weeklyRecap?.gutScoreTrend != null && insight!.weeklyRecap!.gutScoreTrend!.isNotEmpty) {
      series = [for (final s in insight.weeklyRecap!.gutScoreTrend!) s.toDouble()];
    }
    if (series.isEmpty && insight?.gutScore != null) {
      series = [insight!.gutScore.toDouble()];
    }

    final cleanSeries = InsightValues.scores(series);
    final scoredSeries = cleanSeries.where((s) => s > 0).toList();

    final startVal = scoredSeries.isNotEmpty ? scoredSeries.first.round() : (insight?.gutScore != null && insight!.gutScore > 0 ? insight.gutScore : 0);

    final endVal = scoredSeries.isNotEmpty ? scoredSeries.last.round() : (insight?.gutScore != null && insight!.gutScore > 0 ? insight.gutScore : 0);

    int diff;
    if (scoredSeries.length > 1) {
      diff = endVal - startVal;
    } else if (insight?.scoreDiff != null) {
      diff = BentoData.parseDelta(insight!.scoreDiff) ?? 0;
    } else {
      diff = 0;
    }

    final hasEnoughData = scoredSeries.length > 1 && diff != 0;
    final appBarTitle = hasEnoughData ? 'YOUR PROGRESS' : 'BUILDING BASELINE';
    final tagLabel = hasEnoughData ? 'Your Progress' : 'Building Baseline';

    final headline = hasEnoughData ? (args.title.isNotEmpty ? args.title : 'Your gut score is steady.') : 'Building baseline';
    final bodyText = hasEnoughData ? ((args.body ?? '').isNotEmpty ? args.body! : 'Keep logging meals to track your gut health progress.') : 'We’re learning what works for you.';

    final isUp = diff >= 0;
    final absDiff = diff.abs();

    final badgeBgColor = isUp ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
    final badgeIconBgColor = isUp ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final badgeTextColor = isUp ? const Color(0xFF15803D) : const Color(0xFF991B1B);
    final chartLineColor = isUp ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    final rangeText = scoredSeries.length > 1 ? '$startVal → $endVal' : (endVal > 0 ? '$endVal/100' : '—');

    final progressTitle = diff == 0 ? (endVal > 0 ? 'Steady baseline' : 'Building baseline') : (isUp ? 'Positive progress' : 'Area to watch');

    final pct = (startVal > 0 && absDiff > 0) ? ((absDiff / startVal) * 100).round() : 0;
    final progressDesc = diff == 0
        ? (endVal > 0 ? 'Your gut score is steady at $endVal points.' : 'Log meals and scans to track your score trend.')
        : 'Your score has ${isUp ? 'increased' : 'decreased'} by $absDiff point${absDiff == 1 ? '' : 's'}${pct > 0 ? ' ($pct%)' : ''} this week.';

    const dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Scaffold(
      backgroundColor: theme.scaffold,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Same GutSliverAppBar as other screens
          GutSliverAppBar(title: appBarTitle, centerTitle: true, showBrandingIcon: false, backgroundColor: theme.scaffold),

          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 4.w, 16.w, 24.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Gap.h10,

                // 1. HERO SCORE CARD (Gut Barrier Score)
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: context.insightColor(isUp ? const Color(0xFFF4FAF5) : const Color(0xFFFFF5F5)),
                    borderRadius: BorderRadius.circular(20.w),
                    border: Border.all(color: context.insightColor(badgeBgColor), width: 1.w),
                    boxShadow: [BoxShadow(color: const Color(0xFF17171B).withValues(alpha: 0.03), blurRadius: 6.w, offset: Offset(0, 2.w))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Badge + Timeframe
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.5.w),
                            decoration: BoxDecoration(color: context.insightColor(badgeBgColor), borderRadius: BorderRadius.circular(16.w)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.leaf, size: 10.w, color: context.insightColor(badgeTextColor)),
                                Gap.w4,
                                Text(
                                  (args.tag == 'Healing Trend' || args.tag == 'Improving Trend' || args.tag.isEmpty) ? tagLabel : args.tag,
                                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w700, color: context.insightColor(badgeTextColor)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Gap.h8,

                      Text(
                        headline,
                        style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 15.sp, fontWeight: FontWeight.w800, color: theme.textPrimary),
                      ),
                      Gap.h3,
                      Text(
                        bodyText,
                        style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w500, color: theme.textSecondary, height: 1.25),
                      ),
                      Gap.h12,

                      // Chart, Weekday Labels & Badge Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Left Column: 7-Point Trend Chart + Pixel-Aligned Weekday Labels
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 52.w,
                                  width: double.infinity,
                                  child: InsightTrendChart(values: series, height: 52, color: context.insightColor(chartLineColor), endDot: true),
                                ),
                                Gap.h6,
                                AlignedDayLabelsRow(labels: dayLabels, todayIndex: DateTime.now().weekday % 7),
                              ],
                            ),
                          ),
                          Gap.w12,

                          // Right Column: Point Change Badge
                          Container(
                            padding: EdgeInsets.all(10.w),
                            decoration: BoxDecoration(color: context.insightColor(badgeBgColor), borderRadius: BorderRadius.circular(16.w)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(3.w),
                                      decoration: BoxDecoration(color: context.insightColor(badgeIconBgColor), shape: BoxShape.circle),
                                      child: Icon(isUp ? LucideIcons.arrowUp : LucideIcons.arrowDown, size: 10, color: Colors.white),
                                    ),
                                    Gap.w4,
                                    Text(
                                      '${isUp ? '+' : '-'}$absDiff',
                                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 18.sp, fontWeight: FontWeight.w800, color: context.insightColor(badgeTextColor)),
                                    ),
                                  ],
                                ),
                                Gap.h2,
                                Text(
                                  'points this week',
                                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, color: context.insightColor(badgeTextColor), fontWeight: FontWeight.w600),
                                ),
                                Gap.h2,
                                Text(
                                  rangeText,
                                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Gap.h10,

                      Text(
                        progressTitle,
                        style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w700, color: context.insightColor(const Color(0xFF0F172A))),
                      ),
                      Text(
                        progressDesc,
                        style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, color: context.insightColor(const Color(0xFF475569))),
                      ),
                    ],
                  ),
                ),
                Gap.h10,

                // 2. WHAT'S CONTRIBUTING? SECTION
                _buildWhatsContributingSection(context),
                Gap.h10,

                // 3. WEEKLY STATS SECTION
                _buildWeeklyStatsSection(context),
                Gap.h10,

                // 4. PROGRESS HIGHLIGHTS SECTION
                _buildProgressHighlightsSection(context),
                Gap.h10,

                // 5. RECOMMENDED NEXT STEPS SECTION
                _buildNextStepsSection(context),
                Gap.h10,

                // 6. BOTTOM ENCOURAGEMENT BANNER ("Keep going!")
                _buildKeepGoingBanner(context),
                Gap.h12,
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// 2. What's Contributing? Section
  Widget _buildWhatsContributingSection(BuildContext context) {
    final theme = context.insightTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final insight = _highlightInsightOf(context);
    final foods = insight?.healingSummary?.foods.isNotEmpty == true
        ? insight!.healingSummary!.foods
        : (insight?.healingFoods.isNotEmpty == true
              ? insight!.healingFoods
                    .map((f) => InsightFood(foodId: 'f_${f.name}', name: f.name, emoji: f.emoji, imageUrl: f.userImageUrl ?? f.imageUrl, effect: f.effect))
                    .toList()
              : const <InsightFood>[]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.2) : const Color(0xFFDCFCE7), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(LucideIcons.sparkles, size: 14.w, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)),
            ),
            Gap.w8,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "What's Contributing?",
                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: theme.textPrimary),
                  ),
                  Text(
                    foods.isEmpty
                        ? 'Supportive foods will appear here when your logs provide evidence.'
                        : 'Foods observed in your logs as supportive.',
                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, color: theme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        Gap.h8,

        if (foods.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.w),
            child: Text(
              'No supportive foods identified from your logs yet. Keep recording meals and how you feel.',
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, color: theme.textSecondary, height: 1.35),
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (final f in foods) ...[
                  _ContributingCard(
                    title: f.name,
                    subtitle: f.effect?.trim().isNotEmpty == true ? f.effect! : 'No effect details recorded.',
                    badgeText: 'Supportive observation',
                    badgeColor: context.insightColor(const Color(0xFFDCFCE7)),
                    badgeTextColor: const Color(0xFF15803D),
                    imageKeyword: f.name,
                    icon: LucideIcons.leaf,
                  ),
                  Gap.w8,
                ],
              ],
            ),
          ),
      ],
    );
  }

  /// 3. Weekly Stats Section
  Widget _buildWeeklyStatsSection(BuildContext context) {
    final theme = context.insightTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final insight = _highlightInsightOf(context);
    final recap = insight?.weeklyRecap;
    final trend = recap?.gutScoreTrend ?? const <int>[];
    final scoredDays = trend.where((s) => s > 0).toList();
    final trendAvg = scoredDays.isEmpty ? null : (scoredDays.reduce((a, b) => a + b) / scoredDays.length).round();
    final avgScore = recap?.avgScore ?? trendAvg ?? (insight?.hasGutScore == true ? insight!.gutScore : null);
    final bestDay = (recap?.bestDay != null && recap!.bestDay!.isNotEmpty) ? recap.bestDay! : '—';
    final foodsLogged = recap?.foodsLogged ?? ((insight?.evidence?.sampleSizes.meals ?? 0) + (insight?.evidence?.sampleSizes.scans ?? 0));
    final avgLabel = avgScore == null ? '—' : '$avgScore';
    final foodsLabel = foodsLogged == 0 && recap?.foodsLogged == null ? '—' : '$foodsLogged';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.2) : const Color(0xFFDCFCE7), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(LucideIcons.barChart2, size: 14.w, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)),
            ),
            Gap.w8,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Stats',
                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: theme.textPrimary),
                  ),
                  Text(
                    'Your progress at a glance.',
                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, color: theme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        Gap.h8,

        Row(
          children: [
            Expanded(
              child: _WeeklyStatTile(
                icon: LucideIcons.trophy,
                iconBg: context.insightColor(const Color(0xFFDCFCE7)),
                iconColor: const Color(0xFF15803D),
                label: 'Average Score',
                value: avgLabel,
                subtext: recap?.scoreSub ?? 'Gut health score',
              ),
            ),
            Gap.w6,
            Expanded(
              child: _WeeklyStatTile(
                icon: LucideIcons.calendarCheck,
                iconBg: context.insightColor(const Color(0xFFDCFCE7)),
                iconColor: const Color(0xFF15803D),
                label: 'Recorded window',
                value: bestDay,
                subtext: bestDay == '—' ? 'No scored day yet' : 'Highest score',
              ),
            ),
            Gap.w6,
            Expanded(
              child: _WeeklyStatTile(
                icon: LucideIcons.utensils,
                iconBg: context.insightColor(const Color(0xFFFEF3C7)),
                iconColor: const Color(0xFFB45309),
                label: 'Foods Logged',
                value: foodsLabel,
                subtext: recap?.loggedSub ?? 'meals and scans',
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 4. Progress Highlights Section
  Widget _buildProgressHighlightsSection(BuildContext context) {
    final theme = context.insightTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highlights = _highlightInsightOf(context)?.weeklyRecap?.highlights
            .map((item) => item is RecapHighlight ? item.text : item is String ? item : '')
            .where((text) => text.trim().isNotEmpty)
            .take(2)
            .toList() ??
        const <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(color: isDark ? const Color(0xFFD97706).withValues(alpha: 0.2) : const Color(0xFFFEF3C7), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(LucideIcons.star, size: 14.w, color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309)),
            ),
            Gap.w8,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progress Highlights',
                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: theme.textPrimary),
                  ),
                  Text(
                    'Highlights from your recent logs.',
                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, color: theme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        Gap.h8,

        if (highlights.isEmpty)
          Text(
            'No progress highlights are available for this period yet.',
            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, color: theme.textSecondary),
          )
        else
          Row(
            children: [
              for (var i = 0; i < highlights.length; i++) ...[
                if (i > 0) Gap.w8,
                Expanded(
                  child: _HighlightBox(
                    icon: i == 0 ? LucideIcons.leaf : LucideIcons.arrowDown,
                    iconBg: const Color(0xFFDCFCE7),
                    iconColor: const Color(0xFF15803D),
                    title: highlights[i],
                    subtitle: 'From your logs',
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }

  /// 5. Recommended Next Steps Section
  Widget _buildNextStepsSection(BuildContext context) {
    final theme = context.insightTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final insight = _highlightInsightOf(context);
    final actions = insight?.actionsList ?? const [];

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.2) : const Color(0xFFDCFCE7), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(LucideIcons.leaf, size: 14.w, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)),
            ),
            Gap.w8,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recommended Next Steps',
                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: theme.textPrimary),
                  ),
                  Text(
                    'Keep the momentum going.',
                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, color: theme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        Gap.h8,

        Row(
          children: [
            for (var i = 0; i < actions.take(2).length; i++) ...[
              if (i > 0) Gap.w8,
              Expanded(
                child: _NextStepCard(icon: i == 0 ? LucideIcons.leaf : LucideIcons.sprout, title: actions[i].title, body: actions[i].description),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// 6. Bottom Encouragement Quote Card ("Keep going!")
  Widget _buildKeepGoingBanner(BuildContext context) {
    final theme = context.insightTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF102319) : const Color(0xFFF4FAF5),
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.3) : const Color(0xFFDCFCE7), width: 1.w),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '“',
            style: TextStyle(fontFamily: InsightTheme.displayFont, fontSize: 28.sp, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D), height: 1.0),
          ),
          Gap.w6,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keep going!',
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 13.sp, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)),
                ),
                Gap.h2,
                Text(
                  "You're building healthier habits, and your gut thanks you.",
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, color: theme.textSecondary, height: 1.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Trigger / Something to Watch Detail screen
}
