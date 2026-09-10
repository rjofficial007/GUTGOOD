import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/data/additive_concern_db.dart';
import 'package:gutgood/core/models/off_product.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/features/product_details/presentation/pages/additive_level_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// In-sheet "smooth-app style" fact sheet: everything GutGood knows about the
/// scanned product from Open Food Facts, packed into tappable, expandable
/// sections so the sheet stays scannable ("show details if available" —
/// sections with no data simply don't render).
///
/// Used by [ScanSummarySheet] below the Positives/Negatives analysis, above
/// the action CTA. All fields beyond the summary set are optional, so scans
/// cached before this feature degrade gracefully.
class ScanProductDetails extends StatelessWidget {
  const ScanProductDetails({super.key, required this.product});

  final OffProduct product;

  // Official Nutri-Score palette (constants: these colors ARE the label's
  // brand identity, in light and dark mode alike).
  static const nsColors = <String, Color>{
    'a': Color(0xFF038141),
    'b': Color(0xFF85BC2B),
    'c': Color(0xFFFECB02),
    'd': Color(0xFFEE8100),
    'e': Color(0xFFE63E11),
  };

  static const novaColors = <int, Color>{
    1: Color(0xFF038141),
    2: Color(0xFF85BC2B),
    3: Color(0xFFFECB02),
    4: Color(0xFFE63E11),
  };

  bool get _hasScores =>
      (product.nutriscore ?? '').isNotEmpty ||
      product.novaGroup != null ||
      (product.ecoscore ?? '').isNotEmpty ||
      (product.nutriscoreComponents ?? const []).isNotEmpty ||
      (product.nutriscoreExplanation ?? '').isNotEmpty;

  bool get _hasNutrition =>
      product.nutrients != null ||
      (product.nutrientLevels != null &&
          [product.nutrientLevels!.fat, product.nutrientLevels!.saturatedFat, product.nutrientLevels!.sugars, product.nutrientLevels!.salt].any((l) => l != 'unknown'));

  bool get _hasIngredients =>
      (product.ingredientsDetail ?? const []).isNotEmpty ||
      (product.ingredientsText ?? '').isNotEmpty ||
      product.ingredientAnalysisVegan != null ||
      product.ingredientAnalysisVegetarian != null ||
      product.ingredientAnalysisPalmOilFree != null;

  bool get _hasAdditives => (product.additives ?? const []).isNotEmpty;

  bool get _hasAllergens => (product.allergens ?? const []).isNotEmpty || (product.tracesTags ?? const []).isNotEmpty;

  bool get _hasLabels => (product.labels ?? const []).isNotEmpty || (product.countries ?? '').isNotEmpty;

  String get _scoresPeek {
    final parts = <String>[
      if ((product.nutriscore ?? '').isNotEmpty) 'Nutri-Score ${product.nutriscore!.toUpperCase()}',
      if (product.novaGroup != null && product.novaGroup! >= 1 && product.novaGroup! <= 4) 'NOVA ${product.novaGroup}',
      if ((product.ecoscore ?? '').isNotEmpty) 'Eco-Score ${product.ecoscore!.toUpperCase()}',
    ];
    return parts.join(' · ');
  }

  String get _nutritionPeek {
    final cal = product.nutrients?.calories;
    if (cal == null) return 'Declared on the pack';
    return '${cal.round()} kcal per ${_per100Label(product)}';
  }

  String get _ingredientsPeek {
    final count = (product.ingredientsDetail ?? const []).length;
    if (count > 0) return '$count ingredients listed';
    final verdicts = <String>[
      if (product.ingredientAnalysisVegan == 'yes') 'Vegan',
      if (product.ingredientAnalysisVegetarian == 'yes') 'Vegetarian',
      if (product.ingredientAnalysisPalmOilFree == 'yes') 'Palm-oil free',
    ];
    if (verdicts.isNotEmpty) return verdicts.join(' · ');
    return 'Full list as declared';
  }

