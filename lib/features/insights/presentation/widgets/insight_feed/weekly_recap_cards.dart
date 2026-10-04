part of 'insights_feed.dart';

/// Weekly recap insight and empty-state presentation components.

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
                    fontFamily: InsightTheme.fontFamily,
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
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 18.sp, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A), height: 1.1),
                ),
                Gap.w4,
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 2.w),
                    child: Text(
                      quoteText,
                      style: TextStyle(
                        fontFamily: InsightTheme.fontFamily,
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
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 18.sp, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A), height: 1.1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopInsightCard extends StatelessWidget {
  const _TopInsightCard({required this.insight, required this.topInsight, this.onTap});
  final AIInsight insight;
  final InsightSummary topInsight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final titleText = InsightValues.text(topInsight.title, fallback: 'Your food and symptom snapshot');
    final observationCount = (topInsight.frequency ?? 1) < 1 ? 1 : (topInsight.frequency ?? 1);
    final isEarlyObservation = observationCount <= 1;
    final eyebrow = isEarlyObservation
        ? 'Early observation · $observationCount observation${observationCount == 1 ? '' : 's'}'
        : 'Top Insights & Trends';

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
                        eyebrow,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 18.sp, fontWeight: FontWeight.w800, color: Colors.white, height: 1.15, letterSpacing: -0.4),
                      ),

                      Gap.h6,

                      // Line 2: Subtitle
                      Text(
                        titleText,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: InsightTheme.fontFamily,
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
                            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.4),
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

/// Reusable centered empty state and learning banner for Insights tabs that
/// do not yet have enough evidence to render a trustworthy chart or pattern card.
class _InsightsEmptyState extends StatelessWidget {
  const _InsightsEmptyState({required this.headline, required this.description, required this.banner});

  final String headline;
  final String description;
  final Widget banner;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark ? Colors.white : Colors.black;

    final centeredCopy = Padding(
      padding: EdgeInsets.only(left: 16.w, top: 24.w, right: 16.w),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 335.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                headline,
                style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 30.sp, fontWeight: FontWeight.w800, height: 1.12, letterSpacing: -0.7, color: foreground),
                textAlign: TextAlign.center,
              ),
              Gap.h12,
              Text(
                description,
                style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 13.sp, fontWeight: FontWeight.w400, color: foreground, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.68),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [centeredCopy, Gap.h20, banner],
      ),
    );
  }
}

class _EmptyPatternsState extends StatelessWidget {
  const _EmptyPatternsState();

  @override
  Widget build(BuildContext context) => const _InsightsEmptyState(
    headline: 'Your meals.\nYour reactions.\nYour patterns.',
    description: 'Keep logging your food scans and symptoms to discover recurring body patterns and tailored triggers.',
    banner: _PatternsSmarterBannerCard(),
  );
}

