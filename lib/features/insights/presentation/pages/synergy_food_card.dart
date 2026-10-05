part of 'synergy_detail_screen.dart';

/// Synergy involved-food presentation components.

class _FoodCardData {
  const _FoodCardData({required this.name, required this.imageKeyword});
  final String name;
  final String imageKeyword;
}

class _InvolvedFoodCard extends StatelessWidget {
  const _InvolvedFoodCard({required this.food});

  final _FoodCardData food;

  @override
  Widget build(BuildContext context) => Container(
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
            child: InsightUiKit.foodImage(
              food.imageKeyword,
              width: 94.w,
              height: 60.w,
              fit: BoxFit.cover,
              placeholder: Container(color: context.insightColor(const Color(0xFFF1F5F9))),
              errorWidget: Container(
                color: context.insightColor(const Color(0xFFFEF3C7)),
                alignment: Alignment.center,
                child: Icon(LucideIcons.utensils, size: 20.w, color: context.insightColor(const Color(0xFFD97706))),
              ),
            ),
          ),
          Gap.h4,
          Text(
            food.name,
            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w700, color: context.insightColor(const Color(0xFF0F172A))),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Gap.h3,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.w),
            decoration: BoxDecoration(color: context.insightColor(const Color(0xFFDCFCE7)), borderRadius: BorderRadius.circular(10.w)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.leaf, size: 8.5.w, color: context.insightColor(const Color(0xFF15803D))),
                Gap.w2,
                Text(
                  'Supportive observation',
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w700, color: context.insightColor(const Color(0xFF15803D))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
}
