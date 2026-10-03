part of 'smart_insight_detail_screen.dart';

/// Smart insight involved-food presentation component.

class _InvolvedFoodTile extends StatelessWidget {
  const _InvolvedFoodTile({required this.foodName});

  final String foodName;

  @override
  Widget build(BuildContext context) {
    final imageUrl = InsightUiKit.foodImageUrl(foodName);

    return Container(
      width: 108.w,
      padding: EdgeInsets.all(7.w),
      decoration: BoxDecoration(
        color: context.insightColor(const Color(0xFFFFFDF7)),
        borderRadius: BorderRadius.circular(14.w),
        border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0)), width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.w),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: 94.w,
              height: 60.w,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(color: context.insightColor(const Color(0xFFF1F5F9))),
              errorWidget: (_, _, _) => Container(
                color: context.insightColor(const Color(0xFFFEF3C7)),
                alignment: Alignment.center,
                child: Icon(LucideIcons.utensils, size: 20.w, color: context.insightColor(const Color(0xFFD97706))),
              ),
            ),
          ),
          Gap.h4,
          Text(
            foodName,
            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w700, color: context.insightColor(const Color(0xFF0F172A))),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Gap.h3,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.w),
            decoration: BoxDecoration(
              color: context.insightColor(const Color(0xFFF0FDF4)),
              borderRadius: BorderRadius.circular(100.w),
              border: Border.all(color: context.insightColor(const Color(0xFF15803D)).withValues(alpha: 0.2), width: 0.7.w),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.leaf, size: 7.5.w, color: context.insightColor(const Color(0xFF15803D))),
                Gap.w2,
                Text(
                  'Involved',
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.sp, fontWeight: FontWeight.w700, color: context.insightColor(const Color(0xFF15803D)), height: 1.1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

