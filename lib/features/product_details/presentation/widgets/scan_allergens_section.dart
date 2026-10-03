part of 'scan_result_widgets.dart';

/// Allergen presentation component.

class ScanAllergensSection extends StatelessWidget {
  const ScanAllergensSection({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final items = parseAllergenItems(scanData.allergens);
    final visible = items.take(3).toList();
    final hasItems = items.isNotEmpty;
    final color = hasItems ? t.negative : t.positive;

    if (!hasItems) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
              child: Icon(hasItems ? Icons.warning_amber_rounded : Icons.check_rounded, size: 22.sp, color: color),
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
                          AppStrings.allergensLabel,
                          style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.titleSize.sp, fontWeight: FontWeight.w700, color: t.textPrimary),
                        ),
                      ),
                      if (hasItems)
                        InkWell(
                          onTap: () => context.push(
                            AppRoutes.scanListDetail,
                            extra: ScanListDetailArgs(kind: ScanListKind.allergens, scan: scanData),
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
                    hasItems ? 'Potential gut triggers detected.' : 'No allergens declared for this product.',
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.footSize.sp, fontWeight: FontWeight.w400, color: t.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        Gap.h16,
        ...visible.map(
          (name) => _buildModernFactorCard(
            context,
            _ScanFactor(
              icon: Icons.warning_amber_rounded,
              iconColor: t.negative,
              title: name,
              subtitle: 'Potential gut trigger detected',
              badgeColor: t.negative,
              onTap: () => context.push(
                AppRoutes.scanListDetail,
                extra: ScanListDetailArgs(kind: ScanListKind.allergens, scan: scanData),
              ),
            ),
            isPositive: false,
          ),
        ),
      ],
    );
  }
}

/// 🌟 Section 10: Scan details (provenance footer rows).
