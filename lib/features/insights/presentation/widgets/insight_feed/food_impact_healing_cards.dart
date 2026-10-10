part of 'insights_feed.dart';

/// Healing and trigger food-impact cards.

class _SideBySideHealingAndTriggerCards extends StatelessWidget {
  const _SideBySideHealingAndTriggerCards({this.insight});

  final AIInsight? insight;

  @override
  Widget build(BuildContext context) {
    final positiveFromImpacts = _foodsFromImpacts(positive: true);
    final negativeFromImpacts = _foodsFromImpacts(positive: false);
    final healingList = insight?.healingSummary?.foods.isNotEmpty == true
        ? insight!.healingSummary!.foods
        : insight?.healingFoods.isNotEmpty == true
        ? insight!.healingFoods.map((f) => InsightFood(foodId: 'h_${f.name}', name: f.name, emoji: f.emoji, imageUrl: f.userImageUrl ?? f.imageUrl, effect: f.effect)).toList()
        : positiveFromImpacts;
    final triggerList = insight?.triggerSummary?.foods.isNotEmpty == true
        ? insight!.triggerSummary!.foods
        : insight?.triggerFoods.isNotEmpty == true
        ? insight!.triggerFoods.map((f) => InsightFood(foodId: 't_${f.name}', name: f.name, emoji: f.emoji, imageUrl: f.userImageUrl ?? f.imageUrl, effect: f.effect)).toList()
        : negativeFromImpacts;
    final hasHealing = healingList.isNotEmpty;
    final hasTrigger = triggerList.isNotEmpty;

    if (!hasHealing && !hasTrigger) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: context.insightTheme.card,
          borderRadius: BorderRadius.circular(18.w),
          border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0))),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FoodImpactSectionHeader(
              title: 'Healing & Trigger Foods',
              subtitle: 'No specific foods identified yet. Keep logging meals to discover what supports or upsets your gut.',
              icon: LucideIcons.utensils,
              iconColor: Color(0xFFF5A623),
            ),
          ],
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 560.w;
        final cardWidth = isCompact ? constraints.maxWidth : (constraints.maxWidth - 10.w) / 2;
        return Wrap(
          spacing: 10.w,
          runSpacing: 10.w,
          children: [
            // Left Card: Top Healing Foods
            if (healingList.isNotEmpty) ...[
              Container(
                width: cardWidth,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF111F19) : const Color(0xFFF5FBF7),
                  borderRadius: BorderRadius.circular(20.w),
                  border: Border.all(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.22) : const Color(0xFFD8EFE2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FoodImpactSectionHeader(title: 'Supportive Food Patterns', subtitle: 'Foods logged near better reported outcomes.', icon: LucideIcons.leaf, iconColor: Color(0xFF15803D)),
                    Gap.h12,
                    for (var i = 0; i < healingList.take(2).length; i++) ...[
                      if (i > 0) Gap.h8,
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
            ],

            // Right Card: Top Trigger Food
            if (triggerList.isNotEmpty) ...[
              Container(
                width: cardWidth,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1718) : const Color(0xFFFFFAFA),
                  borderRadius: BorderRadius.circular(20.w),
                  border: Border.all(color: isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.55) : const Color(0xFFFECACA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FoodImpactSectionHeader(
                      title: 'Observed Near Symptoms',
                      subtitle: 'Logged around symptoms. This is an association, not proof of cause.',
                      icon: LucideIcons.triangleAlert,
                      iconColor: Color(0xFFDC2626),
                    ),
                    Gap.h12,

                    Container(
                      padding: EdgeInsets.all(9.w),
                      decoration: BoxDecoration(
                        color: context.insightTheme.card,
                        borderRadius: BorderRadius.circular(15.w),
                        border: Border.all(color: context.insightTheme.borderSubtle),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(11.w),
                            child: DynamicFoodImage(
                              keyword: triggerList.first.name,
                              imageUrl: triggerList.first.imageUrl,
                              width: 56.w,
                              height: 56.w,
                              fit: BoxFit.cover,
                              placeholder: Container(color: const Color(0xFFFEE2E2)),
                              errorWidget: Container(
                                color: const Color(0xFFFEF2F2),
                                alignment: Alignment.center,
                                child: Icon(LucideIcons.utensils, size: 22.w, color: const Color(0xFFB42318)),
                              ),
                            ),
                          ),
                          Gap.w10,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  triggerList.first.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                                ),
                                if (triggerList.first.effect?.trim().isNotEmpty == true) ...[
                                  Gap.h3,
                                  Text(
                                    triggerList.first.effect!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, color: context.insightColor(const Color(0xFF475569)), height: 1.2),
                                  ),
                                  Gap.h6,
                                ] else
                                  Gap.h6,
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.w),
                                  decoration: BoxDecoration(color: isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.3) : const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(20.w)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.triangleAlert, size: 10.w, color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB42318)),
                                      Gap.w4,
                                      Flexible(
                                        child: Text(
                                          'Symptom observation',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: InsightTheme.fontFamily,
                                            fontSize: 9.sp,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB42318),
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
                    Gap.h10,
                    Material(
                      color: isDark ? const Color(0xFF991B1B) : const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(14.w),
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
                          final swapObj = matchingSwap ?? FoodSwap(
                            id: 'swap_${triggerList.first.name.toLowerCase()}',
                            source: SwapSource(foodId: 'food_trigger', name: triggerList.first.name),
                            alternatives: const [],
                          );
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => BetterSwapsScreen(swap: swapObj)));
                        },
                        borderRadius: BorderRadius.circular(14.w),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.w),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.repeat, size: 14.w, color: Colors.white),
                              Gap.w8,
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
                                  final count = match?.alternatives.length ?? 0;
                                  final label = count > 0 ? 'Find Better Swaps ($count Options)' : 'Find Better Swaps';
                                  return Text(
                                    label,
                                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w800, color: Colors.white),
                                  );
                                },
                              ),
                              Gap.w6,
                              Icon(Icons.arrow_forward_rounded, size: 14.w, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  List<InsightFood> _foodsFromImpacts({required bool positive}) {
    final grouped = <String, List<FoodImpact>>{};
    for (final impact in insight?.foodImpacts ?? const <FoodImpact>[]) {
      final type = impact.impactType.toLowerCase().trim();
      final matches = positive ? const {'positive', 'healing', 'good', 'supportive'}.contains(type) : const {'negative', 'trigger', 'bad', 'watch'}.contains(type);
      if (!matches || impact.food.trim().isEmpty) continue;
      grouped.putIfAbsent(impact.food.trim().toLowerCase(), () => []).add(impact);
    }

    final entries = grouped.entries.toList()..sort((a, b) => b.value.length.compareTo(a.value.length));
    return [
      for (final entry in entries)
        InsightFood(
          foodId: '${positive ? 'positive' : 'negative'}_${entry.key}',
          name: entry.value.first.food.trim(),
          emoji: entry.value.first.emoji,
          imageUrl: entry.value.first.userImageUrl ?? entry.value.first.imageUrl,
          effect: entry.value.first.effect,
          impactLevel: positive ? 'positive' : 'negative',
        ),
    ];
  }
}

