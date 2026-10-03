part of 'scan_detail_sections.dart';

/// Scan nutrition facts body.

class _NutritionFactsBody extends StatefulWidget {
  const _NutritionFactsBody({required this.product});

  final OffProduct product;

  @override
  State<_NutritionFactsBody> createState() => _NutritionFactsBodyState();
}

class _NutritionFactsBodyState extends State<_NutritionFactsBody> {
  bool _perServing = false;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final product = widget.product;
    final levels = product.nutrientLevels;
    final base = product.nutrients;
    final serving = product.servingNutrients;
    final active = (_perServing && serving != null) ? serving : base;
    final perLabel = _per100Label(product);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Traffic-light levels
        if (levels != null && [levels.fat, levels.saturatedFat, levels.sugars, levels.salt].any((l) => l != 'unknown')) ...[
          Wrap(
            spacing: AppSizes.p8,
            runSpacing: AppSizes.p8,
            children: [
              _levelChip(context, 'Fat', levels.fat),
              _levelChip(context, 'Sat. fat', levels.saturatedFat),
              _levelChip(context, 'Sugars', levels.sugars),
              _levelChip(context, 'Salt', levels.salt),
            ],
          ),
          Gap.h12,
        ],

        // Per 100 g ↔ per serving toggle (only when OFF provides serving data)
        if (serving != null) ...[
          _ServingToggle(
            per100g: 'Per $perLabel',
            perServing: 'Per serving${(product.servingSize ?? '').isNotEmpty ? ' (${product.servingSize})' : ''}',
            perServingActive: _perServing,
            onChanged: (v) => setState(() => _perServing = v),
          ),
          Gap.h12,
        ],

        if (active != null) ...[
          _nutrientRow(context, 'Energy', _fmtKcal(active.calories), emphasis: true),
          _nutrientRow(context, 'Fat', _fmtGrams(active.fat)),
          _nutrientRow(context, 'of which saturated fat', _fmtGrams(active.saturatedFat), indent: true),
          _nutrientRow(context, 'Carbohydrates', _fmtGrams(active.carbs)),
          _nutrientRow(context, 'of which sugars', _fmtGrams(active.sugars), indent: true),
          _nutrientRow(context, 'Fiber', _fmtGrams(active.fiber)),
          _nutrientRow(context, 'Proteins', _fmtGrams(active.proteins)),
          _nutrientRow(context, 'Salt', _fmtGrams(active.salt), last: true),
          Gap.h8,
          Text(
            _perServing && serving != null ? 'Per serving of ${product.servingSize ?? 'one portion'}.' : 'Per $perLabel, as declared on the pack.',
            style: context.captionMicro.copyWith(color: scheme.textMuted),
          ),
        ] else
          Text('Nutrition data not available for this product yet.', style: context.caption),
      ],
    );
  }

  Widget _levelChip(BuildContext context, String label, String level) {
    final scheme = context.appColorScheme;
    final (color, bg) = switch (level) {
      'low' => (scheme.success, scheme.softSuccess),
      'moderate' => (scheme.warning, scheme.softWarning),
      'high' => (scheme.error, scheme.softError),
      _ => (scheme.textMuted, scheme.surfaceSubtle),
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
          Container(
            width: 8.0.w,
            height: 8.0.w,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Gap.w6,
          Text(label, style: context.caption.copyWith(color: scheme.textPrimary)),
          Gap.w4,
          Text(level == 'unknown' ? '—' : level.toLowerCase(), style: context.captionBold.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _nutrientRow(BuildContext context, String label, String value, {bool emphasis = false, bool indent = false, bool last = false}) {
    final scheme = context.appColorScheme;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.0.h),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: scheme.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: emphasis
                  ? context.bodyBold.copyWith(fontWeight: FontWeight.w700)
                  : indent
                  ? context.caption.copyWith(color: scheme.textSecondary)
                  : context.bodyBold.copyWith(color: scheme.textPrimary, fontWeight: FontWeight.w600),
            ),
          ),
          Text(value, style: emphasis ? context.bodyBold : context.bodySm.copyWith(color: scheme.textSecondary)),
        ],
      ),
    );
  }
}

String _per100Label(OffProduct product) => product.nutrientDataPer == '100ml'
    ? '100 ml'
    : product.nutrientDataPer == 'serving'
    ? 'serving'
    : '100 g';

String _fmtGrams(num? value) {
  if (value == null) return '—';
  if (value == value.roundToDouble()) return '${value.toInt()} g';
  return '${value.toStringAsFixed(1)} g';
}

String _fmtKcal(num? value) => value == null ? '—' : '${value.round()} kcal';

// -----------------------------------------------------------------------------
// Ingredients
// -----------------------------------------------------------------------------

