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
      foodItems.add(TopFoodItemData(title: f.name, frequency: countStr, badge: 'Supportive', imageUrl: f.userImageUrl ?? f.imageUrl, description: desc, isPositive: true));
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
      foodItems.add(TopFoodItemData(title: f.food, frequency: countStr, badge: 'Positive', imageUrl: f.userImageUrl ?? f.imageUrl, description: desc, isPositive: true));
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

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF102319) : const Color(0xFFF6FBF7),
        borderRadius: BorderRadius.circular(18.w),
        border: Border.all(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.28) : const Color(0xFFD8F0E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.20) : const Color(0xFFD9F5E7), shape: BoxShape.circle),
                child: Icon(LucideIcons.leaf, size: 23.w, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF087443)),
              ),
              Gap.w10,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Top Foods',
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 15.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                    ),
                    Gap.h3,
                    Text(
                      'Based on your logs, these foods are linked to positive impact for you.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, height: 1.25, color: context.insightColor(const Color(0xFF64748B))),
                    ),
                  ],
                ),
              ),
              Gap.w8,
              Material(
                color: context.insightTheme.card,
                borderRadius: BorderRadius.circular(30.w),
                child: InkWell(
                  onTap: () => context.push(AppRoutes.topFoods, extra: insight),
                  borderRadius: BorderRadius.circular(30.w),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 8.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30.w),
                      border: Border.all(color: context.insightColor(const Color(0xFFDCE5E1))),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 7.w, offset: Offset(0, 2.w))],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All',
                          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF087443)),
                        ),
                        Gap.w3,
                        Icon(Icons.arrow_forward_rounded, size: 12.w, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF087443)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Gap.h12,
          SizedBox(
            height: 112.w * math.max(1.0, MediaQuery.textScalerOf(context).scale(10) / 10),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: foodItems.length,
              separatorBuilder: (_, _) => SizedBox(width: 7.w),
              itemBuilder: (context, index) => _WeeklyTopFoodCard(
                item: foodItems[index],
                onTap: () => context.push(AppRoutes.topFoods, extra: insight),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyTopFoodCard extends StatelessWidget {
  const _WeeklyTopFoodCard({required this.item, required this.onTap});

  final TopFoodItemData item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final green = isDark ? const Color(0xFF4ADE80) : const Color(0xFF087443);
    final lightGreen = isDark ? const Color(0xFF14532D).withValues(alpha: 0.55) : const Color(0xFFE1F7E9);
    final description = item.description?.trim().isNotEmpty == true ? item.description! : 'Positive response in your logs';

    return SizedBox(
      width: 90.w,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.insightTheme.card,
          borderRadius: BorderRadius.circular(14.w),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.06),
              blurRadius: 10.w,
              offset: Offset(0, 3.w),
            ),
          ],
        ),
        child: Material(
          color: context.insightTheme.card,
          borderRadius: BorderRadius.circular(14.w),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DynamicFoodImage(
                  keyword: item.title,
                  imageUrl: item.imageUrl,
                  width: double.infinity,
                  height: 52.w,
                  fit: BoxFit.cover,
                  placeholder: Container(color: lightGreen),
                  errorWidget: Container(
                    color: lightGreen,
                    alignment: Alignment.center,
                    child: Icon(LucideIcons.leaf, color: green, size: 20.w),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(6.w, 5.w, 6.w, 6.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                        ),
                        Gap.h2,
                        Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.sp, color: context.insightColor(const Color(0xFF64748B))),
                        ),
                        const Spacer(),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.w),
                            decoration: BoxDecoration(color: lightGreen, borderRadius: BorderRadius.circular(8.w)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12.w,
                                  height: 12.w,
                                  decoration: BoxDecoration(color: green, shape: BoxShape.circle),
                                  child: Icon(Icons.arrow_upward_rounded, size: 9.w, color: Colors.white),
                                ),
                                Gap.w3,
                                Text(
                                  'Positive',
                                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w800, color: green),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
