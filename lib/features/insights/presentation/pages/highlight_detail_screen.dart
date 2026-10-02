import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/utils/insight_values.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/insights/presentation/pages/better_swaps_screen.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/bento_data.dart';
import 'package:gutgood/features/insights/presentation/widgets/occurrence_tile.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_theme.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/v2_data.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/v2_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// Top Healing / Top Trigger detail screen.
class HighlightDetailScreen extends StatelessWidget {
  const HighlightDetailScreen({super.key, required this.args});

  final HighlightDetailArgs args;

  bool get _isTrigger => (args.chartType ?? '').toLowerCase() == 'trigger';

  @override
  Widget build(BuildContext context) {
    if (_isTrigger) {
      return _buildTriggerDetail(context);
    }
    return _buildHealingTrendDetail(context);
  }

  /// Healing / Improving Trend detail screen — matches exact mock layout from screenshot.
  Widget _buildHealingTrendDetail(BuildContext context) {
    final v2 = context.v2Theme;
    final insight = _insightOf(context);

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
      backgroundColor: v2.scaffold,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Same GutSliverAppBar as other screens
          GutSliverAppBar(title: appBarTitle, centerTitle: true, showBrandingIcon: false, backgroundColor: v2.scaffold),

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
                                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w700, color: context.insightColor(badgeTextColor)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Gap.h8,

                      Text(
                        headline,
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 15.sp, fontWeight: FontWeight.w800, color: v2.textPrimary),
                      ),
                      Gap.h3,
                      Text(
                        bodyText,
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w500, color: v2.textSecondary, height: 1.25),
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
                                  child: V2TrendChart(values: series, height: 52, color: context.insightColor(chartLineColor), endDot: true),
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
                                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 18.sp, fontWeight: FontWeight.w800, color: context.insightColor(badgeTextColor)),
                                    ),
                                  ],
                                ),
                                Gap.h2,
                                Text(
                                  'points this week',
                                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: context.insightColor(badgeTextColor), fontWeight: FontWeight.w600),
                                ),
                                Gap.h2,
                                Text(
                                  rangeText,
                                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Gap.h10,

                      Text(
                        progressTitle,
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w700, color: context.insightColor(const Color(0xFF0F172A))),
                      ),
                      Text(
                        progressDesc,
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: context.insightColor(const Color(0xFF475569))),
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
    final v2 = context.v2Theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final insight = _insightOf(context);
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
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: v2.textPrimary),
                  ),
                  Text(
                    foods.isEmpty
                        ? 'Supportive foods will appear here when your logs provide evidence.'
                        : 'Foods observed in your logs as supportive.',
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: v2.textSecondary),
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
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, color: v2.textSecondary, height: 1.35),
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
    final v2 = context.v2Theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final insight = _insightOf(context);
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
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: v2.textPrimary),
                  ),
                  Text(
                    'Your progress at a glance.',
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: v2.textSecondary),
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
    final v2 = context.v2Theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highlights = _insightOf(context)?.weeklyRecap?.highlights
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
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: v2.textPrimary),
                  ),
                  Text(
                    'Highlights from your recent logs.',
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: v2.textSecondary),
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
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, color: v2.textSecondary),
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
    final v2 = context.v2Theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final insight = _insightOf(context);
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
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: v2.textPrimary),
                  ),
                  Text(
                    'Keep the momentum going.',
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: v2.textSecondary),
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
    final v2 = context.v2Theme;
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
            style: TextStyle(fontFamily: InsightV2Theme.displayFont, fontSize: 28.sp, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D), height: 1.0),
          ),
          Gap.w6,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keep going!',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 13.sp, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)),
                ),
                Gap.h2,
                Text(
                  "You're building healthier habits, and your gut thanks you.",
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: v2.textSecondary, height: 1.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Trigger / Something to Watch Detail screen
  Widget _buildTriggerDetail(BuildContext context) {
    final v2 = context.v2Theme;
    final insight = _insightOf(context);
    final pattern = insight?.detectedPatterns.where((p) => p.type.toLowerCase().contains('trigger') || p.reaction.isNotEmpty).firstOrNull;

    final loggedFoodName = pattern?.involvedFoods.isNotEmpty == true
        ? pattern!.involvedFoods.first
        : (pattern?.trigger.isNotEmpty == true ? pattern!.trigger : '');
    final foodName = loggedFoodName.isEmpty ? 'Food not identified' : loggedFoodName;

    final occurrences = pattern?.occurrences ?? const <PatternOccurrence>[];
    final observationCount = pattern == null ? 0 : (pattern.frequency > 0 ? pattern.frequency : occurrences.length);
    final isSingleObservation = observationCount == 1;

    final reactionText = pattern?.reaction.trim().isNotEmpty == true ? pattern!.reaction : 'Symptom not specified';
    final rawDelay = observationCount < 2 ? 'Building your baseline' : V2Data.reactionTime(insight ?? AIInsight(gutScore: 0, updatedAt: DateTime.now()), pattern);
    final delayText = (rawDelay.toLowerCase() == 'n/a' || rawDelay.toLowerCase() == 'not enough data yet' || rawDelay == '—' || rawDelay.isEmpty) ? 'Building your baseline.' : rawDelay;
    final confidenceLabel = pattern == null || observationCount == 0
        ? 'Not established'
        : isSingleObservation
        ? 'Building'
        : pattern.evidenceRatio > 0
        ? '${(pattern.evidenceRatio * 100).round()}%'
        : 'Not established';

    final title = pattern == null
        ? 'Food and symptom details'
        : isSingleObservation && loggedFoodName.isNotEmpty && reactionText != 'Symptom not specified'
        ? '$loggedFoodName → ${reactionText.toLowerCase()}'
        : (args.title.isNotEmpty ? args.title : 'Observed food and symptom pattern');
    final bodyText = pattern == null || observationCount == 0
        ? 'There is not enough logged evidence to describe a food and symptom pattern yet.'
        : isSingleObservation
        ? 'You reported ${reactionText.toLowerCase()} after logging $loggedFoodName once. One occurrence is not enough to identify a cause.'
        : ((args.body ?? '').isNotEmpty ? args.body! : 'This association appeared in $observationCount observations. That does not establish that the food caused the symptom.');

    return Scaffold(
      backgroundColor: v2.scaffold,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          GutSliverAppBar(title: 'FOOD & SYMPTOM DETAILS', centerTitle: true, showBrandingIcon: false, backgroundColor: v2.scaffold),

          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 4.w, 16.w, 24.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. HERO TRIGGER CARD
                _buildTriggerHeroCard(
                  context,
                  foodName: foodName,
                  title: title,
                  bodyText: bodyText,
                  pattern: pattern,
                  hasFoodName: loggedFoodName.isNotEmpty,
                  isSingleObservation: isSingleObservation,
                  observationCount: observationCount,
                  reactionText: reactionText,
                  delayText: delayText,
                  confidenceLabel: confidenceLabel,
                ),
                Gap.h10,

                // 2. LATEST OBSERVATION SECTION
                _buildLatestObservationSection(context, occurrences: occurrences),
                Gap.h10,

                // 3. WHAT TO DO NEXT CARD
                _buildWhatToDoNextCard(context),
                Gap.h10,

                // 4. WANT A DIFFERENT OPTION? (Better Swaps)
                if (loggedFoodName.isNotEmpty) _buildBetterSwapsOptionCard(context, foodName: loggedFoodName),
                Gap.h12,
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// 1. Hero Trigger Card ("Something to Watch") in Pattern Card Style
  Widget _buildTriggerHeroCard(
    BuildContext context, {
    required String foodName,
    required String title,
    required String bodyText,
    required BodyPattern? pattern,
    required bool hasFoodName,
    required bool isSingleObservation,
    required int observationCount,
    required String reactionText,
    required String delayText,
    required String confidenceLabel,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final firstOccWithImage = pattern?.occurrences.firstWhere(
      (o) => o.imageUrl != null && o.imageUrl!.isNotEmpty,
      orElse: () => const PatternOccurrence(date: '', mealName: '', reaction: '', timeAfter: ''),
    );

    final foodImageUrl = hasFoodName ? V2Kit.foodImageUrl(foodName, imageUrl: firstOccWithImage?.imageUrl) : null;

    final cardBg = isDark ? const Color(0xFF231416) : const Color(0xFFFFF8F6);
    final cardBorder = isDark ? const Color(0xFFEF4444).withValues(alpha: 0.45) : const Color(0xFFFCA5A5);
    final pillBg = isDark ? const Color(0xFFEF4444).withValues(alpha: 0.18) : const Color(0xFFFEE2E2);
    final pillFg = isDark ? const Color(0xFFF87171) : const Color(0xFF991B1B);

    final frequencyText = observationCount > 0 ? '$observationCount observation${observationCount == 1 ? '' : 's'}' : 'Not available';

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: cardBorder, width: 1.w),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626)).withValues(alpha: isDark ? 0.08 : 0.04),
            blurRadius: 10.w,
            offset: Offset(0, 2.w),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Content Section with Side Image
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.w, 16.w, 14.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tag Pill
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.5.w),
                        decoration: BoxDecoration(
                          color: pillBg,
                          borderRadius: BorderRadius.circular(16.w),
                          border: Border.all(color: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.35) : const Color(0xFFFECACA), width: 0.8.w),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.triangleAlert, size: 10.w, color: pillFg),
                            Gap.w4,
                            Text(
                              pattern == null ? 'NO MATCHING PATTERN' : isSingleObservation ? 'POSSIBLE CONNECTION' : 'OBSERVED IN LOGS',
                              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: pillFg),
                            ),
                          ],
                        ),
                      ),
                      Gap.h8,

                      // Title
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: InsightV2Theme.fontFamily,
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w800,
                          color: context.insightColor(const Color(0xFF0F172A)),
                          height: 1.15,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Gap.h4,

                      // Subtitle / Body Description
                      Text(
                        bodyText,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w400, color: context.insightColor(const Color(0xFF475569)), height: 1.3),
                      ),
                      Gap.h14,

                      // Bottom message / Pill
                      if (isSingleObservation)
                        Text(
                          '“Keep logging to see if this happens again.”',
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: pillFg, fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                ),
                Gap.w12,

                // Right Side Food Image Preview
                Container(
                  width: 90.w,
                  height: 90.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18.w),
                    border: Border.all(color: cardBorder, width: 1.w),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8.w, offset: Offset(0, 2.w))],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: foodImageUrl == null ? Icon(LucideIcons.utensils, size: 28.w, color: pillFg) : CachedNetworkImage(
                    imageUrl: foodImageUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    placeholder: (_, _) => Container(color: context.insightColor(const Color(0xFFF1F5F9))),
                    errorWidget: (_, _, _) => Container(
                      color: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.20) : const Color(0xFFFEE2E2),
                      child: Icon(LucideIcons.utensils, size: 28.w, color: pillFg),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Stats Bar (4 columns)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _TriggerStatCol(
                    icon: LucideIcons.barChart2,
                    iconBg: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.18) : const Color(0xFFFEE2E2),
                    iconColor: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                    label: 'Observations',
                    value: frequencyText,
                    subtext: pattern == null ? 'No matching pattern' : (pattern.timeframeDays > 0 ? 'Last ${pattern.timeframeDays} days' : 'Period unavailable'),
                  ),
                ),
                Gap.w4,

                Expanded(
                  child: _TriggerStatCol(
                    icon: LucideIcons.activity,
                    iconBg: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.18) : const Color(0xFFFEE2E2),
                    iconColor: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                    label: 'Reaction',
                    value: reactionText,
                    subtext: pattern == null ? 'No matching pattern' : 'Observed symptom',
                  ),
                ),
                Gap.w4,

                Expanded(
                  child: _TriggerStatCol(
                    icon: LucideIcons.clock,
                    iconBg: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.18) : const Color(0xFFFEE2E2),
                    iconColor: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                    label: 'Typical Delay',
                    value: delayText,
                    subtext: observationCount < 2 ? 'More logs needed' : 'Across observations',
                  ),
                ),
                Gap.w4,

                Expanded(
                  child: _TriggerStatCol(
                    icon: LucideIcons.leaf,
                    iconBg: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.18) : const Color(0xFFFEE2E2),
                    iconColor: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                    label: 'Confidence',
                    value: confidenceLabel,
                    subtext: observationCount < 2 ? 'More logs needed' : 'Evidence score',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Latest Observation Section
  Widget _buildLatestObservationSection(BuildContext context, {required List<PatternOccurrence> occurrences}) {
    if (occurrences.isEmpty) {
      return const SizedBox.shrink();
    }
    final v2 = context.v2Theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final latest = occurrences.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 28.w,
                  height: 28.w,
                  decoration: BoxDecoration(color: isDark ? v2.cardSubtle : const Color(0xFFF1F5F9), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Icon(LucideIcons.fileText, size: 14.w, color: v2.textPrimary),
                ),
                Gap.w8,
                Text(
                  'Latest Observation',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: v2.textPrimary),
                ),
              ],
            ),
          ],
        ),
        Gap.h10,
        if (occurrences.length > 1)
          for (final o in occurrences.take(3)) ...[OccurrenceTile(occurrence: o), Gap.h8]
        else
          OccurrenceTile(occurrence: latest),
      ],
    );
  }

  /// 3. What to do next Card
  Widget _buildWhatToDoNextCard(BuildContext context) {
    final v2 = context.v2Theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF102319) : const Color(0xFFF4FAF5),
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.3) : const Color(0xFFDCFCE7), width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.2) : const Color(0xFFDCFCE7), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(LucideIcons.lightbulb, size: 14.w, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)),
              ),
              Gap.w8,
              Text(
                'What to do next',
                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: v2.textPrimary),
              ),
            ],
          ),
          Gap.h8,
          Text(
            'Keep logging this food and how you feel afterward. A few more observations can help GutGood determine if there\'s a consistent pattern.',
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, color: v2.textSecondary, height: 1.3),
          ),
          Gap.h12,
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    context.push(AppRoutes.scannerPath('meal'));
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.w),
                    decoration: BoxDecoration(color: isDark ? Colors.white : const Color(0xFF0F172A), borderRadius: BorderRadius.circular(100.r)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.utensils, size: 14.w, color: isDark ? const Color(0xFF0F172A) : Colors.white),
                        Gap.w8,
                        Text(
                          'Log a Meal',
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFF0F172A) : Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Gap.w8,
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    context.push(AppRoutes.scannerPath('symptom'));
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.w),
                    decoration: BoxDecoration(
                      color: isDark ? v2.card : Colors.white,
                      borderRadius: BorderRadius.circular(100.r),
                      border: Border.all(color: v2.border, width: 1.w),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.smile, size: 14.w, color: v2.textPrimary),
                        Gap.w8,
                        Text(
                          'Log a Symptom',
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w700, color: v2.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 4. Better Swaps Option Card ("Want a different option?")
  Widget _buildBetterSwapsOptionCard(BuildContext context, {required String foodName}) {
    final v2 = context.v2Theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final insight = _insightOf(context);
    FoodSwap? matchingSwap;
    final targetName = foodName.toLowerCase().trim();
    for (final s in insight?.foodSwaps ?? <FoodSwap>[]) {
      if (s.source.name.toLowerCase().trim() == targetName) {
        matchingSwap = s;
        break;
      }
    }
    final swapObj =
        matchingSwap ??
        (insight?.foodSwaps.isNotEmpty == true
            ? insight!.foodSwaps.first
            : FoodSwap(
                id: 'swap_${foodName.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '_')}',
                source: SwapSource(foodId: 'food_trigger', name: foodName),
                alternatives: const [],
              ));

    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => BetterSwapsScreen(swap: swapObj)));
      },
      borderRadius: BorderRadius.circular(18.w),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1B4B) : const Color(0xFFF5F3FF),
          borderRadius: BorderRadius.circular(18.w),
          border: Border.all(color: isDark ? const Color(0xFF6366F1).withValues(alpha: 0.3) : const Color(0xFFE0E7FF), width: 1.w),
        ),
        child: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(color: isDark ? const Color(0xFF6366F1).withValues(alpha: 0.2) : const Color(0xFFE0E7FF), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(LucideIcons.repeat, size: 16.w, color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5)),
            ),
            Gap.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Want a different option?',
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 13.sp, fontWeight: FontWeight.w800, color: v2.textPrimary),
                  ),
                  Gap.h2,
                  Text(
                    'Explore better swaps for this food and find options that may work better for you.',
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: v2.textSecondary),
                  ),
                ],
              ),
            ),
            Gap.w8,
            Icon(LucideIcons.chevronRight, size: 16.w, color: v2.textSecondary),
          ],
        ),
      ),
    );
  }

  static AIInsight? _insightOf(BuildContext context) {
    try {
      return context.read<InsightsNotifier>().latestInsight;
    } on ProviderNotFoundException {
      return null;
    }
  }
}