class _HealingFoodItemTile extends StatelessWidget {
  const _HealingFoodItemTile({required this.imageUrl, required this.title, required this.sub, required this.badge});

  final String? imageUrl;
  final String title;
  final String sub;
  final String badge;

  @override
  Widget build(BuildContext context) {
    final theme = context.insightTheme;
    return Container(
      padding: EdgeInsets.all(9.w),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(15.w),
        border: Border.all(color: theme.borderSubtle),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11.w),
            child: DynamicFoodImage(
              keyword: title,
              imageUrl: imageUrl,
              width: 56.w,
              height: 56.w,
              fit: BoxFit.cover,
              placeholder: Container(color: const Color(0xFFE7F6E7)),
              errorWidget: Container(
                color: const Color(0xFFE7F6E7),
                alignment: Alignment.center,
                child: Icon(LucideIcons.leaf, size: 22.w, color: const Color(0xFF15803D)),
              ),
            ),
          ),
          Gap.w10,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                ),
                Gap.h2,
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, color: context.insightColor(const Color(0xFF475569))),
                ),
                Gap.h4,
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.w),
                  decoration: BoxDecoration(color: context.insightColor(const Color(0xFFDCFCE7)), borderRadius: BorderRadius.circular(20.w)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.leaf, size: 10.w, color: theme.success),
                      Gap.w4,
                      Text(
                        badge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.sp, fontWeight: FontWeight.w700, color: theme.success),
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
}

// =============================================================================
// FOOD IMPACT TAB: 4. RECENT FOOD IMPACTS SECTION
// =============================================================================
