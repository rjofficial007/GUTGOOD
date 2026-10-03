part of 'insights_feed.dart';

/// Patterns-smarter banner component.

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
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 13.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                ),
                Gap.h2,
                Text(
                  'The more you log, the more personalized your insights become. Keep tracking to unlock deeper insights!',
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, color: context.insightColor(const Color(0xFF475569)), height: 1.25),
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
