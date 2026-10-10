part of 'scan_detail_sections.dart';

/// Scan ingredients body.

class _IngredientsBody extends StatelessWidget {
  const _IngredientsBody({required this.product});

  final OffProduct product;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final details = product.ingredientsDetail ?? const <IngredientDetail>[];
    final allergenHints = (product.allergens ?? const <String>[]).map((a) => a.toLowerCase()).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSizes.p8,
          runSpacing: AppSizes.p8,
          children: [
            if (product.ingredientAnalysisVegan != null) _analysisChip(context, 'Vegan', product.ingredientAnalysisVegan!, LucideIcons.sprout),
            if (product.ingredientAnalysisVegetarian != null) _analysisChip(context, 'Vegetarian', product.ingredientAnalysisVegetarian!, AppIcons.leaf),
            if (product.ingredientAnalysisPalmOilFree != null) _analysisChip(context, 'Palm oil free', product.ingredientAnalysisPalmOilFree!, LucideIcons.treePalm),
          ],
        ),
        if (product.ingredientAnalysisVegan != null || product.ingredientAnalysisVegetarian != null || product.ingredientAnalysisPalmOilFree != null) Gap.h12,
        if (details.isNotEmpty)
          for (var i = 0; i < details.length; i++) ...[if (i > 0) Gap.h12, _ingredientRow(context, details[i], allergenHints, scheme)]
        else if ((product.ingredientsText ?? '').isNotEmpty)
          Text(product.ingredientsText!, style: context.bodySm.copyWith(height: 1.55)),
        if (product.imageIngredientsUrl != null && details.isEmpty && (product.ingredientsText ?? '').isEmpty) Text('Ingredients listed on the packaging photo.', style: context.bodySm),
      ],
    );
  }

  Widget _analysisChip(BuildContext context, String label, String verdict, IconData icon) {
    final scheme = context.appColorScheme;
    final (color, bg, verdictText) = switch (verdict) {
      'yes' => (scheme.success, scheme.softSuccess, 'Yes'),
      'no' => (scheme.error, scheme.softError, 'No'),
      _ => (scheme.warning, scheme.softWarning, 'Maybe'),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.p10, vertical: AppSizes.p6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.r100),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.sp, color: color),
          Gap.w6,
          Text(label, style: context.bodySm.copyWith(color: scheme.textPrimary)),
          Gap.w4,
          Text('· $verdictText', style: context.labelBold.copyWith(color: color, fontSize: 12.sp)),
        ],
      ),
    );
  }

  Widget _ingredientRow(BuildContext context, IngredientDetail detail, List<String> allergenHints, AppColorScheme scheme) {
    final isAllergen = allergenHints.any((a) => a.isNotEmpty && detail.text.toLowerCase().contains(a));
    final percentText = detail.percent == null ? null : '${detail.percentIsEstimate ? '~' : ''}${detail.percent!.toStringAsFixed(detail.percent == detail.percent!.roundToDouble() ? 0 : 1)}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                detail.text,
                style: context.bodySm.copyWith(fontWeight: isAllergen ? FontWeight.w800 : FontWeight.w600, color: isAllergen ? scheme.error : scheme.textPrimary),
              ),
            ),
            if (percentText != null) ...[Gap.w8, Text(percentText, style: context.labelBold.copyWith(color: scheme.textSecondary, fontSize: 12.sp))],
          ],
        ),
        if (detail.subIngredients.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: AppSizes.p4, left: AppSizes.p8),
            child: Text('Contains: ${detail.subIngredients.join(', ')}', style: context.bodySm.copyWith(color: scheme.textSecondary)),
          ),
        if (isAllergen)
          Padding(
            padding: EdgeInsets.only(top: AppSizes.p4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.alertTriangle, size: 12.sp, color: scheme.error),
                Gap.w4,
                Text(
                  'Allergen',
                  style: context.labelBold.copyWith(color: scheme.error, fontSize: 11.5.sp, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Additives (resolved against the in-app concern database)
// -----------------------------------------------------------------------------

