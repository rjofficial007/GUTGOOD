part of 'scan_result_widgets.dart';

/// Watch-out food-impact presentation component.

class ScanWatchSection extends StatelessWidget {
  const ScanWatchSection({super.key, required this.scanData});
  final ScanResult scanData;

  static bool hasData(ScanResult scanData) {
    final n = scanData.nutrients;
    if (n != null) {
      if ((n.sugars ?? 0) > 10 || (n.salt ?? 0) > 0.5 || (n.saturatedFat ?? 0) > 2 || (n.calories ?? 0) > 250) {
        return true;
      }
    }
    if (scanData.allergens != null && scanData.allergens!.isNotEmpty && parseAllergenItems(scanData.allergens).isNotEmpty) return true;
    if (scanData.ingredients.any((ing) => ['red', 'orange', 'yellow'].contains(ing.colorName.toLowerCase()))) return true;
    if (scanData.additiveConcerns.any((c) => c.level == AdditiveConcernLevel.moderate || c.level == AdditiveConcernLevel.higher)) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final serving = scanData.servingSize ?? '1 serving';

    final negativeItems = <_ScanFactor>[];

    // 1. Unfavorable nutrients
    final n = scanData.nutrients;
    if (n != null) {
      if ((n.sugars ?? 0) > 10) {
        negativeItems.add(
          _ScanFactor(
            icon: AppIcons.candy,
            iconColor: t.negative,
            title: 'High Sugar',
            subtitle: (n.sugars ?? 0) > 20 ? 'Too much sugar added' : 'High in sugar',
            valueText: '${(n.sugars ?? 0).toInt()}g',
            badgeColor: t.negative,
          ),
        );
      }
      if ((n.salt ?? 0) > 0.5) {
        negativeItems.add(
          _ScanFactor(
            icon: AppIcons.scale,
            iconColor: t.negative,
            title: 'Sodium',
            subtitle: (n.salt ?? 0) > 1.5 ? 'High sodium content' : 'Moderate sodium',
            valueText: '${((n.salt ?? 0) * 400).toInt()}mg',
            badgeColor: t.negative,
          ),
        );
      }
      if ((n.saturatedFat ?? 0) > 2) {
        negativeItems.add(
          _ScanFactor(
            icon: AppIcons.droplet,
            iconColor: t.orange,
            title: 'Saturated Fat',
            subtitle: 'Pro-inflammatory fat level',
            valueText: '${(n.saturatedFat ?? 0).toInt()}g',
            badgeColor: t.orange,
          ),
        );
      }
      if ((n.calories ?? 0) > 250) {
        negativeItems.add(
          _ScanFactor(icon: AppIcons.flame, iconColor: t.orange, title: 'Calories', subtitle: 'High caloric density', valueText: '${(n.calories ?? 0).toInt()} Cal', badgeColor: t.orange),
        );
      }
    }

    // 2. Allergens (tappable → allergen detail)
    if (scanData.allergens != null && scanData.allergens!.isNotEmpty && parseAllergenItems(scanData.allergens).isNotEmpty) {
      negativeItems.add(
        _ScanFactor(
          icon: Icons.warning_amber_rounded,
          iconColor: t.negative,
          title: 'Allergens',
          subtitle: scanData.allergens!,
          onTap: () => context.push(
            AppRoutes.scanListDetail,
            extra: ScanListDetailArgs(kind: ScanListKind.allergens, scan: scanData),
          ),
        ),
      );
    }

    // 3. Flagged ingredients
    for (final ing in scanData.ingredients) {
      if (['red', 'orange', 'yellow'].contains(ing.colorName.toLowerCase())) {
        final color = ing.colorName.toLowerCase() == 'red' ? t.negative : t.orange;
        negativeItems.add(
          _ScanFactor(icon: AppIcons.leaf, iconColor: color, title: ing.name, subtitle: ing.impact.isNotEmpty ? ing.impact : 'Potential trigger or moderate ingredient', badgeColor: color),
        );
      }
    }

    // 4. Moderate / higher-concern additives (tappable → additive detail)
    for (final concern in scanData.additiveConcerns) {
      if (concern.level == AdditiveConcernLevel.moderate || concern.level == AdditiveConcernLevel.higher) {
        negativeItems.add(
          _ScanFactor(
            icon: AppIcons.flaskConical,
            iconColor: concern.level == AdditiveConcernLevel.higher ? t.negative : t.orange,
            title: concern.displayTitle,
            subtitle: concern.whyFlagged.isNotEmpty ? '${concern.level.label} concern · ${concern.whyFlagged}' : '${concern.level.label} concern',
            onTap: () => context.push(AppRoutes.additiveDetail, extra: concern),
          ),
        );
      }
    }

    if (negativeItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: t.negative.withAlpha(20), shape: BoxShape.circle),
              child: Icon(Icons.warning_amber_rounded, color: t.negative, size: 22.sp),
            ),
            Gap.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What to Watch',
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
        ...negativeItems.map((item) => _buildModernFactorCard(context, item, isPositive: false)),
      ],
    );
  }
}

