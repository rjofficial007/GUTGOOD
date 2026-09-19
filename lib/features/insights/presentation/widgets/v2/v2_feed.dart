import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/features/insights/presentation/pages/action_detail_screen.dart';
import 'package:gutgood/features/insights/presentation/pages/better_swaps_screen.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_theme.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/v2_data.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/v2_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
  String _selectedTimeframe = 'Last 7 days';

  @override
  Widget build(BuildContext context) {
    final delta = V2Data.parseDelta(widget.data.scoreDiff);
    final improving = V2Data.improving(widget.data, widget.series, widget.history);
    final watch = V2Data.watch(widget.data, widget.patterns);

    final isPatternsTab = _selectedFilter == 'Patterns';
    final isFoodImpactTab = _selectedFilter == 'Food Impact';

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 28.w),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // 1. Top App Header & Filter Chips
          Gap.h10,
          _InsightsHeaderWidget(selectedFilter: _selectedFilter, onFilterSelected: (filter) => setState(() => _selectedFilter = filter)),
          Gap.h16,

          // -------------------------------------------------------------------
          // TAB: PATTERNS
          // -------------------------------------------------------------------
          if (isPatternsTab) ...[
            // Section Header: Detected Patterns + Timeframe Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detected Patterns',
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 14.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                    ),
                    Gap.h2,
                    Text(
                      'Recurring reactions your body shows.',
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  onSelected: (val) => setState(() => _selectedTimeframe = val),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'Last 7 days', child: Text('Last 7 days')),
                    PopupMenuItem(value: 'Last 30 days', child: Text('Last 30 days')),
                    PopupMenuItem(value: 'All Time', child: Text('All Time')),
                  ],
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.w),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _selectedTimeframe,
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                        ),
                        Gap.w4,
                        Icon(LucideIcons.chevronDown, size: 12.w, color: const Color(0xFF0F172A)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Gap.h10,

            // Detected Pattern Cards
            if (widget.patterns.isNotEmpty) ...[
              for (final pattern in widget.patterns) ...[
                _FiberSynergyHeroCard(
                  insight: widget.data,
                  pattern: pattern,
                  onTap: () => context.push(AppRoutes.fiberSynergyDetail, extra: pattern),
                ),
                Gap.h10,
              ],
            ] else ...[
              _FiberSynergyHeroCard(
                insight: widget.data,
                onTap: () => context.push(AppRoutes.fiberSynergyDetail, extra: widget.data),
              ),
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

            // 1. Food Impact Balance Hero Card
            _FoodImpactBalanceHeroCard(balance: widget.data.foodImpactBalance, foodImpacts: widget.data.foodImpacts),
            Gap.h10,

            // 2. Side-by-Side: Top Healing Foods & Top Trigger Food
            _SideBySideHealingAndTriggerCards(insight: widget.data),
            Gap.h10,

            // 3. Featured Insight Card: Fiber & Fermentation Synergy
            _FiberSynergyFeaturedCard(insight: widget.data),
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
            V2WeeklyRecapView(data: widget.data, series: widget.series, patterns: widget.patterns),
          ] else ...[
            // -------------------------------------------------------------------
            // TAB: FOR YOU
            // -------------------------------------------------------------------
            // HERO CARD: Gut Score & On Track
            Gap.h16,

            _GutScoreHeroCard(
              score: widget.data.gutScore.clamp(0, 100).toInt(),
              delta: delta ?? 4,
              onTap: () => context.push(AppRoutes.weeklyRecap, extra: widget.data),
            ),
            Gap.h16,

            if (_selectedFilter == 'For You') ...[
              // FEATURED PATTERN: Fiber & Fermentation Synergy
              _FiberSynergyHeroCard(
                insight: widget.data,
                pattern: widget.patterns.isNotEmpty ? widget.patterns.first : null,
                onTap: () => context.push(AppRoutes.fiberSynergyDetail, extra: widget.data),
              ),
              Gap.h16,

              // SIDE-BY-SIDE CARDS: What's Improving & Something to Watch
              _SideBySideImprovingAndWatch(
                improvingData: improving,
                series: widget.series.isEmpty ? const [74.0, 75.0, 76.0, 77.0, 78.0] : widget.series,
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
                onWatchTap: watch == null
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
                          chartValues: const [80.0, 70.0, 60.0, 50.0, 40.0],
                          footLeft: watch.windowLabel,
                          frequency: watch.pattern?.frequency != null ? '${watch.pattern!.frequency} occurrences' : watch.meta,
                          whyPoints: watch.pattern?.commonFactors.map((f) => f.label).toList() ?? const [],
                        ),
                      ),
              ),
              Gap.h10,

              // QUICK WIN: Try More Fermented Foods
              _QuickWinCard(onExploreTap: () => context.push(AppRoutes.foodIntelligence)),
              Gap.h20,
              // TOP FOODS THIS WEEK
              _TopFoodsSection(insight: widget.data),
              Gap.h10,
              // RECENT INSIGHTS
              _RecentInsightsSection(insight: widget.data, onViewAllTap: () => context.push(AppRoutes.insightHistory)),
            ],
          ],
        ]),
      ),
    );
  }
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
    const filters = ['For You', 'Patterns', 'Food Impact', 'Weekly Recap'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Gap.h8,

        // Filter Chips Bar
        SizedBox(
          height: 38.w,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: filters.length,
            separatorBuilder: (_, _) => Gap.w8,
            itemBuilder: (context, index) {
              final filter = filters[index];
              final isSelected = filter == selectedFilter;
              return GestureDetector(
                onTap: () => onFilterSelected(filter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
                  decoration: BoxDecoration(color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20.w)),
                  child: Center(
                    child: Text(
                      filter,
                      style: TextStyle(
                        fontFamily: InsightV2Theme.fontFamily,
                        fontSize: 12.5.sp,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF334155),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
    int pos = balance?.positivePercent ?? 70;
    int neu = balance?.neutralPercent ?? 20;
    int neg = balance?.negativePercent ?? 10;
    final periodLabel = balance?.periodLabel ?? 'Last 4 weeks';

    if (balance == null && foodImpacts.isNotEmpty) {
      int posCount = 0;
      int negCount = 0;
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

    final posRatio = pos / 100.0;
    final neuRatio = neu / 100.0;
    final negRatio = neg / 100.0;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.03), blurRadius: 8.w, offset: Offset(0, 2.w))],
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
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                  ),
                  Text(
                    'Your food choices over the $periodLabel.',
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: const Color(0xFF64748B)),
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
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 20.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), height: 1.0),
                        ),
                        Text(
                          'Positive',
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
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
                  decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(16.w)),
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
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), height: 1.2),
                      ),
                      Gap.h3,
                      Text(
                        "You're making gut-friendly choices $pos% of the time.",
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: const Color(0xFF334155), height: 1.25),
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
  Widget build(BuildContext context) {
    return Row(
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
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                ),
                Gap.w3,
                Text(
                  label,
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                ),
              ],
            ),
            Text(
              sub,
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.5.sp, color: const Color(0xFF64748B)),
            ),
          ],
        ),
      ],
    );
  }
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.w),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Healing & Trigger Foods',
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
            ),
            Gap.h4,
            Text(
              'No specific healing or trigger foods identified yet. Keep logging meals to discover foods that support or upset your gut.',
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, color: const Color(0xFF64748B)),
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
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(18.w),
                  border: Border.all(color: const Color(0xFFDCFCE7)),
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
                            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFF15803D)),
                          ),
                        ),
                      ],
                    ),
                    Gap.h2,
                    Text(
                      'Foods that support your gut health.',
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: const Color(0xFF475569)),
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
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(18.w),
                  border: Border.all(color: const Color(0xFFFEE2E2)),
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
                            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFF991B1B)),
                          ),
                        ),
                      ],
                    ),
                    Gap.h2,
                    Text(
                      'Food most associated with symptoms.',
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: const Color(0xFF475569)),
                    ),
                    Gap.h8,

                    Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.w)),
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
                                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), height: 1.1),
                                ),
                                Gap.h2,
                                Text(
                                  triggerList.first.effect ?? 'Associated with digestive discomfort',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.5.sp, color: const Color(0xFF475569), height: 1.15),
                                ),
                                Gap.h3,
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
                                  decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(6.w)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.triangleAlert, size: 7.w, color: const Color(0xFFB91C1C)),
                                      Gap.w2,
                                      Text(
                                        '${triggerList.first.impactLevel.toUpperCase()} Impact',
                                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.sp, fontWeight: FontWeight.w700, color: const Color(0xFFB91C1C)),
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
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.w)),
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
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                ),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.5.sp, color: const Color(0xFF475569), height: 1.15),
                ),
                SizedBox(height: 2.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
                  decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6.w)),
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
}

