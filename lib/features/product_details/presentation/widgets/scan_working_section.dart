part of 'scan_result_widgets.dart';

/// Positive food-impact presentation component.

class ScanWorkingSection extends StatelessWidget {
  const ScanWorkingSection({super.key, required this.scanData});
  final ScanResult scanData;

  static bool hasData(ScanResult scanData) {
    final textContent = '${scanData.productName} ${scanData.impact} ${scanData.brand}'.toLowerCase();
    if (scanData.isOrganic == true || textContent.contains('organic') || textContent.contains('bio')) return true;
    final n = scanData.nutrients;
    if (n != null) {
      if ((n.proteins ?? 0) >= 2.0 || (n.fiber ?? 0) >= 1.0 || (n.saturatedFat ?? 0) <= 2.0 || (n.sugars ?? 0) <= 10.0 || (n.salt ?? 0) <= 1.5 || (n.calories ?? 0) <= 250) {
        return true;
      }
    }
    if (scanData.ingredients.any((ing) => ['green', 'low', 'positive'].contains(ing.colorName.toLowerCase()))) return true;
    if (scanData.impacts.any((imp) => ['positive', 'healing', 'good', 'low'].contains(imp.level.toLowerCase()))) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final serving = scanData.servingSize ?? '1 serving';

    final positiveItems = <_ScanFactor>[];
    final addedTitles = <String>{};

    void addPositive(_ScanFactor item) {
      if (addedTitles.add(item.title.toLowerCase())) positiveItems.add(item);
    }

    // 1. Organic / clean tags
    final textContent = '${scanData.productName} ${scanData.impact} ${scanData.brand}'.toLowerCase();
    if (scanData.isOrganic == true || textContent.contains('organic') || textContent.contains('bio')) {
      addPositive(
        _ScanFactor(icon: AppIcons.leaf, iconColor: t.positive, title: 'Organic Certified', subtitle: '+10 Gut Score bonus · Certified organic ingredients', valueText: '+10', badgeColor: t.positive),
      );
    }

    // 2. Favorable nutrients (per serving)
    final n = scanData.nutrients;
    if (n != null) {
      if ((n.proteins ?? 0) >= 2.0) {
        addPositive(
          _ScanFactor(
            icon: AppIcons.dumbbell,
            iconColor: t.positive,
            title: 'Protein',
            subtitle: (n.proteins ?? 0) >= 8.0 ? 'High protein source' : 'Provides muscle-building protein',
            valueText: '${(n.proteins ?? 0).toInt()}g',
            badgeColor: t.positive,
          ),
        );
      }
      if ((n.fiber ?? 0) >= 1.0) {
        addPositive(
          _ScanFactor(
            icon: AppIcons.wheat,
            iconColor: t.positive,
            title: 'Fiber',
            subtitle: (n.fiber ?? 0) >= 3.0 ? 'High dietary fiber' : 'Supports digestive motility',
            valueText: '${(n.fiber ?? 0).toStringAsFixed(1)}g',
            badgeColor: t.positive,
          ),
        );
      }
      if ((n.saturatedFat ?? 0) <= 2.0) {
        addPositive(
          _ScanFactor(
            icon: AppIcons.droplet,
            iconColor: t.positive,
            title: 'Saturated Fat',
            subtitle: (n.saturatedFat ?? 0) == 0 ? 'No saturated fat' : 'Low saturated fat',
            valueText: '${(n.saturatedFat ?? 0).toInt()}g',
            badgeColor: t.positive,
          ),
        );
      }
      if ((n.sugars ?? 0) <= 10.0) {
        addPositive(
          _ScanFactor(
            icon: AppIcons.candy,
            iconColor: t.positive,
            title: 'Sugar',
            subtitle: (n.sugars ?? 0) == 0 ? 'No sugar added' : 'Low in sugar',
            valueText: '${(n.sugars ?? 0).toInt()}g',
            badgeColor: t.positive,
          ),
        );
      }
      if ((n.salt ?? 0) <= 1.5) {
        addPositive(
          _ScanFactor(
            icon: AppIcons.scale,
            iconColor: t.positive,
            title: 'Sodium',
            subtitle: (n.salt ?? 0) <= 0.1 ? 'No sodium' : 'Low sodium level',
            valueText: '${((n.salt ?? 0) * 400).toInt()}mg',
            badgeColor: t.positive,
          ),
        );
      }
      if ((n.calories ?? 0) <= 250) {
        addPositive(
          _ScanFactor(
            icon: AppIcons.flame,
            iconColor: t.positive,
            title: 'Calories',
            subtitle: (n.calories ?? 0) <= 100 ? 'Low caloric density' : 'Moderate caloric impact',
            valueText: '${(n.calories ?? 0).toInt()} Cal',
            badgeColor: t.positive,
          ),
        );
      }
    }

    // 3. Positive green ingredients
    for (final ing in scanData.ingredients) {
      if (['green', 'low', 'positive'].contains(ing.colorName.toLowerCase())) {
        addPositive(
          _ScanFactor(
            icon: AppIcons.leaf,
            iconColor: t.positive,
            title: ing.name,
            subtitle: ing.impact.isNotEmpty ? ing.impact : 'Beneficial gut food component',
            trailing: Icon(Icons.check_rounded, color: t.positive, size: 18.sp),
          ),
        );
      }
    }

    // 4. Positive AI impacts
    for (final imp in scanData.impacts) {
      if (['positive', 'healing', 'good', 'low'].contains(imp.level.toLowerCase())) {
        addPositive(
          _ScanFactor(
            icon: AppIcons.sparkles,
            iconColor: t.positive,
            title: imp.title,
            subtitle: imp.level.isNotEmpty ? imp.level : 'Supports gut wellness',
            trailing: Icon(Icons.check_rounded, color: t.positive, size: 18.sp),
          ),
        );
      }
    }

    if (positiveItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: t.positive.withAlpha(20), shape: BoxShape.circle),
              child: Icon(Icons.check_circle_rounded, color: t.positive, size: 22.sp),
            ),
            Gap.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What\'s Working',
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.titleSize.sp, fontWeight: FontWeight.w700, color: t.textPrimary),
                  ),
                  Text(
                    AppStrings.perServing(serving),
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.footSize.sp, fontWeight: FontWeight.w400, color: t.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        Gap.h16,
        ...positiveItems.map((item) => _buildModernFactorCard(context, item, isPositive: true)),
      ],
    );
  }
}

/// 🌟 Section 5: "What to watch" (negative factors + tappable additives/allergens).
