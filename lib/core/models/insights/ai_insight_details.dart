import 'package:equatable/equatable.dart';
import 'package:gutgood/core/utils/insight_presentation.dart';
import 'package:gutgood/core/utils/model_utils.dart';

/// P2-10: keeps a stored emoji when present (legacy docs, tolerated LLM
/// output); otherwise derives it from the food name. Empty strings count as
/// missing — they previously persisted as invisible UI.
String _resolveEmoji(String? stored, String foodName) =>
    (stored == null || stored.isEmpty)
    ? InsightPresentation.emojiForFood(foodName)
    : stored;

class InsightSummary extends Equatable {
  const InsightSummary({
    required this.title,
    required this.description,
    required this.type,
    this.observation,
    this.involvedFoods = const [],
    this.strength,
    this.nextSteps = const [],
    this.frequency,
    this.evidenceRatio,
    this.positiveCount,
    this.negativeCount,
  });

  factory InsightSummary.fromMap(Map<String, dynamic> map) => InsightSummary(
    title: map['title']?.toString() ?? 'Insight',
    description: map['description']?.toString() ?? '',
    type: map['type']?.toString() ?? 'Pattern',
    observation: map['observation']?.toString(),
    involvedFoods: (map['involvedFoods'] as List?)?.cast<String>() ?? const [],
    strength: map['strength']?.toString(),
    nextSteps: (map['nextSteps'] as List?)?.cast<String>() ?? const [],
    frequency: (map['frequency'] as num?)?.toInt(),
    evidenceRatio: (map['evidenceRatio'] as num?)?.toDouble(),
    positiveCount: (map['positiveCount'] as num?)?.toInt(),
    negativeCount: (map['negativeCount'] as num?)?.toInt(),
  );
  final String title;
  final String description;
  final String type;
  final String? observation;
  final List<String> involvedFoods;
  final String? strength;
  final List<String> nextSteps;
  final int? frequency;
  final double? evidenceRatio;
  final int? positiveCount;
  final int? negativeCount;

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'type': type,
    'observation': observation,
    'involvedFoods': involvedFoods,
    'strength': strength,
    'nextSteps': nextSteps,
    'frequency': frequency,
    'evidenceRatio': evidenceRatio,
    'positiveCount': positiveCount,
    'negativeCount': negativeCount,
  };

  @override
  List<Object?> get props => [
    title,
    description,
    type,
    observation,
    strength,
    frequency,
  ];
}

class HealingFood extends Equatable {
  const HealingFood({
    required this.name,
    required this.effect,
    required this.emoji,
    this.imageUrl,
    this.userImageUrl,
    this.foodScanId,
  });

  factory HealingFood.fromMap(Map<String, dynamic> map) {
    final name = (map['name'] ?? map['food'] ?? map['title'] ?? '').toString();
    final img = map['userImageUrl']?.toString() ?? map['imageUrl']?.toString();
    return HealingFood(
      name: name,
      effect: (map['effect'] ?? map['effects'] ?? '').toString(),
      emoji: _resolveEmoji(map['emoji']?.toString(), name),
      imageUrl: map['imageUrl']?.toString() ?? img,
      userImageUrl: img,
      foodScanId: (map['foodScanId'] ?? map['scanId'])?.toString(),
    );
  }
  final String name;
  final String effect;
  final String emoji;
  final String? imageUrl;
  final String? userImageUrl;
  final String? foodScanId;

  Map<String, dynamic> toMap() => {
    'name': name,
    'effect': effect,
    'emoji': emoji,
    'imageUrl': imageUrl,
    'userImageUrl': userImageUrl,
    'foodScanId': foodScanId,
  };

  @override
  List<Object?> get props => [
    name,
    effect,
    emoji,
    imageUrl,
    userImageUrl,
    foodScanId,
  ];
}

class TriggerFood extends Equatable {
  const TriggerFood({
    required this.name,
    required this.effect,
    required this.emoji,
    this.imageUrl,
    this.userImageUrl,
    this.foodScanId,
  });