// =============================================================================
// FOOD IMPACT TAB: 3. FEATURED INSIGHT CARD (Fiber & Fermentation Synergy)
// =============================================================================
class _FiberSynergyFeaturedCard extends StatelessWidget {
  const _FiberSynergyFeaturedCard({required this.insight});

  final AIInsight insight;

  @override
  Widget build(BuildContext context) {
    final yogurtUrl = V2Kit.foodImageUrl('Greek Yogurt Berry Bowl');

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF5),
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: const Color(0xFFFDE6D8)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => context.push(AppRoutes.fiberSynergyDetail, extra: insight),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.barChart2, size: 15.w, color: const Color(0xFF15803D)),
                        Gap.w6,
                        Text(
                          'Fiber & Fermentation Synergy',
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.w),
                      decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(10.w)),
                      child: Text(
                        'Top Insight',
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w700, color: const Color(0xFF15803D)),
                      ),
                    ),
                  ],
                ),
                Gap.h4,
                Text(
                  'Consuming fermented foods alongside prebiotic fiber significantly reduces bloating episodes.',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: const Color(0xFF334155), height: 1.25),
                ),
                Gap.h8,

                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          _StatPill(icon: LucideIcons.barChart2, title: '92%', sub: 'Evidence ratio', color: const Color(0xFF15803D)),
                          Gap.w8,
                          _StatPill(icon: LucideIcons.thumbsUp, title: '5', sub: 'Positive instances', color: const Color(0xFF15803D)),
                          Gap.w8,
                          _StatPill(icon: LucideIcons.thumbsDown, title: '0', sub: 'Negative instances', color: const Color(0xFFDC2626)),
                        ],
                      ),
                    ),
                    Gap.w8,

                    SizedBox(
                      width: 76.w,
                      height: 52.w,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10.w),
                            child: CachedNetworkImage(imageUrl: yogurtUrl, width: 76.w, height: 52.w, fit: BoxFit.cover),
                          ),
                          Positioned(
                            right: 4.w,
                            bottom: 4.w,
                            child: Text(
                              "Better\ntogether ♡",
                              textAlign: TextAlign.right,
                              style: TextStyle(fontFamily: 'serif', fontStyle: FontStyle.italic, fontSize: 8.5.sp, color: const Color(0xFF15803D), height: 1.1),
                            ),
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
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.title, required this.sub, required this.color});

  final IconData icon;
  final String title;
  final String sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 10.w, color: color),
            Gap.w3,
            Text(
              title,
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
            ),
          ],
        ),
        Text(
          sub,
          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.5.sp, color: const Color(0xFF64748B)),
        ),
      ],
    );
  }
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.w),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.clock, size: 15.w, color: const Color(0xFF0F172A)),
                Gap.w6,
                Text(
                  'Recent Food Impacts',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                ),
              ],
            ),
            Gap.h4,
            Text(
              'No recent food impacts recorded yet. Log your meals to see how specific foods affect your gut.',
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, color: const Color(0xFF64748B)),
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
                Icon(LucideIcons.clock, size: 15.w, color: const Color(0xFF0F172A)),
                Gap.w6,
                Text(
                  'Recent Food Impacts',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                ),
              ],
            ),
            Text(
              'View All →',
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
            ),
          ],
        ),
        Gap.h8,

        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.w),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < impacts.take(4).length; i++) ...[
                if (i > 0) Divider(height: 12.w, color: const Color(0xFFF1F5F9)),
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
  Widget build(BuildContext context) {
    return Row(
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
                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
              ),
              Text(
                sub,
                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: const Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Icon(isPositive ? LucideIcons.leaf : LucideIcons.triangleAlert, size: 10.w, color: isPositive ? const Color(0xFF15803D) : const Color(0xFFB91C1C)),
            Gap.w3,
            Text(
              status,
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
            ),
          ],
        ),
        Gap.w8,
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.w),
          decoration: BoxDecoration(color: isPositive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8.w)),
          child: Text(
            isPositive ? 'Positive' : 'Negative',
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.sp, fontWeight: FontWeight.w700, color: isPositive ? const Color(0xFF15803D) : const Color(0xFFB91C1C)),
          ),
        ),
      ],
    );
  }
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.w),
          border: Border.all(color: const Color(0xFFE2E8F0)),
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
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                ),
              ],
            ),
            Gap.h4,
            Text(
              'No action steps recommended right now. Continue logging meals and symptoms to receive personalized guidance.',
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, color: const Color(0xFF64748B)),
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
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                ),
              ],
            ),
            Text(
              'See All →',
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
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
                  child: _NextStepCard(
                    icon: i == 0 ? LucideIcons.leaf : LucideIcons.milk,
                    title: actions[i].title,
                    sub: actions[i].description,
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ActionDetailScreen(action: actions[i])));
                    },
                  ),
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
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.w),
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(16.w),
          border: Border.all(color: const Color(0xFFDCFCE7)),
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
                    Container(
                      width: 20.w,
                      height: 20.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFDCFCE7)),
                      ),
                      child: Icon(Icons.arrow_forward_rounded, size: 10.w, color: const Color(0xFF15803D)),
                    ),
                  ],
                ),
                Gap.h6,
                Text(
                  title,
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), height: 1.2),
                ),
                Gap.h3,
                Text(
                  sub,
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: const Color(0xFF475569), height: 1.25),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// PATTERNS TAB: BOTTOM SMARTER BANNER CARD
// =============================================================================
class _PatternsSmarterBannerCard extends StatelessWidget {
  const _PatternsSmarterBannerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: const Color(0xFFDCFCE7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Bottom-right leaf illustration
          Positioned(
            right: -2.w,
            bottom: -2.w,
            child: CustomPaint(size: Size(48.w, 56.w), painter: const _CardLeafPainter()),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.w),
            child: Row(
              children: [
                // Left Icon Box
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12.w)),
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
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 13.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                      ),
                      Gap.h2,
                      Text(
                        'The more you log, the more personalized your insights become. Keep tracking to unlock deeper insights!',
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: const Color(0xFF475569), height: 1.25),
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

// =============================================================================
// HERO 1: GUT SCORE & ON TRACK CARD
// =============================================================================
class _GutScoreHeroCard extends StatelessWidget {
  const _GutScoreHeroCard({required this.score, required this.delta, this.onTap});

