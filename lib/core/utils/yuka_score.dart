library;

import 'dart:math' as math;

import 'package:gutgood/core/data/additive_concern_db.dart';
import 'package:gutgood/core/utils/model_utils.dart';

/// GutGood packaged-food score, using 60% nutrition, 30% additive concern, and
/// 10% processing / ingredient quality. Yuka's published approach is a QA
/// reference; the scoring rules and deductions here are GutGood's.
/// Nutri-Score letter grades, best (A) to worst (E).
enum NutriScoreGrade { a, b, c, d, e }

extension NutriScoreGradeX on NutriScoreGrade {
  String get letter => name.toUpperCase();

  static NutriScoreGrade? parse(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'a':
        return NutriScoreGrade.a;
      case 'b':
        return NutriScoreGrade.b;
      case 'c':
        return NutriScoreGrade.c;
      case 'd':
        return NutriScoreGrade.d;
      case 'e':
        return NutriScoreGrade.e;
      default:
        return null;
    }
  }
}

/// Outcome of a Nutri-Score computation.
class NutriScoreResult {
  const NutriScoreResult({required this.points, required this.grade, this.estimated = false, this.componentPoints = const {}});

  /// The raw nutritional score. Lower is better; roughly -15 (best) to 40.
  final int points;
  final NutriScoreGrade grade;

  /// True when we computed points from nutrients because no grade was supplied.
  final bool estimated;

  /// Breakdown of points per nutrient (e.g. {'energy': 1, 'sugar': 2}).
  final Map<String, int> componentPoints;
}

/// The full, explainable result of a GutGood evaluation.
class YukaScoreBreakdown {
  const YukaScoreBreakdown({
    required this.hasData,
    required this.score,
    required this.nutritionSubscore,
    required this.additiveSubscore,
    required this.processingSubscore,
    required this.factors,
    required this.explanation,
    this.grade,
    this.gradeEstimated = false,
    this.nutriScorePoints = const {},
  });

  /// False when we had nothing to score — callers should then keep whatever
  /// score the model produced rather than inventing a neutral number.
  final bool hasData;

  /// Final score, 0–100.
  final int score;

  final int nutritionSubscore;
  final int additiveSubscore;
  final int processingSubscore;

  /// Alias for backward compatibility.
  int get organicSubscore => processingSubscore;

  final NutriScoreGrade? grade;
  final bool gradeEstimated;

  /// Breakdown of Nutri-Score points (the logic inputs).
  final Map<String, int> nutriScorePoints;

  /// Contributions that sum to [score].
  final List<ScoreFactor> factors;

  /// Engine-authored "why this score", in plain language.
  final String explanation;
}

class _Band {
  const _Band({required this.minPts, required this.maxPts, required this.top, required this.bottom});

  final double minPts;
  final double maxPts;

  /// Score out of 100 at the best end of the band.
  final double top;

  /// Score out of 100 at the worst end of the band.
  final double bottom;
}

/// GutGood food scoring engine.
///
/// Component weights:
/// - **60% Nutritional Quality** — derived from Nutri-Score.
/// - **30% Additive Quality / Risk** — by risk level.
/// - **10% Ingredient & Processing Quality** — derived from NOVA group & organic certification.
class YukaScore {
  YukaScore._();

  /// Component weights (percent of the final score).
  static const int nutritionWeight = 60;
  static const int additiveWeight = 30;
  static const int processingWeight = 10;
  static const int organicWeight = 10; // Alias for backward compatibility

  /// Additive penalties by concern level. Each band is capped so a long
  /// ingredient list cannot run away with the score.
  static const int _lowPenalty = 2;
  static const int _lowBandCap = 6;
  static const int _moderatePenalty = 10;
  static const int _moderateBandCap = 40;
  static const int _highPenalty = 25;
  static const int _highBandCap = 60;

  /// Nutri-Score → score-out-of-100 bands, as published by Yuka.
  static const Map<NutriScoreGrade, _Band> _bands = {
    NutriScoreGrade.a: _Band(minPts: -15, maxPts: -1, top: 100, bottom: 75),
    NutriScoreGrade.b: _Band(minPts: 0, maxPts: 2, top: 75, bottom: 55),
    NutriScoreGrade.c: _Band(minPts: 3, maxPts: 10, top: 55, bottom: 35),
    NutriScoreGrade.d: _Band(minPts: 11, maxPts: 18, top: 35, bottom: 10),
    NutriScoreGrade.e: _Band(minPts: 19, maxPts: 40, top: 10, bottom: 0),
  };

