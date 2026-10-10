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
    final positiveRatio = totalCount > 0 ? ((positiveCount / totalCount) * 100).round() : 0;

    return Scaffold(
      backgroundColor: theme.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            _TopFoodsPageHeader(title: 'Food Intelligence', subtitle: 'Foods and responses found in your meal logs.', onInfo: () => _showFoodIntelligenceInfo(context)),
            SizedBox(
              height: 38.w,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                physics: const BouncingScrollPhysics(),
                itemCount: 4,
                separatorBuilder: (_, _) => SizedBox(width: 8.w),
                itemBuilder: (context, index) {
                  const filters = ['All', 'Most Positive', 'Most Negative', 'Most Logged'];
                  final filter = filters[index];
                  return _TopFoodsFilterChip(label: filter, selected: filter == _selectedFilter, onTap: () => setState(() => _selectedFilter = filter));
                },
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
                    for (final item in topFoodItems) ...[_TopFoodInsightCard(item: item, statusLabel: item.statusLabel), Gap.h10],
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
        content: const Text(
          'These foods and responses come from your logged meal history. The tabs reorder your foods by positive observations, negative observations, or response count. Associations in your logs do not prove that a food caused a response.',
        ),
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
        list.add(TopFoodItemData(title: f.name, frequency: countStr, description: desc, badge: 'Supportive', isPositive: true, category: 'healing', imageUrl: f.imageUrl));
      }
    }

    // 2. Healing Foods
    for (final f in insight.healingFoods) {
      final key = f.name.toLowerCase().trim();
      if (key.isEmpty || !seen.add(key)) continue;
      final occurrences = countOccurrences(f.name);
      final countStr = occurrences > 0 ? '${occurrences}x logged' : '';
      final desc = f.effect.trim().isNotEmpty ? f.effect : null;
      list.add(TopFoodItemData(title: f.name, frequency: countStr, description: desc, badge: 'Supportive', isPositive: true, category: 'healing', imageUrl: f.userImageUrl ?? f.imageUrl));
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
      list.add(TopFoodItemData(title: fi.food, frequency: countStr, description: desc, badge: 'Good', isPositive: true, category: 'good', imageUrl: fi.userImageUrl ?? fi.imageUrl));
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
      list.add(TopFoodItemData(title: f.name, frequency: countStr, description: desc, badge: 'Watch', isPositive: false, category: 'watch', imageUrl: f.userImageUrl ?? f.imageUrl));
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
      list.add(TopFoodItemData(title: fi.food, frequency: countStr, description: desc, badge: 'Watch', isPositive: false, category: 'watch', imageUrl: fi.userImageUrl ?? fi.imageUrl));
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
    final theme = context.insightTheme;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: theme.borderSubtle),
        boxShadow: [BoxShadow(color: theme.textPrimary.withValues(alpha: 0.04), blurRadius: 14.w, offset: Offset(0, 4.w))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FoodImpactSectionHeader(title: 'Food Impact So Far', subtitle: 'Based on your logged meals and how you felt afterward.'),
          Gap.h12,
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '$positiveRatio%',
                style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 24.sp, fontWeight: FontWeight.w800, color: theme.success),
              ),
              Gap.w8,
              Expanded(
                child: Text(
                  totalCount == 0 ? 'Log meals to build your food balance.' : 'of your tracked foods are supportive',
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, color: theme.textSecondary),
                ),
              ),
            ],
          ),
          Gap.h8,
          ClipRRect(
            borderRadius: BorderRadius.circular(20.w),
            child: SizedBox(
              height: 8.w,
              child: Row(
                children: [
                  if (totalCount == 0)
                    Expanded(child: Container(color: theme.borderSubtle))
                  else ...[
                    if (positiveRatio > 0)
                      Expanded(
                        flex: positiveRatio,
                        child: Container(color: theme.success),
                      ),
                    if (positiveRatio < 100)
                      Expanded(
                        flex: 100 - positiveRatio,
                        child: Container(color: const Color(0xFFDC2626)),
                      ),
                  ],
                ],
              ),
            ),
          ),
          Gap.h10,
          Row(
            children: [
              _HeroStatPill(icon: LucideIcons.sprout, iconColor: theme.success, bgColor: theme.successSoft, label: '$positiveCount Supportive'),
              Gap.w8,
              _HeroStatPill(icon: LucideIcons.triangleAlert, iconColor: const Color(0xFFDC2626), bgColor: const Color(0xFFFEF2F2), label: '$watchCount To Monitor'),
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
