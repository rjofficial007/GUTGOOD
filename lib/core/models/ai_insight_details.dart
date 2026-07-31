import 'package:equatable/equatable.dart';
import 'package:gutgood/core/utils/model_utils.dart';

class InsightSummary extends Equatable {
  final String title;
  final String description;
  final String type;

  const InsightSummary({required this.title, required this.description, required this.type});

  factory InsightSummary.fromMap(Map<String, dynamic> map) {
    return InsightSummary(title: map['title']?.toString() ?? 'Insight', description: map['description']?.toString() ?? '', type: map['type']?.toString() ?? 'Pattern');
  }

  Map<String, dynamic> toMap() {
    return {'title': title, 'description': description, 'type': type};
  }

  @override
  List<Object?> get props => [title, description, type];
}

class HealingFood extends Equatable {
  final String name;
  final String effect;
  final String emoji;

  const HealingFood({required this.name, required this.effect, required this.emoji});

  factory HealingFood.fromMap(Map<String, dynamic> map) {
    return HealingFood(name: map['name']?.toString() ?? '', effect: map['effect']?.toString() ?? '', emoji: map['emoji']?.toString() ?? '🥗');
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'effect': effect, 'emoji': emoji};
  }

  @override
  List<Object?> get props => [name, effect, emoji];
}

class TriggerFood extends Equatable {
  final String name;
  final String effect;
  final String emoji;

  const TriggerFood({required this.name, required this.effect, required this.emoji});

  factory TriggerFood.fromMap(Map<String, dynamic> map) {
    return TriggerFood(name: map['name']?.toString() ?? '', effect: map['effect']?.toString() ?? '', emoji: map['emoji']?.toString() ?? '🍕');
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'effect': effect, 'emoji': emoji};
  }

  @override
  List<Object?> get props => [name, effect, emoji];
}

class DetectedPattern extends Equatable {
  final String title;
  final String description;
  final String icon;

  const DetectedPattern({required this.title, required this.description, required this.icon});

  factory DetectedPattern.fromMap(Map<String, dynamic> map) {
    return DetectedPattern(title: map['title']?.toString() ?? '', description: map['description']?.toString() ?? '', icon: map['icon']?.toString() ?? 'brain');
  }

  Map<String, dynamic> toMap() {
    return {'title': title, 'description': description, 'icon': icon};
  }

  @override
  List<Object?> get props => [title, description, icon];
}

class TopHighlight extends Equatable {
  final String food;
  final String effects;
  final String timeframe;
  final String frequency;
  final String emoji;

  const TopHighlight({required this.food, required this.effects, required this.timeframe, required this.frequency, required this.emoji});

  factory TopHighlight.fromMap(Map<String, dynamic> map) {
    return TopHighlight(
      food: map['food']?.toString() ?? '',
      effects: map['effects']?.toString() ?? '',
      timeframe: map['timeframe']?.toString() ?? '',
      frequency: map['frequency']?.toString() ?? '',
      emoji: map['emoji']?.toString() ?? '🍽️',
    );
  }

  Map<String, dynamic> toMap() {
    return {'food': food, 'effects': effects, 'timeframe': timeframe, 'frequency': frequency, 'emoji': emoji};
  }

  @override
  List<Object?> get props => [food, effects, timeframe, frequency, emoji];
}

class FoodImpact extends Equatable {
  final String food;
  final String dateLabel;
  final String effect;
  final String timeframeLabel;
  final String emoji;
  final String impactType; // 'negative' | 'positive'

  const FoodImpact({required this.food, required this.dateLabel, required this.effect, required this.timeframeLabel, required this.emoji, required this.impactType});

  factory FoodImpact.fromMap(Map<String, dynamic> map) {
    return FoodImpact(
      food: map['food']?.toString() ?? 'Unknown',
      dateLabel: map['dateLabel']?.toString() ?? '',
      effect: map['effect']?.toString() ?? 'Stable',
      timeframeLabel: map['timeframeLabel']?.toString() ?? '',
      emoji: map['emoji']?.toString() ?? '🍽️',
      impactType: map['impactType']?.toString() ?? 'positive',
    );
  }

  Map<String, dynamic> toMap() {
    return {'food': food, 'dateLabel': dateLabel, 'effect': effect, 'timeframeLabel': timeframeLabel, 'emoji': emoji, 'impactType': impactType};
  }

  @override
  List<Object?> get props => [food, dateLabel, effect, impactType];
}

class WeeklyRecap extends Equatable {
  final String dateRange;
  final int avgScore;
  final String scoreSub;
  final String bestDay;
  final int foodsLogged;
  final String loggedSub;
  final List<RecapHighlight> highlights;

  const WeeklyRecap({required this.dateRange, required this.avgScore, required this.scoreSub, required this.bestDay, required this.foodsLogged, required this.loggedSub, this.highlights = const []});

  factory WeeklyRecap.fromMap(Map<String, dynamic> map) {
    return WeeklyRecap(
      dateRange: map['dateRange']?.toString() ?? 'Last 7 Days',
      avgScore: (map['avgScore'] as num?)?.toInt() ?? 0,
      scoreSub: map['scoreSub']?.toString() ?? '',
      bestDay: map['bestDay']?.toString() ?? 'N/A',
      foodsLogged: (map['foodsLogged'] as num?)?.toInt() ?? 0,
      loggedSub: map['loggedSub']?.toString() ?? '',
      highlights: ModelUtils.parseModelList<RecapHighlight>(map['highlights'], RecapHighlight.fromMap),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dateRange': dateRange,
      'avgScore': avgScore,
      'scoreSub': scoreSub,
      'bestDay': bestDay,
      'foodsLogged': foodsLogged,
      'loggedSub': loggedSub,
      'highlights': highlights.map((e) => e.toMap()).toList(),
    };
  }

  @override
  List<Object?> get props => [dateRange, avgScore, bestDay, foodsLogged];
}

class RecapHighlight extends Equatable {
  final String icon;
  final String text;
  final String color;

  const RecapHighlight({required this.icon, required this.text, required this.color});

  factory RecapHighlight.fromMap(Map<String, dynamic> map) {
    return RecapHighlight(icon: map['icon']?.toString() ?? 'sparkles', text: map['text']?.toString() ?? '', color: map['color']?.toString() ?? 'purple');
  }

  Map<String, dynamic> toMap() {
    return {'icon': icon, 'text': text, 'color': color};
  }

  @override
  List<Object?> get props => [icon, text, color];
}
