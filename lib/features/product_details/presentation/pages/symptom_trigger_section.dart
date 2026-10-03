part of 'symptom_detail_screen.dart';

/// Symptom trigger presentation component.

class _SymptomTriggerSection extends StatelessWidget {
  const _SymptomTriggerSection({required this.symptom});
  final SymptomLog symptom;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = <_FactorItem>[];

    if (symptom.foodName != null && symptom.foodName!.isNotEmpty) {
      items.add(_FactorItem(icon: AppIcons.utensils, color: t.negative, title: symptom.foodName!, subtitle: 'Meal consumed shortly before reaction'));
    }

    if (symptom.lastMealFirestoreId != null && symptom.lastMealFirestoreId!.isNotEmpty) {
      items.add(_FactorItem(icon: AppIcons.sparkles, color: const Color(0xFF7C3AED), title: 'Linked Meal Record', subtitle: 'Meal log cross-referenced with your pattern history'));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: t.negative.withAlpha(20), shape: BoxShape.circle),
              child: Icon(Icons.warning_amber_rounded, size: 22.sp, color: t.negative),
            ),
            Gap.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Potential Triggers',
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.titleSize.sp, fontWeight: FontWeight.w700, color: t.textPrimary),
                  ),
                  Text(
                    'Food or environmental triggers linked to this reaction.',
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.footSize.sp, fontWeight: FontWeight.w400, color: t.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        Gap.h16,
        ...items.map((item) => _buildCard(context, item, isDark: isDark)),
      ],
    );
  }

  Widget _buildCard(BuildContext context, _FactorItem item, {required bool isDark}) {
    final t = context.bentoTheme;
    final cardShade = item.color.withValues(alpha: isDark ? 0.16 : 0.08);
    final iconBgColor = item.color.withValues(alpha: isDark ? 0.28 : 0.16);

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
      decoration: BoxDecoration(color: cardShade, borderRadius: BorderRadius.circular(14.r)),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
            child: Icon(item.icon, size: 16.sp, color: item.color),
          ),
          Gap.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w700, color: t.textPrimary, height: 1.2),
                ),
                Gap.h2,
                Text(
                  item.subtitle,
                  style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w400, color: t.textSecondary, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

