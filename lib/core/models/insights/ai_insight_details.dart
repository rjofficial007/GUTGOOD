import 'package:gutgood/core/utils/insight_values.dart';
import 'package:equatable/equatable.dart';
import 'package:gutgood/core/utils/insight_presentation.dart';
import 'package:gutgood/core/utils/model_utils.dart';

String _resolveEmoji(String? stored, String foodName) => (stored == null || stored.isEmpty) ? InsightPresentation.emojiForFood(foodName) : stored;

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
    frequency: InsightValues.integer(map['frequency']),
    evidenceRatio: InsightValues.number(map['evidenceRatio'])?.toDouble(),
    positiveCount: InsightValues.integer(map['positiveCount']),
    negativeCount: InsightValues.integer(map['negativeCount']),
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
  List<Object?> get props => [title, description, type, observation, strength, frequency];
}

class HealingFood extends Equatable {
  const HealingFood({required this.name, required this.effect, required this.emoji, this.imageUrl, this.userImageUrl, this.foodScanId});

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

  Map<String, dynamic> toMap() => {'name': name, 'effect': effect, 'emoji': emoji, 'imageUrl': imageUrl, 'userImageUrl': userImageUrl, 'foodScanId': foodScanId};

  @override
  List<Object?> get props => [name, effect, emoji, imageUrl, userImageUrl, foodScanId];
}

class TriggerFood extends Equatable {
  const TriggerFood({required this.name, required this.effect, required this.emoji, this.imageUrl, this.userImageUrl, this.foodScanId});

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

  Map<String, dynamic> toMap() => {'name': name, 'effect': effect, 'emoji': emoji, 'imageUrl': imageUrl, 'userImageUrl': userImageUrl, 'foodScanId': foodScanId};

  @override
  List<Object?> get props => [name, effect, emoji, imageUrl, userImageUrl, foodScanId];
}

class TopHighlight extends Equatable {
  const TopHighlight({
    required this.food,
    String impact = '',
    required this.emoji,
    this.symptom,
    this.imageUrl,
    this.userImageUrl,
    this.frequency,
    this.foodScanId,
    this.whyPoints = const [],
    String? effects,
    String? timeframe,
  }) : _impact = impact,
       _effects = effects,
       _timeframe = timeframe;

  factory TopHighlight.fromMap(Map<String, dynamic> map) {
    final food = (map['food'] ?? map['title'] ?? map['name'] ?? '').toString();
    final img = map['userImageUrl']?.toString() ?? map['imageUrl']?.toString();
    final eff = (map['effects'] ?? map['impact'] ?? map['effect'] ?? '').toString();
    final tf = map['timeframe']?.toString() ?? map['symptom']?.toString();
    return TopHighlight(
      food: food,
      impact: eff,
      emoji: _resolveEmoji(map['emoji']?.toString(), food),
      symptom: map['symptom']?.toString() ?? tf,
      imageUrl: map['imageUrl']?.toString() ?? img,
      userImageUrl: img,
      frequency: map['frequency']?.toString(),
      foodScanId: (map['foodScanId'] ?? map['scanId'])?.toString(),
      whyPoints: (map['whyPoints'] as List?)?.cast<String>() ?? const [],
      effects: eff,
      timeframe: tf,
    );
  }

  final String food;
  final String _impact;
  final String emoji;
  final String? symptom;
  final String? imageUrl;
  final String? userImageUrl;
  final String? frequency;
  final String? foodScanId;
  final List<String> whyPoints;
  final String? _effects;
  final String? _timeframe;

  String get impact => _effects != null && _effects.isNotEmpty ? _effects : _impact;
  String get effects => impact;
  String? get timeframe => _timeframe ?? symptom;

  Map<String, dynamic> toMap() => {
    'food': food,
    'impact': impact,
    'effects': effects,
    'emoji': emoji,
    'symptom': symptom,
    'timeframe': timeframe,
    'imageUrl': imageUrl,
    'userImageUrl': userImageUrl,
    'frequency': frequency,
    'foodScanId': foodScanId,
    'whyPoints': whyPoints,
  };

  @override
  List<Object?> get props => [food, impact, emoji, symptom, imageUrl, userImageUrl, frequency, foodScanId, whyPoints, _effects, _timeframe];
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
    final food = (map['food'] ?? map['title'] ?? map['name'] ?? '').toString();
    final img = map['userImageUrl']?.toString() ?? map['imageUrl']?.toString();
    return FoodImpact(
      food: food,
      dateLabel: (map['dateLabel'] ?? map['date'] ?? '').toString(),
      effect: (map['effect'] ?? map['impact'] ?? '').toString(),
      timeframeLabel: (map['timeframeLabel'] ?? map['timeframe'] ?? '').toString(),
      emoji: _resolveEmoji(map['emoji']?.toString(), food),
      impactType: (map['impactType'] ?? map['type'] ?? 'neutral').toString(),
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
  List<Object?> get props => [food, dateLabel, effect, timeframeLabel, emoji, impactType, imageUrl, userImageUrl, foodScanId];
}

class RecapHighlight extends Equatable {
  const RecapHighlight({required this.icon, required this.text, required this.color});

