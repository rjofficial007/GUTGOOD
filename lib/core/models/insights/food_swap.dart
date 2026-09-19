import 'package:equatable/equatable.dart';
import 'package:gutgood/core/utils/model_utils.dart';

class SwapSource extends Equatable {
  const SwapSource({
    required this.foodId,
    required this.name,
    this.imageUrl,
  });

  factory SwapSource.fromMap(Map<String, dynamic> map) => SwapSource(
        foodId: (map['foodId'] ?? map['id'] ?? '').toString(),
        name: (map['name'] ?? map['food'] ?? '').toString(),
        imageUrl: map['imageUrl']?.toString(),
      );

  final String foodId;
  final String name;
  final String? imageUrl;

  Map<String, dynamic> toMap() => {
        'foodId': foodId,
        'name': name,
        'imageUrl': imageUrl,
      };

  @override
  List<Object?> get props => [foodId, name, imageUrl];
}

class SwapAlternative extends Equatable {
  const SwapAlternative({
    required this.foodId,
    required this.name,
    this.imageUrl,
    this.reason,
    this.impactLevel = 'high',
  });

  factory SwapAlternative.fromMap(Map<String, dynamic> map) => SwapAlternative(
        foodId: (map['foodId'] ?? map['id'] ?? '').toString(),
        name: (map['name'] ?? map['food'] ?? '').toString(),
        imageUrl: map['imageUrl']?.toString(),
        reason: map['reason']?.toString(),
        impactLevel: map['impactLevel']?.toString() ?? 'high',
      );

  final String foodId;
  final String name;
  final String? imageUrl;
  final String? reason;
  final String impactLevel;

  Map<String, dynamic> toMap() => {
        'foodId': foodId,
        'name': name,
        'imageUrl': imageUrl,
        'reason': reason,
        'impactLevel': impactLevel,
      };

  @override
  List<Object?> get props => [foodId, name, imageUrl, reason, impactLevel];
}

class FoodSwap extends Equatable {
  const FoodSwap({
    required this.id,
    required this.source,
    this.alternatives = const [],
    this.relatedPatternId,
  });

  factory FoodSwap.fromMap(Map<String, dynamic> map) => FoodSwap(
        id: (map['id'] ?? '').toString(),
        source: map['source'] is Map<String, dynamic>
            ? SwapSource.fromMap(map['source'] as Map<String, dynamic>)
            : SwapSource(foodId: '', name: map['source']?.toString() ?? ''),
        alternatives: ModelUtils.parseModelList<SwapAlternative>(
          map['alternatives'],
          SwapAlternative.fromMap,
        ),
        relatedPatternId: map['relatedPatternId']?.toString(),
      );

  final String id;
  final SwapSource source;
  final List<SwapAlternative> alternatives;
  final String? relatedPatternId;

  Map<String, dynamic> toMap() => {
        'id': id,
        'source': source.toMap(),
        'alternatives': alternatives.map((e) => e.toMap()).toList(),
        'relatedPatternId': relatedPatternId,
      };

  @override
  List<Object?> get props => [id, source, alternatives, relatedPatternId];
}
