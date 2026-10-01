import 'package:equatable/equatable.dart';
import 'package:gutgood/core/utils/insight_values.dart';
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
  const SwapNutrition({this.calories, this.protein, this.totalFat, this.fiber});

  factory SwapNutrition.fromMap(Map<String, dynamic> map) => SwapNutrition(
    calories: InsightValues.integer(map['calories']),
    protein: map['protein']?.toString(),
    totalFat: (map['totalFat'] ?? map['total_fat'])?.toString(),
    fiber: map['fiber']?.toString(),
  );

  final int? calories;
  final String? protein;
  final String? totalFat;
  final String? fiber;

  Map<String, dynamic> toMap() => {'calories': calories, 'protein': protein, 'totalFat': totalFat, 'fiber': fiber};

  @override
  List<Object?> get props => [calories, protein, totalFat, fiber];
}

class SwapAlternative extends Equatable {
  const SwapAlternative({
    required this.foodId,
    required this.name,
    this.imageUrl,
    this.reason,
    this.impactLevel = 'high',
    this.category = '',
    this.benefitTags = const [],
    this.benefits = const [],
    this.whyBetterOption,
    this.nutrition = const SwapNutrition(),
  });

  factory SwapAlternative.fromMap(Map<String, dynamic> map) => SwapAlternative(
    foodId: (map['foodId'] ?? map['id'] ?? '').toString(),
    name: (map['name'] ?? map['food'] ?? '').toString(),
    imageUrl: map['imageUrl']?.toString(),
    reason: map['reason']?.toString(),
    impactLevel: map['impactLevel']?.toString() ?? 'high',
    category: map['category']?.toString() ?? '',
    benefitTags: ModelUtils.parseList<String>(map['benefitTags'] ?? map['benefits'] ?? []),
    benefits: ModelUtils.parseModelList<SwapBenefit>(map['structuredBenefits'] ?? map['whyItWorks'], SwapBenefit.fromMap),
    whyBetterOption: map['whyBetterOption']?.toString() ?? map['whyBetter']?.toString(),
    nutrition: map['nutrition'] is Map<String, dynamic> ? SwapNutrition.fromMap(map['nutrition'] as Map<String, dynamic>) : const SwapNutrition(),
  );

  final String foodId;
  final String name;
  final String? imageUrl;
  final String? reason;
  final String impactLevel;
  final String category;
  final List<String> benefitTags;
  final List<SwapBenefit> benefits;
  final String? whyBetterOption;
  final SwapNutrition nutrition;

  Map<String, dynamic> toMap() => {
    'foodId': foodId,
    'name': name,
    'imageUrl': imageUrl,
    'reason': reason,
    'impactLevel': impactLevel,
    'category': category,
    'benefitTags': benefitTags,
    'structuredBenefits': benefits.map((e) => e.toMap()).toList(),
    'whyBetterOption': whyBetterOption,
    'nutrition': nutrition.toMap(),
  };

  @override
  List<Object?> get props => [foodId, name, imageUrl, reason, impactLevel, category, benefitTags, benefits, whyBetterOption, nutrition];
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
