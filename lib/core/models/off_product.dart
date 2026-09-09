import 'package:equatable/equatable.dart';
import 'package:gutgood/core/data/additive_concern_db.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
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
  ];
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
