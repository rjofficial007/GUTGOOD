part of 'scan_result_widgets.dart';

/// Additive presentation component.

class ScanAdditivesSection extends StatelessWidget {
  const ScanAdditivesSection({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final sorted = [...scanData.additiveConcerns]..sort((a, b) => additiveConcernRank(b.level).compareTo(additiveConcernRank(a.level)));
    final visible = sorted.take(3).toList();

    if (sorted.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: t.negative.withAlpha(20), shape: BoxShape.circle),
              child: Icon(AppIcons.flaskConical, size: 22.sp, color: t.negative),
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
                          '${AppStrings.additivesLabel} (${scanData.additiveConcerns.length})',
                          style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.titleSize.sp, fontWeight: FontWeight.w700, color: t.textPrimary),
                        ),
                      ),
                      if (sorted.isNotEmpty)
                        InkWell(
                          onTap: () => context.push(
                            AppRoutes.additivesList,
                            extra: AdditiveListArgs(items: sorted, title: AppStrings.additivesLabel, subtitle: AppStrings.additivesSubtitle),
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
                    'Tap an additive to learn more about what it is and how it may impact you.',
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.footSize.sp, fontWeight: FontWeight.w400, color: t.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        Gap.h16,
        ...visible.map((concern) {
          final color = additiveConcernColor(context, concern.level);
          final isNeg = concern.level == AdditiveConcernLevel.moderate || concern.level == AdditiveConcernLevel.higher;
          return _buildModernFactorCard(
            context,
            _ScanFactor(
              icon: AppIcons.flaskConical,
              iconColor: color,
              title: concern.displayTitle,
              subtitle: concern.whyFlagged.isNotEmpty ? concern.whyFlagged : concern.whatItIs,
              badgeColor: color,
              onTap: () => context.push(AppRoutes.additiveDetail, extra: concern),
            ),
            isPositive: !isNeg,
          );
        }),
      ],
    );
  }
}

/// 🌟 Section 9a: Ingredients section (modern cards → ingredient list detail).
