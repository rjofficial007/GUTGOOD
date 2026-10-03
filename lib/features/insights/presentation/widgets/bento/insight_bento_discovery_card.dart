part of 'insight_bento_feed.dart';

/// Deep-discovery presentation component.

class DeepDiscoveryCard extends StatelessWidget {
  const DeepDiscoveryCard({super.key, required this.insight, this.onTap, this.assetImage = AppAssets.mascotDiscovery, this.gradientColors = const [Color(0xFF7C66EE), Color(0xFF6352DD)]});

  final InsightSummary insight;
  final VoidCallback? onTap;
  final String assetImage;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    final radius = 20.w;

    return Semantics(
      button: onTap != null,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap ?? () => context.push(AppRoutes.smartInsightDetail, extra: insight),
          borderRadius: BorderRadius.circular(radius),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: gradientColors),
              boxShadow: PatternSurface.shadow(context),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Stack(
                children: [
                  // Right Side Hero Illustration
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 0,
                    child: SizedBox(
                      width: 130.w,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Image.asset(assetImage, fit: BoxFit.contain, alignment: Alignment.centerRight, errorBuilder: (_, _, _) => const SizedBox.shrink()),
                      ),
                    ),
                  ),

                  // Left Side Content Column
                  Padding(
                    padding: EdgeInsets.fromLTRB(18.w, 16.w, 130.w, 16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Subtitle / Eyebrow Text
                        Text(
                          AppStrings.bentoSmartInsight,
                          style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.85), letterSpacing: 0.2),
                        ),

                        Gap.h6,

                        // Main Bold White Headline
                        Text(
                          insight.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 17.sp, fontWeight: FontWeight.w800, height: 1.20, letterSpacing: -0.4, color: Colors.white),
                        ),

                        Gap.h14,

                        // Bottom Left Pill CTA Button
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.20), borderRadius: BorderRadius.circular(100)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppStrings.bentoReadAnalysis,
                                style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: Colors.white),
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
        ),
      ),
    );
  }
}

/// The PatternCard-language content card: tone wash, 32px accent tile
/// (emoji or Lucide icon), w800 name with an accent meta on the right,
/// a title + muted paragraph, a chart slot, and the dot footer.
