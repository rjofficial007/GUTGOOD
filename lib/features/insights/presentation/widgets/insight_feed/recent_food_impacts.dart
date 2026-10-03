part of 'insights_feed.dart';

/// Recent food-impact list components.

class _RecentFoodImpactsSection extends StatelessWidget {
  const _RecentFoodImpactsSection({this.impacts = const []});

  final List<FoodImpact> impacts;

  @override
  Widget build(BuildContext context) {
    if (impacts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: context.insightTheme.card,
          borderRadius: BorderRadius.circular(16.w),
          border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.clock, size: 15.w, color: context.insightColor(const Color(0xFF0F172A))),
                Gap.w6,
                Text(
                  'Recent Food Impacts',
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                ),
              ],
            ),
            Gap.h4,
            Text(
              'No recent food impacts recorded yet. Log your meals to see how specific foods affect your gut.',
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, color: context.insightColor(const Color(0xFF64748B))),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(LucideIcons.clock, size: 15.w, color: context.insightColor(const Color(0xFF0F172A))),
                Gap.w6,
                Text(
                  'Recent Food Impacts',
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                ),
              ],
            ),
          ],
        ),
        Gap.h8,

        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: context.insightTheme.card,
            borderRadius: BorderRadius.circular(16.w),
            border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0))),
          ),
          child: Column(
            children: [
              for (var i = 0; i < impacts.take(4).length; i++) ...[
                if (i > 0) Divider(height: 12.w, color: context.insightColor(const Color(0xFFF1F5F9))),
                _FoodImpactRow(
                  imageUrl: impacts[i].userImageUrl ?? impacts[i].imageUrl ?? InsightUiKit.foodImageUrl(impacts[i].food),
                  title: impacts[i].food,
                  sub: '${impacts[i].dateLabel} • ${impacts[i].timeframeLabel}',
                  status: impacts[i].effect,
                  isPositive: impacts[i].impactType == 'positive',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FoodImpactRow extends StatelessWidget {
  const _FoodImpactRow({required this.imageUrl, required this.title, required this.sub, required this.status, required this.isPositive});

  final String imageUrl;
  final String title;
  final String sub;
  final String status;
  final bool isPositive;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(8.w),
        child: CachedNetworkImage(imageUrl: imageUrl, width: 36.w, height: 36.w, fit: BoxFit.cover),
      ),
      Gap.w8,
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
            ),
            Text(
              sub,
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, color: context.insightColor(const Color(0xFF64748B))),
            ),
          ],
        ),
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Icon(isPositive ? LucideIcons.leaf : LucideIcons.triangleAlert, size: 10.w, color: isPositive ? const Color(0xFF15803D) : const Color(0xFFB91C1C)),
              Gap.w3,
              Text(
                status,
                style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w600, color: context.insightColor(const Color(0xFF0F172A))),
              ),
            ],
          ),
          Gap.h2,
          Text(
            isPositive ? 'Positive' : 'Negative',
            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.sp, fontWeight: FontWeight.w700, color: isPositive ? const Color(0xFF15803D) : const Color(0xFFB91C1C)),
          ),
        ],
      ),
    ],
  );
}

// =============================================================================
// FOOD IMPACT TAB: 5. YOUR NEXT STEPS SECTION
// =============================================================================