  final int score;
  final int delta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    borderRadius: BorderRadius.circular(24.w),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24.w),
      child: Row(
        children: [
          // Left: Circular Arc Score Gauge
          SizedBox(
            width: 115.w,
            height: 115.w,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(115.w, 115.w),
                  painter: _GutScoreArcPainter(score: score),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Gut Score',
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                    ),
                    Gap.h2,
                    Text(
                      '$score',
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 28.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), height: 1.0),
                    ),
                    Gap.h2,
                    Text(
                      delta >= 0 ? '+$delta' : '$delta',
                      style: TextStyle(
                        fontFamily: InsightV2Theme.fontFamily,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: delta >= 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                        height: 1.0,
                      ),
                    ),
                    Text(
                      'vs last week',
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.sp, fontWeight: FontWeight.w500, color: const Color(0xFF475569)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Vertical Divider Line
          Container(
            width: 1,
            height: 80.w,
            margin: EdgeInsets.symmetric(horizontal: 14.w),
            color: const Color(0xFFE2E8F0),
          ),

          // Right: On Track Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.w),
                  decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(20.w)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.leaf, size: 12.w, color: const Color(0xFF15803D)),
                      Gap.w4,
                      Text(
                        'On track',
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w700, color: const Color(0xFF15803D)),
                      ),
                    ],
                  ),
                ),
                Gap.h8,
                Text(
                  'Your gut health is improving with better food choices and more fermented foods!',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A), height: 1.35),
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
// HERO 2: FIBER & FERMENTATION SYNERGY PATTERN CARD (Compact Layout)
// =============================================================================
class _FiberSynergyHeroCard extends StatelessWidget {
  const _FiberSynergyHeroCard({required this.insight, this.pattern, this.onTap});

  final AIInsight insight;
  final BodyPattern? pattern;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final trigger = pattern?.trigger.trim() ?? '';
    final reaction = pattern?.reaction.trim() ?? '';
    final title = (trigger.isNotEmpty || reaction.isNotEmpty)
        ? ((trigger.isNotEmpty && reaction.isNotEmpty) ? '$trigger → $reaction' : (trigger.isNotEmpty ? trigger : reaction))
        : (pattern?.description.isNotEmpty == true ? pattern!.description : 'Fiber & Fermentation Synergy');

    final sub = pattern?.description.isNotEmpty == true
        ? pattern!.description
        : (insight.healingGoal?.isNotEmpty == true ? insight.healingGoal! : 'Fermented foods + prebiotic fiber significantly reduce bloating episodes.');

    final imageUrl = V2Kit.foodImageUrl(pattern?.involvedFoods.isNotEmpty == true ? pattern!.involvedFoods.first : 'Greek Yogurt Berry Bowl');

    final confidenceLabel = pattern != null && pattern!.confidence.isNotEmpty
        ? (pattern!.confidence.toLowerCase().contains('confidence') ? pattern!.confidence : '${pattern!.confidence} Confidence')
        : 'High Confidence';

    final (tagLabel, tagIcon, tagBg, tagFg) = _tagStyle(pattern);