  factory TriggerFood.fromMap(Map<String, dynamic> map) {
    final name = (map['name'] ?? map['food'] ?? map['title'] ?? '').toString();
    final img = map['userImageUrl']?.toString() ?? map['imageUrl']?.toString();
    return TriggerFood(
      name: name,
      effect: (map['effect'] ?? map['effects'] ?? '').toString(),
      emoji: _resolveEmoji(map['emoji']?.toString(), name),
      imageUrl: map['imageUrl']?.toString() ?? img,
      userImageUrl: img,
      foodScanId: (map['foodScanId'] ?? map['scanId'])?.toString(),
    );
  }
  final String name;
  final String effect;
  final String emoji;
  final String? imageUrl;
  final String? userImageUrl;
  final String? foodScanId;

  Map<String, dynamic> toMap() => {
    'name': name,
    'effect': effect,
    'emoji': emoji,
    'imageUrl': imageUrl,
    'userImageUrl': userImageUrl,
    'foodScanId': foodScanId,
  };

  @override
  List<Object?> get props => [
    name,
    effect,
    emoji,
    imageUrl,
    userImageUrl,
    foodScanId,
  ];
}

class DetectedPattern extends Equatable {
  const DetectedPattern({
    required this.title,
    required this.description,
    required this.icon,
  });

  factory DetectedPattern.fromMap(Map<String, dynamic> map) => DetectedPattern(
    title: (map['title'] ?? map['name'] ?? map['text'] ?? '').toString(),
    description: (map['description'] ?? '').toString(),
    icon: map['icon']?.toString() ?? 'brain',
  );
  final String title;
  final String description;
  final String icon;

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'icon': icon,
  };

  @override
  List<Object?> get props => [title, description, icon];
}

class TopHighlight extends Equatable {
  const TopHighlight({
    required this.food,
    required this.effects,
    required this.timeframe,
    required this.frequency,
    required this.emoji,
    this.imageUrl,
    this.userImageUrl,
    this.foodScanId,
    this.whyPoints = const [],
  });

  factory TopHighlight.fromMap(Map<String, dynamic> map) {
    final food = map['food']?.toString() ?? '';
    final img = map['userImageUrl']?.toString() ?? map['imageUrl']?.toString();
    return TopHighlight(
      food: food,
      effects: map['effects']?.toString() ?? '',
      timeframe: map['timeframe']?.toString() ?? '',
      frequency: map['frequency']?.toString() ?? '',
      emoji: _resolveEmoji(map['emoji']?.toString(), food),
      imageUrl: map['imageUrl']?.toString() ?? img,
      userImageUrl: img,
      foodScanId: (map['foodScanId'] ?? map['scanId'])?.toString(),
      whyPoints: (map['whyPoints'] as List?)?.cast<String>() ?? const [],
    );
  }
  final String food;
  final String effects;
  final String timeframe;
  final String frequency;
  final String emoji;
  final String? imageUrl;
  final String? userImageUrl;
  final String? foodScanId;

  /// v3: checklist for the detail screen's "Why it works"/"Why it's a trigger"
  /// section. Empty on legacy docs — the UI falls back to [effects].
  final List<String> whyPoints;

  Map<String, dynamic> toMap() => {
    'food': food,
    'effects': effects,
    'timeframe': timeframe,
    'frequency': frequency,
    'emoji': emoji,
    'imageUrl': imageUrl,
    'userImageUrl': userImageUrl,
    'foodScanId': foodScanId,
    'whyPoints': whyPoints,
  };

  @override
  List<Object?> get props => [
    food,
    effects,
    timeframe,
    frequency,
    emoji,
    imageUrl,
    userImageUrl,
    foodScanId,
    whyPoints,
  ];
}

