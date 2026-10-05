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

    final filteredItems = switch (_selectedFilter) {
      'Healing' => items.where((i) => i.category == 'healing').toList(),
      'Good' => items.where((i) => i.category == 'good').toList(),
      'Watch' => items.where((i) => i.category == 'watch').toList(),
      _ => items,
    };

    final positiveCount = healingCount + goodCount;
    final positiveRatio = totalCount > 0 ? ((positiveCount / totalCount) * 100).round() : 100;

    return Scaffold(
      backgroundColor: context.appColorScheme.cardBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          GutSliverAppBar(title: 'FOOD INTELLIGENCE', centerTitle: true, showBrandingIcon: false, backgroundColor: theme.scaffold),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 8.w, 16.w, 28.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. HERO INTELLIGENCE DASHBOARD CARD
                _FoodIntelligenceHeroCard(positiveRatio: positiveRatio, positiveCount: positiveCount, watchCount: watchCount, totalCount: totalCount),
                Gap.h16,

                // 2. FILTER CATEGORY CHIPS
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  clipBehavior: Clip.none,
                  child: Row(
                    children: [
                      _FilterChip(label: 'All ($totalCount)', isSelected: _selectedFilter == 'All', onTap: () => setState(() => _selectedFilter = 'All')),
                      Gap.w8,
                      _FilterChip(
                        label: 'Healing ($healingCount)',
                        icon: LucideIcons.sprout,
                        iconColor: const Color(0xFF15803D),
                        isSelected: _selectedFilter == 'Healing',
                        onTap: () => setState(() => _selectedFilter = 'Healing'),
                      ),
                      Gap.w8,
                      _FilterChip(
                        label: 'Good ($goodCount)',
                        icon: LucideIcons.sparkles,
                        iconColor: const Color(0xFF16A34A),
                        isSelected: _selectedFilter == 'Good',
                        onTap: () => setState(() => _selectedFilter = 'Good'),
                      ),
                      Gap.w8,
                      _FilterChip(
                        label: 'Watch ($watchCount)',
                        icon: LucideIcons.triangleAlert,
                        iconColor: const Color(0xFFDC2626),
                        isSelected: _selectedFilter == 'Watch',
                        onTap: () => setState(() => _selectedFilter = 'Watch'),
                      ),
                    ],
                  ),
                ),
                Gap.h16,

                // 3. FOOD ITEMS SEPARATE LIST CARDS (using shared TopFoodTile)
                if (filteredItems.isEmpty) ...[
                  _EmptyFoodIntelligenceCard(filter: _selectedFilter),
                ] else ...[
                  Column(
                    children: [
                      for (final food in filteredItems) ...[TopFoodTile(item: food), Gap.h10],
                    ],
                  ),
                ],
                Gap.h16,

                // 4. HABIT ENCOURAGEMENT FOOTER
                const _HabitFooterCard(),
              ]),
            ),
          ),
        ],
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32.w,
                    height: 32.w,
                    decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
                    child: Center(
                      child: Icon(LucideIcons.leaf, size: 16.w, color: Colors.white),
                    ),
                  ),
                  Gap.w10,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Food Intelligence',
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
                        style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, color: theme.textTertiary),
                      ),
                    ],
                  ),
                ],
              ),

              // Positive Ratio Badge
              Container(
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
            onPressed: () => context.push(AppRoutes.scannerPath('meal')),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.isSelected, required this.onTap, this.icon, this.iconColor});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedBg = isDark ? Colors.white : const Color(0xFF171717);
    final selectedFg = isDark ? Colors.black : Colors.white;
    final unselectedFg = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final unselectedBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(100.w),
          border: Border.all(color: isSelected ? selectedBg : unselectedBorder, width: 1.w),
          boxShadow: isSelected && !isDark ? [BoxShadow(color: const Color(0xFF17171B).withValues(alpha: 0.15), blurRadius: 4.w, offset: Offset(0, 2.w))] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: InsightTheme.fontFamily,
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? selectedFg : unselectedFg,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}
