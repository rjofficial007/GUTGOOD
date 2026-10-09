import 'package:equatable/equatable.dart';
import 'package:gutgood/core/models/insights/food_swap.dart';
import 'package:gutgood/core/utils/model_utils.dart';

class NutrientLevels extends Equatable {
  const NutrientLevels({this.sugars = 'unknown', this.salt = 'unknown', this.fat = 'unknown', this.saturatedFat = 'unknown'});

  factory NutrientLevels.fromMap(Map<String, dynamic> map) => NutrientLevels(
    sugars: map['sugars']?.toString() ?? 'unknown',
    salt: map['salt']?.toString() ?? 'unknown',
    fat: map['fat']?.toString() ?? 'unknown',
    saturatedFat: map['saturated-fat']?.toString() ?? 'unknown',
  );
  final String sugars;
  final String salt;
  final String fat;
  final String saturatedFat;

  Map<String, dynamic> toMap() => {'sugars': sugars, 'salt': salt, 'fat': fat, 'saturated-fat': saturatedFat};

  @override
  List<Object?> get props => [sugars, salt, fat, saturatedFat];
}

class NutrientData extends Equatable {
  const NutrientData({this.calories, this.fat, this.saturatedFat, this.carbs, this.sugars, this.fiber, this.proteins, this.salt});

  factory NutrientData.fromMap(Map<String, dynamic> map) {
    num? parseGram(dynamic val) {
      final n = ModelUtils.parseNum(val);
      if (n == null) return null;
      if (n > 100) return n / 1000;
      return n;
    }

    final rawSalt = ModelUtils.parseNum(map['salt']);
    num? saltInGrams;
    if (rawSalt != null) {
      // Safety net: if AI emitted mg sodium/salt (e.g. 600 mg), convert to grams (salt = mg / 400)
      saltInGrams = rawSalt > 50 ? (rawSalt / 400) : rawSalt;
    }

    return NutrientData(
      calories: ModelUtils.parseNum(map['calories']),
      fat: parseGram(map['fat']),
      saturatedFat: parseGram(map['saturatedFat']),
      carbs: parseGram(map['carbs']),
      sugars: parseGram(map['sugars']),
      fiber: parseGram(map['fiber']),
      proteins: parseGram(map['proteins']),
      salt: saltInGrams,
    );
  }
  final num? calories;
  final num? fat;
  final num? saturatedFat;
  final num? carbs;
  final num? sugars;
  final num? fiber;
  final num? proteins;
  final num? salt;

  Map<String, dynamic> toMap() => {'calories': calories, 'fat': fat, 'saturatedFat': saturatedFat, 'carbs': carbs, 'sugars': sugars, 'fiber': fiber, 'proteins': proteins, 'salt': salt};

  @override
  List<Object?> get props => [calories, fat, saturatedFat, carbs, sugars, fiber, proteins, salt];
}

class ImpactDetail extends Equatable {
  const ImpactDetail({required this.title, required this.level, required this.color});

  factory ImpactDetail.fromMap(Map<String, dynamic> map) =>
      ImpactDetail(title: map['title']?.toString() ?? 'Impact', level: map['level']?.toString() ?? 'Neutral', color: map['color']?.toString() ?? 'gold');
  final String title;
  final String level;
  final String color;

  Map<String, dynamic> toMap() => {'title': title, 'level': level, 'color': color};

  @override
  List<Object?> get props => [title, level, color];
}

class Ingredient extends Equatable {
  const Ingredient({required this.name, required this.impact, required this.colorName, this.confidence});

  factory Ingredient.fromMap(Map<String, dynamic> map) => Ingredient(
    name: map['name']?.toString() ?? 'Ingredient',
    impact: map['impact']?.toString() ?? '',
    colorName: map['colorName']?.toString() ?? 'low',
    confidence: ModelUtils.parseNum(map['confidence']),
  );
  final String name;
  final String impact;
  final String colorName;
  final num? confidence;

  Map<String, dynamic> toMap() => {'name': name, 'impact': impact, 'colorName': colorName, if (confidence != null) 'confidence': confidence};

  @override
  List<Object?> get props => [name, impact, colorName, confidence];
}

class CycleInsight extends Equatable {
  const CycleInsight({required this.phase, required this.description, this.tags});

  factory CycleInsight.fromMap(Map<String, dynamic> map) {
    String? clean(dynamic value) {
      final text = value?.toString().trim();
      if (text == null || text.isEmpty || {'string', 'null', 'unknown'}.contains(text.toLowerCase())) return null;
      return text;
    }

    final tags = ModelUtils.parseModelList<CycleTag>(map['tags'], CycleTag.fromMap)
        .where((tag) => tag.text.trim().isNotEmpty && tag.text.toLowerCase() != 'string' && tag.icon.toLowerCase() != 'string' && tag.color.toLowerCase() != 'string')
        .toList();
    return CycleInsight(phase: clean(map['phase']) ?? 'Unknown', description: clean(map['description']) ?? '', tags: tags);
  }
  final String phase;
  final String description;
  final List<CycleTag>? tags;

