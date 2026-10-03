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
            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 26.sp, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -0.5, color: primaryTextColor),
            textAlign: TextAlign.center,
          ),
          Gap.h12,

          // Subtitle Paragraph
          Text(
            'Keep logging your food scans and symptoms to discover recurring body patterns and tailored triggers.',
            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 13.sp, fontWeight: FontWeight.w400, color: secondaryTextColor, height: 1.35),
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
                        style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: primaryTextColor),
                      ),
                      Gap.h2,
                      Text(
                        'Body patterns emerge automatically as you log meals alongside symptoms over time. No guessing—just clear data.',
                        style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, color: secondaryTextColor, height: 1.35),
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
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: scheme.textPrimary, height: 1.15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Gap.h2,
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, color: scheme.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
