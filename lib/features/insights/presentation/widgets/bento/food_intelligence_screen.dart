part of 'insight_bento_screens.dart';

/// Food intelligence presentation components.

class FoodIntelligenceScreen extends StatefulWidget {
  const FoodIntelligenceScreen({super.key, this.insight});

  final AIInsight? insight;

  @override
  State<FoodIntelligenceScreen> createState() => _FoodIntelligenceScreenState();
}

class _FoodIntelligenceScreenState extends State<FoodIntelligenceScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = context.insightTheme;
    final activeInsight = widget.insight ?? _getLatestInsight(context);
    final items = _buildFoodItems(activeInsight);

    final healingCount = items.where((i) => i.category == 'healing').length;
    final goodCount = items.where((i) => i.category == 'good').length;
    final watchCount = items.where((i) => i.category == 'watch').length;
    final totalCount = items.length;

    _sortFoodItems(items, activeInsight);
    final topFoodItems = items.map((item) => _toTopFoodInsight(item, activeInsight)).toList();

    final positiveCount = healingCount + goodCount;
    final positiveRatio = totalCount > 0 ? ((positiveCount / totalCount) * 100).round() : 100;

    return Scaffold(
      backgroundColor: theme.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            _TopFoodsPageHeader(
              title: 'Food Intelligence',
              subtitle: 'Foods and responses found in your meal logs.',
              onInfo: () => _showFoodIntelligenceInfo(context),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    for (final filter in const ['All', 'Most Positive', 'Most Negative', 'Most Logged']) ...[
                      if (filter != 'All') SizedBox(width: 6.w),
                      _TopFoodsFilterChip(label: filter, selected: filter == _selectedFilter, onTap: () => setState(() => _selectedFilter = filter)),
                    ],
                  ],
                ),
              ),
            ),
            Gap.h12,
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 28.w),
                children: [
                  _FoodIntelligenceHeroCard(positiveRatio: positiveRatio, positiveCount: positiveCount, watchCount: watchCount, totalCount: totalCount),
                  Gap.h16,
                  if (topFoodItems.isEmpty)
                    _EmptyFoodIntelligenceCard(filter: _selectedFilter)
                  else
                    for (final item in topFoodItems) ...[
                      _TopFoodInsightCard(item: item, statusLabel: item.statusLabel),
                      Gap.h10,
                    ],
                  Gap.h16,
                  const _HabitFooterCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sortFoodItems(List<TopFoodItemData> items, AIInsight? insight) {
    int observations(TopFoodItemData item) => int.tryParse(RegExp(r'\d+').firstMatch(item.frequency)?.group(0) ?? '') ?? 0;
    final negativeCounts = <String, int>{};
    for (var i = 0; i < (insight?.foodImpacts.length ?? 0); i++) {
      final impact = insight!.foodImpacts[i];
      final key = impact.food.toLowerCase().trim();
      if (const {'negative', 'trigger', 'watch', 'bad'}.contains(impact.impactType.toLowerCase())) {
        negativeCounts.update(key, (count) => count + 1, ifAbsent: () => 1);
      }
    }

    int negativeObservations(TopFoodItemData item) => negativeCounts[item.title.toLowerCase().trim()] ?? 0;
    switch (_selectedFilter) {
      case 'Most Positive':
        items.sort((a, b) {
          final byPositive = (b.isPositive ? 1 : 0).compareTo(a.isPositive ? 1 : 0);
          if (byPositive != 0) return byPositive;
          final byCount = observations(b).compareTo(observations(a));
          return byCount != 0 ? byCount : a.title.compareTo(b.title);
        });
      case 'Most Logged':
        items.sort((a, b) {
          final byCount = observations(b).compareTo(observations(a));
          return byCount != 0 ? byCount : a.title.compareTo(b.title);
        });
      case 'Most Negative':
        items.sort((a, b) {
          final byNegative = negativeObservations(b).compareTo(negativeObservations(a));
          if (byNegative != 0) return byNegative;
          final byWatchCategory = (b.category == 'watch' ? 1 : 0).compareTo(a.category == 'watch' ? 1 : 0);
          if (byWatchCategory != 0) return byWatchCategory;
          final byCount = observations(b).compareTo(observations(a));
          return byCount != 0 ? byCount : a.title.compareTo(b.title);
        });
      default:
        items.sort((a, b) {
          final byPositive = (b.isPositive ? 1 : 0).compareTo(a.isPositive ? 1 : 0);
          if (byPositive != 0) return byPositive;
          final byCount = observations(b).compareTo(observations(a));
          return byCount != 0 ? byCount : a.title.compareTo(b.title);
        });
    }
  }

  _TopFoodInsight _toTopFoodInsight(TopFoodItemData food, AIInsight? insight) {
    final item = _TopFoodInsight(name: food.title, imageUrl: food.imageUrl, effect: food.description, statusLabel: food.badge, isTopFood: food.isPositive);
    final key = food.title.toLowerCase().trim();
    for (final impact in insight?.foodImpacts ?? const <FoodImpact>[]) {
      if (impact.food.toLowerCase().trim() != key) continue;
      item.observations++;
      item.impacts.add(impact);
      final type = impact.impactType.toLowerCase();
      if (const {'positive', 'healing', 'good', 'supportive'}.contains(type)) {
        item.positiveObservations++;
        item.addEffect(impact.effect);
      } else if (const {'negative', 'trigger', 'watch', 'bad'}.contains(type)) {
        item.negativeObservations++;
      }
    }
    if (item.observations == 0) {
      item.observations = int.tryParse(RegExp(r'\d+').firstMatch(food.frequency)?.group(0) ?? '') ?? 0;
    }
    if (item.effects.isEmpty && food.description?.trim().isNotEmpty == true) item.addEffect(food.description);
    return item;
  }

  void _showFoodIntelligenceInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Food Intelligence'),
        content: const Text('These foods and responses come from your logged meal history. The tabs reorder your foods by positive observations, negative observations, or response count. Associations in your logs do not prove that a food caused a response.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))],
      ),
    );
  }

  static AIInsight? _getLatestInsight(BuildContext context) {
    try {
      return context.read<InsightsNotifier>().latestInsight;
    } on ProviderNotFoundException {
      return null;
    }
  }

  List<TopFoodItemData> _buildFoodItems(AIInsight? insight) {
    if (insight == null) return const <TopFoodItemData>[];
    final list = <TopFoodItemData>[];
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

    // 1. Healing Summary Foods
    if (insight.healingSummary?.foods.isNotEmpty == true) {
      for (final f in insight.healingSummary!.foods) {
        final key = f.name.toLowerCase().trim();
        if (key.isEmpty || !seen.add(key)) continue;
        final occurrences = countOccurrences(f.name);
        final countStr = occurrences > 0 ? '${occurrences}x logged' : '';
        final desc = f.effect?.trim().isNotEmpty == true ? f.effect : null;
        list.add(
          TopFoodItemData(
            title: f.name,
            frequency: countStr,
            description: desc,
            badge: 'Supportive',
            isPositive: true,
            category: 'healing',
            imageUrl: f.imageUrl,
          ),
        );
      }
    }

    // 2. Healing Foods
    for (final f in insight.healingFoods) {
      final key = f.name.toLowerCase().trim();
      if (key.isEmpty || !seen.add(key)) continue;
      final occurrences = countOccurrences(f.name);
      final countStr = occurrences > 0 ? '${occurrences}x logged' : '';
      final desc = f.effect.trim().isNotEmpty ? f.effect : null;
      list.add(
        TopFoodItemData(
          title: f.name,
          frequency: countStr,
          description: desc,
          badge: 'Supportive',
          isPositive: true,
          category: 'healing',
          imageUrl: f.userImageUrl ?? f.imageUrl,
        ),
      );
    }

    // 3. Positive / Good Food Impacts
    for (final fi in insight.foodImpacts.where((i) {
      final type = i.impactType.toLowerCase();
      return type == 'positive' || type == 'healing' || type == 'good' || type == 'supportive';
    })) {
      final key = fi.food.toLowerCase().trim();
      if (key.isEmpty || !seen.add(key)) continue;
      final occurrences = countOccurrences(fi.food);
      final countStr = occurrences > 0 ? '${occurrences}x logged' : '';
      final desc = fi.effect.trim().isNotEmpty ? fi.effect : null;
      list.add(
        TopFoodItemData(
          title: fi.food,
          frequency: countStr,
          description: desc,
          badge: 'Good',
          isPositive: true,
          category: 'good',
          imageUrl: fi.userImageUrl ?? fi.imageUrl,
        ),
      );
    }

    // 4. Trigger Summary Foods
    if (insight.triggerSummary?.foods.isNotEmpty == true) {
      for (final f in insight.triggerSummary!.foods) {
        final key = f.name.toLowerCase().trim();
        if (key.isEmpty || !seen.add(key)) continue;
        final occurrences = countOccurrences(f.name);
        final countStr = occurrences > 0 ? '${occurrences}x logged' : '';
        final desc = f.effect?.trim().isNotEmpty == true ? f.effect : null;
        list.add(TopFoodItemData(title: f.name, frequency: countStr, description: desc, badge: 'Watch', isPositive: false, category: 'watch', imageUrl: f.imageUrl));
      }
    }

    // 5. Trigger Foods
    for (final f in insight.triggerFoods) {
      final key = f.name.toLowerCase().trim();
      if (key.isEmpty || !seen.add(key)) continue;
      final occurrences = countOccurrences(f.name);
      final countStr = occurrences > 0 ? '${occurrences}x logged' : '';
      final desc = f.effect.trim().isNotEmpty ? f.effect : null;
      list.add(
        TopFoodItemData(
          title: f.name,
          frequency: countStr,
          description: desc,
          badge: 'Watch',
          isPositive: false,
          category: 'watch',
          imageUrl: f.userImageUrl ?? f.imageUrl,
        ),
      );
    }

    // 6. Food Impacts (Watch / Negative)
    for (final fi in insight.foodImpacts.where((i) {
      final type = i.impactType.toLowerCase();
      return type == 'negative' || type == 'trigger' || type == 'watch' || type == 'bad';
    })) {
      final key = fi.food.toLowerCase().trim();
      if (key.isEmpty || !seen.add(key)) continue;
      final occurrences = countOccurrences(fi.food);
      final countStr = occurrences > 0 ? '${occurrences}x logged' : '';
      final desc = fi.effect.trim().isNotEmpty ? fi.effect : null;
      list.add(
        TopFoodItemData(
          title: fi.food,
          frequency: countStr,
          description: desc,
          badge: 'Watch',
          isPositive: false,
          category: 'watch',
          imageUrl: fi.userImageUrl ?? fi.imageUrl,
        ),
      );
    }

    return list;
  }
}

