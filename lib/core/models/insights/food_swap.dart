import 'package:equatable/equatable.dart';
import 'package:gutgood/core/utils/model_utils.dart';

class SwapSource extends Equatable {
  const SwapSource({required this.foodId, required this.name, this.imageUrl});

  factory SwapSource.fromMap(Map<String, dynamic> map) =>
      SwapSource(foodId: (map['foodId'] ?? map['id'] ?? '').toString(), name: (map['name'] ?? map['food'] ?? '').toString(), imageUrl: map['imageUrl']?.toString());

  final String foodId;
  final String name;
  final String? imageUrl;

  Map<String, dynamic> toMap() => {'foodId': foodId, 'name': name, 'imageUrl': imageUrl};

  @override
  List<Object?> get props => [foodId, name, imageUrl];
}

class SwapBenefit extends Equatable {
  const SwapBenefit({required this.title, required this.description, required this.icon});

  factory SwapBenefit.fromMap(Map<String, dynamic> map) =>
      SwapBenefit(title: (map['title'] ?? '').toString(), description: (map['description'] ?? '').toString(), icon: (map['icon'] ?? 'leaf').toString());

  final String title;
  final String description;
  final String icon;

  Map<String, dynamic> toMap() => {'title': title, 'description': description, 'icon': icon};

  @override
  List<Object?> get props => [title, description, icon];
}

class SwapNutrition extends Equatable {
  const SwapNutrition({this.calories, this.protein, this.totalFat, this.fiber, this.basis});

  factory SwapNutrition.fromMap(Map<String, dynamic> map) => SwapNutrition(
    calories: map['calories'] is num ? (map['calories'] as num).toInt() : int.tryParse(map['calories']?.toString() ?? ''),
    protein: map['protein']?.toString(),
    totalFat: (map['totalFat'] ?? map['total_fat'])?.toString(),
    fiber: map['fiber']?.toString(),
    basis: map['basis']?.toString(),
  );

  final int? calories;
  final String? protein;
  final String? totalFat;
  final String? fiber;
  final String? basis;

  bool get hasData => calories != null || protein?.trim().isNotEmpty == true || totalFat?.trim().isNotEmpty == true || fiber?.trim().isNotEmpty == true;

  Map<String, dynamic> toMap() => {'calories': calories, 'protein': protein, 'totalFat': totalFat, 'fiber': fiber, 'basis': basis};

  @override
  List<Object?> get props => [calories, protein, totalFat, fiber, basis];
}

class SwapAlternative extends Equatable {
  const SwapAlternative({
    required this.foodId,
    required this.name,
    this.imageUrl,
    this.imageKeyword,
    this.reason,
    this.tag,
    this.badge,
    this.isBlackBadge = false,
    this.barcode,
    this.nutriscore,
    this.impactLevel = 'unknown',
    this.category = '',
    this.benefitTags = const [],
    this.benefits = const [],
    this.replaces,
    this.whyBetterOption,
    this.nutrition = const SwapNutrition(),
  });

  factory SwapAlternative.fromMap(Map<String, dynamic> map) => SwapAlternative(
    foodId: (map['foodId'] ?? map['id'] ?? map['barcode'] ?? map['name'] ?? map['title'] ?? '').toString(),
    name: (map['name'] ?? map['food'] ?? map['title'] ?? '').toString(),
    imageUrl: map['imageUrl']?.toString(),
    imageKeyword: map['imageKeyword']?.toString(),
    reason: (map['reason'] ?? map['subtitle'])?.toString(),
    tag: map['tag']?.toString(),
    badge: map['badge']?.toString(),
    isBlackBadge: ModelUtils.parseBool(map['isBlackBadge']),
    barcode: map['barcode']?.toString(),
    nutriscore: map['nutriscore']?.toString(),
    impactLevel: map['impactLevel']?.toString() ?? 'unknown',
    category: (map['category'] ?? map['badge'])?.toString() ?? '',
    benefitTags: ModelUtils.parseList<String>(map['benefitTags'] ?? map['benefits'] ?? []),
    benefits: ModelUtils.parseModelList<SwapBenefit>(map['structuredBenefits'] ?? map['whyItWorks'], SwapBenefit.fromMap),
    replaces: map['replaces']?.toString(),
    whyBetterOption: map['whyBetterOption']?.toString() ?? map['whyBetter']?.toString(),
    nutrition: map['nutrition'] is Map<String, dynamic> ? SwapNutrition.fromMap(map['nutrition'] as Map<String, dynamic>) : const SwapNutrition(),
  );

  final String foodId;
  final String name;
  final String? imageUrl;
  final String? imageKeyword;
  final String? reason;
  final String? tag;
  final String? badge;
  final bool isBlackBadge;
  final String? barcode;
  final String? nutriscore;
  final String impactLevel;
  final String category;
  final List<String> benefitTags;
  final List<SwapBenefit> benefits;
  final String? replaces;
  final String? whyBetterOption;
  final SwapNutrition nutrition;

  Map<String, dynamic> toMap() => {
    'foodId': foodId,
    'name': name,
    'imageUrl': imageUrl,
    'imageKeyword': imageKeyword,
    'reason': reason,
    'tag': tag,
    'badge': badge,
    'isBlackBadge': isBlackBadge,
    'barcode': barcode,
    'nutriscore': nutriscore,
    'impactLevel': impactLevel,
    'category': category,
    'benefitTags': benefitTags,
    'structuredBenefits': benefits.map((e) => e.toMap()).toList(),
    if (replaces?.trim().isNotEmpty == true) 'replaces': replaces,
    'whyBetterOption': whyBetterOption,
    'nutrition': nutrition.toMap(),
  };

  @override
  List<Object?> get props => [foodId, name, imageUrl, imageKeyword, reason, tag, badge, isBlackBadge, barcode, nutriscore, impactLevel, category, benefitTags, benefits, replaces, whyBetterOption, nutrition];
}

class FoodSwap extends Equatable {
  const FoodSwap({required this.id, required this.source, this.alternatives = const [], this.relatedPatternId});

  factory FoodSwap.fromMap(Map<String, dynamic> map) {
    final parsedAlternatives = ModelUtils.parseModelList<SwapAlternative>(map['alternatives'], SwapAlternative.fromMap);

    return FoodSwap(
      id: (map['id'] ?? '').toString(),
      source: map['source'] is Map<String, dynamic> ? SwapSource.fromMap(map['source'] as Map<String, dynamic>) : SwapSource(foodId: '', name: map['source']?.toString() ?? ''),
      alternatives: parsedAlternatives,
      relatedPatternId: map['relatedPatternId']?.toString(),
    );
  }

  final String id;
  final SwapSource source;
  final List<SwapAlternative> alternatives;
  final String? relatedPatternId;

  Map<String, dynamic> toMap() => {'id': id, 'source': source.toMap(), 'alternatives': alternatives.map((e) => e.toMap()).toList(), 'relatedPatternId': relatedPatternId};

  @override
  List<Object?> get props => [id, source, alternatives, relatedPatternId];
}