  factory RecapHighlight.fromMap(Map<String, dynamic> map) =>
      RecapHighlight(icon: map['icon']?.toString() ?? 'sparkles', text: map['text']?.toString() ?? '', color: map['color']?.toString() ?? 'green');

  final String icon;
  final String text;
  final String color;

  Map<String, dynamic> toMap() => {'icon': icon, 'text': text, 'color': color};

  @override
  List<Object?> get props => [icon, text, color];
}

class WeeklyRecap extends Equatable {
  const WeeklyRecap({
    this.highlights = const [],
    this.stats = const [],
    this.gutScoreTrend,
    this.summary,
    this.avgScore,
    this.dateRange,
    this.scoreSub,
    this.bestDay,
    this.foodsLogged,
    this.loggedSub,
  });

  factory WeeklyRecap.fromMap(Map<String, dynamic> map) {
    final rawHighlights = map['highlights'];
    final parsedHighlights = <dynamic>[];
    if (rawHighlights is List) {
      for (final item in rawHighlights) {
        if (item is Map<String, dynamic>) {
          parsedHighlights.add(RecapHighlight.fromMap(item));
        } else if (item is RecapHighlight) {
          parsedHighlights.add(item);
        } else if (item != null) {
          parsedHighlights.add(item.toString());
        }
      }
    }

    return WeeklyRecap(
      highlights: parsedHighlights,
      stats: (map['stats'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      gutScoreTrend: map['gutScoreTrend'] is List ? (map['gutScoreTrend'] as List).map(InsightValues.integer).whereType<int>().where((score) => score >= 0 && score <= 100).toList() : null,
      summary: map['summary']?.toString() ?? map['weeklyInsight']?.toString(),
      avgScore: InsightValues.integer(map['avgScore']),
      dateRange: map['dateRange']?.toString(),
      scoreSub: map['scoreSub']?.toString(),
      bestDay: map['bestDay']?.toString(),
      foodsLogged: InsightValues.integer(map['foodsLogged']),
      loggedSub: map['loggedSub']?.toString(),
    );
  }

  final List<dynamic> highlights;
  final List<String> stats;
  final List<int>? gutScoreTrend;
  final String? summary;
  final int? avgScore;
  final String? dateRange;
  final String? scoreSub;
  final String? bestDay;
  final int? foodsLogged;
  final String? loggedSub;

  WeeklyRecap copyWith({
    List<dynamic>? highlights,
    List<String>? stats,
    List<int>? gutScoreTrend,
    String? summary,
    int? avgScore,
    String? dateRange,
    String? scoreSub,
    String? bestDay,
    int? foodsLogged,
    String? loggedSub,
  }) =>
      WeeklyRecap(
        highlights: highlights ?? this.highlights,
        stats: stats ?? this.stats,
        gutScoreTrend: gutScoreTrend ?? this.gutScoreTrend,
        summary: summary ?? this.summary,
        avgScore: avgScore ?? this.avgScore,
        dateRange: dateRange ?? this.dateRange,
        scoreSub: scoreSub ?? this.scoreSub,
        bestDay: bestDay ?? this.bestDay,
        foodsLogged: foodsLogged ?? this.foodsLogged,
        loggedSub: loggedSub ?? this.loggedSub,
      );

  Map<String, dynamic> toMap() => {
    'highlights': highlights.map((e) {
      if (e is RecapHighlight) return e.toMap();
      return e;
    }).toList(),
    'stats': stats,
    'gutScoreTrend': gutScoreTrend,
    'summary': summary,
    'avgScore': avgScore,
    'dateRange': dateRange,
    'scoreSub': scoreSub,
    'bestDay': bestDay,
    'foodsLogged': foodsLogged,
    'loggedSub': loggedSub,
  };

  @override
  List<Object?> get props => [highlights, stats, gutScoreTrend, summary, avgScore, dateRange, scoreSub, bestDay, foodsLogged, loggedSub];
}

class GutScoreSummary extends Equatable {
  const GutScoreSummary({required this.score, required this.trend, this.status, this.description});

  factory GutScoreSummary.fromMap(Map<String, dynamic> map) =>
      GutScoreSummary(score: InsightValues.integer(map['score']) ?? 0, trend: map['trend']?.toString() ?? '', status: map['status']?.toString() ?? 'Stable', description: map['description']?.toString());

  final int score;
  final String trend;
  final String? status;
  final String? description;

  Map<String, dynamic> toMap() => {'score': score, 'trend': trend, 'status': status, 'description': description};

  @override
  List<Object?> get props => [score, trend, status, description];
}

class InsightFood extends Equatable {
  const InsightFood({required this.foodId, required this.name, required this.emoji, this.imageUrl, this.effect, this.impactLevel = 'medium'});

  factory InsightFood.fromMap(Map<String, dynamic> map) {
    final name = (map['name'] ?? map['food'] ?? '').toString();
    return InsightFood(
      foodId: (map['foodId'] ?? map['id'] ?? 'food_${name.hashCode}').toString(),
      name: name,
      emoji: _resolveEmoji(map['emoji']?.toString(), name),
      imageUrl: map['imageUrl']?.toString() ?? map['userImageUrl']?.toString(),
      effect: map['effect']?.toString(),
      impactLevel: map['impactLevel']?.toString() ?? 'medium',
    );
  }

  final String foodId;
  final String name;
  final String emoji;
  final String? imageUrl;
  final String? effect;
  final String impactLevel;

  Map<String, dynamic> toMap() => {'foodId': foodId, 'name': name, 'emoji': emoji, 'imageUrl': imageUrl, 'effect': effect, 'impactLevel': impactLevel};

  @override
  List<Object?> get props => [foodId, name, emoji, imageUrl, effect, impactLevel];
}

class HealingSummary extends Equatable {
  const HealingSummary({required this.foods, required this.goal, required this.trend});

  factory HealingSummary.fromMap(Map<String, dynamic> map) => HealingSummary(
    foods: ModelUtils.parseModelList<InsightFood>(map['foods'], InsightFood.fromMap),
    goal: map['goal']?.toString() ?? 'Microbiome Diversity',
    trend: map['trend']?.toString() ?? 'Improving',
  );

  final List<InsightFood> foods;
  final String goal;
  final String trend;

  Map<String, dynamic> toMap() => {'foods': foods.map((f) => f.toMap()).toList(), 'goal': goal, 'trend': trend};

  @override
  List<Object?> get props => [foods, goal, trend];
}

class TriggerSummary extends Equatable {
  const TriggerSummary({required this.foods, required this.primarySymptom, required this.trend});

  factory TriggerSummary.fromMap(Map<String, dynamic> map) => TriggerSummary(
    foods: ModelUtils.parseModelList<InsightFood>(map['foods'], InsightFood.fromMap),
    primarySymptom: map['primarySymptom']?.toString() ?? 'Bloating',
    trend: map['trend']?.toString() ?? 'Needs Attention',
  );

  final List<InsightFood> foods;
  final String primarySymptom;
  final String trend;

  Map<String, dynamic> toMap() => {'foods': foods.map((f) => f.toMap()).toList(), 'primarySymptom': primarySymptom, 'trend': trend};

  @override
  List<Object?> get props => [foods, primarySymptom, trend];
}

class FoodImpactBalance extends Equatable {
  const FoodImpactBalance({required this.positivePercent, required this.neutralPercent, required this.negativePercent, this.periodLabel = 'Last 4 weeks'});

  factory FoodImpactBalance.fromMap(Map<String, dynamic> map) => FoodImpactBalance(
    positivePercent: InsightValues.integer(map['positivePercent']) ?? 0,
    neutralPercent: InsightValues.integer(map['neutralPercent']) ?? 0,
    negativePercent: InsightValues.integer(map['negativePercent']) ?? 0,
    periodLabel: map['periodLabel']?.toString() ?? 'Last 4 weeks',
  );

  final int positivePercent;
  final int neutralPercent;
  final int negativePercent;
  final String periodLabel;

  Map<String, dynamic> toMap() => {'positivePercent': positivePercent, 'neutralPercent': neutralPercent, 'negativePercent': negativePercent, 'periodLabel': periodLabel};

  @override
  List<Object?> get props => [positivePercent, neutralPercent, negativePercent, periodLabel];
}

class WeeklyRecapHistoryItem extends Equatable {
  const WeeklyRecapHistoryItem({required this.id, required this.weekLabel, required this.avgScore, required this.summary, this.date});

  factory WeeklyRecapHistoryItem.fromMap(Map<String, dynamic> map) => WeeklyRecapHistoryItem(
    id: map['id']?.toString() ?? 'week_01',
    weekLabel: map['weekLabel']?.toString() ?? 'Week 1',
    avgScore: InsightValues.integer(map['avgScore']) ?? 0,
    summary: map['summary']?.toString() ?? 'Great consistency in plant diversity.',
    date: map['date']?.toString(),
  );

  final String id;
  final String weekLabel;
  final int avgScore;
  final String summary;
  final String? date;

  Map<String, dynamic> toMap() => {'id': id, 'weekLabel': weekLabel, 'avgScore': avgScore, 'summary': summary, 'date': date};

  @override
  List<Object?> get props => [id, weekLabel, avgScore, summary, date];
}
