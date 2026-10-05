part of 'insights_feed.dart';

/// Insights feed shell and filter controls.

bool _hasFoodImpactEvidence(AIInsight insight) {
  final balance = insight.foodImpactBalance;
  final hasBalance = balance != null && (balance.positivePercent > 0 || balance.neutralPercent > 0 || balance.negativePercent > 0);
  return hasBalance ||
      insight.foodImpacts.isNotEmpty ||
      insight.healingFoods.isNotEmpty ||
      insight.healingSummary?.foods.isNotEmpty == true ||
      insight.triggerFoods.isNotEmpty ||
      insight.triggerSummary?.foods.isNotEmpty == true;
}

class InsightsFeed extends StatefulWidget {
  const InsightsFeed({super.key, required this.data, required this.patterns, this.series = const [], this.history = const []});

  final AIInsight data;
  final List<BodyPattern> patterns;
  final List<double> series;
  final List<AIInsight> history;

  @override
  State<InsightsFeed> createState() => _InsightsFeedState();
}

class _InsightsFeedState extends State<InsightsFeed> {
  String _selectedFilter = 'For You';

  @override
  Widget build(BuildContext context) {
    final previous = InsightFeedDerivations.previousScoreInWindow(widget.series);
    final delta = !widget.data.hasGutScore
        ? null
        : previous != null
        ? widget.data.gutScore - previous
        : InsightFeedDerivations.parseScoreDelta(widget.data.scoreDiff);
    final improving = InsightFeedDerivations.buildImprovingData(widget.data, widget.series, widget.history);
    final watch = InsightFeedDerivations.buildWatchData(widget.data, widget.patterns);

    final isPatternsTab = _selectedFilter == 'Patterns';
    final isFoodImpactTab = _selectedFilter == 'Food Impact';
    final hasFoodImpactEvidence = _hasFoodImpactEvidence(widget.data);

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
                  const _EmptyPatternsState(),
                ],
              ] else if (isFoodImpactTab) ...[
                // -------------------------------------------------------------------
                // TAB: FOOD IMPACT
                // -------------------------------------------------------------------
                Gap.h10,
                if (!hasFoodImpactEvidence) ...[
                  const _InsightsEmptyState(
                    headline: 'Your foods.\nYour impacts.\nYour insights.',
                    description: 'Keep scanning foods and logging meals and symptoms to understand how they affect your gut.',
                    banner: _InsightsLearningBannerCard(title: 'Food impacts get clearer over time', description: 'Keep logging to unlock more personalized food impact insights.'),
                  ),
                ] else ...[
                  // 1. Food Impact Balance Hero Card
                  _FoodImpactBalanceHeroCard(balance: widget.data.foodImpactBalance, foodImpacts: widget.data.foodImpacts),
                  Gap.h10,

                  // 2. Side-by-Side: Top Healing Foods & Top Trigger Food
                  _SideBySideHealingAndTriggerCards(insight: widget.data),
                  Gap.h10,

                  // 4. Top Foods This Week
                  _TopFoodsSection(insight: widget.data),
                  Gap.h10,

                  // 5. Recent Food Impacts List
                  _RecentFoodImpactsSection(impacts: widget.data.foodImpacts),
                  Gap.h10,

                  // 6. Your Next Steps Action Cards
                  _YourNextStepsSection(actions: widget.data.actionsList, insight: widget.data),
                ],
              ] else if (_selectedFilter == 'Weekly Recap') ...[
                // -------------------------------------------------------------------
                // TAB: WEEKLY RECAP
                // -------------------------------------------------------------------
                WeeklyRecapView(data: widget.data, series: widget.data.hasGutScore ? widget.series : const [], patterns: widget.patterns, history: widget.history),
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
                    TopInsightCard(
                      topInsight: widget.data.topInsight!,
                      onTap: () => context.push(AppRoutes.smartInsightDetail, extra: widget.data.topInsight),
                    )
                  else if (widget.patterns.isNotEmpty)
                    PatternCard(pattern: widget.patterns.first),
                  Gap.h10,

                  // SIDE-BY-SIDE CARDS: What's Improving & Something to Watch
                  _SideBySideImprovingAndWatch(
                    improvingData: improving,
                    series: widget.data.hasGutScore ? widget.series : const [],
                    observationCount: widget.data.topInsight?.frequency,
                    watchData: watch,
                    onImprovingTap: () {
                      final cleanSeries = InsightValues.scores(widget.series);
                      final scoredSeries = cleanSeries.where((s) => s > 0).toList();
                      final hasEnoughData = scoredSeries.length > 1;
                      context.push(
                        AppRoutes.highlightDetail,
                        extra: HighlightDetailArgs(
                          tag: hasEnoughData ? 'Your Progress' : 'Building Baseline',
                          emoji: '🌱',
                          title: improving.headline,
                          body: hasEnoughData ? improving.encouragement : 'We’re learning what works for you.',
                          accentColor: 0xFF1F7A3D,
                          backgroundColor: 0xFFE7F6E7,
                          chartType: 'healing',
                          chartValues: widget.series,
                          footLeft: 'this window',
                          frequency: improving.deltaPts == 0 ? null : '${improving.deltaPts > 0 ? '+' : ''}${improving.deltaPts} pts',
                        ),
                      );
                    },
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
                            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, color: context.insightColor(const Color(0xFF64748B)), height: 1.35),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = context.insightTheme;
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
                  color: filters[i] == selectedFilter ? (isDark ? Colors.white : const Color(0xFF171717)) : Colors.transparent,
                  borderRadius: BorderRadius.circular(100.w),
                  border: Border.all(color: filters[i] == selectedFilter ? (isDark ? Colors.white : const Color(0xFF171717)) : theme.border, width: 1.w),
                  boxShadow: filters[i] == selectedFilter
                      ? [BoxShadow(color: (isDark ? Colors.black : const Color(0xFF17171B)).withValues(alpha: 0.15), blurRadius: 4.w, offset: Offset(0, 2.w))]
                      : null,
                ),
                child: Text(
                  filters[i],
                  style: TextStyle(
                    fontFamily: InsightTheme.fontFamily,
                    fontSize: 12.sp,
                    fontWeight: filters[i] == selectedFilter ? FontWeight.w800 : FontWeight.w600,
                    color: filters[i] == selectedFilter ? (isDark ? const Color(0xFF0F172A) : Colors.white) : theme.textSecondary,
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