    return Container(
      height: 160.w,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF5),
        borderRadius: BorderRadius.circular(20.w),
        boxShadow: [BoxShadow(color: const Color(0xFF17171B).withValues(alpha: 0.04), blurRadius: 8.w, offset: Offset(0, 2.w))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              // 1. Right Side Food Photo
              Positioned.fill(
                child: Row(
                  children: [
                    const Spacer(flex: 4),
                    Expanded(
                      flex: 4,
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        placeholder: (_, _) => Container(color: const Color(0xFFF1F5F9)),
                        errorWidget: (_, _, _) => Container(
                          color: const Color(0xFFFED7AA),
                          child: const Icon(LucideIcons.utensils, color: Color(0xFF9A3412)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Left Cream Angled Background Container
              Positioned.fill(
                child: ClipPath(
                  clipper: const _AngledCardClipper(),
                  child: Container(color: const Color(0xFFFFFDF7)),
                ),
              ),

              // 3. Green Leaf Branch Illustration near bottom center
              Positioned(
                left: 140.w,
                bottom: -2.w,
                child: CustomPaint(size: Size(44.w, 52.w), painter: const _CardLeafPainter()),
              ),

              // 4. Left Content Column
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 190.w,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12.w, 10.w, 6.w, 10.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Tag Pill
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.w),
                            decoration: BoxDecoration(color: tagBg, borderRadius: BorderRadius.circular(16.w)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(tagIcon, size: 11.w, color: tagFg),
                                Gap.w4,
                                Text(
                                  tagLabel,
                                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: tagFg),
                                ),
                              ],
                            ),
                          ),
                          Gap.h6,

                          // Title
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 15.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), height: 1.15, letterSpacing: -0.3),
                          ),
                          Gap.h3,

                          // Subtitle
                          Text(
                            sub,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w500, color: const Color(0xFF334155), height: 1.25),
                          ),
                        ],
                      ),

                      // View Details Pill Button
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFDF9),
                          borderRadius: BorderRadius.circular(20.w),
                          border: Border.all(color: const Color(0xFFE5DCD0), width: 1.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View Details',
                              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                            ),
                            Gap.w4,
                            Icon(Icons.arrow_forward_rounded, size: 12.w, color: const Color(0xFF0F172A)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. High Confidence Dark Forest Green Badge on bottom-right of image
              Positioned(
                right: 8.w,
                bottom: 8.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF024A2B),
                    borderRadius: BorderRadius.circular(16.w),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6.w, offset: Offset(0, 2.w))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.shieldCheck, size: 11.w, color: Colors.white),
                      Gap.w4,
                      Text(
                        confidenceLabel,
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      Gap.w3,
                      Icon(Icons.arrow_forward_rounded, size: 10.w, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static (String, IconData, Color, Color) _tagStyle(BodyPattern? pattern) {
    if (pattern == null || pattern.type.trim().isEmpty) {
      return ('Pattern', LucideIcons.leaf, const Color(0xFFFDE6D8), const Color(0xFF7C2D12));
    }
    final rawType = pattern.type.trim();
    final t = rawType.toLowerCase();
    final label = rawType[0].toUpperCase() + rawType.substring(1);

    return switch (t) {
      'bloating' => ('Bloating', LucideIcons.leaf, const Color(0xFFFDE6D8), const Color(0xFF7C2D12)),
      'digestion' || 'digestive' => ('Digestion', LucideIcons.leaf, const Color(0xFFFDE6D8), const Color(0xFF7C2D12)),
      'energy' => (label, LucideIcons.zap, const Color(0xFFFEF3C7), const Color(0xFF92400E)),
      'headache' => (label, LucideIcons.activity, const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
      'fullness' => (label, LucideIcons.activity, const Color(0xFFFDE6D8), const Color(0xFF7C2D12)),
      'sleep' => (label, LucideIcons.moon, const Color(0xFFE0E7FF), const Color(0xFF3730A3)),
      'healing' => (label, LucideIcons.sparkles, const Color(0xFFDCFCE7), const Color(0xFF15803D)),
      'trigger' => (label, LucideIcons.alertTriangle, const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
      _ => (label, LucideIcons.leaf, const Color(0xFFFDE6D8), const Color(0xFF7C2D12)),
    };
  }
}

class _AngledCardClipper extends CustomClipper<Path> {
  const _AngledCardClipper();

  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, 0)
    ..lineTo(size.width * 0.61, 0)
    ..lineTo(size.width * 0.51, size.height)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _CardLeafPainter extends CustomPainter {
  const _CardLeafPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = const Color(0xFF86EFAC).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final stemPaint = Paint()
      ..color = const Color(0xFF22C55E).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.2, size.height);
    path.quadraticBezierTo(size.width * 0.4, size.height * 0.5, size.width * 0.7, 0);
    canvas.drawPath(path, stemPaint);

    void drawLeaf(Offset center, double angle, double scale) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      final leafPath = Path();
      leafPath.moveTo(0, 0);
      leafPath.quadraticBezierTo(12 * scale, -8 * scale, 22 * scale, 0);
      leafPath.quadraticBezierTo(12 * scale, 8 * scale, 0, 0);
      canvas.drawPath(leafPath, fillPaint);
      canvas.restore();
    }

    drawLeaf(Offset(size.width * 0.7, size.height * 0.1), -0.5, 0.9);
    drawLeaf(Offset(size.width * 0.5, size.height * 0.4), 0.6, 1.0);
    drawLeaf(Offset(size.width * 0.3, size.height * 0.7), -0.4, 0.8);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Left Card: What's Improving
          Expanded(
            child: _ImprovingCardWidget(data: improvingData, series: series, onTap: onImprovingTap),
          ),
          Gap.w4,

          // 2. Right Card: Something to Watch
          Expanded(
            child: _WatchCardWidget(data: watchData, onTap: onWatchTap),
          ),
        ],
      ),
    );
  }
}

class _ImprovingCardWidget extends StatelessWidget {
  const _ImprovingCardWidget({required this.data, required this.series, this.onTap});

  final V2ImprovingData data;
  final List<double> series;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final startVal = series.isNotEmpty ? series.first.round() : 74;
    final endVal = series.isNotEmpty ? series.last.round() : 78;

