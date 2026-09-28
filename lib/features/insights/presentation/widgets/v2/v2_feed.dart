import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_assets.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/utils/insight_values.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_score_card.dart';
import 'package:gutgood/features/insights/presentation/pages/better_swaps_screen.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_score_card.dart';
import 'package:gutgood/features/insights/presentation/widgets/pattern_grid.dart';
import 'package:gutgood/features/insights/presentation/widgets/top_food_tile.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_theme.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/v2_data.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/v2_kit.dart';
import 'package:gutgood/features/insights/presentation/widgets/why_score_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class V2InsightsFeed extends StatefulWidget {
  const V2InsightsFeed({super.key, required this.data, required this.patterns, this.series = const [], this.history = const []});

  final AIInsight data;
  final List<BodyPattern> patterns;
  final List<double> series;
  final List<AIInsight> history;

  @override
  State<V2InsightsFeed> createState() => _V2InsightsFeedState();
}

class _V2InsightsFeedState extends State<V2InsightsFeed> {
  String _selectedFilter = 'For You';

  @override
  Widget build(BuildContext context) {
    final previous = V2Data.previousScore(widget.series);
    final delta = !widget.data.hasGutScore
        ? null
        : previous != null
        ? widget.data.gutScore - previous
        : V2Data.parseDelta(widget.data.scoreDiff);
    final improving = V2Data.improving(widget.data, widget.series, widget.history);
    final watch = V2Data.watch(widget.data, widget.patterns);

    final isPatternsTab = _selectedFilter == 'Patterns';
    final isFoodImpactTab = _selectedFilter == 'Food Impact';

    return SliverMainAxisGroup(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyTabBarDelegate(
            child: Container(
              color: context.appColorScheme.cardBackground,
              padding: EdgeInsets.only(top: 0.w, bottom: 8.w, left: 16.w, right: 16.w),
              alignment: Alignment.centerLeft,
              child: _InsightsHeaderWidget(selectedFilter: _selectedFilter, onFilterSelected: (filter) => setState(() => _selectedFilter = filter)),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 28.w),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // -------------------------------------------------------------------
              // TAB: PATTERNS
              // -------------------------------------------------------------------
              if (isPatternsTab) ...[
                Gap.h10,
                // Detected Pattern Cards
                if (widget.patterns.isNotEmpty) ...[
                  for (final pattern in widget.patterns) ...[PatternCard(pattern: pattern), Gap.h10],
                ] else ...[
                  const _EmptyPatternsCard(),
                  Gap.h10,
                ],

                // Side-by-Side Pattern Grid: Positive Pattern & Food Timing
                Gap.h10,

                // Bottom Banner: Patterns get smarter over time
                const _PatternsSmarterBannerCard(),
              ] else if (isFoodImpactTab) ...[
                // -------------------------------------------------------------------
                // TAB: FOOD IMPACT
                // -------------------------------------------------------------------
                Gap.h10,
                // 1. Food Impact Balance Hero Card
                _FoodImpactBalanceHeroCard(balance: widget.data.foodImpactBalance, foodImpacts: widget.data.foodImpacts),
                Gap.h10,

                // 2. Side-by-Side: Top Healing Foods & Top Trigger Food
                _SideBySideHealingAndTriggerCards(insight: widget.data),
                Gap.h10,

                // 4. Recent Food Impacts List
                _RecentFoodImpactsSection(impacts: widget.data.foodImpacts),
                Gap.h10,

                // 5. Your Next Steps Action Cards
                _YourNextStepsSection(actions: widget.data.actionsList),
              ] else if (_selectedFilter == 'Weekly Recap') ...[
                // -------------------------------------------------------------------
                // TAB: WEEKLY RECAP
                // -------------------------------------------------------------------
                V2WeeklyRecapView(data: widget.data, series: widget.data.hasGutScore ? widget.series : const [], patterns: widget.patterns, history: widget.history),
              ] else ...[
                // -------------------------------------------------------------------
                // TAB: FOR YOU
                // -------------------------------------------------------------------
                // HERO CARD: Gut Score & On Track

                if (widget.data.hasGutScore || (widget.data.weeklyRecap?.gutScoreTrend?.any((s) => s > 0) ?? false) || (widget.data.weeklyRecap?.avgScore ?? 0) > 0) ...[
                  _ForYouGutScoreCard(data: widget.data, series: widget.series, delta: delta),
                ] else ...[
                  InsightScoreCard(score: null, delta: null, onTap: null, onWhyTap: () => WhyScoreSheet.show(context, widget.data)),
                ],
                Gap.h10,

                if (_selectedFilter == 'For You') ...[
                  // TOP INSIGHT CARD (Replaces duplicate PatternCard on For You tab)
                  if (widget.data.topInsight != null)
                    _V2TopInsightCard(
                      insight: widget.data,
                      topInsight: widget.data.topInsight!,
                      onTap: () => context.push(AppRoutes.smartInsightDetail, extra: widget.data),
                    )
                  else if (widget.patterns.isNotEmpty)
                    PatternCard(pattern: widget.patterns.first),
                  Gap.h10,

                  // SIDE-BY-SIDE CARDS: What's Improving & Something to Watch
                  _SideBySideImprovingAndWatch(
                    improvingData: improving,
                    series: widget.data.hasGutScore ? widget.series : const [],
                    watchData: watch,
                    onImprovingTap: () => context.push(
                      AppRoutes.highlightDetail,
                      extra: HighlightDetailArgs(
                        tag: 'Healing Trend',
                        emoji: '🌱',
                        title: improving.headline,
                        body: improving.description,
                        accentColor: 0xFF1F7A3D,
                        backgroundColor: 0xFFE7F6E7,
                        chartType: 'healing',
                        chartValues: widget.series,
                        footLeft: 'this window',
                        frequency: improving.deltaPts == 0 ? null : '${improving.deltaPts > 0 ? '+' : ''}${improving.deltaPts} pts',
                      ),
                    ),
                    onWatchTap: (watch == null || watch.pattern == null || watch.title.isEmpty || watch.title == 'No Triggers Detected')
                        ? null
                        : () => context.push(
                            AppRoutes.highlightDetail,
                            extra: HighlightDetailArgs(
                              tag: 'Something to Watch',
                              emoji: '⚠️',
                              title: watch.title,
                              body: watch.description,
                              accentColor: 0xFFC4302B,
                              backgroundColor: 0xFFFFF1F0,
                              chartType: 'trigger',
                              chartValues: const [],
                              footLeft: watch.windowLabel,
                              frequency: watch.pattern?.frequency != null ? '${watch.pattern!.frequency} occurrences' : watch.meta,
                              whyPoints: watch.pattern?.commonFactors.map((f) => f.label).toList() ?? const [],
                            ),
                          ),
                  ),
                  Gap.h10,

                  // TOP FOODS THIS WEEK
                  _TopFoodsSection(insight: widget.data),

                  Gap.h16,
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: context.insightColor(const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(14.w),
                      border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.shieldAlert, size: 16.w, color: context.insightColor(const Color(0xFF94A3B8))),
                        Gap.w10,
                        Expanded(
                          child: Text(
                            'GutGood Insights reflects statistical correlations from your meal and symptom logs, not permanent allergies or medical diagnoses. Always listen to your body.',
                            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: context.insightColor(const Color(0xFF64748B)), height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ]),
          ),
        ),
      ],
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  _StickyTabBarDelegate({required this.child});
  final Widget child;

  @override
  double get minExtent => 44.w; // Compact height for pill tab bar
  @override
  double get maxExtent => 44.w;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) => true;
}

// =============================================================================
// HEADER & FILTER CHIPS WIDGET
// =============================================================================
class _InsightsHeaderWidget extends StatelessWidget {
  const _InsightsHeaderWidget({required this.selectedFilter, required this.onFilterSelected});
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    final filters = ['For You', 'Patterns', 'Food Impact', 'Weekly Recap'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < filters.length; i++) ...[
            if (i > 0) Gap.w8,
            GestureDetector(
              onTap: () => onFilterSelected(filters[i]),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
                decoration: BoxDecoration(
                  color: filters[i] == selectedFilter ? const Color(0xFF171717) : Colors.transparent,
                  borderRadius: BorderRadius.circular(100.w),
                  border: Border.all(color: filters[i] == selectedFilter ? const Color(0xFF171717) : context.insightColor(const Color(0xFFE2E8F0)), width: 1.w),
                  boxShadow: filters[i] == selectedFilter ? [BoxShadow(color: const Color(0xFF17171B).withValues(alpha: 0.15), blurRadius: 4.w, offset: Offset(0, 2.w))] : null,
                ),
                child: Text(
                  filters[i],
                  style: TextStyle(
                    fontFamily: InsightV2Theme.fontFamily,
                    fontSize: 12.sp,
                    fontWeight: filters[i] == selectedFilter ? FontWeight.w800 : FontWeight.w600,
                    color: filters[i] == selectedFilter ? Colors.white : context.insightColor(const Color(0xFF475569)),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// FOOD IMPACT TAB: 1. FOOD IMPACT BALANCE HERO CARD (Compact Layout)
// =============================================================================
class _FoodImpactBalanceHeroCard extends StatelessWidget {
  const _FoodImpactBalanceHeroCard({this.balance, this.foodImpacts = const []});

  final FoodImpactBalance? balance;
  final List<FoodImpact> foodImpacts;

  @override
  Widget build(BuildContext context) {
    var pos = balance?.positivePercent ?? 0;
    var neu = balance?.neutralPercent ?? 0;
    var neg = balance?.negativePercent ?? 0;
    final periodLabel = balance?.periodLabel ?? 'Last 4 weeks';

    if (balance == null || (pos == 0 && neu == 0 && neg == 0)) {
      if (foodImpacts.isNotEmpty) {
        var posCount = 0;
        var negCount = 0;
        for (final f in foodImpacts) {
          if (f.impactType == 'positive') {
            posCount++;
          } else if (f.impactType == 'negative') {
            negCount++;
          }
        }
        final total = foodImpacts.length;
        if (total > 0) {
          pos = ((posCount / total) * 100).round();
          neg = ((negCount / total) * 100).round();
          neu = (100 - pos - neg).clamp(0, 100);
        }
      }
    }

    if (pos == 0 && neu == 0 && neg == 0) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: context.v2Theme.card,
          borderRadius: BorderRadius.circular(20.w),
          border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.leaf, size: 15.w, color: const Color(0xFF15803D)),
                Gap.w6,
                Text(
                  'Food Impact Balance',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                ),
              ],
            ),
            Gap.h4,
            Text(
              'No food impact balance data yet. Keep logging your meals and symptoms to track your food impact ratios.',
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, color: context.insightColor(const Color(0xFF64748B))),
            ),
          ],
        ),
      );
    }

    pos = pos.clamp(0, 100);
    neu = neu.clamp(0, 100);
    neg = neg.clamp(0, 100);
    final totalPercent = pos + neu + neg;
    if (totalPercent > 0 && totalPercent != 100) {
      pos = (pos * 100 / totalPercent).round();
      neg = (neg * 100 / totalPercent).round();
      neu = 100 - pos - neg;
    }
    final posRatio = pos / 100.0;
    final neuRatio = neu / 100.0;
    final negRatio = neg / 100.0;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.v2Theme.card,
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0))),
        boxShadow: [BoxShadow(color: context.insightColor(const Color(0xFF0F172A)).withValues(alpha: 0.03), blurRadius: 8.w, offset: Offset(0, 2.w))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(5.w),
                decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                child: Icon(LucideIcons.leaf, size: 13.w, color: const Color(0xFF15803D)),
              ),
              Gap.w8,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Food Impact Balance',
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                  ),
                  Text(
                    'Your food choices over the $periodLabel.',
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: context.insightColor(const Color(0xFF64748B))),
                  ),
                ],
              ),
            ],
          ),
          Gap.h10,

          // Row with Donut Chart + Legend + Recommendation Box
          Row(
            children: [
              // Donut Chart
              SizedBox(
                width: 80.w,
                height: 80.w,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: Size(80.w, 80.w),
                      painter: _FoodImpactDonutPainter(positiveRatio: posRatio, neutralRatio: neuRatio, negativeRatio: negRatio),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$pos%',
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 20.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A)), height: 1.0),
                        ),
                        Text(
                          'Positive',
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w600, color: context.insightColor(const Color(0xFF64748B))),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Gap.w10,

              // Middle Legend
              Column(
                crossAxisAlignment: .start,
                children: [
                  _LegendItem(color: const Color(0xFF22C55E), percent: '$pos%', label: 'Positive', sub: 'Helping your gut'),
                  Gap.h6,
                  _LegendItem(color: const Color(0xFFFBBF24), percent: '$neu%', label: 'Neutral', sub: 'Minimal impact'),
                  Gap.h6,
                  _LegendItem(color: const Color(0xFFF87171), percent: '$neg%', label: 'Negative', sub: 'May trigger symptoms'),
                ],
              ),
              Gap.w8,

              // Right Message Box
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(color: context.insightColor(const Color(0xFFF0FDF4)), borderRadius: BorderRadius.circular(16.w)),
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                        child: Icon(LucideIcons.leaf, size: 11.w, color: const Color(0xFF15803D)),
                      ),
                      Gap.h4,
                      Text(
                        'More good food days ahead!',
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A)), height: 1.2),
                      ),
                      Gap.h3,
                      Text(
                        "You're making gut-friendly choices $pos% of the time.",
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: context.insightColor(const Color(0xFF334155)), height: 1.25),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.percent, required this.label, required this.sub});

  final Color color;
  final String percent;
  final String label;
  final String sub;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 7.w,
        height: 7.w,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      Gap.w4,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                percent,
                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
              ),
              Gap.w3,
              Text(
                label,
                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w700, color: context.insightColor(const Color(0xFF0F172A))),
              ),
            ],
          ),
          Text(
            sub,
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.5.sp, color: context.insightColor(const Color(0xFF64748B))),
          ),
        ],
      ),
    ],
  );
}

