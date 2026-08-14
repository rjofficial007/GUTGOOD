import 'package:equatable/equatable.dart';

class BodyPattern extends Equatable {
  const BodyPattern({
    required this.type,
    required this.trigger,
    required this.reaction,
    required this.frequency,
    required this.confidence,
    required this.description,
    this.involvedFoods = const [],
    this.recommendation,
    required this.updatedAt,
  });

  factory BodyPattern.fromMap(Map<String, dynamic> map) => BodyPattern(
    type: map['type'] ?? '',
    trigger: map['trigger'] ?? '',
    reaction: map['reaction'] ?? '',
    frequency: (map['frequency'] as num?)?.toInt() ?? 0,
    confidence: map['confidence'] ?? 'Moderate',
    description: map['description'] ?? '',
    involvedFoods: (map['involvedFoods'] as List?)?.cast<String>() ?? const [],
    recommendation: map['recommendation'] as String?,
    updatedAt: map['updatedAt'] ?? DateTime.now().toIso8601String(),
  );
  final String type;
  final String trigger;
  final String reaction;
  final int frequency;
  final String confidence;
  final String description;
  final List<String> involvedFoods;
  final String? recommendation;
  final String updatedAt;

  Map<String, dynamic> toMap() => {
    'type': type,
    'trigger': trigger,
    'reaction': reaction,
    'frequency': frequency,
    'confidence': confidence,
    'description': description,
    'involvedFoods': involvedFoods,
    'recommendation': recommendation,
    'updatedAt': updatedAt,
  };

  @override
  List<Object?> get props => [
    type,
    trigger,
    reaction,
    frequency,
    confidence,
    description,
    involvedFoods,
    recommendation,
    updatedAt,
  ];
}