class _FoodIntelligenceHeroCard extends StatelessWidget {
  const _FoodIntelligenceHeroCard({required this.positiveRatio, required this.positiveCount, required this.watchCount, required this.totalCount});

  final int positiveRatio;
  final int positiveCount;
  final int watchCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = context.insightTheme;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF102319) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(22.w),
        border: Border.all(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.28) : const Color(0xFFDCFCE7), width: 1.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF15803D).withValues(alpha: isDark ? 0.10 : 0.05),
            blurRadius: 12.w,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
                child: Center(child: Icon(LucideIcons.leaf, size: 16.w, color: Colors.white)),
              ),
              Gap.w10,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Food Impact So Far',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: InsightTheme.fontFamily,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Foods shaping your gut health',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, color: theme.textTertiary),
                    ),
                  ],
                ),
              ),
              Gap.w8,
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.w),
                    decoration: BoxDecoration(
                      color: theme.card,
                      borderRadius: BorderRadius.circular(16.w),
                      border: Border.all(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.28) : const Color(0xFFDCFCE7)),
                      boxShadow: [BoxShadow(color: theme.textPrimary.withValues(alpha: 0.04), blurRadius: 6.w, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.trendingUp, size: 13.w, color: theme.success),
                        Gap.w4,
                        Text(
                          '$positiveRatio% Positive',
                          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: theme.success),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Gap.h14,

          // Visual Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8.w),
            child: SizedBox(
              height: 7.w,
              child: Row(
                children: [
                  Expanded(
                    flex: positiveRatio > 0 ? positiveRatio : 1,
                    child: Container(color: const Color(0xFF16A34A)),
                  ),
                  if (100 - positiveRatio > 0)
                    Expanded(
                      flex: 100 - positiveRatio,
                      child: Container(color: const Color(0xFFEF4444)),
                    ),
                ],
              ),
            ),
          ),
          Gap.h12,

          // Stats Chips Row
          Row(
            children: [
              _HeroStatPill(
                icon: LucideIcons.sprout,
                iconColor: context.insightColor(const Color(0xFF15803D)),
                bgColor: context.insightColor(const Color(0xFFDCFCE7)),
                label: '$positiveCount Gut Supporting',
              ),
              Gap.w8,
              _HeroStatPill(
                icon: LucideIcons.triangleAlert,
                iconColor: context.insightColor(const Color(0xFF991B1B)),
                bgColor: context.insightColor(const Color(0xFFFEE2E2)),
                label: '$watchCount To Monitor',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStatPill extends StatelessWidget {
  const _HeroStatPill({required this.icon, required this.iconColor, required this.bgColor, required this.label});

  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = context.insightTheme;
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.w),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(12.w),
          border: Border.all(color: theme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, size: 10.w, color: iconColor),
            ),
            Gap.w6,
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: theme.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFoodIntelligenceCard extends StatelessWidget {
  const _EmptyFoodIntelligenceCard({required this.filter});

  final String filter;

  @override
  Widget build(BuildContext context) {
    final theme = context.insightTheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 28.w),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(22.w),
        border: Border.all(color: theme.border),
        boxShadow: [BoxShadow(color: theme.textPrimary.withValues(alpha: 0.03), blurRadius: 10.w, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(color: theme.cardSubtle, shape: BoxShape.circle),
            child: Icon(LucideIcons.apple, size: 28.w, color: theme.textTertiary),
          ),
          Gap.h12,
          Text(
            filter == 'All' ? 'No Food Intelligence Items Yet' : 'No $filter Foods Recorded Yet',
            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: theme.textPrimary),
          ),
          Gap.h6,
          Text(
            'Keep logging your meals and food scans to discover which foods support or affect your gut health.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, color: theme.textTertiary, height: 1.4),
          ),
          Gap.h16,
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF15803D),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.w),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.w)),
            ),
            icon: Icon(LucideIcons.plus, size: 16.w),
            label: Text(
              'Log a Meal',
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w700),
            ),
            onPressed: () => openScannerAndProcessResult(context, 'meal'),
          ),
        ],
      ),
    );
  }
}

class _HabitFooterCard extends StatelessWidget {
  const _HabitFooterCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = context.insightTheme;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF102319) : const Color(0xFFF4FAF5),
        borderRadius: BorderRadius.circular(18.w),
        border: Border.all(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.28) : const Color(0xFFDCFCE7), width: 1.w),
      ),
      child: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(color: context.insightColor(const Color(0xFFDCFCE7)), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(LucideIcons.sprout, size: 16.w, color: theme.success),
          ),
          Gap.w10,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keep Building Good Habits',
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF0F172A)),
                ),
                Gap.h2,
                Text(
                  'Small, consistent choices add up to a healthier, happier gut.',
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, color: theme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
