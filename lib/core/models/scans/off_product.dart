import 'package:equatable/equatable.dart';
import 'package:gutgood/core/data/additive_concern_db.dart';
import 'package:gutgood/core/models/scans/scan_result_details.dart';
import 'package:gutgood/core/utils/model_utils.dart';
import 'package:gutgood/core/utils/yuka_score.dart';

class OffProduct extends Equatable {
  const OffProduct({
    required this.productName,
    this.brand,
    this.imageUrl,
    this.barcode,
    this.score,
    this.status,
    this.statusColor,
    this.nutriscore,
    this.nutriscoreScore,
    this.isOrganic,
    this.novaGroup,
    this.ecoscore,
    this.ingredientsText,
    this.ingredients,
    this.additivesCount,
    this.additives,
    this.allergens,
    this.allergensText,
    this.labels,
    this.category,
    this.categoryTag,
    this.servingSize,
    this.nutrientLevels,
    this.nutrients,
    this.impacts,
    this.miscTags,
    this.quantity,
    this.ecoscoreScore,
    this.imageIngredientsUrl,
    this.imageNutritionUrl,
    this.nutrientDataPer,
    this.ingredientsDetail,
    this.ingredientAnalysisVegan,
    this.ingredientAnalysisVegetarian,
    this.ingredientAnalysisPalmOilFree,
    this.servingNutrients,
    this.tracesTags,
    this.countries,
    this.comparedToCategory,
    this.nutriscoreComponents,
    this.nutriscoreExplanation,
  });

  factory OffProduct.fromMap(Map<String, dynamic> map) => OffProduct(
    productName: map['productName'] ?? 'Unknown Product',
    brand: map['brand'],
    imageUrl: map['imageUrl'],
    barcode: map['barcode'],
    score: map['score'] as int?,
    status: map['status'],
    statusColor: map['statusColor'],
    nutriscore: map['nutriscore'],
    nutriscoreScore: map['nutriscoreScore'] is int ? map['nutriscoreScore'] as int : int.tryParse(map['nutriscoreScore']?.toString() ?? ''),
    isOrganic: map['isOrganic'] == true || (map['isOrganic'] is String && (map['isOrganic'] as String).toLowerCase() == 'true'),
    novaGroup: map['novaGroup'] as int?,
    ecoscore: map['ecoscore'],
    ingredientsText: map['ingredientsText'],
    ingredients: ModelUtils.parseList<String>(map['ingredients']),
    additivesCount: map['additivesCount'] as int?,
    additives: ModelUtils.parseList<String>(map['additives']),
    allergens: ModelUtils.parseList<String>(map['allergens']),
    allergensText: map['allergensText'],
    labels: ModelUtils.parseList<String>(map['labels']),
    category: map['category'],
    categoryTag: map['categoryTag'],
    servingSize: map['servingSize']?.toString() ?? map['serving_size']?.toString(),
    nutrientLevels: ModelUtils.parseNestedModel<NutrientLevels>(map['nutrientLevels'], NutrientLevels.fromMap),
    nutrients: ModelUtils.parseNestedModel<NutrientData>(map['nutrients'], NutrientData.fromMap),
    impacts: ModelUtils.parseModelList<ImpactDetail>(map['impacts'], ImpactDetail.fromMap),
    miscTags: ModelUtils.parseList<String>(map['miscTags'] ?? map['misc_tags']),
    quantity: map['quantity'],
    ecoscoreScore: map['ecoscoreScore'] is int ? map['ecoscoreScore'] as int : int.tryParse(map['ecoscoreScore']?.toString() ?? ''),
    imageIngredientsUrl: map['imageIngredientsUrl'],
    imageNutritionUrl: map['imageNutritionUrl'],
    nutrientDataPer: map['nutrientDataPer'],
    ingredientsDetail: ModelUtils.parseModelList<IngredientDetail>(map['ingredientsDetail'], IngredientDetail.fromMap),
    ingredientAnalysisVegan: map['ingredientAnalysisVegan'],
    ingredientAnalysisVegetarian: map['ingredientAnalysisVegetarian'],
    ingredientAnalysisPalmOilFree: map['ingredientAnalysisPalmOilFree'],
    servingNutrients: ModelUtils.parseNestedModel<NutrientData>(map['servingNutrients'], NutrientData.fromMap),
    tracesTags: ModelUtils.parseList<String>(map['tracesTags']),
    countries: map['countries'],
    comparedToCategory: map['comparedToCategory'],
    nutriscoreComponents: ModelUtils.parseModelList<NutriScoreComponent>(map['nutriscoreComponents'], NutriScoreComponent.fromMap),
    nutriscoreExplanation: map['nutriscoreExplanation'],
  );

  /// Additive concerns resolved from [additives] (E-codes / additive names).
  List<AdditiveConcern> get additiveConcerns => AdditiveConcernDb.resolveAll(additives ?? const []);