// =============================================================================
// SUB-COMPONENTS & PAINTERS
// =============================================================================

class _ContributingCard extends StatelessWidget {
  const _ContributingCard({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.imageKeyword,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String badgeText;
  final Color badgeColor;
  final Color badgeTextColor;
  final String imageKeyword;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final v2 = context.v2Theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageUrl = V2Kit.foodImageUrl(imageKeyword);

    return Container(
      width: 108.w,
      padding: EdgeInsets.all(7.w),
      decoration: BoxDecoration(
        color: v2.card,
        borderRadius: BorderRadius.circular(14.w),
        border: Border.all(color: v2.border, width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.w),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: 94.w,
              height: 60.w,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(color: v2.cardSubtle),
              errorWidget: (_, _, _) => Container(
                color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.2) : const Color(0xFFDCFCE7),
                alignment: Alignment.center,
                child: Icon(icon, size: 20.w, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)),
              ),
            ),
          ),
          Gap.h5,
          Text(
            title,
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w700, color: v2.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.sp, color: v2.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Gap.h3,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.w),
            decoration: BoxDecoration(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.2) : badgeColor, borderRadius: BorderRadius.circular(10.w)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 8.5.w, color: isDark ? const Color(0xFF4ADE80) : badgeTextColor),
                Gap.w2,
                Text(
                  badgeText,
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFF4ADE80) : badgeTextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyStatTile extends StatelessWidget {
  const _WeeklyStatTile({required this.icon, required this.iconBg, required this.iconColor, required this.label, required this.value, required this.subtext});

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final String subtext;

  @override
  Widget build(BuildContext context) {
    final v2 = context.v2Theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFoodsLogged = label.toLowerCase().contains('foods logged');

    final tileBg = isDark ? (isFoodsLogged ? const Color(0xFF231A14) : const Color(0xFF102319)) : v2.card;
    final tileBorder = isDark ? (isFoodsLogged ? const Color(0xFFF97316).withValues(alpha: 0.28) : const Color(0xFF22C55E).withValues(alpha: 0.28)) : v2.border;
    final resolvedIconBg = isDark ? (isFoodsLogged ? const Color(0xFFF97316).withValues(alpha: 0.18) : const Color(0xFF22C55E).withValues(alpha: 0.18)) : iconBg;
    final resolvedIconColor = isDark ? (isFoodsLogged ? const Color(0xFFFB923C) : const Color(0xFF4ADE80)) : iconColor;
    final resolvedLabelColor = isDark ? (isFoodsLogged ? const Color(0xFFFB923C) : const Color(0xFF4ADE80)) : v2.textSecondary;

    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(14.w),
        border: Border.all(color: tileBorder, width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24.w,
            height: 24.w,
            decoration: BoxDecoration(color: resolvedIconBg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(icon, size: 12.w, color: resolvedIconColor),
          ),
          Gap.h6,
          Text(
            label,
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: resolvedLabelColor, fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 16.sp, fontWeight: FontWeight.w800, color: v2.textPrimary),
          ),
          Text(
            subtext,
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.5.sp, color: v2.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _HighlightBox extends StatelessWidget {
  const _HighlightBox({required this.icon, required this.iconBg, required this.iconColor, required this.title, required this.subtitle});

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final v2 = context.v2Theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: v2.card,
        borderRadius: BorderRadius.circular(14.w),
        border: Border.all(color: v2.border, width: 1.w),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22.w,
            height: 22.w,
            decoration: BoxDecoration(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.2) : iconBg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(icon, size: 11.w, color: isDark ? const Color(0xFF4ADE80) : iconColor),
          ),
          Gap.w6,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: v2.textPrimary, height: 1.2),
                ),
                Gap.h2,
                Text(
                  subtitle,
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: v2.textSecondary, height: 1.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NextStepCard extends StatelessWidget {
  const _NextStepCard({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final v2 = context.v2Theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF102319) : const Color(0xFFF4FAF5),
        borderRadius: BorderRadius.circular(14.w),
        border: Border.all(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.3) : const Color(0xFFDCFCE7), width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 22.w,
                height: 22.w,
                decoration: BoxDecoration(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.2) : const Color(0xFFDCFCE7), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(icon, size: 11.w, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)),
              ),
            ],
          ),
          Gap.h6,
          Text(
            title,
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: v2.textPrimary, height: 1.2),
          ),
          if (body.isNotEmpty && body.trim() != title.trim()) ...[
            Gap.h2,
            Text(
              body,
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: v2.textSecondary, height: 1.2),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _TriggerStatCol extends StatelessWidget {
  const _TriggerStatCol({required this.icon, required this.iconBg, required this.iconColor, required this.label, required this.value, required this.subtext});

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final String subtext;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22.w,
          height: 22.w,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Icon(icon, size: 11.w, color: iconColor),
        ),
        Gap.h4,
        Text(
          label,
          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.sp, color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626), fontWeight: FontWeight.w600),
        ),
        Gap.h2,
        Text(
          value,
          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A)), height: 1.15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Gap.h2,
        Text(
          subtext,
          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.5.sp, color: context.insightColor(const Color(0xFF64748B))),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class AlignedDayLabelsRow extends StatelessWidget {
  const AlignedDayLabelsRow({super.key, required this.labels, required this.todayIndex, this.chartPadding = 6.0});

  final List<String> labels;
  final int todayIndex;
  final double chartPadding;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final totalW = constraints.maxWidth;
      if (totalW <= 0) return const SizedBox.shrink();

      final chartW = totalW - (chartPadding * 2);
      const count = 7;
      const labelBoxW = 20.0;

      return SizedBox(
        height: 16,
        width: totalW,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < labels.length && i < count; i++)
              Positioned(
                left: (chartPadding + (chartW * i / (count - 1))) - (labelBoxW / 2),
                top: 0,
                width: labelBoxW,
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: InsightV2Theme.fontFamily,
                    fontSize: 9.5.sp,
                    fontWeight: i == todayIndex ? FontWeight.w900 : FontWeight.w700,
                    color: i == todayIndex ? context.insightColor(const Color(0xFF0F172A)) : context.insightColor(const Color(0xFF64748B)),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