// =============================================================================
// FOOD IMPACT TAB: 2. SIDE-BY-SIDE TOP HEALING & TOP TRIGGER FOOD CARDS
// =============================================================================
class _SideBySideHealingAndTriggerCards extends StatelessWidget {
  const _SideBySideHealingAndTriggerCards({this.insight});

  final AIInsight? insight;

  @override
  Widget build(BuildContext context) {
    final hasHealing = insight?.healingSummary?.foods.isNotEmpty == true || insight?.healingFoods.isNotEmpty == true;
    final hasTrigger = insight?.triggerSummary?.foods.isNotEmpty == true || insight?.triggerFoods.isNotEmpty == true;

    if (!hasHealing && !hasTrigger) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: context.v2Theme.card,
          borderRadius: BorderRadius.circular(18.w),
          border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Healing & Trigger Foods',
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
            ),
            Gap.h4,
            Text(
              'No specific healing or trigger foods identified yet. Keep logging meals to discover foods that support or upset your gut.',
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, color: context.insightColor(const Color(0xFF64748B))),
            ),
          ],
        ),
      );
    }

    final healingList = insight?.healingSummary?.foods.isNotEmpty == true
        ? insight!.healingSummary!.foods
        : (insight?.healingFoods.isNotEmpty == true
              ? insight!.healingFoods
                    .map((f) => InsightFood(foodId: 'h_${f.name}', name: f.name, emoji: f.emoji, imageUrl: f.userImageUrl ?? f.imageUrl, effect: f.effect, impactLevel: 'high'))
                    .toList()
              : <InsightFood>[]);

    final triggerList = insight?.triggerSummary?.foods.isNotEmpty == true
        ? insight!.triggerSummary!.foods
        : (insight?.triggerFoods.isNotEmpty == true
              ? insight!.triggerFoods
                    .map((f) => InsightFood(foodId: 't_${f.name}', name: f.name, emoji: f.emoji, imageUrl: f.userImageUrl ?? f.imageUrl, effect: f.effect, impactLevel: 'high'))
                    .toList()
              : <InsightFood>[]);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Card: Top Healing Foods
          if (healingList.isNotEmpty) ...[
            Expanded(
              child: Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF102319) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(18.w),
                  border: Border.all(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.28) : const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 22.w,
                          height: 22.w,
                          decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
                          child: Icon(LucideIcons.trophy, size: 11.w, color: Colors.white),
                        ),
                        Gap.w4,
                        Expanded(
                          child: Text(
                            'Top Healing Foods',
                            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)),
                          ),
                        ),
                      ],
                    ),
                    Gap.h2,
                    Text(
                      'Foods that support your gut health.',
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: context.insightColor(const Color(0xFF475569))),
                    ),
                    Gap.h8,

                    for (var i = 0; i < healingList.take(2).length; i++) ...[
                      if (i > 0) Gap.h6,
                      _HealingFoodItemTile(
                        imageUrl: healingList[i].imageUrl ?? V2Kit.foodImageUrl(healingList[i].name),
                        title: healingList[i].name,
                        sub: healingList[i].effect ?? 'Supports gut diversity',
                        badge: '${healingList[i].impactLevel.toUpperCase()} Impact',
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          if (healingList.isNotEmpty && triggerList.isNotEmpty) Gap.w10,

          // Right Card: Top Trigger Food
          if (triggerList.isNotEmpty) ...[
            Expanded(
              child: Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF231416) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(18.w),
                  border: Border.all(color: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.45) : const Color(0xFFFCA5A5), width: 1.2.w),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626)).withValues(alpha: isDark ? 0.08 : 0.04),
                      blurRadius: 10.w,
                      offset: Offset(0, 2.w),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 22.w,
                          height: 22.w,
                          decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
                          child: Icon(LucideIcons.triangleAlert, size: 11.w, color: Colors.white),
                        ),
                        Gap.w4,
                        Expanded(
                          child: Text(
                            'Top Trigger Food',
                            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFFF87171) : const Color(0xFF991B1B)),
                          ),
                        ),
                      ],
                    ),
                    Gap.h2,
                    Text(
                      'Food most associated with symptoms.',
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: context.insightColor(const Color(0xFF475569))),
                    ),
                    Gap.h8,

                    Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(color: context.v2Theme.card, borderRadius: BorderRadius.circular(12.w)),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.w),
                            child: CachedNetworkImage(imageUrl: triggerList.first.imageUrl ?? V2Kit.foodImageUrl(triggerList.first.name), width: 40.w, height: 40.w, fit: BoxFit.cover),
                          ),
                          Gap.w6,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  triggerList.first.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: InsightV2Theme.fontFamily,
                                    fontSize: 10.5.sp,
                                    fontWeight: FontWeight.w800,
                                    color: context.insightColor(const Color(0xFF0F172A)),
                                    height: 1.1,
                                  ),
                                ),
                                Gap.h2,
                                Text(
                                  triggerList.first.effect ?? 'Associated with digestive discomfort',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.5.sp, color: context.insightColor(const Color(0xFF475569)), height: 1.15),
                                ),
                                Gap.h3,
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.18) : const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(6.w),
                                    border: Border.all(color: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.35) : const Color(0xFFFECACA), width: 0.8.w),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.triangleAlert, size: 7.w, color: isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C)),
                                      Gap.w2,
                                      Text(
                                        '${triggerList.first.impactLevel.toUpperCase()} Impact',
                                        style: TextStyle(
                                          fontFamily: InsightV2Theme.fontFamily,
                                          fontSize: 7.5.sp,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Gap.h6,
                    InkWell(
                      onTap: () {
                        FoodSwap? matchingSwap;
                        final targetName = triggerList.first.name.toLowerCase().trim();
                        for (final s in insight?.foodSwaps ?? <FoodSwap>[]) {
                          if (s.source.name.toLowerCase().trim() == targetName) {
                            matchingSwap = s;
                            break;
                          }
                        }
                        final swapObj =
                            matchingSwap ??
                            FoodSwap(
                              id: 'swap_${triggerList.first.name.toLowerCase()}',
                              source: SwapSource(foodId: 'food_trigger', name: triggerList.first.name),
                              alternatives: [
                                SwapAlternative(
                                  foodId: 'food_alt_01',
                                  name: 'Gut-Friendly ${triggerList.first.name} Alternative',
                                  reason: 'Easier to digest with lower fermentation load for your gut balance.',
                                ),
                              ],
                            );
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => BetterSwapsScreen(swap: swapObj)));
                      },
                      borderRadius: BorderRadius.circular(8.w),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.w),
                        decoration: BoxDecoration(
                          color: context.v2Theme.card,
                          borderRadius: BorderRadius.circular(8.w),
                          border: Border.all(color: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.35) : context.insightColor(const Color(0xFFFECACA))),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.repeat, size: 9.w, color: isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C)),
                            Gap.w4,
                            Text(
                              'Find Better Swaps',
                              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HealingFoodItemTile extends StatelessWidget {
  const _HealingFoodItemTile({required this.imageUrl, required this.title, required this.sub, required this.badge});

  final String imageUrl;
  final String title;
  final String sub;
  final String badge;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(6.w),
    decoration: BoxDecoration(color: context.v2Theme.card, borderRadius: BorderRadius.circular(12.w)),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.w),
          child: CachedNetworkImage(imageUrl: imageUrl, width: 36.w, height: 36.w, fit: BoxFit.cover),
        ),
        Gap.w6,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
              ),
              Text(
                sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.5.sp, color: context.insightColor(const Color(0xFF475569)), height: 1.15),
              ),
              SizedBox(height: 2.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
                decoration: BoxDecoration(color: context.insightColor(const Color(0xFFDCFCE7)), borderRadius: BorderRadius.circular(6.w)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.leaf, size: 7.w, color: const Color(0xFF15803D)),
                    Gap.w2,
                    Text(
                      badge,
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.sp, fontWeight: FontWeight.w700, color: const Color(0xFF15803D)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// =============================================================================
// FOOD IMPACT TAB: 4. RECENT FOOD IMPACTS SECTION
// =============================================================================
class _RecentFoodImpactsSection extends StatelessWidget {
  const _RecentFoodImpactsSection({this.impacts = const []});

  final List<FoodImpact> impacts;

  @override
  Widget build(BuildContext context) {
    if (impacts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: context.v2Theme.card,
          borderRadius: BorderRadius.circular(16.w),
          border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.clock, size: 15.w, color: context.insightColor(const Color(0xFF0F172A))),
                Gap.w6,
                Text(
                  'Recent Food Impacts',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                ),
              ],
            ),
            Gap.h4,
            Text(
              'No recent food impacts recorded yet. Log your meals to see how specific foods affect your gut.',
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, color: context.insightColor(const Color(0xFF64748B))),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(LucideIcons.clock, size: 15.w, color: context.insightColor(const Color(0xFF0F172A))),
                Gap.w6,
                Text(
                  'Recent Food Impacts',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                ),
              ],
            ),
          ],
        ),
        Gap.h8,

        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: context.v2Theme.card,
            borderRadius: BorderRadius.circular(16.w),
            border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0))),
          ),
          child: Column(
            children: [
              for (var i = 0; i < impacts.take(4).length; i++) ...[
                if (i > 0) Divider(height: 12.w, color: context.insightColor(const Color(0xFFF1F5F9))),
                _FoodImpactRow(
                  imageUrl: impacts[i].userImageUrl ?? impacts[i].imageUrl ?? V2Kit.foodImageUrl(impacts[i].food),
                  title: impacts[i].food,
                  sub: '${impacts[i].dateLabel} • ${impacts[i].timeframeLabel}',
                  status: impacts[i].effect,
                  isPositive: impacts[i].impactType == 'positive',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FoodImpactRow extends StatelessWidget {
  const _FoodImpactRow({required this.imageUrl, required this.title, required this.sub, required this.status, required this.isPositive});

  final String imageUrl;
  final String title;
  final String sub;
  final String status;
  final bool isPositive;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(8.w),
        child: CachedNetworkImage(imageUrl: imageUrl, width: 36.w, height: 36.w, fit: BoxFit.cover),
      ),
      Gap.w8,
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
            ),
            Text(
              sub,
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: context.insightColor(const Color(0xFF64748B))),
            ),
          ],
        ),
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Icon(isPositive ? LucideIcons.leaf : LucideIcons.triangleAlert, size: 10.w, color: isPositive ? const Color(0xFF15803D) : const Color(0xFFB91C1C)),
              Gap.w3,
              Text(
                status,
                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w600, color: context.insightColor(const Color(0xFF0F172A))),
              ),
            ],
          ),
          Gap.h2,
          Text(
            isPositive ? 'Positive' : 'Negative',
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.sp, fontWeight: FontWeight.w700, color: isPositive ? const Color(0xFF15803D) : const Color(0xFFB91C1C)),
          ),
        ],
      ),
    ],
  );
}

