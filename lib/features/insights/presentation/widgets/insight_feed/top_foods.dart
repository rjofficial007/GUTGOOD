part of 'insights_feed.dart';

/// Top food and impact chart presentation components.

class _TopFoodsSection extends StatelessWidget {
  const _TopFoodsSection({required this.insight});

  final AIInsight insight;

  @override
  Widget build(BuildContext context) {
    final foodItems = <TopFoodItemData>[];
    final seen = <String>{};

    int countOccurrences(String foodName) {
      final key = foodName.toLowerCase().trim();
      if (key.isEmpty) return 0;
      var n = 0;
      for (final impact in insight.foodImpacts) {
        if (impact.food.toLowerCase().trim() == key) n++;
      }
      return n;
    }

    if (insight.healingSummary?.foods.isNotEmpty == true) {
      for (final f in insight.healingSummary!.foods) {
        final key = f.name.toLowerCase().trim();
        if (key.isEmpty || !seen.add(key)) continue;
        final n = countOccurrences(f.name);
        final countStr = n > 0 ? '${n}x logged' : '';
        final desc = f.effect?.trim().isNotEmpty == true ? f.effect : null;
        foodItems.add(TopFoodItemData(title: f.name, frequency: countStr, badge: 'Supportive', imageUrl: f.imageUrl, description: desc, isPositive: true));
      }
    }

    for (final f in insight.healingFoods) {
      final key = f.name.toLowerCase().trim();
      if (key.isEmpty || !seen.add(key)) continue;
      final n = countOccurrences(f.name);
      final countStr = n > 0 ? '${n}x logged' : '';
      final desc = f.effect.trim().isNotEmpty ? f.effect : null;
      foodItems.add(
        TopFoodItemData(title: f.name, frequency: countStr, badge: 'Supportive', imageUrl: f.userImageUrl ?? f.imageUrl, description: desc, isPositive: true),
      );
    }

    for (final f in insight.foodImpacts.where((i) {
      final type = i.impactType.toLowerCase();
      return type == 'positive' || type == 'healing' || type == 'good' || type == 'supportive';
    })) {
      final key = f.food.toLowerCase().trim();
      if (key.isEmpty || !seen.add(key)) continue;
      final n = countOccurrences(f.food);
      final countStr = n > 0 ? '${n}x logged' : f.dateLabel;
      final desc = f.effect.trim().isNotEmpty ? f.effect : null;
      foodItems.add(
        TopFoodItemData(title: f.food, frequency: countStr, badge: 'Positive', imageUrl: f.userImageUrl ?? f.imageUrl, description: desc, isPositive: true),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (foodItems.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: context.insightTheme.card,
          borderRadius: BorderRadius.circular(18.w),
          border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0))),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.20) : const Color(0xFFDCFCE7), shape: BoxShape.circle),
              child: Icon(LucideIcons.leaf, size: 16.w, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)),
            ),
            Gap.w10,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discover Your Top Foods',
                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                  ),
                  Gap.h2,
                  Text(
                    'Log a few meals and we’ll start finding what works for you.',
                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, color: context.insightColor(const Color(0xFF64748B))),
                  ),
                ],
              ),
            ),
            Gap.w8,
            GestureDetector(
              onTap: () => openScannerAndProcessResult(context, 'meal'),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.w),
                decoration: BoxDecoration(color: const Color(0xFF15803D), borderRadius: BorderRadius.circular(12.w)),
                child: Text(
                  'Log Meal',
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.20) : const Color(0xFFDCFCE7), shape: BoxShape.circle),
                  child: Icon(LucideIcons.trophy, size: 12.w, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)),
                ),
                Gap.w8,
                Text(
                  'Top Foods This Week',
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => context.push(AppRoutes.foodIntelligence, extra: insight),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View All',
                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w700, color: context.insightColor(const Color(0xFF0F172A))),
                  ),
                  Gap.w3,
                  Icon(Icons.arrow_forward_rounded, size: 11.w, color: context.insightColor(const Color(0xFF0F172A))),
                ],
              ),
            ),
          ],
        ),
        Gap.h10,

        // Separate List Items (Top 3 foods) using TopFoodTile
        Column(
          children: [
            for (final item in foodItems.take(3)) ...[
              TopFoodTile(
                item: item,
                onTap: () => context.push(AppRoutes.foodIntelligence, extra: insight),
              ),
              Gap.h10,
            ],
          ],
        ),
      ],
    );
  }
}
