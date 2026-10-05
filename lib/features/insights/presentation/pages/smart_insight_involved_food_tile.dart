part of 'smart_insight_detail_screen.dart';

/// Smart insight involved-food presentation component.

class _InvolvedFoodTile extends StatelessWidget {
  const _InvolvedFoodTile({required this.foodName});

  final String foodName;

  @override
  Widget build(BuildContext context) {
    final theme = context.insightTheme;

    return Container(
      width: 156.w,
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(14.w),
        border: Border.all(color: theme.border, width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.w),
            child: InsightUiKit.foodImage(
              foodName,
              width: 140.w,
              height: 72.w,
              fit: BoxFit.cover,
              placeholder: Container(color: theme.cardSubtle),
              errorWidget: Container(
                color: theme.warningSoft,
                alignment: Alignment.center,
                child: Icon(LucideIcons.utensils, size: 20.w, color: theme.warning),
              ),
            ),
          ),
          Gap.h4,
          Text(
            foodName,
            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: theme.textPrimary, height: 1.15),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Gap.h3,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.w),
            decoration: BoxDecoration(
              color: theme.warningSoft,
              borderRadius: BorderRadius.circular(100.w),
              border: Border.all(color: theme.warning.withValues(alpha: 0.2), width: 0.7.w),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.utensils, size: 7.5.w, color: theme.warning),
                Gap.w2,
                Text(
                  'Mentioned',
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.sp, fontWeight: FontWeight.w700, color: theme.warning, height: 1.1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
