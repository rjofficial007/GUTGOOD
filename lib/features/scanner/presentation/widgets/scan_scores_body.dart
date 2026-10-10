part of 'scan_detail_sections.dart';

/// Scan scores explanation body.

class _ScoresBody extends StatelessWidget {
  const _ScoresBody({required this.product});

  final OffProduct product;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final grade = product.nutriscore?.toLowerCase();
    final components = product.nutriscoreComponents ?? const <NutriScoreComponent>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nutri-Score A–E strip
        if (grade != null && ScanProductDetails.nsColors.containsKey(grade)) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final entry in ScanProductDetails.nsColors.entries)
                Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 2.0.w),
                    padding: EdgeInsets.symmetric(vertical: AppSizes.p8),
                    decoration: BoxDecoration(
                      color: grade == entry.key ? entry.value : entry.value.withAlpha(38),
                      borderRadius: BorderRadius.circular(AppSizes.r8),
                      border: grade == entry.key ? null : Border.all(color: entry.value.withAlpha(89)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      entry.key.toUpperCase(),
                      style: context.title.copyWith(fontSize: 15.sp, fontWeight: FontWeight.w800, color: grade == entry.key ? Colors.white : entry.value),
                    ),
                  ),
                ),
            ],
          ),
          Gap.h12,
        ],

        // NOVA + Eco-Score chips
        Wrap(
          spacing: AppSizes.p8,
          runSpacing: AppSizes.p8,
          children: [
            if (product.novaGroup != null && product.novaGroup! >= 1 && product.novaGroup! <= 4)
              _gradeChip(
                context,
                label: 'NOVA ${product.novaGroup}${product.novaGroup == 4 ? ' — ultra-processed' : ''}',
                color: ScanProductDetails.novaColors[product.novaGroup]!,
                textOnColor: product.novaGroup == 2 || product.novaGroup == 3 ? Colors.black87 : Colors.white,
              ),
            if ((product.ecoscore ?? '').isNotEmpty && ScanProductDetails.nsColors.containsKey(product.ecoscore!.toLowerCase()))
              _gradeChip(
                context,
                label: 'Eco-Score ${product.ecoscore!.toUpperCase()}${product.ecoscoreScore != null ? ' (${product.ecoscoreScore}/100)' : ''}',
                color: ScanProductDetails.nsColors[product.ecoscore!.toLowerCase()]!,
                textOnColor: Colors.white,
              ),
            if (product.isOrganic == true) _gradeChip(context, label: 'Organic', color: scheme.success, textOnColor: Colors.white, icon: AppIcons.leaf),
          ],
        ),

        if ((product.comparedToCategory ?? '').isNotEmpty) ...[Gap.h12, Text('Nutri-Score compared with: ${product.comparedToCategory}', style: context.bodySm)],

        if ((product.nutriscoreExplanation ?? '').isNotEmpty) ...[Gap.h12, Text(product.nutriscoreExplanation!, style: context.bodySm.copyWith(height: 1.5))],

        // Component table (which nutrients pushed the score)
        if (components.isNotEmpty) ...[
          Gap.h12,
          Text('Components', style: context.labelBold.copyWith(fontSize: 12.sp)),
          Gap.h8,
          for (var i = 0; i < components.length; i++) ...[if (i > 0) Divider(height: AppSizes.p16, color: scheme.borderSubtle), _componentRow(context, components[i], scheme)],
          Gap.h8,
          Wrap(spacing: AppSizes.p16, children: [_legendDot(context, scheme.success, 'Supports'), _legendDot(context, scheme.warning, 'Neutral'), _legendDot(context, scheme.error, 'Limits')]),
        ],

        if (product.unscorableReason != null) ...[Gap.h12, Text(product.unscorableReason!, style: context.bodySm.copyWith(color: scheme.textMuted))],
      ],
    );
  }

  Widget _componentRow(BuildContext context, NutriScoreComponent c, AppColorScheme scheme) {
    // OFF evaluations: 'good' favors the score (fiber, proteins…), 'bad'
    // drags it down (energy, sugars…), everything else is neutral/unknown.
    final (dotColor, amountColor) = switch (c.evaluation) {
      'good' => (scheme.success, scheme.success),
      'bad' => (scheme.error, scheme.error),
      'neutral' => (scheme.warning, scheme.textSecondary),
      _ => (scheme.textMuted, scheme.textSecondary),
    };
    return Row(
      children: [
        Container(
          width: 8.0.w,
          height: 8.0.w,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        Gap.w12,
        Expanded(
          child: Text(c.label, style: context.bodySm.copyWith(color: scheme.textPrimary)),
        ),
        Text(c.value, style: context.labelBold.copyWith(color: amountColor, fontSize: 12.sp)),
      ],
    );
  }

  Widget _legendDot(BuildContext context, Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8.0.w,
        height: 8.0.w,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      Gap.w4,
      Text(label, style: context.bodySm.copyWith(color: context.appColorScheme.textMuted, fontSize: 11.5.sp)),
    ],
  );
}

Widget _gradeChip(BuildContext context, {required String label, required Color color, required Color textOnColor, IconData? icon}) => Container(
  padding: EdgeInsets.symmetric(horizontal: AppSizes.p12, vertical: AppSizes.p6),
  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppSizes.r100)),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (icon != null) ...[Icon(icon, size: 13.sp, color: textOnColor), Gap.w4],
      Text(
        label,
        style: context.captionBold.copyWith(color: textOnColor, fontSize: 12.sp),
      ),
    ],
  ),
);

// -----------------------------------------------------------------------------
// Nutrition facts (levels chips + per 100 g ↔ per serving table)
// -----------------------------------------------------------------------------