// =============================================================================
// FOOD IMPACT TAB: 5. YOUR NEXT STEPS SECTION
// =============================================================================
class _YourNextStepsSection extends StatelessWidget {
  const _YourNextStepsSection({this.actions = const []});

  final List<InsightAction> actions;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: context.v2Theme.card,
          borderRadius: BorderRadius.circular(16.w),
          border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.sprout, size: 15.w, color: const Color(0xFF15803D)),
                Gap.w6,
                Text(
                  'Your Next Steps',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                ),
              ],
            ),
            Gap.h4,
            Text(
              'No action steps recommended right now. Continue logging meals and symptoms to receive personalized guidance.',
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, color: context.insightColor(const Color(0xFF64748B))),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(LucideIcons.sprout, size: 15.w, color: const Color(0xFF15803D)),
                Gap.w6,
                Text(
                  'Your Next Steps',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                ),
              ],
            ),
          ],
        ),
        Gap.h8,

        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < actions.take(2).length; i++) ...[
                if (i > 0) Gap.w10,
                Expanded(
                  child: _NextStepCard(icon: i == 0 ? LucideIcons.leaf : LucideIcons.milk, title: actions[i].title, sub: actions[i].description, onTap: () {}),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NextStepCard extends StatelessWidget {
  const _NextStepCard({required this.icon, required this.title, required this.sub, this.onTap});

  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16.w),
    child: Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: context.insightColor(const Color(0xFFF0FDF4)),
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: context.insightColor(const Color(0xFFDCFCE7))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 24.w,
                    height: 24.w,
                    decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                    child: Icon(icon, size: 12.w, color: const Color(0xFF15803D)),
                  ),
                ],
              ),
              Gap.h6,
              Text(
                title,
                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A)), height: 1.2),
              ),
              Gap.h3,
              Text(
                sub,
                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: context.insightColor(const Color(0xFF475569)), height: 1.25),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

