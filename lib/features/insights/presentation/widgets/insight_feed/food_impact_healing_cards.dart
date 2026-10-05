part of 'insights_feed.dart';

/// Healing and trigger food-impact cards.

class _SideBySideHealingAndTriggerCards extends StatelessWidget {
  const _SideBySideHealingAndTriggerCards({this.insight});

  final AIInsight? insight;

  @override
  Widget build(BuildContext context) {
    final hasHealing = insight?.healingSummary?.foods.isNotEmpty == true || insight?.healingFoods.isNotEmpty == true;
    final hasTrigger = insight?.triggerSummary?.foods.isNotEmpty == true || insight?.triggerFoods.isNotEmpty == true;

    if (!hasHealing && !hasTrigger) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: context.insightTheme.card,
          borderRadius: BorderRadius.circular(18.w),
          border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Healing & Trigger Foods',
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
            ),
            Gap.h4,
            Text(
              'No specific healing or trigger foods identified yet. Keep logging meals to discover foods that support or upset your gut.',
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, color: context.insightColor(const Color(0xFF64748B))),
            ),
          ],
        ),
      );
    }

    final healingList = insight?.healingSummary?.foods.isNotEmpty == true
        ? insight!.healingSummary!.foods
        : (insight?.healingFoods.isNotEmpty == true
              ? insight!.healingFoods
                    .map((f) => InsightFood(foodId: 'h_${f.name}', name: f.name, emoji: f.emoji, imageUrl: f.userImageUrl ?? f.imageUrl, effect: f.effect))
                    .toList()
              : <InsightFood>[]);

    final triggerList = insight?.triggerSummary?.foods.isNotEmpty == true
        ? insight!.triggerSummary!.foods
        : (insight?.triggerFoods.isNotEmpty == true
              ? insight!.triggerFoods
                    .map((f) => InsightFood(foodId: 't_${f.name}', name: f.name, emoji: f.emoji, imageUrl: f.userImageUrl ?? f.imageUrl, effect: f.effect))
                    .toList()
              : <InsightFood>[]);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Card: Top Healing Foods
          if (healingList.isNotEmpty) ...[
            Expanded(
              child: Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF102319) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(18.w),
                  border: Border.all(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.28) : const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 22.w,
                          height: 22.w,
                          decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
                          child: Icon(LucideIcons.trophy, size: 11.w, color: Colors.white),
                        ),
                        Gap.w4,
                        Expanded(
                          child: Text(
                            'Top Healing Foods',
                            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)),
                          ),
                        ),
                      ],
                    ),
                    Gap.h2,
                    Text(
                      'Foods listed as supportive in this insight.',
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, color: context.insightColor(const Color(0xFF475569))),
                    ),
                      Gap.h8,

                      for (var i = 0; i < healingList.take(2).length; i++) ...[
                        if (i > 0) Gap.h6,
                      _HealingFoodItemTile(
                        imageUrl: healingList[i].imageUrl,
                        title: healingList[i].name,
                        sub: healingList[i].effect ?? 'No effect details available.',
                        badge: 'Supportive observation',
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          if (healingList.isNotEmpty && triggerList.isNotEmpty) Gap.w10,

          // Right Card: Top Trigger Food
          if (triggerList.isNotEmpty) ...[
            Expanded(
              child: Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF231416) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(18.w),
                  border: Border.all(color: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.45) : const Color(0xFFFCA5A5), width: 1.2.w),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626)).withValues(alpha: isDark ? 0.08 : 0.04),
                      blurRadius: 10.w,
                      offset: Offset(0, 2.w),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 22.w,
                          height: 22.w,
                          decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
                          child: Icon(LucideIcons.triangleAlert, size: 11.w, color: Colors.white),
                        ),
                        Gap.w4,
                        Expanded(
                          child: Text(
                      'Food Observed Near Symptoms',
                            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFFF87171) : const Color(0xFF991B1B)),
                          ),
                        ),
                      ],
                    ),
                    Gap.h2,
                    Text(
                      'This food was listed alongside symptoms in this insight.',
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, color: context.insightColor(const Color(0xFF475569))),
                    ),
                    Gap.h8,

                    Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(color: context.insightTheme.card, borderRadius: BorderRadius.circular(12.w)),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.w),
                            child: DynamicFoodImage(
                              keyword: triggerList.first.name,
                              imageUrl: triggerList.first.imageUrl,
                              width: 40.w,
                              height: 40.w,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Gap.w6,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  triggerList.first.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: InsightTheme.fontFamily,
                                    fontSize: 10.5.sp,
                                    fontWeight: FontWeight.w800,
                                    color: context.insightColor(const Color(0xFF0F172A)),
                                    height: 1.1,
                                  ),
                                ),
                                Gap.h2,
                                  if (triggerList.first.effect?.trim().isNotEmpty == true) Text(
                                  triggerList.first.effect!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.5.sp, color: context.insightColor(const Color(0xFF475569)), height: 1.15),
                                ),
                                Gap.h3,
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.18) : const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(6.w),
                                    border: Border.all(color: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.35) : const Color(0xFFFECACA), width: 0.8.w),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.triangleAlert, size: 7.w, color: isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C)),
                                      Gap.w2,
                                      Flexible(
                                        child: Text(
                                          'Symptom observation',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: InsightTheme.fontFamily,
                                            fontSize: 7.5.sp,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C),
                                          ),
                                        ),
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
                    Gap.h8,
                    Material(
                      color: isDark ? const Color(0xFF991B1B) : const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(10.w),
                      child: InkWell(
                        onTap: () {
                          FoodSwap? matchingSwap;
                          final targetName = triggerList.first.name.toLowerCase().trim();
                          for (final s in insight?.foodSwaps ?? <FoodSwap>[]) {
                            if (s.source.name.toLowerCase().trim() == targetName) {
                              matchingSwap = s;
                              break;
                            }
                          }
                          final swapObj =
                              matchingSwap ??
                              (insight?.foodSwaps.isNotEmpty == true
                                  ? insight!.foodSwaps.first
                                  : FoodSwap(
                                      id: 'swap_${triggerList.first.name.toLowerCase()}',
                                      source: SwapSource(foodId: 'food_trigger', name: triggerList.first.name),
                                      alternatives: const [],
                                    ));
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => BetterSwapsScreen(swap: swapObj)));
                        },
                        borderRadius: BorderRadius.circular(10.w),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.w),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.repeat, size: 11.w, color: Colors.white),
                              Gap.w6,
                              Builder(
                                builder: (_) {
                                  FoodSwap? match;
                                  final name = triggerList.first.name.toLowerCase().trim();
                                  for (final s in insight?.foodSwaps ?? <FoodSwap>[]) {
                                    if (s.source.name.toLowerCase().trim() == name) {
                                      match = s;
                                      break;
                                    }
                                  }
                                  final count = match?.alternatives.length ?? (insight?.foodSwaps.isNotEmpty == true ? insight!.foodSwaps.first.alternatives.length : 0);
                                  final label = count > 0 ? 'Find Swaps ($count Options) →' : 'Find Better Swaps →';
                                  return Text(
                                    label,
                                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.2),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HealingFoodItemTile extends StatelessWidget {
  const _HealingFoodItemTile({required this.imageUrl, required this.title, required this.sub, required this.badge});

  final String? imageUrl;
  final String title;
  final String sub;
  final String badge;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(6.w),
    decoration: BoxDecoration(color: context.insightTheme.card, borderRadius: BorderRadius.circular(12.w)),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.w),
          child: DynamicFoodImage(
            keyword: title,
            imageUrl: imageUrl,
            width: 36.w,
            height: 36.w,
            fit: BoxFit.cover,
          ),
        ),
        Gap.w6,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
              ),
              Text(
                sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.5.sp, color: context.insightColor(const Color(0xFF475569)), height: 1.15),
              ),
              SizedBox(height: 2.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
                decoration: BoxDecoration(color: context.insightColor(const Color(0xFFDCFCE7)), borderRadius: BorderRadius.circular(6.w)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.leaf, size: 7.w, color: const Color(0xFF15803D)),
                    Gap.w2,
                    Flexible(
                      child: Text(
                        badge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.sp, fontWeight: FontWeight.w700, color: const Color(0xFF15803D)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// =============================================================================
// FOOD IMPACT TAB: 4. RECENT FOOD IMPACTS SECTION
// =============================================================================