    final headline = data.headline.isNotEmpty ? data.headline : 'Your gut barrier score is up!';
    final description = data.description.isNotEmpty ? data.description : 'Consistent vegetable fiber intake is making a real difference.';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF2),
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: const Color(0xFFDCFCE7)),
        boxShadow: [BoxShadow(color: const Color(0xFF17171B).withValues(alpha: 0.03), blurRadius: 6.w, offset: Offset(0, 2.w))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.w),
          child: Stack(
            children: [
              // Bottom Right Leaf Branch Decoration
              Positioned(
                right: -4.w,
                bottom: -4.w,
                child: CustomPaint(size: Size(44.w, 44.w), painter: const _CardLeafPainter()),
              ),
              Padding(
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
                              decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
                              child: Center(
                                child: Icon(Icons.arrow_upward_rounded, size: 14.w, color: Colors.white),
                              ),
                            ),
                            Gap.w6,
                            Expanded(
                              child: Text(
                                "What's Improving",
                                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: const Color(0xFF14532D)),
                              ),
                            ),
                          ],
                        ),
                        Gap.h8,

                        // Headline
                        Text(
                          headline,
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: const Color(0xFF14532D), height: 1.2),
                        ),
                        Gap.h3,

                        // Description
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: const Color(0xFF334155), height: 1.25),
                        ),
                        Gap.h8,

                        // Trend Area Chart
                        SizedBox(
                          height: 38.w,
                          width: double.infinity,
                          child: CustomPaint(painter: _ImprovingAreaChartPainter(values: series)),
                        ),
                        Gap.h2,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$startVal',
                                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFF14532D), height: 1.0),
                                ),
                                Text(
                                  'Last week',
                                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.5.sp, color: const Color(0xFF15803D)),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$endVal',
                                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFF14532D), height: 1.0),
                                ),
                                Text(
                                  'This week',
                                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.5.sp, color: const Color(0xFF15803D)),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.w),
                        border: Border.all(color: const Color(0xFFDCFCE7)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'See Details',
                            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                          ),
                          Gap.w4,
                          Icon(Icons.arrow_forward_rounded, size: 12.w, color: const Color(0xFF0F172A)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
    final title = data?.title.isNotEmpty == true ? data!.title : 'Fried Foods → Bloating';
    final desc = data?.description.isNotEmpty == true ? data!.description : 'Fried and heavily processed foods consistently precede bloating by 2 hours.';

    final thumbnails = [V2Kit.foodImageUrl('Fried Onion Rings'), V2Kit.foodImageUrl('French Fries'), V2Kit.foodImageUrl('Burger')];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: const Color(0xFFFEE2E2)),
        boxShadow: [BoxShadow(color: const Color(0xFF17171B).withValues(alpha: 0.03), blurRadius: 6.w, offset: Offset(0, 2.w))],
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(20.w),
        child: InkWell(
          onTap:
              onTap ??
              () {
                final swapObj = FoodSwap(
                  id: 'swap_watch',
                  source: SwapSource(foodId: 'food_trigger', name: title),
                  alternatives: [SwapAlternative(foodId: 'food_alt_01', name: data?.swapAfter ?? 'Roasted Vegetables', reason: data?.swapTip ?? 'Lower in added frying fat and easier to digest.')],
                );
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => BetterSwapsScreen(swap: swapObj)));
              },
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
                            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: const Color(0xFF881337)),
                          ),
                        ),
                      ],
                    ),
                    Gap.h8,

                    // Headline
                    Text(
                      title,
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), height: 1.2),
                    ),
                    Gap.h3,

                    // Description
                    Text(
                      desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: const Color(0xFF334155), height: 1.25),
                    ),
                    Gap.h8,

                    // 3 Food Thumbnails
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
                              placeholder: (_, _) => Container(color: const Color(0xFFFEE2E2)),
                              errorWidget: (_, _, _) => Container(
                                color: const Color(0xFFFECDD3),
                                child: const Icon(LucideIcons.utensils, size: 14, color: Color(0xFF881337)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Gap.h6,

                    // High Frequency Badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.w),
                      decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12.w)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.target, size: 10.w, color: const Color(0xFF881337)),
                          Gap.w3,
                          Text(
                            'High Frequency',
                            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.sp, fontWeight: FontWeight.w700, color: const Color(0xFF881337)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Gap.h8,

                // Bottom Row: See Details Button + Cursive Script Text
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.w),
                        border: Border.all(color: const Color(0xFFFEE2E2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'See Details',
                            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                          ),
                          Gap.w4,
                          Icon(Icons.arrow_forward_rounded, size: 12.w, color: const Color(0xFF0F172A)),
                        ],
                      ),
                    ),
                  ],
                ),
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
    final List<_FoodItemData> foodItems = [];

    if (insight.healingSummary?.foods.isNotEmpty == true) {
      for (final f in insight.healingSummary!.foods) {
        foodItems.add(_FoodItemData(f.name, 'Frequent', '${f.impactLevel.toUpperCase()} Impact', f.imageUrl ?? V2Kit.foodImageUrl(f.name)));
      }
    } else if (insight.healingFoods.isNotEmpty) {
      for (final f in insight.healingFoods) {
        foodItems.add(_FoodItemData(f.name, 'Active', 'Supportive', f.userImageUrl ?? f.imageUrl ?? V2Kit.foodImageUrl(f.name)));
      }
    } else {
      for (final f in insight.foodImpacts.where((i) => i.impactType == 'positive')) {
        foodItems.add(_FoodItemData(f.food, f.dateLabel, 'Positive', f.userImageUrl ?? f.imageUrl ?? V2Kit.foodImageUrl(f.food)));
      }
    }

    if (foodItems.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.w),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Foods This Week',
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
            ),
            Gap.h4,
            Text(
              'No top supportive foods recorded yet. Continue logging meals to see your gut-friendly choices.',
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, color: const Color(0xFF64748B)),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top Foods This Week',
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                    ),
                    Text(
                      'These foods are supporting your gut health.',
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
            GestureDetector(
              onTap: () => context.push(AppRoutes.foodIntelligence),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View All',
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                  ),
                  Gap.w3,
                  Icon(Icons.arrow_forward_rounded, size: 12.w, color: const Color(0xFF0F172A)),
                ],
              ),
            ),
          ],
        ),
        Gap.h10,

        // 4 Compact Food Cards Row
        SizedBox(
          height: 122.w,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: foodItems.length,
            separatorBuilder: (_, _) => Gap.w8,
            itemBuilder: (context, index) {
              final item = foodItems[index];
              return GestureDetector(
                onTap: () => context.push(AppRoutes.foodIntelligence),
                child: Container(
                  width: 100.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.w),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(12.w), topRight: Radius.circular(12.w)),
                        child: CachedNetworkImage(
                          imageUrl: item.imageUrl,
                          height: 50.w,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(color: const Color(0xFFF1F5F9)),
                          errorWidget: (_, _, _) => Container(color: const Color(0xFFE2E8F0)),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(5.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                            ),
                            Gap.h2,
                            Text(
                              item.frequency,
                              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                            ),
                            Gap.h2,
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
                              decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8.w)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.leaf, size: 8.w, color: const Color(0xFF15803D)),
                                  Gap.w2,
                                  Expanded(
                                    child: Text(
                                      item.badge,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.sp, fontWeight: FontWeight.w700, color: const Color(0xFF15803D)),
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
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FoodItemData {
  const _FoodItemData(this.title, this.frequency, this.badge, this.imageUrl);
  final String title;
  final String frequency;
  final String badge;
  final String imageUrl;
}

// =============================================================================
// HERO 5: QUICK WIN CARD ("Try More Fermented Foods" - Compact Layout)
// =============================================================================
class _QuickWinCard extends StatelessWidget {
  const _QuickWinCard({this.onExploreTap});

  final VoidCallback? onExploreTap;

  @override
  Widget build(BuildContext context) {
    final smoothieUrl = V2Kit.foodImageUrl('Green Smoothie Lime');

    return Container(
      height: 120.w,
      decoration: BoxDecoration(
        color: const Color(0xFFEFFDF5),
        borderRadius: BorderRadius.circular(18.w),
        boxShadow: [BoxShadow(color: const Color(0xFF16A34A).withValues(alpha: 0.04), blurRadius: 6.w, offset: Offset(0, 2.w))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            // 1. Left Angled Image (Positioned to left section width)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 115.w,
              child: ClipPath(
                clipper: const _LeftAngledImageClipper(),
                child: CachedNetworkImage(
                  imageUrl: smoothieUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  placeholder: (_, _) => Container(color: const Color(0xFFDCFCE7)),
                  errorWidget: (_, _, _) => Container(color: const Color(0xFF86EFAC)),
                ),
              ),
            ),

            // 2. Bottom Right Leaf Branch Decoration
            Positioned(
              right: -4.w,
              bottom: -4.w,
              child: CustomPaint(size: Size(48.w, 56.w), painter: const _CardLeafPainter()),
            ),

            // 4. Right Content Area
            Positioned(
              left: 120.w,
              top: 0,
              bottom: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.fromLTRB(6.w, 10.w, 10.w, 10.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Tag Pill
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.w),
                          decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(14.w)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.zap, size: 10.w, color: const Color(0xFF166534)),
                              Gap.w3,
                              Text(
                                'Quick Win',
                                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w700, color: const Color(0xFF166534)),
                              ),
                            ],
                          ),
                        ),
                        Gap.h4,

                        // Title
                        Text(
                          'Try more fermented foods',
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), height: 1.15, letterSpacing: -0.3),
                        ),
                        Gap.h2,

                        // Subtitle
                        Text(
                          'Add kefir, yogurt or kimchi to your meals\nfor better gut balance.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w500, color: const Color(0xFF334155), height: 1.2),
                        ),
                      ],
                    ),

                    // Explore Foods Dark Pill Button
                    GestureDetector(
                      onTap: onExploreTap,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.w),
                        decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(18.w)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Explore Foods',
                              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            Gap.w4,
                            Icon(Icons.arrow_forward_rounded, size: 11.w, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeftAngledImageClipper extends CustomClipper<Path> {
  const _LeftAngledImageClipper();

  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width * 0.82, size.height)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// =============================================================================
// HERO 6: RECENT INSIGHTS SECTION
// =============================================================================
class _RecentInsightsSection extends StatelessWidget {
  const _RecentInsightsSection({required this.insight, this.onViewAllTap});

  final AIInsight insight;
  final VoidCallback? onViewAllTap;

  @override
  Widget build(BuildContext context) {
    final recentList = insight.recentInsights;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(LucideIcons.clock, size: 11.w, color: const Color(0xFF0F172A)),
                Gap.w8,
                Text(
                  'Recent Insights',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                ),
              ],
            ),
            GestureDetector(
              onTap: onViewAllTap,
              child: Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                  ),
                  Gap.w2,
                  Icon(Icons.arrow_forward_rounded, size: 13.w, color: const Color(0xFF0F172A)),
                ],
              ),
            ),
          ],
        ),
        Gap.h12,

        if (recentList.isNotEmpty) ...[
          for (var i = 0; i < recentList.take(3).length; i++) ...[if (i > 0) Gap.h8, _RecentInsightCard(item: recentList[i])],
        ] else if (insight.topInsight != null) ...[
          _RecentInsightCard(
            item: RecentInsightItem(
              id: 'top_ins',
              title: insight.topInsight!.title,
              description: insight.topInsight!.description,
              kind: insight.topInsight!.type,
              date: 'Latest',
              dateLabel: 'Latest',
              imageUrl: V2Kit.foodImageUrl(insight.topInsight!.involvedFoods.firstOrNull ?? insight.topInsight!.title),
            ),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.w),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No recent insights yet',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                ),
                Gap.h4,
                Text(
                  'Insights and pattern discoveries will appear here as you log meals and symptoms.',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _RecentInsightCard extends StatelessWidget {
  const _RecentInsightCard({required this.item});

  final RecentInsightItem item;

  @override
  Widget build(BuildContext context) {
    final imgUrl = item.imageUrl ?? V2Kit.foodImageUrl(item.title);

    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.w),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8.w, offset: Offset(0, 2.w))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.w),
            child: CachedNetworkImage(
              imageUrl: imgUrl,
              width: 54.w,
              height: 54.w,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(color: const Color(0xFFF1F5F9)),
              errorWidget: (_, _, _) => Container(color: const Color(0xFFE2E8F0)),
            ),
          ),
          Gap.w12,

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.scanLine, size: 11.w, color: const Color(0xFF15803D)),
                    Gap.w3,
                    Text(
                      item.kind ?? 'Discovery',
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w700, color: const Color(0xFF15803D)),
                    ),
                  ],
                ),
                Gap.h2,
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                ),
                if (item.description.isNotEmpty) ...[
                  Gap.h2,
                  Text(
                    item.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: const Color(0xFF64748B)),
                  ),
                ],
              ],
            ),
          ),

          if (item.date.isNotEmpty) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.date,
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                ),
                Gap.h4,
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.w),
                  decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(10.w)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.leaf, size: 9.w, color: const Color(0xFF15803D)),
                      Gap.w3,
                      Text(
                        'Observed',
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w700, color: const Color(0xFF15803D)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// CUSTOM PAINTERS
// =============================================================================
class _GutScoreArcPainter extends CustomPainter {
  const _GutScoreArcPainter({required this.score});
  final int score;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = 9.w;
    final radius = (size.width - strokeWidth) / 2;

    const startAngle = 135 * math.pi / 180;
    const totalSweep = 270 * math.pi / 180;

    // Background Arc
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFEFEBE4);

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, totalSweep, false, trackPaint);

    // Active Arc Gradient
    final clampedScore = score.clamp(0, 100);
    final activeSweep = totalSweep * (clampedScore / 100);

    final rect = Rect.fromCircle(center: center, radius: radius);
    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + totalSweep,
        colors: const [Color(0xFF047857), Color(0xFF10B981), Color(0xFFA3E635), Color(0xFFFDE047)],
        stops: const [0.0, 0.45, 0.8, 1.0],
      ).createShader(rect);

    canvas.drawArc(rect, startAngle, activeSweep, false, activePaint);
  }

  @override
  bool shouldRepaint(covariant _GutScoreArcPainter oldDelegate) => oldDelegate.score != score;
}

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