  /// Midpoint used when only the letter is known (no points available).
  static const Map<NutriScoreGrade, double> _gradeRepresentativePoints = {NutriScoreGrade.a: -8, NutriScoreGrade.b: 1, NutriScoreGrade.c: 6.5, NutriScoreGrade.d: 14.5, NutriScoreGrade.e: 29.5};

  // ---------------------------------------------------------------------------
  // Nutri-Score (original algorithm — the one Yuka states it uses)
  // ---------------------------------------------------------------------------

  /// Unfavourable-component thresholds. `points` = how many thresholds the
  /// value exceeds (0–10).
  static const List<num> _energyKj = [335, 670, 1005, 1340, 1675, 2010, 2345, 2680, 3015, 3350];
  static const List<num> _sugarsG = [4.5, 9, 13.5, 18, 22.5, 27, 31, 36, 40, 45];
  static const List<num> _satFatG = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
  static const List<num> _sodiumMg = [90, 180, 270, 360, 450, 540, 630, 720, 810, 900];

  /// Fibre (g/100g) thresholds for 1–5 favourable points.
  static const List<num> _fiberG = [0.9, 1.9, 2.8, 3.7, 4.7];

  /// Protein (g/100g) thresholds for 1–5 favourable points.
  static const List<num> _proteinG = [1.6, 3.2, 4.8, 6.4, 8.0];

  static int _pointsAbove(num value, List<num> thresholds) {
    var points = 0;
    for (final t in thresholds) {
      if (value > t) points++;
    }
    return points;
  }

  /// Fruit/vegetable/pulse/nut content: 0 ≤40%, 1 >40%, 2 >60%, 5 >80%.
  static int _fruitVegPoints(num pct) {
    if (pct > 80) return 5;
    if (pct > 60) return 2;
    if (pct > 40) return 1;
    return 0;
  }

  /// Grade from nutritional score points.
  ///
  /// Solid foods: A ≤ -1, B 0–2, C 3–10, D 11–18, E ≥ 19.
  /// Beverages: B ≤ 1, C 2–5, D 6–9, E ≥ 10 (water is A).
  static NutriScoreGrade gradeFromPoints(int points, {bool isBeverage = false}) {
    if (!isBeverage) {
      if (points <= -1) return NutriScoreGrade.a;
      if (points <= 2) return NutriScoreGrade.b;
      if (points <= 10) return NutriScoreGrade.c;
      if (points <= 18) return NutriScoreGrade.d;
      return NutriScoreGrade.e;
    }
    if (points <= 1) return NutriScoreGrade.b;
    if (points <= 5) return NutriScoreGrade.c;
    if (points <= 9) return NutriScoreGrade.d;
    return NutriScoreGrade.e;
  }

  /// Computes the Nutri-Score from nutrients using the original algorithm.
  ///
  /// Returns null when the four unfavourable values (energy, sugars, saturated
  /// fat, sodium) aren't all available — a Nutri-Score built on two thirds of
  /// its inputs would be worse than none.
  static NutriScoreResult? computeNutriScore({
    required num? energyKj,
    required num? sugarsG,
    required num? saturatedFatG,
    required num? sodiumMg,
    num? fiberG,
    num? proteinG,
    num? fruitVegPct,
    bool isBeverage = false,
  }) {
    if (energyKj == null || sugarsG == null || saturatedFatG == null || sodiumMg == null) return null;

    final pEnergy = _pointsAbove(energyKj, _energyKj);
    final pSugar = _pointsAbove(sugarsG, _sugarsG);
    final pSatFat = _pointsAbove(saturatedFatG, _satFatG);
    final pSodium = _pointsAbove(sodiumMg, _sodiumMg);

    final n = pEnergy + pSugar + pSatFat + pSodium;

    final pFiber = _pointsAbove(fiberG ?? 0, _fiberG);
    final pProtein = _pointsAbove(proteinG ?? 0, _proteinG);
    final pFv = _fruitVegPoints(fruitVegPct ?? 0);

    // Original algorithm: once the unfavourable component reaches 11, protein
    // stops counting (the fibre and fruit/veg points still do).
    final points = n < 11 ? n - (pFiber + pProtein + pFv) : n - (pFiber + pFv);

    return NutriScoreResult(
      points: points,
      grade: gradeFromPoints(points, isBeverage: isBeverage),
      estimated: true,
      componentPoints: {'energy': pEnergy, 'sugar': pSugar, 'saturatedFat': pSatFat, 'sodium': pSodium, 'fiber': -pFiber, 'protein': (n < 11) ? -pProtein : 0, 'fruitVeg': -pFv},
    );
  }