  /// Returns the full explainable breakdown of the gut score.
  YukaScoreBreakdown get yukaBreakdown => YukaScore.evaluate(
    nutriscore: nutriscore,
    nutriscoreScore: nutriscoreScore,
    energyKcal: nutrients?.calories,
    fiberG: nutrients?.fiber,
    proteinG: nutrients?.proteins,
    sugarG: nutrients?.sugars,
    saltG: nutrients?.salt,
    saturatedFatG: nutrients?.saturatedFat,
    additiveConcerns: additiveConcerns,
    isOrganic: isOrganic,
    novaGroup: novaGroup,
    isBeverage: YukaScore.isBeverageCategory('$categoryTag $category'),
    isWater: YukaScore.isPlainWater(
      productName: productName,
      category: '$categoryTag $category',
      energyKcal: nutrients?.calories,
      sugarG: nutrients?.sugars,
    ),
  );

  /// Returns the deterministically calculated Gut Score (0-100) for this
  /// product, using the Yuka-style engine.
  int get gutScore => yukaBreakdown.score;

  final String productName;
  final String? brand;
  final String? imageUrl;
  final String? barcode;
  final int? score;
  final String? status;
  final String? statusColor;
  final String? nutriscore;

  /// Raw Nutri-Score points from Open Food Facts (`nutriscore_score`).
  /// Lets the engine place a product *within* its Nutri-Score band instead of
  /// falling back to a representative value for the letter.
  final int? nutriscoreScore;

  /// Certified organic (from OFF labels) — worth 10% of the score.
  final bool? isOrganic;

  final int? novaGroup;
  final String? ecoscore;
  final String? ingredientsText;
  final List<String>? ingredients;
  final int? additivesCount;
  final List<String>? additives;
  final List<String>? allergens;
  final String? allergensText;
  final List<String>? labels;
  final String? category;
  final String? categoryTag;
  final String? servingSize;
  final NutrientLevels? nutrientLevels;
  final NutrientData? nutrients;
  final List<ImpactDetail>? impacts;

  /// Raw Open Food Facts `misc_tags`.
  ///
  /// These explain *why* a Nutri-Score could not be computed — for example
  /// `en:nutriscore-missing-nutrition-data-sodium` or
  /// `en:nutriscore-missing-category`. Without them an unscorable product just
  /// looks unscored, and the user is left guessing whether the app is broken.
  final List<String>? miscTags;

  /// Why this product has no Nutri-Score, in plain English — or `null` when
  /// Open Food Facts doesn't say (or the product scored fine).
  ///
  /// Turns a bare "we couldn't score this" into an actionable answer, and
  /// nudges the user towards contributing the missing data back to OFF.
  /// Implementation lives in [ModelUtils.unscorableReason] so the scanner can
  /// reuse it without constructing an [OffProduct].
  String? get unscorableReason => ModelUtils.unscorableReason(miscTags);

  // --- Full-details fields (smooth-app parity) -----------------------------
  // Populated by OffService since the move to the official SDK + expanded
  // field list; all optional so V1 persisted documents stay readable.

  /// Declared net quantity (`quantity`), e.g. "330 ml".
  final String? quantity;

  /// Numeric Eco-Score (0-100), distinct from the [ecoscore] letter.
  final int? ecoscoreScore;

  /// OFF image URLs for the ingredients and nutrition-facts panels.
  final String? imageIngredientsUrl;
  final String? imageNutritionUrl;

  /// What `nutriments` are expressed per (`nutrition_data_per`): "100g",
  /// "100ml" or "serving".
  final String? nutrientDataPer;

  /// Structured ingredients (rank, name, percent, sub-ingredients) for the
  /// smooth-app-style ingredients breakdown.
  final List<IngredientDetail>? ingredientsDetail;

  /// Ingredient analysis (`ingredients_analysis_tags`) condensed to
  /// 'yes' / 'no' / 'maybe' / null (unknown).
  final String? ingredientAnalysisVegan;
  final String? ingredientAnalysisVegetarian;
  final String? ingredientAnalysisPalmOilFree;

  /// Per-serving nutrient values, when OFF provides them (same shape as
  /// [nutrients], which is per 100 g).
  final NutrientData? servingNutrients;

  /// "May contain" allergens (`traces_tags`, language-stripped).
  final List<String>? tracesTags;

  /// Countries where the product is sold (server-localized string).
  final String? countries;

  /// The OFF category the Nutri-Score is benchmarked against.
  final String? comparedToCategory;

  /// Nutri-Score component rows from the OFF `nutriscore` knowledge panel
  /// (the per-nutrient points table shown in the smooth-app detail page).
  final List<NutriScoreComponent>? nutriscoreComponents;

  /// Plain-language Nutri-Score summary from the same knowledge panel.
  final String? nutriscoreExplanation;