// =============================================================================
// PATTERNS TAB: BOTTOM SMARTER BANNER CARD
// =============================================================================
class _PatternsSmarterBannerCard extends StatelessWidget {
  const _PatternsSmarterBannerCard();

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: context.insightColor(const Color(0xFFF0FDF4)),
      borderRadius: BorderRadius.circular(20.w),
      border: Border.all(color: context.insightColor(const Color(0xFFDCFCE7))),
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.w),
      child: Row(
        children: [
          // Left Icon Box
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(color: context.insightColor(const Color(0xFFDCFCE7)), borderRadius: BorderRadius.circular(12.w)),
            child: Icon(LucideIcons.barChart2, size: 16.w, color: const Color(0xFF15803D)),
          ),
          Gap.w10,

          // Middle Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patterns get smarter over time',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 13.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                ),
                Gap.h2,
                Text(
                  'The more you log, the more personalized your insights become. Keep tracking to unlock deeper insights!',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: context.insightColor(const Color(0xFF475569)), height: 1.25),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// =============================================================================
// HERO 1: GUT SCORE & ON TRACK CARD
// =============================================================================
// =============================================================================
// HERO 3: SIDE-BY-SIDE CARDS ("What's Improving" & "Something to Watch")
// =============================================================================
class _SideBySideImprovingAndWatch extends StatelessWidget {
  const _SideBySideImprovingAndWatch({required this.improvingData, required this.series, this.watchData, this.onImprovingTap, this.onWatchTap});

  final V2ImprovingData improvingData;
  final List<double> series;
  final V2WatchData? watchData;
  final VoidCallback? onImprovingTap;
  final VoidCallback? onWatchTap;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _ImprovingCardWidget(data: improvingData, series: series, onTap: onImprovingTap),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _WatchCardWidget(data: watchData, onTap: onWatchTap),
        ),
      ],
    ),
  );
}

class _ImprovingCardWidget extends StatelessWidget {
  const _ImprovingCardWidget({required this.data, required this.series, this.onTap});

  final V2ImprovingData data;
  final List<double> series;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cleanSeries = InsightValues.scores(series);
    final scoredSeries = cleanSeries.where((s) => s > 0).toList();

    final startVal = scoredSeries.length > 1
        ? scoredSeries.first.round().toString()
        : (scoredSeries.length == 1
            ? scoredSeries.single.round().toString()
            : (data.current > 0 ? data.current.toString() : '—'));

    final endVal = scoredSeries.isNotEmpty
        ? scoredSeries.last.round().toString()
        : (data.current > 0 ? data.current.toString() : '—');

    final headline = (data.headline.isNotEmpty && data.headline != 'Your gut score is on the move')
        ? data.headline
        : (scoredSeries.length < 2 && data.lastWeek == null ? 'Your score baseline' : (data.headline.isNotEmpty ? data.headline : 'Your gut score is steady.'));

