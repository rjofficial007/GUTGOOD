part of 'scan_result_widgets.dart';

/// Ingredient presentation component.

class ScanIngredientsSection extends StatelessWidget {
  const ScanIngredientsSection({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final ingredients = scanData.ingredients;
    final visible = ingredients.take(3).toList();
    final hasItems = ingredients.isNotEmpty;

    if (!hasItems) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: t.positive.withAlpha(20), shape: BoxShape.circle),
              child: Icon(AppIcons.leaf, size: 22.sp, color: t.positive),
            ),
            Gap.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppStrings.ingredientsTitle,
                          style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.titleSize.sp, fontWeight: FontWeight.w700, color: t.textPrimary),
                        ),
                      ),
                      if (hasItems)
                        InkWell(
                          onTap: () => context.push(
                            AppRoutes.scanListDetail,
                            extra: ScanListDetailArgs(kind: ScanListKind.ingredients, scan: scanData),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppStrings.seeAll,
                                style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.bodySize.sp, fontWeight: FontWeight.w700, color: t.textSecondary),
                              ),
                              Icon(AppIcons.chevronRight, size: 16.sp, color: t.textQuaternary),
                            ],
                          ),
                        ),
                    ],
                  ),
                  Text(
                    'Tap an ingredient to see details.',
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.footSize.sp, fontWeight: FontWeight.w400, color: t.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        Gap.h16,
        ...visible.map((ing) {
          final isPos = ['green', 'low', 'positive'].contains(ing.colorName.toLowerCase());
          final color = ingredientSignalColor(context, ing.colorName);
          return _buildModernFactorCard(
            context,
            _ScanFactor(
              icon: AppIcons.leaf,
              iconColor: color,
              title: ing.name,
              subtitle: ing.impact.isNotEmpty ? ing.impact : (isPos ? 'Beneficial gut food component' : 'Potential trigger ingredient'),
              badgeColor: color,
              onTap: () => context.push(
                AppRoutes.scanListDetail,
                extra: ScanListDetailArgs(kind: ScanListKind.ingredients, scan: scanData),
              ),
            ),
            isPositive: isPos,
          );
        }),
      ],
    );
  }
}

/// 🌟 Section 9b: Allergens section (modern cards → allergen list detail).
