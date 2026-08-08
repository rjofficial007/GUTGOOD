import 'package:equatable/equatable.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/utils/model_utils.dart';

/// Categorizes the directional impact of a product on gut health.
enum ImpactType { positive, neutral, negative }

/// Represents the exhaustive result of an AI product analysis.
///
/// This model encapsulates all the data points required to render
/// the [ScanResultScreen], including nutrient levels, ingredient breakdown,
/// and hormonal cycle insights.
class ScanResult extends Equatable {
  const ScanResult({
    required this.productName,
    required this.brand,
    this.imageUrl,
    required this.score,
    required this.impactType,
    required this.impact,
    this.badge,
    this.nutriscore,
    this.novaGroup,
    this.allergens,
    this.additives,
    this.ingredients = const [],
    this.nutrients,
    this.nutrientLevels,
    this.impacts = const [],
    this.swaps = const [],
    this.cycleInsight,
    this.barcode,
    this.source,
    this.userImageUrl,
    this.flaggedIngredients = const [],
    this.time,
  });

  factory ScanResult.fromMap(Map<String, dynamic> map) {
    var type = ImpactType.neutral;
    final it = map['impactType']?.toString().toLowerCase();
    if (it == 'positive' || it == 'healing') type = ImpactType.positive;
    if (it == 'negative' || it == 'trigger') type = ImpactType.negative;

    if (map['impactType'] == null) {
      final score = (map['score'] as num?)?.toInt() ?? 0;
      if (score > 70) {
        type = ImpactType.positive;
      } else if (score < 40) {
        type = ImpactType.negative;
      }
    }

    return ScanResult(
      productName: map['productName'] ?? 'Unknown',
      brand: map['brand'] ?? 'Unknown',
      imageUrl: map['imageUrl'],
      score: (map['score'] as num?)?.toInt() ?? 0,
      impactType: type,
      impact: map['impact'] ?? '',
      badge: map['badge'],
      nutriscore: map['nutriscore'],
      novaGroup: map['novaGroup']?.toString(),
      allergens: map['allergens'],
      additives: map['additives'],
      ingredients: ModelUtils.parseModelList<Ingredient>(
        map['ingredients'],
        Ingredient.fromMap,
      ),
      nutrients: ModelUtils.parseNestedModel<NutrientData>(
        map['nutrients'],
        NutrientData.fromMap,
      ),
      nutrientLevels: ModelUtils.parseNestedModel<NutrientLevels>(
        map['nutrientLevels'],
        NutrientLevels.fromMap,
      ),
      impacts: ModelUtils.parseModelList<ImpactDetail>(
        map['impacts'],
        ImpactDetail.fromMap,
      ),
      swaps: ModelUtils.parseModelList<ProductSwap>(
        map['swaps'],
        ProductSwap.fromMap,
      ),
      cycleInsight: ModelUtils.parseNestedModel<CycleInsight>(
        map['cycleInsight'],
        CycleInsight.fromMap,
      ),
      barcode: map['barcode'],
      source: map['source'],
      userImageUrl: map['userImageUrl'],
      flaggedIngredients: ModelUtils.parseList<String>(
        map['flaggedIngredients'],
      ),
      time: map['time'] != null ? DateTime.tryParse(map['time']) : null,
    );
  }

  /// The official name of the product.
  final String productName;

  /// The manufacturing brand.
  final String brand;

  /// URL to the product's image (usually front-facing).
  final String? imageUrl;

  /// Calculated gut health score (0-100).
  final int score;

  /// The general impact category (e.g., healing vs trigger).
  final ImpactType impactType;

  /// Narrative summary of the product's effect on gut health.
  final String impact;

  /// Optional highlight badge text (e.g., "CLEAN CHOICE").
  final String? badge;

  /// Nutri-Score grade (A-E).
  final String? nutriscore;

  /// NOVA processing group (1-4).
  final String? novaGroup;

  /// Summary of detected allergens based on user profile.
  final String? allergens;

  /// Summary of detected additives or ultra-processed components.
  final String? additives;

  /// List of identified ingredients with their individual risk levels.
  final List<Ingredient> ingredients;

  /// Breakdown of caloric and macronutrient values per 100g.
  final NutrientData? nutrients;