    final description = (data.description.isNotEmpty && data.description != 'Keep logging meals and symptoms to sharpen this trend.')
        ? data.description
        : (scoredSeries.length < 2 && data.lastWeek == null
            ? 'One recorded score sets a starting point. Another score will show whether it changed.'
            : (data.description.isNotEmpty ? data.description : 'Keep logging meals and symptoms to track your gut health progress.'));

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF102319) : const Color(0xFFF4FAF2),
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.28) : const Color(0xFFDCFCE7)),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFF22C55E) : const Color(0xFF17171B)).withValues(alpha: isDark ? 0.06 : 0.03),
            blurRadius: 6.w,
            offset: Offset(0, 2.w),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.w),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      children: [
                        Container(
                          width: 24.w,
                          height: 24.w,
                          decoration: BoxDecoration(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.18) : const Color(0xFF16A34A), shape: BoxShape.circle),
                          child: Center(
                            child: Icon(Icons.show_chart_rounded, size: 14.w, color: isDark ? const Color(0xFF4ADE80) : Colors.white),
                          ),
                        ),
                        Gap.w6,
                        Expanded(
                          child: Text(
                            "What's Improving",
                            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF14532D)),
                          ),
                        ),
                      ],
                    ),
                    Gap.h8,

                    // Headline
                    Text(
                      headline,
                      style: TextStyle(
                        fontFamily: InsightV2Theme.fontFamily,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF14532D),
                        height: 1.2,
                      ),
                    ),
                    Gap.h3,

                    // Description
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: context.insightColor(const Color(0xFF334155)), height: 1.25),
                    ),
                    Gap.h8,

                    // Trend Area Chart
                    SizedBox(
                      height: 38.w,
                      width: double.infinity,
                      child: V2TrendChart(values: series),
                    ),
                    Gap.h2,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              startVal,
                              style: TextStyle(
                                fontFamily: InsightV2Theme.fontFamily,
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w800,
                                color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF14532D),
                                height: 1.0,
                              ),
                            ),
                            Text(
                              'First recorded',
                              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.5.sp, color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D)),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              endVal,
                              style: TextStyle(
                                fontFamily: InsightV2Theme.fontFamily,
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w800,
                                color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF14532D),
                                height: 1.0,
                              ),
                            ),
                            Text(
                              'Latest',
                              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.5.sp, color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                Gap.h8,

                // See Details Button
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.w),
                  decoration: BoxDecoration(
                    color: context.v2Theme.card,
                    borderRadius: BorderRadius.circular(20.w),
                    border: Border.all(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.28) : const Color(0xFFDCFCE7)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'See Details',
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w700, color: context.insightColor(const Color(0xFF0F172A))),
                      ),
                      Gap.w4,
                      Icon(Icons.arrow_forward_rounded, size: 12.w, color: context.insightColor(const Color(0xFF0F172A))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WatchCardWidget extends StatelessWidget {
  const _WatchCardWidget({this.data, this.onTap});

  final V2WatchData? data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasTrigger = data != null && data!.pattern != null && data!.title.isNotEmpty && data!.title != 'No Triggers Detected';

    final title = hasTrigger ? data!.title : 'No Triggers Detected';
    final desc = hasTrigger && data!.description.isNotEmpty ? data!.description : 'Repeated food and symptom associations have not been established yet. Keep logging to build enough evidence.';

    final thumbnails = hasTrigger && data?.pattern?.involvedFoods.isNotEmpty == true
        ? data!.pattern!.involvedFoods.take(3).map(V2Kit.foodImageUrl).toList()
        : (hasTrigger && data?.timeline.isNotEmpty == true ? data!.timeline.take(3).map((t) => t.imageUrl ?? V2Kit.foodImageUrl(t.imageName ?? 'Food')).toList() : const <String>[]);

    final effectiveOnTap = hasTrigger
        ? (onTap ??
              () {
                final swapObj = FoodSwap(
                  id: 'swap_watch',
                  source: SwapSource(foodId: 'food_trigger', name: title),
                  alternatives: [SwapAlternative(foodId: 'food_alt_01', name: data?.swapAfter ?? 'Gentle Gut Alternative', reason: data?.swapTip ?? 'Lower digestive burden and easier to process.')],
                );
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => BetterSwapsScreen(swap: swapObj)));
              })
        : null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF231416) : const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.45) : const Color(0xFFFCA5A5), width: 1.2.w),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626)).withValues(alpha: isDark ? 0.08 : 0.04),
            blurRadius: 8.w,
            offset: Offset(0, 2.w),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(20.w),
        child: InkWell(
          onTap: effectiveOnTap,
          borderRadius: BorderRadius.circular(20.w),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      children: [
                        Container(
                          width: 24.w,
                          height: 24.w,
                          decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
                          child: Center(
                            child: Icon(LucideIcons.triangleAlert, size: 13.w, color: Colors.white),
                          ),
                        ),
                        Gap.w6,
                        Expanded(
                          child: Text(
                            'Something to Watch',
                            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFFF87171) : const Color(0xFF881337)),
                          ),
                        ),
                      ],
                    ),
                    Gap.h8,

                    // Headline
                    Text(
                      title,
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A)), height: 1.2),
                    ),
                    Gap.h3,

                    // Description
                    Text(
                      desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: context.insightColor(const Color(0xFF334155)), height: 1.25),
                    ),
                    Gap.h8,

                    // 3 Food Thumbnails
                    if (hasTrigger && thumbnails.isNotEmpty) ...[
                      Row(
                        children: [
                          for (var i = 0; i < thumbnails.length; i++) ...[
                            if (i > 0) Gap.w4,
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.w),
                              child: CachedNetworkImage(
                                imageUrl: thumbnails[i],
                                width: 36.w,
                                height: 36.w,
                                fit: BoxFit.cover,
                                placeholder: (_, _) => Container(color: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.18) : const Color(0xFFFEE2E2)),
                                errorWidget: (_, _, _) => Container(
                                  color: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.20) : const Color(0xFFFECDD3),
                                  child: Icon(LucideIcons.utensils, size: 14, color: isDark ? const Color(0xFFF87171) : const Color(0xFF881337)),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Gap.h6,
                    ],

                    // High Frequency Badge
                    if (hasTrigger) ...[
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.w),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.18) : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12.w),
                          border: Border.all(color: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.35) : const Color(0xFFFECACA), width: 0.8.w),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.target, size: 10.w, color: isDark ? const Color(0xFFF87171) : const Color(0xFF881337)),
                            Gap.w3,
                            Text(
                              '${data?.pattern?.frequency ?? data?.timeline.length ?? 0} Observations',
                              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.sp, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFFF87171) : const Color(0xFF881337)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                // Bottom Row: See Details Button (Only when trigger detected)
                if (hasTrigger) ...[
                  Gap.h8,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.w),
                        decoration: BoxDecoration(
                          color: context.v2Theme.card,
                          borderRadius: BorderRadius.circular(20.w),
                          border: Border.all(color: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.35) : const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'See Details',
                              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w700, color: context.insightColor(const Color(0xFF0F172A))),
                            ),
                            Gap.w4,
                            Icon(Icons.arrow_forward_rounded, size: 12.w, color: context.insightColor(const Color(0xFF0F172A))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// HERO 4: TOP FOODS THIS WEEK CARD
// =============================================================================
class _TopFoodsSection extends StatelessWidget {
  const _TopFoodsSection({required this.insight});

  final AIInsight insight;

  @override
  Widget build(BuildContext context) {
    final foodItems = <TopFoodItemData>[];
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

    if (insight.healingSummary?.foods.isNotEmpty == true) {
      for (final f in insight.healingSummary!.foods) {
        final key = f.name.toLowerCase().trim();
        if (key.isEmpty || !seen.add(key)) continue;
        final n = countOccurrences(f.name);
        final countStr = n > 0 ? '${n}x logged' : 'Active';
        final desc = f.effect != null && f.effect!.isNotEmpty ? f.effect : 'Supports microbiome diversity and gut balance.';
        foodItems.add(
          TopFoodItemData(
            title: f.name,
            frequency: countStr,
            badge: f.impactLevel.toUpperCase() == 'HIGH' ? 'High Impact' : 'Supportive',
            imageUrl: f.imageUrl ?? V2Kit.foodImageUrl(f.name),
            description: desc,
            isPositive: true,
          ),
        );
      }
    }

    for (final f in insight.healingFoods) {
      final key = f.name.toLowerCase().trim();
      if (key.isEmpty || !seen.add(key)) continue;
      final n = countOccurrences(f.name);
      final countStr = n > 0 ? '${n}x logged' : 'Active';
      final desc = f.effect.isNotEmpty ? f.effect : 'Supports microbiome diversity and gut balance.';
      foodItems.add(TopFoodItemData(title: f.name, frequency: countStr, badge: 'Gut Hero', imageUrl: f.userImageUrl ?? f.imageUrl ?? V2Kit.foodImageUrl(f.name), description: desc, isPositive: true));
    }

    for (final f in insight.foodImpacts.where((i) {
      final type = i.impactType.toLowerCase();
      return type == 'positive' || type == 'healing' || type == 'good' || type == 'supportive';
    })) {
      final key = f.food.toLowerCase().trim();
      if (key.isEmpty || !seen.add(key)) continue;
      final n = countOccurrences(f.food);
      final countStr = n > 0 ? '${n}x logged' : f.dateLabel;
      final desc = f.effect.isNotEmpty ? f.effect : 'Observed positive effect on gut health.';
      foodItems.add(TopFoodItemData(title: f.food, frequency: countStr, badge: 'Positive', imageUrl: f.userImageUrl ?? f.imageUrl ?? V2Kit.foodImageUrl(f.food), description: desc, isPositive: true));
    }

    if (foodItems.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: context.v2Theme.card,
          borderRadius: BorderRadius.circular(18.w),
          border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0))),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
              child: Icon(LucideIcons.leaf, size: 16.w, color: const Color(0xFF15803D)),
            ),
            Gap.w10,
            Expanded(
              child: Text(
                'Top Foods This Week',
                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
              ),
            ),
            GestureDetector(
              onTap: () => context.push(AppRoutes.scannerPath('meal')),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.w),
                decoration: BoxDecoration(color: const Color(0xFF15803D), borderRadius: BorderRadius.circular(12.w)),
                child: Text(
                  'Log Meal',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                  child: Icon(LucideIcons.trophy, size: 12.w, color: const Color(0xFF15803D)),
                ),
                Gap.w8,
                Text(
                  'Top Foods This Week',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => context.push(AppRoutes.foodIntelligence, extra: insight),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View All',
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w700, color: context.insightColor(const Color(0xFF0F172A))),
                  ),
                  Gap.w3,
                  Icon(Icons.arrow_forward_rounded, size: 11.w, color: context.insightColor(const Color(0xFF0F172A))),
                ],
              ),
            ),
          ],
        ),
        Gap.h10,

        // Separate List Items (Top 3 foods) using TopFoodTile
        Column(
          children: [
            for (final item in foodItems.take(3)) ...[
              TopFoodTile(
                item: item,
                onTap: () => context.push(AppRoutes.foodIntelligence, extra: insight),
              ),
              Gap.h10,
            ],
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// CUSTOM PAINTERS
// =============================================================================
class _FoodImpactDonutPainter extends CustomPainter {
  const _FoodImpactDonutPainter({required this.positiveRatio, required this.neutralRatio, required this.negativeRatio});

  final double positiveRatio;
  final double neutralRatio;
  final double negativeRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = 10.w;
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    const startAngle = -math.pi / 2;
    const gap = 0.05;

    final posSweep = (2 * math.pi * positiveRatio) - gap;
    final neuSweep = (2 * math.pi * neutralRatio) - gap;
    final negSweep = (2 * math.pi * negativeRatio) - gap;

    final paintPos = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF22C55E);

    final paintNeu = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFBBF24);

    final paintNeg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFF87171);

    var currentAngle = startAngle;
    canvas.drawArc(rect, currentAngle, posSweep, false, paintPos);

    currentAngle += posSweep + gap;
    canvas.drawArc(rect, currentAngle, neuSweep, false, paintNeu);

    currentAngle += neuSweep + gap;
    canvas.drawArc(rect, currentAngle, negSweep, false, paintNeg);
  }

  @override
  bool shouldRepaint(covariant _FoodImpactDonutPainter oldDelegate) => true;
}