  // ---------------------------------------------------------------------------
  // Evaluation
  // ---------------------------------------------------------------------------

  /// Converts nutritional score points into the 0–100 nutrition sub-score,
  /// interpolating within the published band for its grade.
  static int nutritionSubscore(NutriScoreGrade grade, double points) {
    final band = _bands[grade]!;
    final span = band.maxPts - band.minPts;
    final t = span <= 0 ? 0.0 : ((points - band.minPts) / span).clamp(0.0, 1.0);
    return (band.top + t * (band.bottom - band.top)).round().clamp(0, 100);
  }

  static int additiveSubscore(List<AdditiveConcern> concerns) {
    var low = 0;
    var moderate = 0;
    var high = 0;
    for (final c in concerns) {
      switch (c.level) {
        case AdditiveConcernLevel.low:
          low++;
        case AdditiveConcernLevel.unknown:
          // Missing evidence is not evidence of risk; unknown additives are
          // reported but do not reduce the score until they can be assessed.
          break;
        case AdditiveConcernLevel.moderate:
          moderate++;
        case AdditiveConcernLevel.higher:
          high++;
      }
    }

    final penalty = math.min(low * _lowPenalty, _lowBandCap) + math.min(moderate * _moderatePenalty, _moderateBandCap) + math.min(high * _highPenalty, _highBandCap);

    return (100 - penalty).clamp(0, 100).toInt();
  }

  static bool isBeverageCategory(String? category) {
    final value = category?.toLowerCase().replaceAll('_', '-');
    return value != null && RegExp('beverage|drink|water|juice|soda|soft-drink|tea|coffee').hasMatch(value);
  }

  /// Avoid treating zero-calorie soft drinks as water: require a water product
  /// name/category and zero energy/sugar, both of which come from the label.
  static bool isPlainWater({required String? productName, required String? category, required num? energyKcal, required num? sugarG}) {
    final water = '${productName ?? ''} ${category ?? ''}'.toLowerCase();
    return RegExp(r'\b(water|waters)\b').hasMatch(water) && energyKcal == 0 && sugarG == 0;
  }

  /// Label fragments that indicate an official organic certification.
  ///
  /// Yuka awards the 10% for "an official national or international organic
  /// label", so we look for recognised certifications rather than any use of
  /// the word "bio" in marketing text.
  static const List<String> _organicLabelFragments = [
    'organic',
    'ab-agriculture-biologique',
    'agriculture-biologique',
    'bio-européen',
    'bio-europeen',
    'eu-bio',
    'ökologischer-landbau',
    'okologischer-landbau',
    'bioland',
    'naturland',
    'demeter',
    'ecocert',
    'usda-organic',
    'canada-organic',
    'japan-organic',
    'soil-association',
    'krav',
  ];

  /// True when the product's labels include a recognised organic certification.
  static bool detectOrganic(List<String>? labels) {
    if (labels == null || labels.isEmpty) return false;
    for (final raw in labels) {
      final label = raw.toLowerCase().replaceAll('en:', '').replaceAll('_', '-');
      for (final fragment in _organicLabelFragments) {
        if (label.contains(fragment)) return true;
      }
    }
    return false;
  }

  /// Evaluates 0–100 Ingredient & Processing Quality subscore based on
  /// NOVA processing group (1 = Unprocessed, 2 = Culinary, 3 = Processed, 4 = Ultra-processed)
  /// and organic certification.
  static int processingSubscore(int? novaGroup, bool isOrganic) {
    var score = 50; // Neutral default if NOVA processing classification is unknown

    if (novaGroup != null) {
      switch (novaGroup) {
        case 1:
          score = 100; // Unprocessed / minimally processed whole foods
        case 2:
          score = 80; // Processed culinary ingredients
        case 3:
          score = 50; // Processed foods
        case 4:
          score = 0; // Ultra-processed foods
        default:
          score = 50;
      }
    }

    // Organic certification bonus (+15 subscore pts, capped at 100)
    if (isOrganic) {
      score = (score + 15).clamp(0, 100);
    }

    return score;
  }