class _ImprovingAreaChartPainter extends CustomPainter {
  const _ImprovingAreaChartPainter({required this.values});
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final points = <Offset>[];
    final minVal = values.reduce(math.min);
    final maxVal = values.reduce(math.max);
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    for (var i = 0; i < values.length; i++) {
      final x = (size.width / (values.length - 1)) * i;
      final normalizedY = (values[i] - minVal) / range;
      final y = size.height - (normalizedY * (size.height * 0.5) + size.height * 0.25);
      points.add(Offset(x, y));
    }

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    // Gradient Fill below line
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF22C55E).withValues(alpha: 0.25), const Color(0xFF22C55E).withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = const Color(0xFF22C55E);

    canvas.drawPath(path, linePaint);

    // Data Point Dots
    final dotPaint = Paint()..color = const Color(0xFF16A34A);
    final innerDotPaint = Paint()..color = Colors.white;

    for (final p in points) {
      canvas.drawCircle(p, 3.5, dotPaint);
      canvas.drawCircle(p, 1.8, innerDotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ImprovingAreaChartPainter oldDelegate) => true;
}

// =============================================================================
// WEEKLY RECAP TAB VIEW (Matches image_preview_-898749313.png - Compact Layout)
// =============================================================================
class V2WeeklyRecapView extends StatelessWidget {
  const V2WeeklyRecapView({super.key, required this.data, this.series = const [], this.patterns = const []});

