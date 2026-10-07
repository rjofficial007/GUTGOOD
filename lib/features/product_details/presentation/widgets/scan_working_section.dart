part of 'scan_result_widgets.dart';

/// Positive food-impact presentation component.

class ScanWorkingSection extends StatelessWidget {
  const ScanWorkingSection({super.key, required this.scanData});
  final ScanResult scanData;

  static bool hasData(ScanResult scanData) {
    if (scanData.isOrganic == true) return true;
    final n = scanData.nutrients;
    if (n != null) {
      if ((n.proteins ?? 0) >= 2.0 ||
          (n.fiber ?? 0) >= 1.0 ||
          (n.saturatedFat != null && n.saturatedFat! <= 2.0) ||
          (n.sugars != null && n.sugars! <= 10.0) ||
          (n.salt != null && n.salt! <= 1.5) ||
          (n.calories != null && n.calories! <= 250)) {
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

    final positiveItems = <_ScanFactor>[];
    final addedTitles = <String>{};

    void addPositive(_ScanFactor item) {
      if (addedTitles.add(item.title.toLowerCase())) positiveItems.add(item);
    }

    // 1. Organic status from structured scan data
    if (scanData.isOrganic == true) {
      addPositive(_ScanFactor(icon: AppIcons.leaf, iconColor: t.positive, title: 'Organic', subtitle: '+10 score bonus · Organic status reported', valueText: '+10', badgeColor: t.positive));
    }

    // 2. Nutrient facts use the basis shown in the section header.
    final n = scanData.nutrients;
    if (n != null) {
      if (n.proteins != null && n.proteins! >= 2.0) {
        addPositive(_ScanFactor(icon: AppIcons.dumbbell, iconColor: t.positive, title: 'Protein', subtitle: 'Protein in this basis', valueText: '${n.proteins!.toInt()}g', badgeColor: t.positive));
      }
      if (n.fiber != null && n.fiber! >= 1.0) {
        addPositive(
          _ScanFactor(icon: AppIcons.wheat, iconColor: t.positive, title: 'Fiber', subtitle: 'Dietary fiber in this basis', valueText: '${n.fiber!.toStringAsFixed(1)}g', badgeColor: t.positive),
        );
      }
      if (n.saturatedFat != null && n.saturatedFat! <= 2.0) {
        addPositive(
          _ScanFactor(icon: AppIcons.droplet, iconColor: t.positive, title: 'Saturated Fat', subtitle: 'Saturated fat in this basis', valueText: '${n.saturatedFat!.toInt()}g', badgeColor: t.positive),
        );
      }
      if (n.sugars != null && n.sugars! <= 10.0) {
        addPositive(_ScanFactor(icon: AppIcons.candy, iconColor: t.positive, title: 'Sugar', subtitle: 'Total sugars in this basis', valueText: '${n.sugars!.toInt()}g', badgeColor: t.positive));
      }
      if (n.salt != null && n.salt! <= 1.5) {
        addPositive(
          _ScanFactor(icon: AppIcons.scale, iconColor: t.positive, title: 'Sodium', subtitle: 'Sodium estimate in this basis', valueText: '${(n.salt! * 400).toInt()}mg', badgeColor: t.positive),
        );
      }
      if (n.calories != null && n.calories! <= 250) {
        addPositive(_ScanFactor(icon: AppIcons.flame, iconColor: t.positive, title: 'Calories', subtitle: 'Energy in this basis', valueText: '${n.calories!.toInt()} Cal', badgeColor: t.positive));
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
                    scanData.nutritionBasisLabel,
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