  /// Scores a product.
  ///
  /// Supply [nutriscoreScore] (raw points) or [nutriscore] (letter) when a
  /// trusted source has it; otherwise the grade is computed from the nutrients.
  static YukaScoreBreakdown evaluate({
    String? nutriscore,
    int? nutriscoreScore,
    num? energyKcal,
    num? fiberG,
    num? proteinG,
    num? sugarG,
    num? saltG,
    num? saturatedFatG,
    num? fruitVegPct,
    List<AdditiveConcern>? additiveConcerns,
    bool? isOrganic,
    int? novaGroup,
    bool isBeverage = false,
    bool isWater = false,
  }) {
    final concerns = additiveConcerns ?? const <AdditiveConcern>[];
    final organic = isOrganic ?? false;

    // --- nutrition ---------------------------------------------------------
    NutriScoreGrade? grade;
    double? points;
    var estimated = false;
    var componentPoints = <String, int>{};

    if (isWater) {
      // Plain water is the beverage Nutri-Score A exception.
      grade = NutriScoreGrade.a;
      points = -15;
    } else if (nutriscoreScore != null) {
      points = nutriscoreScore.toDouble();
      grade = gradeFromPoints(nutriscoreScore, isBeverage: isBeverage);
    }

    grade ??= NutriScoreGradeX.parse(nutriscore);
    if (grade != null) {
      points ??= _gradeRepresentativePoints[grade]!;
    } else {
      final computed = computeNutriScore(
        energyKj: energyKcal == null ? null : energyKcal * 4.184,
        sugarsG: sugarG,
        saturatedFatG: saturatedFatG,
        // Salt (g) → sodium (mg): sodium = salt / 2.5.
        sodiumMg: saltG == null ? null : saltG * 400,
        fiberG: fiberG,
        proteinG: proteinG,
        fruitVegPct: fruitVegPct,
        isBeverage: isBeverage,
      );
      if (computed != null) {
        grade = computed.grade;
        points = computed.points.toDouble();
        estimated = true;
        componentPoints = computed.componentPoints;
      }
    }

    final hasNutrition = grade != null && points != null;
    if (!hasNutrition && concerns.isEmpty && novaGroup == null && !organic) {
      return const YukaScoreBreakdown(hasData: false, score: 0, nutritionSubscore: 0, additiveSubscore: 0, processingSubscore: 0, factors: [], explanation: '');
    }

    final nutrition = hasNutrition ? nutritionSubscore(grade, points) : 50; // no signal → neutral
    final additive = additiveSubscore(concerns);
    final processing = processingSubscore(novaGroup, organic);

    final nutritionPts = (nutrition * nutritionWeight / 100).round();
    final additivePts = (additive * additiveWeight / 100).round();
    final processingPts = (processing * processingWeight / 100).round();

    final score = (nutritionPts + additivePts + processingPts).clamp(0, 100);

    // --- factors (contributions; they sum to the score) --------------------
    final factors = <ScoreFactor>[
      ScoreFactor(
        label: isWater
            ? 'Nutrition · Plain water, zero calories & sugar · $nutritionPts/$nutritionWeight (0 lost)'
            : hasNutrition
            ? 'Nutrition · Nutri-Score ${grade.letter}${estimated ? ' (estimated: ${_nutrientPointSummary(componentPoints)})' : ''} · $nutritionPts/$nutritionWeight (${nutritionWeight - nutritionPts} lost)'
            : 'Nutrition · not enough data · neutral $nutritionPts/$nutritionWeight',
        delta: nutritionPts,
        phrase: isWater ? 'plain water with zero calories and sugar' : hasNutrition ? 'a Nutri-Score of ${grade.letter}' : 'incomplete nutrition data',
      ),
      ScoreFactor(
        label: 'Additives · ${_additiveSummary(concerns)} · $additivePts/$additiveWeight (${additiveWeight - additivePts} lost)',
        delta: additivePts,
        phrase: concerns.isEmpty ? 'no additives detected' : _additivePhrase(concerns),
      ),
      ScoreFactor(
        label: novaGroup == null && !organic
            ? 'Processing & Ingredients · NOVA not available · neutral $processingPts/$processingWeight'
            : 'Processing & Ingredients · ${_processingSummary(novaGroup, organic)} · $processingPts/$processingWeight (${processingWeight - processingPts} lost)',
        delta: processingPts,
        phrase: _processingPhrase(novaGroup, organic),
      ),
    ];

    return YukaScoreBreakdown(
      hasData: true,
      score: score,
      nutritionSubscore: nutrition,
      additiveSubscore: additive,
      processingSubscore: processing,
      grade: grade,
      gradeEstimated: estimated,
      nutriScorePoints: componentPoints,
      factors: factors,
      explanation: _explain(score, nutritionPts, additivePts, processingPts, grade, estimated, novaGroup, organic, isWater),
    );
  }