  final AIInsight data;
  final List<double> series;
  final List<BodyPattern> patterns;

  @override
  Widget build(BuildContext context) {
    final recap = data.weeklyRecap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Average Gut Score Card
        _AverageGutScoreCard(data: data, series: series),
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

class _AverageGutScoreCard extends StatelessWidget {
  const _AverageGutScoreCard({required this.data, required this.series});

  final AIInsight data;
  final List<double> series;

  @override
  Widget build(BuildContext context) {
    final recap = data.weeklyRecap;
    final avgScore = (recap?.avgScore != null && recap!.avgScore! > 0) ? recap.avgScore! : (data.gutScore > 0 ? data.gutScore : 78);
    final scoreDiff = data.scoreDiff?.isNotEmpty == true ? data.scoreDiff! : '+12';
    final dateRange = (recap?.dateRange != null && recap!.dateRange!.isNotEmpty) ? recap.dateRange! : 'Sep 08 - Sep 14';
    final subText = (recap?.scoreSub != null && recap!.scoreSub!.isNotEmpty) ? recap.scoreSub! : 'Great improvement in fiber intake and probiotic diversity!';

    final dayScores = series.length >= 7 ? series.sublist(series.length - 7) : const [72.0, 74.0, 76.0, 80.0, 82.0, 78.0, 78.0];
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(5.w),
                  decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                  child: Icon(LucideIcons.trophy, size: 12.w, color: const Color(0xFF15803D)),
                ),
                Gap.w6,
                Text(
                  'Average Gut Score',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFF15803D)),
                ),
              ],
            ),
            Text(
              dateRange,
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
            ),
          ],
        ),
        Gap.h10,

        // Body Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Gauge Arc Circle
            SizedBox(
              width: 115.w,
              height: 115.w,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size(115.w, 115.w),
                    painter: _GutScoreArcPainter(score: avgScore),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Gut Score',
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                      ),
                      Text(
                        '$avgScore',
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 30.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), height: 1.0),
                      ),
                      Gap.h2,
                      Text(
                        scoreDiff.startsWith('+') || scoreDiff.startsWith('-') ? scoreDiff : '+$scoreDiff',
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: const Color(0xFF16A34A), height: 1.0),
                      ),
                      Text(
                        'vs last week',
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.sp, fontWeight: FontWeight.w500, color: const Color(0xFF475569)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Gap.w10,

            // Middle Column: Banner + 7-Day Bar Chart
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subText,
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A), height: 1.2),
                  ),

                  // Bar chart
                  SizedBox(
                    height: 60.w,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < dayScores.length; i++) ...[_WeeklyBarItem(score: dayScores[i].round(), label: dayLabels[i % dayLabels.length], maxScore: 100)],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WeeklyBarItem extends StatelessWidget {
  const _WeeklyBarItem({required this.score, required this.label, this.maxScore = 100});

  final int score;
  final String label;
  final int maxScore;

  @override
  Widget build(BuildContext context) {
    final heightRatio = (score / maxScore).clamp(0.2, 1.0);
    const barMaxHeight = 40.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$score',
          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
        ),
        Gap.h2,
        Container(
          width: 8.w,
          height: barMaxHeight.w * heightRatio,
          decoration: BoxDecoration(color: const Color(0xFF22C55E), borderRadius: BorderRadius.circular(10.w)),
        ),
        Gap.h2,
        Text(
          label,
          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.sp, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
        ),
      ],
    );
  }
}

class _WeeklyRecapStatCardsRow extends StatelessWidget {
  const _WeeklyRecapStatCardsRow({required this.recap, required this.data});