  String get _additivesPeek {
    final concerns = product.additiveConcerns;
    final flagged = concerns.where((c) => c.level == AdditiveConcernLevel.higher || c.level == AdditiveConcernLevel.moderate).length;
    return flagged == 0 ? '${concerns.length} additives · none flagged' : '${concerns.length} additives · $flagged flagged';
  }

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      if (_hasScores)
        _DetailTile(
          icon: AppIcons.gauge,
          title: 'Scores & grades',
          peek: _scoresPeek,
          body: _ScoresBody(product: product),
        ),
      if (_hasNutrition)
        _DetailTile(
          icon: AppIcons.flame,
          title: 'Nutrition facts',
          peek: _nutritionPeek,
          body: _NutritionFactsBody(product: product),
        ),
      if (_hasIngredients)
        _DetailTile(
          icon: AppIcons.wheat,
          title: 'Ingredients',
          peek: _ingredientsPeek,
          body: _IngredientsBody(product: product),
        ),
      if (_hasAdditives)
        _DetailTile(
          icon: AppIcons.flaskConical,
          title: 'Additives',
          peek: _additivesPeek,
          body: _AdditivesBody(product: product),
        ),
      if (_hasAllergens)
        _DetailTile(
          icon: AppIcons.alertTriangle,
          title: 'Allergens',
          peek: (product.allergens ?? const []).isNotEmpty ? (product.allergens!).take(3).join(', ') : 'Traces only',
          body: _AllergensBody(product: product),
        ),
      if (_hasLabels)
        _DetailTile(
          icon: AppIcons.globe,
          title: 'Labels & availability',
          peek: (product.labels ?? const []).isNotEmpty ? product.labels!.take(3).map((l) => l.replaceAll('-', ' ')).join(', ') : 'Sold in: ${product.countries}',
          body: _LabelsBody(product: product),
        ),
    ];

    if (tiles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Product details',
              style: context.title.copyWith(fontSize: 20.sp, fontWeight: FontWeight.w900),
            ),
            const Spacer(),
            Text('Open Food Facts', style: context.caption.copyWith(color: context.appColorScheme.textMuted)),
          ],
        ),
        Gap.h4,
        ...tiles,
      ],
    );
  }
}

// -----------------------------------------------------------------------------

/// One collapsible detail section: icon + title + one-line peek, tap to expand
/// the smooth-app-style content underneath (only rendered when data exists).
class _DetailTile extends StatefulWidget {
  const _DetailTile({required this.icon, required this.title, required this.peek, required this.body});

  final IconData icon;
  final String title;
  final String peek;
  final Widget body;

  @override
  State<_DetailTile> createState() => _DetailTileState();
}

class _DetailTileState extends State<_DetailTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Row(
              children: [
                Icon(widget.icon, size: 24.sp, color: scheme.textPrimary.withAlpha(200)),
                Gap.w16,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: context.body.copyWith(fontWeight: FontWeight.w700, color: scheme.textPrimary)),
                      Text(
                        widget.peek,
                        style: context.caption.copyWith(color: scheme.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Gap.w12,
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(AppIcons.chevronDown, size: 16.sp, color: scheme.textMuted),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _expanded
              ? Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: _DetailCard(child: widget.body),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Soft rounded card wrapping the expanded section content.
class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: scheme.elevatedSurface,
        borderRadius: BorderRadius.circular(AppSizes.r16),
        border: Border.all(color: scheme.borderSubtle),
      ),
      child: child,
    );
  }
}

// -----------------------------------------------------------------------------
// Scores & grades
// -----------------------------------------------------------------------------

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
                      style: context.title.copyWith(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: grade == entry.key ? Colors.white : entry.value,
                      ),
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

        if ((product.comparedToCategory ?? '').isNotEmpty) ...[
          Gap.h12,
          Text('Nutri-Score compared with: ${product.comparedToCategory}', style: context.caption),
        ],

        if ((product.nutriscoreExplanation ?? '').isNotEmpty) ...[
          Gap.h12,
          Text(product.nutriscoreExplanation!, style: context.bodySm.copyWith(height: 1.5)),
        ],

        // Component table (which nutrients pushed the score)
        if (components.isNotEmpty) ...[
          Gap.h12,
          Text('Components', style: context.captionBold),
          Gap.h8,
          for (var i = 0; i < components.length; i++) ...[
            if (i > 0) Divider(height: AppSizes.p16, color: scheme.borderSubtle),
            _componentRow(context, components[i], scheme),
          ],
          Gap.h8,
          Wrap(
            spacing: AppSizes.p16,
            children: [
              _legendDot(context, scheme.success, 'Supports'),
              _legendDot(context, scheme.warning, 'Neutral'),
              _legendDot(context, scheme.error, 'Limits'),
            ],
          ),
        ],

        if (product.unscorableReason != null) ...[Gap.h12, Text(product.unscorableReason!, style: context.captionMicro)],
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
        Expanded(child: Text(c.label, style: context.caption.copyWith(color: scheme.textPrimary))),
        Text(c.value, style: context.captionBold.copyWith(color: amountColor)),
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
      Text(label, style: context.captionMicro),
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
      Text(label, style: context.captionBold.copyWith(color: textOnColor, fontSize: 12.sp)),
    ],
  ),
);