class FoodImpact extends Equatable {
  const FoodImpact({
    required this.food,
    required this.dateLabel,
    required this.effect,
    required this.timeframeLabel,
    required this.emoji,
    required this.impactType,
    this.imageUrl,
    this.userImageUrl,
    this.foodScanId,
  });

  factory FoodImpact.fromMap(Map<String, dynamic> map) {
    final food = map['food']?.toString() ?? 'Unknown';
    final img = map['userImageUrl']?.toString() ?? map['imageUrl']?.toString();
    return FoodImpact(
      food: food,
      dateLabel: map['dateLabel']?.toString() ?? '',
      effect: map['effect']?.toString() ?? 'Stable',
      timeframeLabel: map['timeframeLabel']?.toString() ?? '',
      emoji: _resolveEmoji(map['emoji']?.toString(), food),
      impactType: map['impactType']?.toString() ?? 'positive',
      imageUrl: map['imageUrl']?.toString() ?? img,
      userImageUrl: img,
      foodScanId: (map['foodScanId'] ?? map['scanId'])?.toString(),
    );
  }
  final String food;
  final String dateLabel;
  final String effect;
  final String timeframeLabel;
  final String emoji;
  final String impactType;
  final String? imageUrl;
  final String? userImageUrl;
  final String? foodScanId;

  Map<String, dynamic> toMap() => {
    'food': food,
    'dateLabel': dateLabel,
    'effect': effect,
    'timeframeLabel': timeframeLabel,
    'emoji': emoji,
    'impactType': impactType,
    'imageUrl': imageUrl,
    'userImageUrl': userImageUrl,
    'foodScanId': foodScanId,
  };

  @override
  List<Object?> get props => [
    food,
    dateLabel,
    effect,
    impactType,
    emoji,
    imageUrl,
    userImageUrl,
    foodScanId,
  ];
}

class WeeklyRecap extends Equatable {
  const WeeklyRecap({
    required this.dateRange,
    required this.avgScore,
    required this.scoreSub,
    required this.bestDay,
    required this.foodsLogged,
    required this.loggedSub,
    this.highlights = const [],
  });

  factory WeeklyRecap.fromMap(Map<String, dynamic> map) => WeeklyRecap(
    dateRange: map['dateRange']?.toString() ?? 'Last 7 Days',
    avgScore: (map['avgScore'] as num?)?.toInt() ?? 0,
    scoreSub: map['scoreSub']?.toString() ?? '',
    bestDay: map['bestDay']?.toString() ?? 'N/A',
    foodsLogged: (map['foodsLogged'] as num?)?.toInt() ?? 0,
    loggedSub: map['loggedSub']?.toString() ?? '',
    highlights: ModelUtils.parseModelList<RecapHighlight>(
      map['highlights'],
      RecapHighlight.fromMap,
    ),
  );
  final String dateRange;
  final int avgScore;
  final String scoreSub;
  final String bestDay;
  final int foodsLogged;
  final String loggedSub;
  final List<RecapHighlight> highlights;

  Map<String, dynamic> toMap() => {
    'dateRange': dateRange,
    'avgScore': avgScore,
    'scoreSub': scoreSub,
    'bestDay': bestDay,
    'foodsLogged': foodsLogged,
    'loggedSub': loggedSub,
    'highlights': highlights.map((e) => e.toMap()).toList(),
  };

  @override
  List<Object?> get props => [dateRange, avgScore, bestDay, foodsLogged];
}

class RecapHighlight extends Equatable {
  const RecapHighlight({
    required this.icon,
    required this.text,
    required this.color,
  });

  factory RecapHighlight.fromMap(Map<String, dynamic> map) => RecapHighlight(
    icon: map['icon']?.toString() ?? 'sparkles',
    text: map['text']?.toString() ?? '',
    color: map['color']?.toString() ?? 'purple',
  );
  final String icon;
  final String text;
  final String color;

  Map<String, dynamic> toMap() => {'icon': icon, 'text': text, 'color': color};

  @override
  List<Object?> get props => [icon, text, color];
}
