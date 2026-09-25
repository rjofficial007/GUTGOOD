import 'package:equatable/equatable.dart';
import 'package:gutgood/core/utils/insight_values.dart';
import 'package:gutgood/core/utils/model_utils.dart';

class EmptyStateRequirement extends Equatable {
  const EmptyStateRequirement({
    required this.key,
    required this.label,
    required this.current,
    required this.recommended,
  });

  factory EmptyStateRequirement.fromMap(Map<String, dynamic> map) =>
      EmptyStateRequirement(
        key: map['key']?.toString() ?? '',
        label: map['label']?.toString() ?? '',
        current: InsightValues.integer(map['current']) ?? 0,
        recommended: InsightValues.integer(map['recommended']) ?? 0,
      );

  final String key;
  final String label;
  final int current;
  final int recommended;

  Map<String, dynamic> toMap() => {
        'key': key,
        'label': label,
        'current': current,
        'recommended': recommended,
      };

  @override
  List<Object?> get props => [key, label, current, recommended];
}

class EmptyStateAction extends Equatable {
  const EmptyStateAction({
    required this.label,
    required this.route,
  });

  factory EmptyStateAction.fromMap(Map<String, dynamic> map) => EmptyStateAction(
        label: map['label']?.toString() ?? '',
        route: map['route']?.toString() ?? '',
      );

  final String label;
  final String route;

  Map<String, dynamic> toMap() => {
        'label': label,
        'route': route,
      };

  @override
  List<Object?> get props => [label, route];
}

class InsightEmptyState extends Equatable {
  const InsightEmptyState({
    required this.reason,
    required this.title,
    required this.description,
    this.requirements = const [],
    this.primaryAction,
    this.secondaryAction,
  });

  factory InsightEmptyState.fromMap(Map<String, dynamic> map) => InsightEmptyState(
        reason: map['reason']?.toString() ?? 'insufficient_data',
        title: map['title']?.toString() ?? "We're still learning about your gut",
        description: map['description']?.toString() ??
            'Log a few more meals and symptoms to unlock personalized patterns.',
        requirements: ModelUtils.parseModelList<EmptyStateRequirement>(
          map['requirements'],
          EmptyStateRequirement.fromMap,
        ),
        primaryAction: map['primaryAction'] is Map<String, dynamic>
            ? EmptyStateAction.fromMap(
                map['primaryAction'] as Map<String, dynamic>)
            : null,
        secondaryAction: map['secondaryAction'] is Map<String, dynamic>
            ? EmptyStateAction.fromMap(
                map['secondaryAction'] as Map<String, dynamic>)
            : null,
      );

  final String reason;
  final String title;
  final String description;
  final List<EmptyStateRequirement> requirements;
  final EmptyStateAction? primaryAction;
  final EmptyStateAction? secondaryAction;

  Map<String, dynamic> toMap() => {
        'reason': reason,
        'title': title,
        'description': description,
        'requirements': requirements.map((e) => e.toMap()).toList(),
        'primaryAction': primaryAction?.toMap(),
        'secondaryAction': secondaryAction?.toMap(),
      };

  @override
  List<Object?> get props => [
        reason,
        title,
        description,
        requirements,
        primaryAction,
        secondaryAction,
      ];
}
