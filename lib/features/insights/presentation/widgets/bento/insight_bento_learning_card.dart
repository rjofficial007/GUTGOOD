part of 'insight_bento_feed.dart';

/// Learning card presentation component.

class _LearningCard extends StatelessWidget {
  const _LearningCard({required this.icon, required this.title, required this.current, required this.total, required this.isDone, required this.accentColor, this.onTap});

  final IconData icon;
  final String title;
  final int current;
  final int total;
  final bool isDone;
  final Color accentColor;
  final VoidCallback? onTap;

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
          border: Border.all(color: isDone ? accentColor.withValues(alpha: 0.4) : scheme.borderSubtle),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Centered Icon Circle with Checkmark Badge
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.05), shape: BoxShape.circle),
                  child: Center(
                    child: Icon(icon, size: 20.w, color: accentColor),
                  ),
                ),
                if (isDone)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(color: scheme.cardBackground, shape: BoxShape.circle),
                      child: Icon(Icons.check_circle_rounded, size: 16.w, color: accentColor),
                    ),
                  ),
              ],
            ),
            Gap.h10,

            // Centered Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.bodyBold.copyWith(height: 1.15, fontSize: 13.sp),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Gap.h4,

            // Centered Count
            Text(
              '$current / $total',
              textAlign: TextAlign.center,
              style: context.captionBold.copyWith(color: scheme.textSecondary, fontSize: 11.sp, fontFeatures: const [FontFeature.tabularFigures()]),
            ),
            Gap.h8,
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

/// A dedicated Smart Insight / Deep Discovery hero card matching the referral banner style:
/// rich purple gradient background, white headline, bottom-left pill CTA button,
/// and [AppAssets.deepDiscovery] illustration aligned on the right side.
