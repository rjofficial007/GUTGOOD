import 'package:equatable/equatable.dart';
import 'package:gutgood/core/utils/insight_values.dart';

class InsightDestination extends Equatable {
  const InsightDestination({
    required this.screen,
    required this.id,
  });

  factory InsightDestination.fromMap(Map<String, dynamic> map) =>
      InsightDestination(
        screen: map['screen']?.toString() ?? '',
        id: map['id']?.toString() ?? '',
      );

  final String screen;
  final String id;

  Map<String, dynamic> toMap() => {
        'screen': screen,
        'id': id,
      };

  @override
  List<Object?> get props => [screen, id];
}

class RecentInsightItem extends Equatable {
  const RecentInsightItem({
    required this.id,
    required this.kind,
    required this.date,
    required this.dateLabel,
    required this.title,
    required this.description,
    this.score,
    this.impactDirection = 'positive',
    this.impactLabel,
    this.imageUrl,
    this.destination,
  });

  factory RecentInsightItem.fromMap(Map<String, dynamic> map) =>
      RecentInsightItem(
        id: (map['id'] ?? '').toString(),
        kind: map['kind']?.toString() ?? 'pattern',
        date: map['date']?.toString() ?? '',
        dateLabel: map['dateLabel']?.toString() ?? '',
        title: (map['title'] ?? '').toString(),
        description: (map['description'] ?? '').toString(),
        score: InsightValues.integer(map['score']),
        impactDirection: map['impactDirection']?.toString() ?? 'positive',
        impactLabel: map['impactLabel']?.toString(),
        imageUrl: map['imageUrl']?.toString(),
        destination: map['destination'] is Map<String, dynamic>
            ? InsightDestination.fromMap(
                map['destination'] as Map<String, dynamic>)
            : null,
      );

  final String id;
  final String kind;
  final String date;
  final String dateLabel;
  final String title;
  final String description;
  final int? score;
  final String impactDirection;
  final String? impactLabel;
  final String? imageUrl;
  final InsightDestination? destination;

  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': kind,
        'date': date,
        'dateLabel': dateLabel,
        'title': title,
        'description': description,
        'score': score,
        'impactDirection': impactDirection,
        'impactLabel': impactLabel,
        'imageUrl': imageUrl,
        'destination': destination?.toMap(),
      };

  @override
  List<Object?> get props => [
        id,
        kind,
        date,
        dateLabel,
        title,
        description,
        score,
        impactDirection,
        impactLabel,
        imageUrl,
        destination,
      ];
}
