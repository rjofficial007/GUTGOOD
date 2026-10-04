part of 'insights_feed.dart';

/// Patterns-smarter banner component.

class _InsightsLearningBannerCard extends StatelessWidget {
  const _InsightsLearningBannerCard({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark ? Colors.white : Colors.black;
    final surface = isDark ? Colors.black : Colors.white;
    final inverse = isDark ? Colors.black : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: foreground),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(color: foreground, borderRadius: BorderRadius.circular(12.w)),
              child: Icon(LucideIcons.barChart2, size: 16.w, color: inverse),
            ),
            Gap.w10,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 13.sp, fontWeight: FontWeight.w800, color: foreground),
                  ),
                  Gap.h2,
                  Text(
                    description,
                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, color: foreground, height: 1.25),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatternsSmarterBannerCard extends StatelessWidget {
  const _PatternsSmarterBannerCard();

  @override
  Widget build(BuildContext context) => const _InsightsLearningBannerCard(
    title: 'Patterns get smarter over time',
    description: 'The more you log, the more personalized your insights become. Keep tracking to unlock deeper insights!',
  );
}

// =============================================================================
// HERO 1: GUT SCORE & ON TRACK CARD
// =============================================================================
// =============================================================================
// HERO 3: SIDE-BY-SIDE CARDS ("What's Improving" & "Something to Watch")
// =============================================================================
