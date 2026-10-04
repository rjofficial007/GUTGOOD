part of 'insights_feed.dart';

/// Improving and watch food-impact presentation components.

class _SideBySideImprovingAndWatch extends StatelessWidget {
  const _SideBySideImprovingAndWatch({required this.improvingData, required this.series, this.watchData, this.onImprovingTap, this.onWatchTap});

  final InsightImprovingData improvingData;
  final List<double> series;
  final InsightWatchData? watchData;
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

  final InsightImprovingData data;
  final List<double> series;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cleanSeries = InsightValues.scores(series);
    final scoredSeries = cleanSeries.where((s) => s > 0).toList();

    final startVal = scoredSeries.length > 1
        ? scoredSeries.first.round().toString()
        : (scoredSeries.length == 1 ? scoredSeries.single.round().toString() : (data.current > 0 ? data.current.toString() : '—'));

    final endVal = scoredSeries.isNotEmpty ? scoredSeries.last.round().toString() : (data.current > 0 ? data.current.toString() : '—');

    final headline = (data.headline.isNotEmpty && data.headline != 'Your gut score is on the move')
        ? data.headline
        : (scoredSeries.length < 2 && data.lastWeek == null ? 'Your score baseline' : (data.headline.isNotEmpty ? data.headline : 'Your gut score is steady.'));

    final description = (data.description.isNotEmpty && data.description != 'Keep logging meals and symptoms to sharpen this trend.')
        ? data.description
        : (scoredSeries.length < 2 && data.lastWeek == null
              ? 'One recorded score sets a starting point. Another score will show whether it changed.'
              : (data.description.isNotEmpty ? data.description : 'Keep logging meals and symptoms to track your gut health progress.'));
    final sectionLabel = scoredSeries.length < 2 ? 'Building Baseline' : 'Your Progress';

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
                            sectionLabel,
                            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF14532D)),
                          ),
                        ),
                      ],
                    ),
                    Gap.h8,

                    // Headline
                    Text(
                      headline,
                      style: TextStyle(
                        fontFamily: InsightTheme.fontFamily,
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
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, color: context.insightColor(const Color(0xFF334155)), height: 1.25),
                    ),
                    Gap.h8,

                    // Trend Area Chart
                    SizedBox(
                      height: 38.w,
                      width: double.infinity,
                      child: InsightTrendChart(values: cleanSeries),
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
                                fontFamily: InsightTheme.fontFamily,
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w800,
                                color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF14532D),
                                height: 1.0,
                              ),
                            ),
                            Text(
                              'First recorded',
                              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.5.sp, color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D)),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              endVal,
                              style: TextStyle(
                                fontFamily: InsightTheme.fontFamily,
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w800,
                                color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF14532D),
                                height: 1.0,
                              ),
                            ),
                            Text(
                              'Latest',
                              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.5.sp, color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D)),
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
                    color: context.insightTheme.card,
                    borderRadius: BorderRadius.circular(20.w),
                    border: Border.all(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.28) : const Color(0xFFDCFCE7)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'See Details',
                        style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w700, color: context.insightColor(const Color(0xFF0F172A))),
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

  final InsightWatchData? data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasTrigger = data != null && data!.pattern != null && data!.title.isNotEmpty && data!.title != 'No Triggers Detected';

    final title = hasTrigger ? data!.title : 'No triggers yet';
    final desc = hasTrigger && data!.description.isNotEmpty ? data!.description : 'Repeated food and symptom associations have not been established yet. Keep logging to build enough evidence.';
    final cardBackground = hasTrigger
        ? (isDark ? const Color(0xFF231416) : const Color(0xFFFFF5F5))
        : (isDark ? const Color(0xFF111E2E) : const Color(0xFFF8FAFC));
    final cardBorder = hasTrigger
        ? (isDark ? const Color(0xFFEF4444).withValues(alpha: 0.45) : const Color(0xFFFCA5A5))
        : (isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.28) : const Color(0xFFE2E8F0));
    final headerColor = hasTrigger ? (isDark ? const Color(0xFFF87171) : const Color(0xFF881337)) : (isDark ? const Color(0xFF7DD3FC) : const Color(0xFF334155));
    final iconBackground = hasTrigger ? const Color(0xFFDC2626) : (isDark ? const Color(0xFF0369A1) : const Color(0xFF64748B));

    final thumbnails = hasTrigger && data?.pattern?.involvedFoods.isNotEmpty == true
        ? data!.pattern!.involvedFoods.take(3).map(InsightUiKit.foodImageUrl).toList()
        : (hasTrigger && data?.timeline.isNotEmpty == true ? data!.timeline.take(3).map((t) => t.imageUrl ?? InsightUiKit.foodImageUrl(t.imageName ?? 'Food')).toList() : const <String>[]);

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
        color: cardBackground,
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: cardBorder, width: 1.2.w),
        boxShadow: [
          BoxShadow(
            color: (hasTrigger ? (isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626)) : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF64748B))).withValues(alpha: isDark ? 0.08 : 0.04),
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
                          decoration: BoxDecoration(color: iconBackground, shape: BoxShape.circle),
                          child: Center(
                            child: Icon(hasTrigger ? LucideIcons.triangleAlert : LucideIcons.info, size: 13.w, color: Colors.white),
                          ),
                        ),
                        Gap.w6,
                        Expanded(
                          child: Text(
                            hasTrigger ? 'Something to Watch' : 'Pattern Check',
                            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: headerColor),
                          ),
                        ),
                      ],
                    ),
                    Gap.h8,

                    // Headline
                    Text(
                      title,
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A)), height: 1.2),
                    ),
                    Gap.h3,

                    // Description
                    Text(
                      desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, color: context.insightColor(const Color(0xFF334155)), height: 1.25),
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
                              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.sp, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFFF87171) : const Color(0xFF881337)),
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
                          color: context.insightTheme.card,
                          borderRadius: BorderRadius.circular(20.w),
                          border: Border.all(color: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.35) : const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'See Details',
                              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w700, color: context.insightColor(const Color(0xFF0F172A))),
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