  final WeeklyRecap? recap;
  final AIInsight data;

  @override
  Widget build(BuildContext context) {
    final bestDay = (recap?.bestDay != null && recap!.bestDay!.isNotEmpty) ? recap!.bestDay! : 'Sep 11';
    final foodsLogged = recap?.foodsLogged ?? 21;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Best Day Card
          Expanded(
            child: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16.w),
                border: Border.all(color: const Color(0xFFDCFCE7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                        child: Icon(LucideIcons.calendar, size: 11.w, color: const Color(0xFF15803D)),
                      ),
                      Gap.w4,
                      Expanded(
                        child: Text(
                          'Best Day',
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w700, color: const Color(0xFF15803D)),
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
                              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 16.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), height: 1.1),
                            ),
                            Gap.h2,
                            Text(
                              'Highest score (82)',
                              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.5.sp, color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      Icon(LucideIcons.leaf, size: 20.w, color: const Color(0xFF86EFAC).withValues(alpha: 0.7)),
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
                color: const Color(0xFFFFFBF5),
                borderRadius: BorderRadius.circular(16.w),
                border: Border.all(color: const Color(0xFFFFEDD5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: const BoxDecoration(color: Color(0xFFFFEDD5), shape: BoxShape.circle),
                        child: Icon(LucideIcons.utensils, size: 11.w, color: const Color(0xFFC2410C)),
                      ),
                      Gap.w4,
                      Expanded(
                        child: Text(
                          'Foods Logged',
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w700, color: const Color(0xFF9A3412)),
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
                              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 17.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), height: 1.1),
                            ),
                            Gap.h2,
                            Text(
                              'Meals this week',
                              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.5.sp, color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      Icon(LucideIcons.utensils, size: 18.w, color: const Color(0xFFFED7AA).withValues(alpha: 0.7)),
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
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(16.w),
                border: Border.all(color: const Color(0xFFE0F2FE)),
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
                            decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
                            child: Icon(LucideIcons.barChart2, size: 11.w, color: const Color(0xFF0369A1)),
                          ),
                          Gap.w3,
                          Expanded(
                            child: Text(
                              'Your Evidence',
                              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0369A1)),
                            ),
                          ),
                          Icon(LucideIcons.info, size: 10.w, color: const Color(0xFF94A3B8)),
                        ],
                      ),
                      Gap.h6,
                      _EvidenceRow(label: 'Meals', count: foodsLogged),
                      Gap.h2,
                      const _EvidenceRow(label: 'Symptoms', count: 3),
                      Gap.h2,
                      const _EvidenceRow(label: 'Scans', count: 15),
                    ],
                  ),
                  Gap.h4,
                  Text(
                    'More data = more insights',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 7.5.sp, color: const Color(0xFF64748B)),
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
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(LucideIcons.checkSquare, size: 9.w, color: const Color(0xFF0284C7)),
            Gap.w3,
            Text(
              label,
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: const Color(0xFF334155)),
            ),
          ],
        ),
        Text(
          '$count',
          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
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

    final highlight1 = h1 is RecapHighlight ? h1.text : (h1 is String ? h1 : 'Added fermented foods on 5 out of 7 days.');
    const sub1 = 'That\'s 71% of the week!';

    final highlight2 = h2 is RecapHighlight ? h2.text : (h2 is String ? h2 : 'Reduced sugary beverage intake by 50%.');
    const sub2 = 'Great progress for your gut!';

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: const Color(0xFFDCFCE7)),
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
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.w),
                    border: Border.all(color: const Color(0xFFDCFCE7)),
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
                              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A), height: 1.2),
                            ),
                            Gap.h2,
                            Text(
                              sub1,
                              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.sp, color: const Color(0xFF64748B)),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.w),
                    border: Border.all(color: const Color(0xFFDCFCE7)),
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
                              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A), height: 1.2),
                            ),
                            Gap.h2,
                            Text(
                              sub2,
                              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.sp, color: const Color(0xFF64748B)),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.w),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Top Foods',
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
            ),
            Gap.h4,
            Text(
              'No top supportive or trigger foods recorded yet for this week.',
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, color: const Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

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
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(18.w),
                  border: Border.all(color: const Color(0xFFDCFCE7)),
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
                                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFF15803D)),
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
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                        ),
                        Gap.h2,
                        Text(
                          topHealing.effect ?? 'Supports gut health',
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: const Color(0xFF64748B), height: 1.15),
                        ),
                      ],
                    ),
                    Gap.h6,

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Observed',
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.w),
                          decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8.w)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.leaf, size: 8.w, color: const Color(0xFF15803D)),
                              Gap.w2,
                              Text(
                                '${topHealing.impactLevel.toUpperCase()} Impact',
                                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.sp, fontWeight: FontWeight.w700, color: const Color(0xFF15803D)),
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
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(18.w),
                  border: Border.all(color: const Color(0xFFFEE2E2)),
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
                                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFF991B1B)),
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
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                        ),
                        Gap.h2,
                        Text(
                          topTrigger.effect ?? 'Associated with discomfort',
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: const Color(0xFF64748B), height: 1.15),
                        ),
                      ],
                    ),
                    Gap.h6,

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Observed',
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.w),
                          decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8.w)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.triangleAlert, size: 8.w, color: const Color(0xFFB91C1C)),
                              Gap.w2,
                              Text(
                                '${topTrigger.impactLevel.toUpperCase()} Impact',
                                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.sp, fontWeight: FontWeight.w700, color: const Color(0xFFB91C1C)),
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
    final quoteText = data.healingGoal?.isNotEmpty == true ? '“${data.healingGoal}”' : '“Consistent vegetable fiber intake is actively improving your gut barrier score.”';

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: const Color(0xFFDCFCE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(5.w),
                decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                child: Icon(LucideIcons.quote, size: 12.w, color: const Color(0xFF15803D)),
              ),
              Gap.w6,
              Text(
                'Your Weekly Insight',
                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
              ),
            ],
          ),
          Gap.h8,

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  quoteText,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontFamilyFallback: const ['Georgia', 'Times New Roman'],
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                    height: 1.3,
                  ),
                ),
              ),
              Gap.w8,
            ],
          ),
        ],
      ),
    );
  }
}