  Map<String, dynamic> toMap() => {'phase': phase, 'description': description, 'tags': tags?.map((e) => e.toMap()).toList()};

  @override
  List<Object?> get props => [phase, description, tags];
}

class CycleTag extends Equatable {
  const CycleTag({required this.text, required this.icon, required this.color});

  factory CycleTag.fromMap(Map<String, dynamic> map) => CycleTag(text: map['text']?.toString() ?? '', icon: map['icon']?.toString() ?? 'sparkle', color: map['color']?.toString() ?? 'purple');
  final String text;
  final String icon;
  final String color;

  Map<String, dynamic> toMap() => {'text': text, 'icon': icon, 'color': color};

  @override
  List<Object?> get props => [text, icon, color];
}

class ProductSwap extends Equatable {
  const ProductSwap({
    required this.title,
    required this.subtitle,
    required this.imageKeyword,
    this.imageUrl,
    required this.tag,
    this.badge,
    this.isBlackBadge = false,
    this.barcode,
    this.nutriscore,
    this.benefits = const [],
    this.alternative,
  });

  factory ProductSwap.fromMap(Map<String, dynamic> map) {
    final title = (map['title'] ?? map['name'])?.toString() ?? '';
    final rawImageKeyword = map['imageKeyword']?.toString().trim() ?? '';
    final imageKeyword = rawImageKeyword.isEmpty || rawImageKeyword.toLowerCase() == 'string' ? title : rawImageKeyword;
    final rawBenefits = map['benefits'] ?? map['benefitTags'];
    final benefits = rawBenefits is List
        ? rawBenefits.map((value) => value.toString()).toList()
        : map['reason'] != null
        ? [map['reason'].toString()]
        : const <String>[];

    return ProductSwap(
      title: title,
      subtitle: (map['subtitle'] ?? map['reason'] ?? map['whyBetterOption'])?.toString() ?? '',
      imageKeyword: imageKeyword,
      imageUrl: map['imageUrl']?.toString(),
      tag: (map['tag'] ?? map['impactLevel'] ?? (map['benefitTags'] is List && (map['benefitTags'] as List).isNotEmpty ? (map['benefitTags'] as List).first : null))?.toString() ?? 'GOOD OPTION',
      badge: (map['badge'] ?? map['category'])?.toString(),
      isBlackBadge: ModelUtils.parseBool(map['isBlackBadge']),
      // P2-11: absent on legacy docs and LLM-invented swaps; present when the
      // swap round-trips OFF grounding (echoed barcode + grade).
      barcode: map['barcode']?.toString(),
      nutriscore: map['nutriscore']?.toString(),
      benefits: benefits,
      alternative: map.containsKey('name') || map.containsKey('structuredBenefits') || map.containsKey('nutrition') ? SwapAlternative.fromMap(map) : null,
    );
  }
  final String title;
  final String subtitle;
  final String imageKeyword;
  final String? imageUrl;
  final String tag;
  final String? badge;
  final bool isBlackBadge;

  /// OFF barcode when the swap is grounded (enables dedupe, rescore, scan links).
  final String? barcode;

  /// OFF Nutri-Score grade (a-e, lowercase) when the swap is grounded.
  final String? nutriscore;

  final List<String> benefits;

  /// Retains the shared details while older chat cards use the flat fields.
  final SwapAlternative? alternative;

  SwapAlternative toAlternative() =>
      alternative ??
      SwapAlternative(
        foodId: barcode ?? title,
        name: title,
        imageUrl: imageUrl,
        imageKeyword: imageKeyword,
        reason: subtitle,
        tag: tag,
        badge: badge,
        isBlackBadge: isBlackBadge,
        barcode: barcode,
        nutriscore: nutriscore,
        category: badge ?? '',
        benefitTags: benefits,
        whyBetterOption: subtitle,
      );

  Map<String, dynamic> toMap() => {
    ...?alternative?.toMap(),
    'title': title,
    'subtitle': subtitle,
    'imageKeyword': imageKeyword,
    'imageUrl': imageUrl,
    'tag': tag,
    'badge': badge,
    'isBlackBadge': isBlackBadge ? 1 : 0,
    'barcode': barcode,
    'nutriscore': nutriscore,
    'benefits': benefits,
  };

  @override
  List<Object?> get props => [title, subtitle, tag, badge, imageUrl, barcode, nutriscore, benefits, alternative];
}
