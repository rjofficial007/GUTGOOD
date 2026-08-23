import 'package:equatable/equatable.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/utils/model_utils.dart';

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
    nutrientLevels: ModelUtils.parseNestedModel<NutrientLevels>(
      map['nutrientLevels'],
      NutrientLevels.fromMap,
    ),
    nutrients: ModelUtils.parseNestedModel<NutrientData>(
      map['nutrients'],
      NutrientData.fromMap,
    ),
    impacts: ModelUtils.parseModelList<ImpactDetail>(
      map['impacts'],
      ImpactDetail.fromMap,
    ),
  );
  final String productName;
  final String? brand;
  final String? imageUrl;
  final String? barcode;
  final int? score;
  final String? status;
  final String? statusColor;
  final String? nutriscore;
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

  Map<String, dynamic> toMap() => {
    'productName': productName,
    'brand': brand,
    'imageUrl': imageUrl,
    'barcode': barcode,
    'score': score,
    'status': status,
    'statusColor': statusColor,
    'nutriscore': nutriscore,
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
  };

  @override
  List<Object?> get props => [productName, barcode, score];
}
