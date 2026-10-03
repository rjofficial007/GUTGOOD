part of 'scan_result_widgets.dart';

/// Cycle insight presentation component.

class CycleInsightSection extends StatelessWidget {
  const CycleInsightSection({super.key, required this.insight});
  final CycleInsight insight;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final palette = t.bento(BentoTone.pink);

    return Container(
      padding: EdgeInsets.all(BentoMetrics.padding.w),
      decoration: BoxDecoration(gradient: palette.gradient, borderRadius: BorderRadius.circular(BentoMetrics.radius.w)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BentoCardHeader(title: AppStrings.cycleInsightLabel, icon: AppIcons.sparkles, textColor: palette.tagForeground, iconColor: palette.tagForeground),
          Gap.h12,
          Text(
            insight.phase.toUpperCase(),
            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 16.sp, fontWeight: FontWeight.w900, letterSpacing: -0.4, color: t.textPrimary),
          ),
          Gap.h6,
          Text(
            insight.description,
            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.bodySize.sp, fontWeight: FontWeight.w500, height: 1.5, color: t.textSecondary),
          ),
          if (insight.tags != null && insight.tags!.isNotEmpty) ...[
            Gap.h12,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: insight.tags!
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: palette.tagBackground, borderRadius: BorderRadius.circular(100)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getIcon(tag.icon), size: 10.sp, color: palette.tagForeground),
                          Gap.w6,
                          Text(
                            tag.text.toUpperCase(),
                            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 9.sp, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: palette.tagForeground),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getIcon(String icon) {
    switch (icon.toLowerCase()) {
      case 'zap':
        return AppIcons.zap;
      case 'leaf':
        return AppIcons.leaf;
      case 'sparkles':
      case 'sparkle':
        return AppIcons.sparkles;
      case 'activity':
        return AppIcons.activity;
      default:
        return AppIcons.sparkles;
    }
  }
}