  /// Standardized nutrient levels (low/moderate/high) for salt, sugar, fat.
  final NutrientLevels? nutrientLevels;

  /// Mapping of specific body impacts (e.g., inflammation, satiety).
  final List<ImpactDetail> impacts;

  /// Healthier alternatives for this specific product.
  final List<ProductSwap> swaps;

  /// Contextual advice based on the user's current hormonal phase.
  final CycleInsight? cycleInsight;

  /// Product EAN/UPC barcode string.
  final String? barcode;

  /// Analytics source identifier (e.g., 'barcode', 'label').
  final String? source;

  /// Public URL to the actual photo taken by the user.
  final String? userImageUrl;

  /// List of names for ingredients flagged as risky during analysis.
  final List<String> flaggedIngredients;

  /// The timestamp when this scan was created.
  final DateTime? time;

  ScanResult copyWith({
    String? productName,
    String? brand,
    String? imageUrl,
    int? score,
    ImpactType? impactType,
    String? impact,
    String? badge,
    String? nutriscore,
    String? novaGroup,
    String? allergens,
    String? additives,
    List<Ingredient>? ingredients,
    NutrientData? nutrients,
    NutrientLevels? nutrientLevels,
    List<ImpactDetail>? impacts,
    List<ProductSwap>? swaps,
    CycleInsight? cycleInsight,
    String? barcode,
    String? source,
    String? userImageUrl,
    List<String>? flaggedIngredients,
    DateTime? time,
  }) => ScanResult(
    productName: productName ?? this.productName,
    brand: brand ?? this.brand,
    imageUrl: imageUrl ?? this.imageUrl,
    score: score ?? this.score,
    impactType: impactType ?? this.impactType,
    impact: impact ?? this.impact,
    badge: badge ?? this.badge,
    nutriscore: nutriscore ?? this.nutriscore,
    novaGroup: novaGroup ?? this.novaGroup,
    allergens: allergens ?? this.allergens,
    additives: additives ?? this.additives,
    ingredients: ingredients ?? this.ingredients,
    nutrients: nutrients ?? this.nutrients,
    nutrientLevels: nutrientLevels ?? this.nutrientLevels,
    impacts: impacts ?? this.impacts,
    swaps: swaps ?? this.swaps,
    cycleInsight: cycleInsight ?? this.cycleInsight,
    barcode: barcode ?? this.barcode,
    source: source ?? this.source,
    userImageUrl: userImageUrl ?? this.userImageUrl,
    flaggedIngredients: flaggedIngredients ?? this.flaggedIngredients,
    time: time ?? this.time,
  );

  Map<String, dynamic> toMap() => {
    'productName': productName,
    'brand': brand,
    'imageUrl': imageUrl,
    'score': score,
    'impactType': impactType.name,
    'impact': impact,
    'badge': badge,
    'nutriscore': nutriscore,
    'novaGroup': novaGroup,
    'allergens': allergens,
    'additives': additives,
    'ingredients': ingredients.map((e) => e.toMap()).toList(),
    'nutrients': nutrients?.toMap(),
    'nutrientLevels': nutrientLevels?.toMap(),
    'impacts': impacts.map((e) => e.toMap()).toList(),
    'swaps': swaps.map((e) => e.toMap()).toList(),
    'cycleInsight': cycleInsight?.toMap(),
    'barcode': barcode,
    'source': source,
    'userImageUrl': userImageUrl,
    'flaggedIngredients': flaggedIngredients,
    'time': time?.toIso8601String(),
  };

  /// 🟢 NEW: Optimized Map for AI context to prevent 502/payload-too-large errors.
  /// Excludes large fields like full ingredients, nutrients, and swaps.
  Map<String, dynamic> toAiMap() => {
    'productName': productName,
    'brand': brand,
    'score': score,
    'impact': impact,
    'nutriscore': nutriscore,
    'novaGroup': novaGroup,
    'flaggedIngredients': flaggedIngredients,
  };

  @override
  List<Object?> get props => [
    productName,
    brand,
    score,
    impactType,
    impact,
    barcode,
    userImageUrl,
    flaggedIngredients,
  ];
}