class V2WeeklyRecapView extends StatelessWidget {
  const V2WeeklyRecapView({super.key, required this.data, this.series = const [], this.patterns = const [], this.history = const []});

  final AIInsight data;
  final List<double> series;
  final List<BodyPattern> patterns;
  final List<AIInsight> history;

  @override
  Widget build(BuildContext context) {
    final recap = data.weeklyRecap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Average Gut Score Card
        _WeeklyAverageScoreCard(recap: recap, data: data),
        Gap.h10,

        // 2. Row of 3 Stat Cards (Best Day, Foods Logged, Your Evidence)
        _WeeklyRecapStatCardsRow(recap: recap, data: data),
        Gap.h10,

        // 3. Weekly Highlights Card
        _WeeklyHighlightsCard(recap: recap),
        Gap.h10,

        // 4. Side-by-Side Top Healing Food & Top Trigger Food
        _WeeklyTopFoodsRow(data: data),
        Gap.h10,

        // 5. Your Weekly Insight Card
        _YourWeeklyInsightCard(data: data),
      ],
    );
  }
}

class _WeeklyAverageScoreCard extends StatelessWidget {
  const _WeeklyAverageScoreCard({required this.recap, required this.data});
  final WeeklyRecap? recap;
  final AIInsight data;

  @override
  Widget build(BuildContext context) {
    GutScoreRecord? scoreRecord;
    try {
      scoreRecord = context.read<InsightsNotifier>().latestScoreRecord;
    } catch (_) {}

    var trendInts = const <int>[];
    if (scoreRecord != null && scoreRecord.dailyScores.isNotEmpty) {
      trendInts = scoreRecord.dailyScores;
    } else if (recap?.gutScoreTrend != null && recap!.gutScoreTrend!.isNotEmpty) {
      trendInts = recap!.gutScoreTrend!;
    }

    final trendDoubles = trendInts.map((e) => e.toDouble()).toList();
    final scored = trendInts.where((s) => s > 0).toList();
    final trendAvg = scored.isEmpty ? null : (scored.reduce((a, b) => a + b) / scored.length).round();

    final recordScore = scoreRecord?.gutScore;
    final avgScore = (recordScore != null && recordScore > 0) ? recordScore : (recap?.avgScore ?? trendAvg ?? (data.hasGutScore ? data.gutScore : 0));

    final hasAnyScore = (recordScore != null && recordScore > 0) || data.hasGutScore || scored.isNotEmpty || (recap?.avgScore ?? 0) > 0;

    if (!hasAnyScore) {
      return InsightScoreCard(score: null, delta: null, onTap: null, onWhyTap: () => WhyScoreSheet.show(context, data));
    }

    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return GutScoreCard(
      score: avgScore,
      title: 'WEEKLY AVERAGE',
      subtitle: recap?.scoreSub ?? 'Your gut score trend over the last 7 days.',
      showChevron: false,
      series: trendDoubles.isNotEmpty ? trendDoubles : [avgScore.toDouble()],
      labels: labels,
    );
  }
}

class _ForYouGutScoreCard extends StatelessWidget {
  const _ForYouGutScoreCard({required this.data, required this.series, this.delta});
  final AIInsight data;
  final List<double> series;
  final int? delta;

  @override
  Widget build(BuildContext context) {
    GutScoreRecord? scoreRecord;
    try {
      scoreRecord = context.read<InsightsNotifier>().latestScoreRecord;
    } catch (_) {}

    var trendInts = const <int>[];
    if (scoreRecord != null && scoreRecord.dailyScores.isNotEmpty) {
      trendInts = scoreRecord.dailyScores;
    } else if (data.weeklyRecap?.gutScoreTrend != null && data.weeklyRecap!.gutScoreTrend!.isNotEmpty) {
      trendInts = data.weeklyRecap!.gutScoreTrend!;
    }

    final trendDoubles = trendInts.map((e) => e.toDouble()).toList();
    final scored = trendInts.where((s) => s > 0).toList();
    final trendAvg = scored.isEmpty ? null : (scored.reduce((a, b) => a + b) / scored.length).round();

    final recordScore = scoreRecord?.gutScore;
    final displayScore = (recordScore != null && recordScore > 0) ? recordScore : (data.hasGutScore ? data.gutScore : (data.weeklyRecap?.avgScore ?? trendAvg ?? 0));

    final hasAnyScore = (recordScore != null && recordScore > 0) || data.hasGutScore || scored.isNotEmpty || (data.weeklyRecap?.avgScore ?? 0) > 0;

    if (!hasAnyScore) {
      return InsightScoreCard(score: null, delta: null, onTap: null, onWhyTap: () => WhyScoreSheet.show(context, data));
    }

    final chartSeries = trendDoubles.isNotEmpty ? trendDoubles : (series.isNotEmpty ? series : [displayScore.toDouble()]);

    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return GutScoreCard(
      score: displayScore,
      delta: delta,
      title: 'GUTGOOD SCORE',
      subtitle: data.weeklyRecap?.scoreSub ?? 'Based on your recent meal and symptom logs.',
      series: chartSeries,
      labels: labels,
      onTap: () => WhyScoreSheet.show(context, data),
    );
  }
}

class _WeeklyRecapStatCardsRow extends StatelessWidget {
  const _WeeklyRecapStatCardsRow({required this.recap, required this.data});