  Map<String, dynamic> toMap() => {
    'productName': productName,
    'brand': brand,
    'imageUrl': imageUrl,
    'barcode': barcode,
    'score': score,
    'status': status,
    'statusColor': statusColor,
    'nutriscore': nutriscore,
    'nutriscoreScore': nutriscoreScore,
    'isOrganic': isOrganic,
    'novaGroup': novaGroup,
    'ecoscore': ecoscore,
    'ingredientsText': ingredientsText,
    'ingredients': ingredients,
    'additivesCount': additivesCount,
    'additives': additives,
    'allergens': allergens,
    'allergensText': allergensText,
    'labels': labels,
    'category': category,
    'categoryTag': categoryTag,
    'servingSize': servingSize,
    'nutrientLevels': nutrientLevels?.toMap(),
    'nutrients': nutrients?.toMap(),
    'impacts': impacts?.map((e) => e.toMap()).toList(),
    'miscTags': miscTags,
    'quantity': quantity,
    'ecoscoreScore': ecoscoreScore,
    'imageIngredientsUrl': imageIngredientsUrl,
    'imageNutritionUrl': imageNutritionUrl,
    'nutrientDataPer': nutrientDataPer,
    'ingredientsDetail': ingredientsDetail?.map((e) => e.toMap()).toList(),
    'ingredientAnalysisVegan': ingredientAnalysisVegan,
    'ingredientAnalysisVegetarian': ingredientAnalysisVegetarian,
    'ingredientAnalysisPalmOilFree': ingredientAnalysisPalmOilFree,
    'servingNutrients': servingNutrients?.toMap(),
    'tracesTags': tracesTags,
    'countries': countries,
    'comparedToCategory': comparedToCategory,
    'nutriscoreComponents': nutriscoreComponents?.map((e) => e.toMap()).toList(),
    'nutriscoreExplanation': nutriscoreExplanation,
  };

  @override
  List<Object?> get props => [
    productName,
    barcode,
    score,
    brand,
    imageUrl,
    nutriscore,
    nutriscoreScore,
    isOrganic,
    novaGroup,
    ecoscore,
    ingredientsText,
    ingredients,
    additivesCount,
    additives,
    allergens,
    allergensText,
    labels,
    category,
    categoryTag,
    servingSize,
    nutrientLevels,
    nutrients,
    impacts,
    miscTags,
    quantity,
    ecoscoreScore,
    imageIngredientsUrl,
    imageNutritionUrl,
    nutrientDataPer,
    ingredientsDetail,
    ingredientAnalysisVegan,
    ingredientAnalysisVegetarian,
    ingredientAnalysisPalmOilFree,
    servingNutrients,
    tracesTags,
    countries,
    comparedToCategory,
    nutriscoreComponents,
    nutriscoreExplanation,
  ];
}

/// One structured ingredient with its share — mirrors the smooth-app
/// ingredients breakdown (rank order, percent where known, sub-ingredients).
class IngredientDetail extends Equatable {
  const IngredientDetail({required this.text, this.percent, this.percentIsEstimate = false, this.subIngredients = const []});

  factory IngredientDetail.fromMap(Map<String, dynamic> map) => IngredientDetail(
    text: map['text']?.toString() ?? '',
    percent: map['percent'] is num ? (map['percent'] as num).toDouble() : double.tryParse(map['percent']?.toString() ?? ''),
    percentIsEstimate: map['percentIsEstimate'] == true,
    subIngredients: ModelUtils.parseList<String>(map['subIngredients']),
  );

  final String text;

  /// Share of the product in percent (0-100), when OFF knows/estimates it.
  final double? percent;

  /// True when [percent] is an OFF estimate rather than a declared value.
  final bool percentIsEstimate;

  /// Sub-ingredient names (one level), e.g. sugar/glucose inside "syrup".
  final List<String> subIngredients;

  Map<String, dynamic> toMap() => {'text': text, 'percent': percent, 'percentIsEstimate': percentIsEstimate, 'subIngredients': subIngredients};

  @override
  List<Object?> get props => [text, percent, percentIsEstimate, subIngredients];
}

/// One row of the OFF Nutri-Score components table (knowledge panel),
/// e.g. `Sugars — 9 points` with a good/bad evaluation for coloring.
class NutriScoreComponent extends Equatable {
  const NutriScoreComponent({required this.label, required this.value, this.evaluation});

  factory NutriScoreComponent.fromMap(Map<String, dynamic> map) =>
      NutriScoreComponent(label: map['label']?.toString() ?? '', value: map['value']?.toString() ?? '', evaluation: map['evaluation']?.toString());

  final String label;
  final String value;

  /// OFF cell evaluation ('good' | 'neutral' | 'bad' | …); null when absent.
  final String? evaluation;

  Map<String, dynamic> toMap() => {'label': label, 'value': value, 'evaluation': evaluation};

  @override
  List<Object?> get props => [label, value, evaluation];
}

/// P2-11: maps OFF alternatives to grounded swap cards. Lives here (not on
/// [ProductSwap]) because off_product already depends on scan_result_details
/// and the reverse edge would be a needless import cycle.
extension OffProductSwapX on OffProduct {
  ProductSwap toSwap() => ProductSwap(
    title: productName,
    subtitle: brand ?? 'Better Alternative',
    tag: 'BETTER CHOICE',
    imageKeyword: productName,
    imageUrl: imageUrl,
    isBlackBadge: true,
    barcode: barcode,
    nutriscore: nutriscore,
  );
}