  static String _processingSummary(int? novaGroup, bool organic) {
    final parts = <String>[];
    if (novaGroup != null) {
      parts.add(switch (novaGroup) {
        1 => 'Unprocessed',
        2 => 'Culinary',
        3 => 'Processed',
        4 => 'Ultra-processed',
        _ => 'NOVA $novaGroup',
      });
    } else {
      parts.add('Standard processing');
    }
    if (organic) parts.add('Organic');
    return parts.join(' · ');
  }

  static String _nutrientPointSummary(Map<String, int> points) => points.entries.where((entry) => entry.value != 0).map((entry) => '${entry.key} ${entry.value > 0 ? '+' : ''}${entry.value}').join(', ');

  static String _processingPhrase(int? novaGroup, bool organic) {
    if (novaGroup == 1) {
      return organic ? 'unprocessed organic ingredients' : 'unprocessed whole ingredients';
    } else if (novaGroup == 4) {
      return organic ? 'ultra-processed organic food' : 'ultra-processed food';
    } else {
      return organic ? 'processed organic ingredients' : 'ingredient processing quality';
    }
  }

  static String _additiveSummary(List<AdditiveConcern> concerns) {
    if (concerns.isEmpty) return 'none detected';
    String namesFor(AdditiveConcernLevel level) {
      final items = concerns.where((c) => c.level == level).toList();
      final names = items.take(3).map((c) => c.code.isNotEmpty ? c.code : c.name).join(', ');
      return names.isEmpty ? '' : ': $names${items.length > 3 ? ', +${items.length - 3} more' : ''}';
    }
    var low = 0;
    var moderate = 0;
    var high = 0;
    for (final c in concerns) {
      switch (c.level) {
        case AdditiveConcernLevel.low:
          low++;
        case AdditiveConcernLevel.unknown:
          break;
        case AdditiveConcernLevel.moderate:
          moderate++;
        case AdditiveConcernLevel.higher:
          high++;
      }
    }
    final parts = <String>[];
    if (high > 0) parts.add('$high high concern${namesFor(AdditiveConcernLevel.higher)}');
    if (moderate > 0) parts.add('$moderate moderate${namesFor(AdditiveConcernLevel.moderate)}');
    if (low > 0) parts.add('$low low${namesFor(AdditiveConcernLevel.low)}');
    final unknown = concerns.where((c) => c.level == AdditiveConcernLevel.unknown).length;
    if (unknown > 0) parts.add('$unknown unknown${namesFor(AdditiveConcernLevel.unknown)} (no deduction)');
    return parts.join(', ');
  }

  static String _additivePhrase(List<AdditiveConcern> concerns) {
    if (concerns.length == 1) return '1 flagged additive';
    return '${concerns.length} flagged additives';
  }

  static String _explain(
    int score,
    int nutritionPts,
    int additivePts,
    int processingPts,
    NutriScoreGrade? grade,
    bool estimated,
    int? novaGroup,
    bool organic,
    bool isWater,
  ) {
    final buffer = StringBuffer('Score $score out of 100 — ')
      ..write(
        isWater
            ? 'nutrition $nutritionPts/$nutritionWeight (plain water: zero calories and sugar)'
            : grade != null
            ? 'nutrition $nutritionPts/$nutritionWeight (Nutri-Score ${grade.letter}${estimated ? ', estimated from its nutrients' : ''})'
            : 'nutrition $nutritionPts/$nutritionWeight (incomplete data)',
      )
      ..write(', additives $additivePts/$additiveWeight')
      ..write(' and processing & ingredients $processingPts/$processingWeight (${_processingSummary(novaGroup, organic)}).');

    return buffer.toString();
  }
}
