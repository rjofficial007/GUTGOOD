import 'package:equatable/equatable.dart';
import 'package:gutgood/core/utils/insight_values.dart';

class ActionProgress extends Equatable {
  const ActionProgress({required this.target, required this.completed, required this.unit});

  factory ActionProgress.fromMap(Map<String, dynamic> map) =>
      ActionProgress(target: InsightValues.integer(map['target']) ?? 0, completed: InsightValues.integer(map['completed']) ?? 0, unit: map['unit']?.toString() ?? '');

  final int target;
  final int completed;
  final String unit;

  Map<String, dynamic> toMap() => {'target': target, 'completed': completed, 'unit': unit};

  @override
  List<Object?> get props => [target, completed, unit];
}

class InsightAction extends Equatable {
  const InsightAction({
    required this.id,
    required this.title,
    required this.description,
    this.category = 'nutrition',
    this.impactLevel = 'moderate',
    this.difficulty = 'easy',
    this.status = 'not_started',
    this.whenToDo,
    this.expectedBenefit,
    this.relatedPatternIds = const [],
    this.relatedFoodIds = const [],
    this.progress,
  });

  factory InsightAction.fromMap(Map<String, dynamic> map) => InsightAction(
    id: (map['id'] ?? '').toString(),
    title: (map['title'] ?? map['name'] ?? map['text'] ?? '').toString(),
    description: (map['description'] ?? '').toString(),
    category: map['category']?.toString() ?? 'nutrition',
    impactLevel: map['impactLevel']?.toString() ?? 'moderate',
    difficulty: map['difficulty']?.toString() ?? 'easy',
    status: map['status']?.toString() ?? 'not_started',
    whenToDo: map['whenToDo']?.toString(),
    expectedBenefit: map['expectedBenefit']?.toString(),
    relatedPatternIds: (map['relatedPatternIds'] as List?)?.cast<String>() ?? const [],
    relatedFoodIds: (map['relatedFoodIds'] as List?)?.cast<String>() ?? const [],
    progress: map['progress'] is Map<String, dynamic> ? ActionProgress.fromMap(map['progress'] as Map<String, dynamic>) : null,
  );

  final String id;
  final String title;
  final String description;
  final String category;
  final String impactLevel;
  final String difficulty;
  final String status;
  final String? whenToDo;
  final String? expectedBenefit;
  final List<String> relatedPatternIds;
  final List<String> relatedFoodIds;
  final ActionProgress? progress;

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'impactLevel': impactLevel,
    'difficulty': difficulty,
    'status': status,
    'whenToDo': whenToDo,
    'expectedBenefit': expectedBenefit,
    'relatedPatternIds': relatedPatternIds,
    'relatedFoodIds': relatedFoodIds,
    'progress': progress?.toMap(),
  };

  @override
  List<Object?> get props => [id, title, description, category, impactLevel, difficulty, status, whenToDo, expectedBenefit, relatedPatternIds, relatedFoodIds, progress];
}