  final WeeklyRecap? recap;
  final AIInsight data;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bestDay = (recap?.bestDay != null && recap!.bestDay!.isNotEmpty) ? recap!.bestDay! : '—';
    // Prefer recap counts (7-day). Fall back to evidence sample sizes so the
    // card never shows a blank "—" when the insight has real logs.
    final foodsLogged = recap?.foodsLogged ?? ((data.evidence?.sampleSizes.meals ?? 0) + (data.evidence?.sampleSizes.scans ?? 0));
    final foodsLabel = recap?.loggedSub ?? 'meals and scans';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Best Day Card
          Expanded(
            child: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF102319) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16.w),
                border: Border.all(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.28) : const Color(0xFFDCFCE7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.18) : const Color(0xFFDCFCE7), shape: BoxShape.circle),
                        child: Icon(LucideIcons.calendar, size: 11.w, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)),
                      ),
                      Gap.w4,
                      Expanded(
                        child: Text(
                          'Best Day',
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)),
                        ),
                      ),
                    ],
                  ),
                  Gap.h6,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bestDay,
                              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 16.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A)), height: 1.1),
                            ),
                            Gap.h2,
                            Text(
                              recap?.dateRange ?? 'No best day recorded',
                              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.5.sp, color: context.insightColor(const Color(0xFF64748B))),
                            ),
                          ],
                        ),
                      ),
                      Icon(LucideIcons.leaf, size: 20.w, color: isDark ? const Color(0xFF4ADE80).withValues(alpha: 0.25) : const Color(0xFF86EFAC).withValues(alpha: 0.7)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Gap.w6,

          // 2. Foods Logged Card
          Expanded(
            child: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF231A14) : const Color(0xFFFFFBF5),
                borderRadius: BorderRadius.circular(16.w),
                border: Border.all(color: isDark ? const Color(0xFFF97316).withValues(alpha: 0.28) : const Color(0xFFFFEDD5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(color: isDark ? const Color(0xFFF97316).withValues(alpha: 0.18) : const Color(0xFFFFEDD5), shape: BoxShape.circle),
                        child: Icon(LucideIcons.utensils, size: 11.w, color: isDark ? const Color(0xFFFB923C) : const Color(0xFFC2410C)),
                      ),
                      Gap.w4,
                      Expanded(
                        child: Text(
                          'Foods Logged',
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFFFB923C) : const Color(0xFF9A3412)),
                        ),
                      ),
                    ],
                  ),
                  Gap.h6,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$foodsLogged',
                              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 17.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A)), height: 1.1),
                            ),
                            Gap.h2,
                            Text(
                              foodsLabel,
                              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.5.sp, color: context.insightColor(const Color(0xFF64748B))),
                            ),
                          ],
                        ),
                      ),
                      Icon(LucideIcons.utensils, size: 18.w, color: isDark ? const Color(0xFFFB923C).withValues(alpha: 0.20) : const Color(0xFFFED7AA).withValues(alpha: 0.7)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Gap.w6,

          // 3. Your Evidence Card
          Expanded(
            child: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111E2E) : const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(16.w),
                border: Border.all(color: isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.28) : const Color(0xFFE0F2FE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(color: isDark ? const Color(0xFF0284C7).withValues(alpha: 0.20) : const Color(0xFFE0F2FE), shape: BoxShape.circle),
                            child: Icon(LucideIcons.barChart2, size: 11.w, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1)),
                          ),
                          Gap.w3,
                          Expanded(
                            child: Text(
                              'Your Evidence',
                              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1)),
                            ),
                          ),
                          Icon(LucideIcons.info, size: 10.w, color: isDark ? const Color(0xFF64748B) : context.insightColor(const Color(0xFF94A3B8))),
                        ],
                      ),
                      Gap.h6,
                      _EvidenceRow(label: 'Meals', count: data.evidence?.sampleSizes.meals),
                      Gap.h2,
                      _EvidenceRow(label: 'Symptoms', count: data.evidence?.sampleSizes.symptoms),
                      Gap.h2,
                      _EvidenceRow(label: 'Scans', count: data.evidence?.sampleSizes.scans),
                    ],
                  ),
                  Gap.h4,
                  Text(
                    'More data = more insights',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 7.5.sp, color: context.insightColor(const Color(0xFF64748B))),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceRow extends StatelessWidget {
  const _EvidenceRow({required this.label, required this.count});

  final String label;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(LucideIcons.checkSquare, size: 9.w, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
            Gap.w3,
            Text(
              label,
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: context.insightColor(const Color(0xFF334155))),
            ),
          ],
        ),
        Text(
          count?.toString() ?? '—',
          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
        ),
      ],
    );
  }
}

class _WeeklyHighlightsCard extends StatelessWidget {
  const _WeeklyHighlightsCard({required this.recap});

  final WeeklyRecap? recap;

