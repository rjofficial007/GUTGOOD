part of 'pattern_detail_screen.dart';

/// Pattern involved-food presentation component.

class _InvolvedFoodTile extends StatelessWidget {
  const _InvolvedFoodTile({required this.foodName});

  final String foodName;

  @override
  Widget build(BuildContext context) {
    final theme = context.insightTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 108.w,
      padding: EdgeInsets.all(7.w),
      decoration: BoxDecoration(
        color: isDark ? theme.card : const Color(0xFFFFFDF7),
        borderRadius: BorderRadius.circular(14.w),
        border: Border.all(color: isDark ? theme.border : const Color(0xFFE2E8F0), width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.w),
            child: InsightUiKit.foodImage(
              foodName,
              width: 94.w,
              height: 60.w,
              fit: BoxFit.cover,
              placeholder: Container(color: theme.cardSubtle),
              errorWidget: Container(
                color: isDark ? const Color(0xFFB45309).withValues(alpha: 0.20) : const Color(0xFFFEF3C7),
                alignment: Alignment.center,
                child: Icon(LucideIcons.utensils, size: 20.w, color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706)),
              ),
            ),
          ),
          Gap.h4,
          Text(
            foodName,
            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w700, color: theme.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Gap.h3,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.15) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(100.w),
              border: Border.all(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.3) : const Color(0xFF15803D).withValues(alpha: 0.2), width: 0.7.w),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.leaf, size: 7.5.w, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)),
                Gap.w2,
                Text(
                  'Involved',
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.sp, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D), height: 1.1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
