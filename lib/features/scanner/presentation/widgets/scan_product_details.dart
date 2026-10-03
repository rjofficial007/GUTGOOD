part of 'scan_detail_sections.dart';

/// Scanned-product details sheet and section orchestration.

class ScanProductDetails extends StatelessWidget {
  const ScanProductDetails({super.key, required this.product});

  final OffProduct product;

  // Official Nutri-Score palette (constants: these colors ARE the label's
  // brand identity, in light and dark mode alike).
  static const nsColors = <String, Color>{'a': Color(0xFF038141), 'b': Color(0xFF85BC2B), 'c': Color(0xFFFECB02), 'd': Color(0xFFEE8100), 'e': Color(0xFFE63E11)};

  static const novaColors = <int, Color>{1: Color(0xFF038141), 2: Color(0xFF85BC2B), 3: Color(0xFFFECB02), 4: Color(0xFFE63E11)};

  bool get _hasScores =>
      (product.nutriscore ?? '').isNotEmpty ||
      product.novaGroup != null ||
      (product.ecoscore ?? '').isNotEmpty ||
      (product.nutriscoreComponents ?? const []).isNotEmpty ||
      (product.nutriscoreExplanation ?? '').isNotEmpty;

  bool get _hasNutrition =>
      product.nutrients != null ||
      (product.nutrientLevels != null && [product.nutrientLevels!.fat, product.nutrientLevels!.saturatedFat, product.nutrientLevels!.sugars, product.nutrientLevels!.salt].any((l) => l != 'unknown'));

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