  @override
  Widget build(BuildContext context) {
    final highlights = recap?.highlights ?? const [];

    final h1 = highlights.isNotEmpty ? highlights.first : null;
    final h2 = highlights.length > 1 ? highlights[1] : null;

    final highlight1 = h1 is RecapHighlight ? h1.text : (h1 is String ? h1 : 'Logged meals consistently this week.');
    const sub1 = 'Great logging habit!';

    final highlight2 = h2 is RecapHighlight ? h2.text : (h2 is String ? h2 : 'Tracking symptoms and food impacts.');
    const sub2 = 'Building your baseline!';

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.insightColor(const Color(0xFFF0FDF4)),
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: context.insightColor(const Color(0xFFDCFCE7))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.star, size: 15.w, color: const Color(0xFFD97706)),
                  Gap.w6,
                  Text(
                    'Weekly Highlights',
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                  ),
                ],
              ),
            ],
          ),
          Gap.h8,

          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: context.v2Theme.card,
                    borderRadius: BorderRadius.circular(14.w),
                    border: Border.all(color: context.insightColor(const Color(0xFFDCFCE7))),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(5.w),
                        decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                        child: Icon(LucideIcons.leaf, size: 12.w, color: const Color(0xFF15803D)),
                      ),
                      Gap.w8,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              highlight1,
                              style: TextStyle(
                                fontFamily: InsightV2Theme.fontFamily,
                                fontSize: 10.5.sp,
                                fontWeight: FontWeight.w700,
                                color: context.insightColor(const Color(0xFF0F172A)),
                                height: 1.2,
                              ),
                            ),
                            Gap.h2,
                            Text(
                              sub1,
                              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.sp, color: context.insightColor(const Color(0xFF64748B))),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Gap.w8,

              Expanded(
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: context.v2Theme.card,
                    borderRadius: BorderRadius.circular(14.w),
                    border: Border.all(color: context.insightColor(const Color(0xFFDCFCE7))),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(5.w),
                        decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                        child: Icon(LucideIcons.arrowDown, size: 12.w, color: const Color(0xFF15803D)),
                      ),
                      Gap.w8,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              highlight2,
                              style: TextStyle(
                                fontFamily: InsightV2Theme.fontFamily,
                                fontSize: 10.5.sp,
                                fontWeight: FontWeight.w700,
                                color: context.insightColor(const Color(0xFF0F172A)),
                                height: 1.2,
                              ),
                            ),
                            Gap.h2,
                            Text(
                              sub2,
                              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.sp, color: context.insightColor(const Color(0xFF64748B))),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeklyTopFoodsRow extends StatelessWidget {
  const _WeeklyTopFoodsRow({required this.data});

  final AIInsight data;

  @override
  Widget build(BuildContext context) {
    final topHealing =
        data.healingSummary?.foods.firstOrNull ??
        (data.healingFoods.isNotEmpty
            ? InsightFood(
                foodId: 'h_${data.healingFoods.first.name}',
                name: data.healingFoods.first.name,
                emoji: data.healingFoods.first.emoji,
                imageUrl: data.healingFoods.first.userImageUrl ?? data.healingFoods.first.imageUrl,
                effect: data.healingFoods.first.effect,
                impactLevel: 'high',
              )
            : null);

    final topTrigger =
        data.triggerSummary?.foods.firstOrNull ??
        (data.triggerFoods.isNotEmpty
            ? InsightFood(
                foodId: 't_${data.triggerFoods.first.name}',
                name: data.triggerFoods.first.name,
                emoji: data.triggerFoods.first.emoji,
                imageUrl: data.triggerFoods.first.userImageUrl ?? data.triggerFoods.first.imageUrl,
                effect: data.triggerFoods.first.effect,
                impactLevel: 'high',
              )
            : null);

    if (topHealing == null && topTrigger == null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: context.v2Theme.card,
          borderRadius: BorderRadius.circular(16.w),
          border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Top Foods',
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
            ),
            Gap.h4,
            Text(
              'No top supportive or trigger foods recorded yet for this week.',
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, color: context.insightColor(const Color(0xFF64748B))),
            ),
          ],
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Card: Top Healing Food
          if (topHealing != null) ...[
            Expanded(
              child: Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF102319) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(18.w),
                  border: Border.all(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.28) : const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(4.w),
                              decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
                              child: Icon(LucideIcons.arrowUp, size: 10.w, color: Colors.white),
                            ),
                            Gap.w4,
                            Expanded(
                              child: Text(
                                'Top Healing Food',
                                style: TextStyle(
                                  fontFamily: InsightV2Theme.fontFamily,
                                  fontSize: 11.5.sp,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Gap.h8,

                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.w),
                          child: CachedNetworkImage(imageUrl: topHealing.imageUrl ?? V2Kit.foodImageUrl(topHealing.name), height: 64.w, width: double.infinity, fit: BoxFit.cover),
                        ),
                        Gap.h6,

                        Text(
                          topHealing.name,
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                        ),
                        Gap.h2,
                        Text(
                          topHealing.effect ?? 'Supports gut health',
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: context.insightColor(const Color(0xFF64748B)), height: 1.15),
                        ),
                      ],
                    ),
                    Gap.h6,

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Observed',
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.w),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.18) : const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8.w),
                            border: Border.all(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.35) : const Color(0xFFBBF7D0), width: 0.8.w),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.leaf, size: 8.w, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)),
                              Gap.w2,
                              Text(
                                '${topHealing.impactLevel.isEmpty ? 'Observed' : topHealing.impactLevel.toUpperCase()} Impact',
                                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.sp, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (topHealing != null && topTrigger != null) Gap.w10,

          // Right Card: Top Trigger Food
          if (topTrigger != null) ...[
            Expanded(
              child: Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF231416) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(18.w),
                  border: Border.all(color: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.45) : const Color(0xFFFCA5A5), width: 1.2.w),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626)).withValues(alpha: isDark ? 0.08 : 0.04),
                      blurRadius: 10.w,
                      offset: Offset(0, 2.w),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(4.w),
                              decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
                              child: Icon(LucideIcons.triangleAlert, size: 10.w, color: Colors.white),
                            ),
                            Gap.w4,
                            Expanded(
                              child: Text(
                                'Top Trigger Food',
                                style: TextStyle(
                                  fontFamily: InsightV2Theme.fontFamily,
                                  fontSize: 11.5.sp,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? const Color(0xFFF87171) : const Color(0xFF991B1B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Gap.h8,

                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.w),
                          child: CachedNetworkImage(imageUrl: topTrigger.imageUrl ?? V2Kit.foodImageUrl(topTrigger.name), height: 64.w, width: double.infinity, fit: BoxFit.cover),
                        ),
                        Gap.h6,

                        Text(
                          topTrigger.name,
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                        ),
                        Gap.h2,
                        Text(
                          topTrigger.effect ?? 'Associated with discomfort',
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: context.insightColor(const Color(0xFF64748B)), height: 1.15),
                        ),
                      ],
                    ),
                    Gap.h6,

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Observed',
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.w),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.18) : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(8.w),
                            border: Border.all(color: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.35) : const Color(0xFFFECACA), width: 0.8.w),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.triangleAlert, size: 8.w, color: isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C)),
                              Gap.w2,
                              Text(
                                '${topTrigger.impactLevel.isEmpty ? 'Observed' : topTrigger.impactLevel.toUpperCase()} Impact',
                                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.sp, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _YourWeeklyInsightCard extends StatelessWidget {
  const _YourWeeklyInsightCard({required this.data});

  final AIInsight data;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final weeklyInsightText = data.weeklyRecap?.summary ?? data.healingGoal ?? data.topInsight?.description;
    final hasRealInsight = weeklyInsightText != null && weeklyInsightText.trim().isNotEmpty;
    final quoteText = hasRealInsight ? weeklyInsightText.trim() : 'Keep logging meals and symptoms to build your personalized weekly gut health trend.';

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF102319) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.28) : const Color(0xFFDCFCE7)),
        boxShadow: [BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF15803D).withValues(alpha: 0.05), blurRadius: 10.w, offset: Offset(0, 3.w))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.2) : const Color(0xFFDCFCE7), shape: BoxShape.circle),
                child: Icon(LucideIcons.quote, size: 13.w, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)),
              ),
              Gap.w8,
              Expanded(
                child: Text(
                  'Your Weekly Insight',
                  style: TextStyle(
                    fontFamily: InsightV2Theme.fontFamily,
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFFECFDF5) : const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          Gap.h10,

          // Quote Card Box
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0A1811) : Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(14.w),
              border: Border.all(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.16) : const Color(0xFFBBF7D0).withValues(alpha: 0.6)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '“',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 18.sp, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A), height: 1.1),
                ),
                Gap.w4,
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 2.w),
                    child: Text(
                      quoteText,
                      style: TextStyle(
                        fontFamily: InsightV2Theme.fontFamily,
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                Gap.w4,
                Text(
                  '”',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 18.sp, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A), height: 1.1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _V2TopInsightCard extends StatelessWidget {
  const _V2TopInsightCard({required this.insight, required this.topInsight, this.onTap});
  final AIInsight insight;
  final InsightSummary topInsight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final titleText = InsightValues.text(topInsight.title, fallback: 'Your food and symptom snapshot');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.w),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF6F67DD), Color(0xFF8B85EC), Color(0xFF9F98F4)]),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap ?? () => context.push(AppRoutes.smartInsightDetail, extra: insight),
          borderRadius: BorderRadius.circular(20.w),
          child: Padding(
            padding: EdgeInsets.fromLTRB(18.w, 16.w, 14.w, 16.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Column: Eyebrow, Main Headline Title, Pill CTA Button
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Top Insights & Trends',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 18.sp, fontWeight: FontWeight.w800, color: Colors.white, height: 1.15, letterSpacing: -0.4),
                      ),

                      Gap.h6,

                      // Line 2: Subtitle
                      Text(
                        titleText,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: InsightV2Theme.fontFamily,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.88),
                          height: 1.2,
                          letterSpacing: -0.2,
                        ),
                      ),

                      Gap.h16,

                      // Pill CTA Button
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 32.w,
                            height: 32.w,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: Center(
                              child: Icon(Icons.north_east_rounded, size: 16.w, color: const Color(0xFF6F67DD)),
                            ),
                          ),
                          Gap.w10,
                          Text(
                            'Explore',
                            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.4),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Gap.w5,

                // Right Illustration Graphic Element
                SizedBox(
                  width: 80.w,
                  height: 80.w,
                  child: Image.asset(
                    color: Colors.white,
                    AppAssets.appIconBg,
                    height: 80.w,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Container(
                      width: 70.w,
                      height: 70.w,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                      child: Icon(LucideIcons.sparkles, size: 36.w, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyPatternsCard extends StatelessWidget {
  const _EmptyPatternsCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white.withValues(alpha: 0.70) : const Color(0xFF64748B);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 20.w, 16.w, 24.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(28.w),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
        boxShadow: isDark
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4))]
            : [BoxShadow(color: const Color(0xFF17171B).withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Display Headline (Matching Chat Empty State UI/UX)
          Text(
            'Your meals.\nYour reactions.\nYour patterns.',
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 26.sp, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -0.5, color: primaryTextColor),
            textAlign: TextAlign.center,
          ),
          Gap.h12,

          // Subtitle Paragraph
          Text(
            'Keep logging your food scans and symptoms to discover recurring body patterns and tailored triggers.',
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 13.sp, fontWeight: FontWeight.w400, color: secondaryTextColor, height: 1.35),
            textAlign: TextAlign.center,
          ),
          Gap.h20,

          // 2-Column Action Cards (Scan Food & Track Symptoms)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSizes.p8,
            mainAxisSpacing: AppSizes.p8,
            childAspectRatio: 1.1,
            children: [
              _EmptyPatternActionCard(
                icon: AppIcons.scan,
                title: 'Scan food',
                subtitle: 'Log meals',
                accentColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                onTap: () => context.push(AppRoutes.scannerPath('meal')),
              ),
              _EmptyPatternActionCard(
                icon: AppIcons.heart,
                title: 'Track symptoms',
                subtitle: 'Record reactions',
                accentColor: isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
                onTap: () => context.push(AppRoutes.scannerPath('symptom')),
              ),
            ],
          ),
          Gap.h16,

          // Bottom Guidance Callout
          Container(
            padding: EdgeInsets.all(AppSizes.p14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(AppSizes.r20),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28.w,
                  height: 28.w,
                  decoration: BoxDecoration(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Icon(LucideIcons.lightbulb, size: 14.w, color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706)),
                ),
                Gap.w10,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Understanding Your Patterns',
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: primaryTextColor),
                      ),
                      Gap.h2,
                      Text(
                        'Body patterns emerge automatically as you log meals alongside symptoms over time. No guessing—just clear data.',
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: secondaryTextColor, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPatternActionCard extends StatelessWidget {
  const _EmptyPatternActionCard({required this.icon, required this.title, required this.subtitle, required this.accentColor, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(AppSizes.p12),
        decoration: BoxDecoration(
          color: scheme.cardBackground,
          borderRadius: BorderRadius.circular(AppSizes.r20),
          border: Border.all(color: scheme.borderSubtle),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Center(
                child: Icon(icon, size: 18.w, color: accentColor),
              ),
            ),
            Gap.h8,
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: scheme.textPrimary, height: 1.15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Gap.h2,
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: scheme.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
