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
    this.category,
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
    this.isSaved = false,
  });

  factory ScanResult.fromMap(Map<String, dynamic> map) {
    var type = ImpactType.neutral;
    final it = map['impactType']?.toString().toLowerCase();
    if (it == 'positive' || it == 'healing') type = ImpactType.positive;
    if (it == 'negative' || it == 'trigger') type = ImpactType.negative;

    // 🟢 FIXED: score is now clamped 0-100 via ModelUtils.parseScore instead
    // of trusting the AI's raw integer verbatim. A malformed/out-of-range
    // score used to flow straight into UI progress gauges
    // (`CircularProgressIndicator(value: score / 100)`), which could
    // render as overflowing or negative visuals.
    final score = ModelUtils.parseScore(map['score']);

    if (map['impactType'] == null) {
      if (score > 70) {
        type = ImpactType.positive;
      } else if (score < 40) {
        type = ImpactType.negative;
      }
    }

    // 🟢 FIXED: nutriscore is normalized to uppercase A-E, or null if the
    // model returns something outside that set (previously any string,
    // including stray lowercase letters or "unknown", was accepted as-is
    // and rendered directly as a grade badge).
    String? normalizedNutriscore;
    final rawNutriscore = map['nutriscore']?.toString().trim().toUpperCase();
    if (rawNutriscore != null && {'A', 'B', 'C', 'D', 'E'}.contains(rawNutriscore)) {
      normalizedNutriscore = rawNutriscore;
    }

    // 🟢 FIXED: novaGroup is normalized to a plain "1".."4" string (or
    // null) even if the model returns an int, a "1-4" range string, or a
    // stray "unknown" — previously that malformed value was passed
    // straight to `int.tryParse`-adjacent UI code with no guardrail.
    String? normalizedNova;
    final rawNova = map['novaGroup'];
    final novaInt = rawNova is num ? rawNova.toInt() : int.tryParse(rawNova?.toString() ?? '');
    if (novaInt != null && novaInt >= 1 && novaInt <= 4) {
      normalizedNova = novaInt.toString();
    }

    return ScanResult(
      productName: map['productName']?.toString() ?? 'Unknown',
      brand: map['brand']?.toString() ?? 'Unknown',
      category: map['category']?.toString(),
      imageUrl: map['imageUrl']?.toString(),
      score: score,
      impactType: type,
      impact: map['impact']?.toString() ?? '',
      badge: map['badge']?.toString(),
      nutriscore: normalizedNutriscore,
      novaGroup: normalizedNova,
      allergens: ModelUtils.parseString(map['allergens']),
      additives: ModelUtils.parseString(map['additives']),
      ingredients: ModelUtils.parseModelList<Ingredient>(map['ingredients'], Ingredient.fromMap),
      nutrients: ModelUtils.parseNestedModel<NutrientData>(map['nutrients'], NutrientData.fromMap),
      nutrientLevels: ModelUtils.parseNestedModel<NutrientLevels>(map['nutrientLevels'], NutrientLevels.fromMap),
      impacts: ModelUtils.parseModelList<ImpactDetail>(map['impacts'], ImpactDetail.fromMap),
      swaps: ModelUtils.parseModelList<ProductSwap>(map['swaps'], ProductSwap.fromMap),
      cycleInsight: ModelUtils.parseNestedModel<CycleInsight>(map['cycleInsight'], CycleInsight.fromMap),
      barcode: map['barcode']?.toString(),
      source: map['source']?.toString(),
      userImageUrl: map['userImageUrl']?.toString(),
      flaggedIngredients: ModelUtils.parseList<String>(map['flaggedIngredients']),
      time: map['time'] != null ? DateTime.tryParse(map['time']) : null,
      isSaved: ModelUtils.parseBool(map['isSaved']),
    );
  }

  /// The official name of the product.
  final String productName;

  /// The manufacturing brand.
  final String brand;

  /// The category of the scan (e.g., 'food', 'menu', 'label').
  final String? category;

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

  /// Whether this product is saved as a favorite.
  final bool isSaved;

  /// Returns true if this result represents a specific food product suitable for history.
  ///
  /// Filters out generic utility scans like "Restaurant Menus" or "Ingredient Labels"
  /// which are analyzed for immediate feedback but shouldn't clutter the Pattern Engine.
  bool get isLoggableProduct {
    // 1. Explicit AI Category Check (Primary)
    if (category != null) {
      return category == 'food';
    }

    // 2. Barcode scans are always legitimate products from the database.
    if (barcode != null && barcode!.isNotEmpty) return true;

    // 3. Fallback Heuristics for older scans or missing category
    final name = productName.toLowerCase();
    final isMenu = name.contains('menu') && !name.contains('meal') && !name.contains('combo');
    final isLabelOnly = name.contains('ingredients list') || name.contains('nutrition label') || name.contains('ingredients only');
    final isGeneric = const {'menu', 'ingredients', 'label', 'nutrition', 'facts'}.contains(name);

    return !(isMenu || isLabelOnly || isGeneric);
  }

  ScanResult copyWith({
    String? productName,
    String? brand,
    String? category,
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
    bool? isSaved,
  }) => ScanResult(
    productName: productName ?? this.productName,
    brand: brand ?? this.brand,
    category: category ?? this.category,
    imageUrl: imageUrl ?? this.imageUrl,
    score: score != null ? score.clamp(0, 100) : this.score,
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
    isSaved: isSaved ?? this.isSaved,
  );

  Map<String, dynamic> toMap() => {
    'productName': productName,
    'brand': brand,
    'category': category,
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
    'isSaved': isSaved,
  };

  /// Optimized Map for AI context to prevent 502/payload-too-large errors.
  /// Excludes large fields like full ingredients, nutrients, and swaps.
  ///
  /// 🟢 NEW: now also includes `flaggedIngredients` short-circuit already
  /// present, plus is actually WIRED UP into chat history round-trips —
  /// see `AiServiceImpl._historyToPayload` in ai_service.dart. Previously
  /// this method existed but was never called from the chat streaming
  /// path, so scan context silently vanished from follow-up turns.
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
  List<Object?> get props => [productName, brand, category, score, impactType, impact, barcode, userImageUrl, flaggedIngredients, isSaved];
}