// -----------------------------------------------------------------------------
// Nutrition facts (levels chips + per 100 g ↔ per serving table)
// -----------------------------------------------------------------------------

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
      decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: scheme.borderSubtle))),
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
          for (var i = 0; i < details.length; i++) ...[
            if (i > 0) Gap.h12,
            _ingredientRow(context, details[i], allergenHints, scheme),
          ]
        else if ((product.ingredientsText ?? '').isNotEmpty)
          Text(product.ingredientsText!, style: context.bodySm.copyWith(height: 1.55)),
        if (product.imageIngredientsUrl != null && details.isEmpty && (product.ingredientsText ?? '').isEmpty)
          Text('Ingredients listed on the packaging photo.', style: context.caption),
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
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppSizes.r100), border: Border.all(color: color.withAlpha(120))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.sp, color: color),
          Gap.w6,
          Text(label, style: context.caption.copyWith(color: scheme.textPrimary)),
          Gap.w4,
          Text('· $verdictText', style: context.captionBold.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _ingredientRow(BuildContext context, IngredientDetail detail, List<String> allergenHints, AppColorScheme scheme) {
    final isAllergen = allergenHints.any((a) => a.isNotEmpty && detail.text.toLowerCase().contains(a));
    final percentText = detail.percent == null
        ? null
        : '${detail.percentIsEstimate ? '~' : ''}${detail.percent!.toStringAsFixed(detail.percent == detail.percent!.roundToDouble() ? 0 : 1)}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                detail.text,
                style: context.bodySm.copyWith(
                  fontWeight: isAllergen ? FontWeight.w800 : FontWeight.w600,
                  color: isAllergen ? scheme.error : scheme.textPrimary,
                ),
              ),
            ),
            if (percentText != null) ...[
              Gap.w8,
              Text(percentText, style: context.captionBold.copyWith(color: scheme.textSecondary)),
            ],
          ],
        ),
        if (detail.subIngredients.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: AppSizes.p4, left: AppSizes.p8),
            child: Text('Contains: ${detail.subIngredients.join(', ')}', style: context.captionMicro),
          ),
        if (isAllergen)
          Padding(
            padding: EdgeInsets.only(top: AppSizes.p4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.alertTriangle, size: 12.sp, color: scheme.error),
                Gap.w4,
                Text('Allergen', style: context.captionMicro.copyWith(color: scheme.error, fontWeight: FontWeight.w700)),
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

class _AdditivesBody extends StatelessWidget {
  const _AdditivesBody({required this.product});

  final OffProduct product;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final concerns = product.additiveConcerns;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < concerns.length; i++) ...[
          if (i > 0) Gap.h12,
          _additiveRow(context, concerns[i], scheme),
        ],
        Gap.h8,
        Text('Fewer additives usually means less ultra-processing.', style: context.captionMicro.copyWith(color: scheme.textMuted)),
      ],
    );
  }

  Widget _additiveRow(BuildContext context, AdditiveConcern c, AppColorScheme scheme) {
    final colors = AdditiveLevelColors.of(context, c.level);
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(AppSizes.p6),
          decoration: BoxDecoration(color: colors.iconBackground, shape: BoxShape.circle),
          child: Icon(AdditiveLevelColors.iconFor(c.level), size: 14.sp, color: colors.accent),
        ),
        Gap.w12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.displayTitle, style: context.captionBold.copyWith(color: scheme.textPrimary)),
              if (c.name.isNotEmpty && c.name.toLowerCase() != c.displayTitle.toLowerCase())
                Text(c.name, style: context.captionMicro, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.p8, vertical: 3.0.h),
          decoration: BoxDecoration(color: colors.pillBackground, borderRadius: BorderRadius.circular(AppSizes.r100)),
          child: Text(c.level.label, style: context.captionMicro.copyWith(color: colors.accent, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Allergens & traces
// -----------------------------------------------------------------------------

class _AllergensBody extends StatelessWidget {
  const _AllergensBody({required this.product});

  final OffProduct product;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((product.allergens ?? const []).isNotEmpty) ...[
          Row(
            children: [
              Icon(AppIcons.alertTriangle, size: 14.sp, color: scheme.error),
              Gap.w6,
              Text('Contains', style: context.captionBold),
            ],
          ),
          Gap.h8,
          Wrap(
            spacing: AppSizes.p8,
            runSpacing: AppSizes.p8,
            children: [for (final allergen in product.allergens!) _tagChip(context, allergen, color: scheme.error, background: scheme.softError)],
          ),
        ],
        if ((product.tracesTags ?? const []).isNotEmpty) ...[
          if ((product.allergens ?? const []).isNotEmpty) Gap.h16,
          Row(
            children: [
              Icon(AppIcons.info, size: 14.sp, color: scheme.warning),
              Gap.w6,
              Text('May contain', style: context.captionBold),
            ],
          ),
          Gap.h8,
          Wrap(
            spacing: AppSizes.p8,
            runSpacing: AppSizes.p8,
            children: [for (final trace in product.tracesTags!) _tagChip(context, trace, color: scheme.warning, background: scheme.softWarning)],
          ),
        ],
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Labels & availability
// -----------------------------------------------------------------------------

class _LabelsBody extends StatelessWidget {
  const _LabelsBody({required this.product});

  final OffProduct product;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((product.labels ?? const []).isNotEmpty)
          Wrap(
            spacing: AppSizes.p8,
            runSpacing: AppSizes.p8,
            children: [for (final label in product.labels!) _tagChip(context, label.replaceAll('-', ' '), color: scheme.info, background: scheme.softInfo)],
          ),
        if ((product.countries ?? '').isNotEmpty) ...[
          if ((product.labels ?? const []).isNotEmpty) Gap.h12,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(AppIcons.globe, size: 14.sp, color: scheme.textMuted),
              Gap.w6,
              Expanded(child: Text('Sold in: ${product.countries}', style: context.caption)),
            ],
          ),
        ],
        if ((product.barcode ?? '').isNotEmpty || (product.quantity ?? '').isNotEmpty) ...[
          Gap.h12,
          Wrap(
            spacing: AppSizes.p12,
            runSpacing: AppSizes.p4,
            children: [
              if ((product.quantity ?? '').isNotEmpty) _miniMeta(context, AppIcons.scale, product.quantity!),
              if ((product.barcode ?? '').isNotEmpty) _miniMeta(context, AppIcons.barcode, product.barcode!),
              if ((product.servingSize ?? '').isNotEmpty) _miniMeta(context, AppIcons.utensils, 'Serving ${product.servingSize}'),
            ],
          ),
        ],
      ],
    );
  }

  Widget _miniMeta(BuildContext context, IconData icon, String text) {
    final scheme = context.appColorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13.sp, color: scheme.textMuted),
        Gap.w4,
        Text(text, style: context.captionTiny),
      ],
    );
  }
}

