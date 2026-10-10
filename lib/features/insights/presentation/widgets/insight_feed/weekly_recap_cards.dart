part of 'insights_feed.dart';

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
      padding: EdgeInsets.symmetric(horizontal: 16.w),
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

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.68,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: centeredCopy),
          Gap.h20,
          banner,
        ],
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