Widget _tagChip(BuildContext context, String tag, {required Color color, required Color background}) => Container(
  padding: EdgeInsets.symmetric(horizontal: AppSizes.p10, vertical: AppSizes.p6),
  decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppSizes.r100)),
  child: Text(tag, style: context.captionBold.copyWith(color: color, fontSize: 12.sp)),
);

// -----------------------------------------------------------------------------
// Shared: segmented Per 100 g ↔ Per serving toggle
// -----------------------------------------------------------------------------

class _ServingToggle extends StatelessWidget {
  const _ServingToggle({required this.per100g, required this.perServing, required this.perServingActive, required this.onChanged});

  final String per100g;
  final String perServing;
  final bool perServingActive;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.0.w),
      decoration: BoxDecoration(color: scheme.surfaceSubtle, borderRadius: BorderRadius.circular(AppSizes.r100)),
      child: Row(
        children: [
          _option(context, label: per100g, active: !perServingActive, onTap: () => onChanged(false)),
          _option(context, label: perServing, active: perServingActive, onTap: () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _option(BuildContext context, {required String label, required bool active, required VoidCallback onTap}) {
    final scheme = context.appColorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(vertical: AppSizes.p8),
          decoration: BoxDecoration(
            color: active ? scheme.elevatedSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.r100),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.captionBold.copyWith(color: active ? scheme.textPrimary : scheme.textMuted, fontSize: 12.sp),
          ),
        ),
      ),
    );
  }
}
