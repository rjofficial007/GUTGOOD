library;

import 'dart:math' as math;

import 'package:gutgood/core/data/additive_concern_db.dart';
import 'package:gutgood/core/utils/model_utils.dart';

/// Product scoring built on the method Yuka publishes openly.
///
/// Source: https://help.yuka.io/l/en/article/ijzgfvi1jq-how-are-food-products-scored
///
///   * **60% nutritional quality** — derived from Nutri-Score.
///   * **30% additives** — by risk level.
///   * **10% organic dimension** — a bonus for certified-organic products.
///   * **Any high-risk additive caps the final score at 49/100**, however good
///     the nutrition is.
///
/// Two things are worth being precise about, because they are easy to
/// misrepresent:
///
/// 1. **The weights (60/30/10) and the 49 cap are Yuka's, published.**
/// 2. **The intra-grade curve is ours.** Yuka publishes a correspondence table
///    that smooths Nutri-Score into a score out of 100 (27 steps, solids and
///    liquids separately), but only as an image. We reproduce the published
///    *band edges* (A: 100–75, B: 75–55, C: 55–35, D: 35–10, E: 10–0) and
///    interpolate *within* a band using the underlying Nutri-Score points.
///    That delivers Yuka's stated goal — "avoid threshold effects that could
///    lead to significant rating differences between two products with similar
///    nutritional values" — but it will not match Yuka to the decimal.
///
/// The Nutri-Score points themselves are computed with the **original**
/// Nutri-Score algorithm (the one Yuka states it uses), so where a product has
/// no Nutri-Score on the label we can still derive one from its nutrients
/// instead of guessing.
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

/// The full, explainable result of a Yuka-style evaluation.
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
    this.scoreBeforeCap,
    this.nutriScorePoints = const {},
  });

  /// False when we had nothing to score — callers should then keep whatever
  /// score the model produced rather than inventing a neutral number.
  final bool hasData;

  /// Final score, 0–100, already capped for high-risk additives.
  final int score;

  /// Score before the high-risk additive cap, when the cap actually bit.
  final int? scoreBeforeCap;

  final int nutritionSubscore;
  final int additiveSubscore;
  final int processingSubscore;

  /// Alias for backward compatibility.
  int get organicSubscore => processingSubscore;

  final NutriScoreGrade? grade;
  final bool gradeEstimated;

  /// Breakdown of Nutri-Score points (the logic inputs).
  final Map<String, int> nutriScorePoints;

  /// Contributions that sum to [score] (except when the cap applied, in which
  /// case the cap factor is the difference).
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
/// - Any high-risk additive caps the final score at 49/100.
class YukaScore {
  YukaScore._();

  /// Component weights (percent of the final score).
  static const int nutritionWeight = 60;
  static const int additiveWeight = 30;
  static const int processingWeight = 10;
  static const int organicWeight = 10; // Alias for backward compatibility

  /// Published ceiling for any product containing a high-risk additive.
  static const int highRiskCap = 49;

  /// Additive penalties, per Yuka's risk bands. Each band is capped so a long
  /// ingredient list cannot run away with the score — Yuka penalises by risk,
  /// not by count, and so do we.
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
    if (concerns.isEmpty) return 100;

    var low = 0;
    var moderate = 0;
    var high = 0;
    for (final c in concerns) {
      switch (c.level) {
        case AdditiveConcernLevel.low:
        case AdditiveConcernLevel.unknown:
          low++;
        case AdditiveConcernLevel.moderate:
          moderate++;
        case AdditiveConcernLevel.higher:
          high++;
      }
    }

    final penalty = math.min(low * _lowPenalty, _lowBandCap) + math.min(moderate * _moderatePenalty, _moderateBandCap) + math.min(high * _highPenalty, _highBandCap);

    return (100 - penalty).clamp(0, 100).toInt();
  }

  static bool _isHighRisk(AdditiveConcern c) => c.level == AdditiveConcernLevel.higher;

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
  }) {
    final concerns = additiveConcerns ?? const <AdditiveConcern>[];
    final organic = isOrganic ?? false;

    // --- nutrition ---------------------------------------------------------
    NutriScoreGrade? grade;
    double? points;
    var estimated = false;
    var componentPoints = <String, int>{};

    if (nutriscoreScore != null) {
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

    var score = (nutritionPts + additivePts + processingPts).clamp(0, 100);
    int? beforeCap;

    final hasHighRisk = concerns.any(_isHighRisk);
    if (hasHighRisk && score > highRiskCap) {
      beforeCap = score;
      score = highRiskCap;
    }

    // --- factors (contributions; they sum to the score) --------------------
    final factors = <ScoreFactor>[
      ScoreFactor(
        label: hasNutrition
            ? 'Nutrition · Nutri-Score ${grade.letter}${estimated ? ' (estimated)' : ''} · $nutritionPts/$nutritionWeight'
            : 'Nutrition · not enough data · $nutritionPts/$nutritionWeight',
        delta: nutritionPts,
        phrase: hasNutrition ? 'a Nutri-Score of ${grade.letter}' : 'incomplete nutrition data',
      ),
      ScoreFactor(
        label: 'Additives · ${_additiveSummary(concerns)} · $additivePts/$additiveWeight',
        delta: additivePts,
        phrase: concerns.isEmpty ? 'no additives detected' : _additivePhrase(concerns),
      ),
      ScoreFactor(
        label: 'Processing & Ingredients · ${_processingSummary(novaGroup, organic)} · $processingPts/$processingWeight',
        delta: processingPts,
        phrase: _processingPhrase(novaGroup, organic),
      ),
    ];

    if (beforeCap != null) {
      factors.add(ScoreFactor(label: 'High-concern additive cap · max $highRiskCap', delta: highRiskCap - beforeCap, phrase: 'a high-concern additive, which caps the score at $highRiskCap'));
    }

    return YukaScoreBreakdown(
      hasData: true,
      score: score,
      scoreBeforeCap: beforeCap,
      nutritionSubscore: nutrition,
      additiveSubscore: additive,
      processingSubscore: processing,
      grade: grade,
      gradeEstimated: estimated,
      nutriScorePoints: componentPoints,
      factors: factors,
      explanation: _explain(score, nutritionPts, additivePts, processingPts, grade, estimated, beforeCap, concerns, novaGroup, organic),
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
    var low = 0;
    var moderate = 0;
    var high = 0;
    for (final c in concerns) {
      switch (c.level) {
        case AdditiveConcernLevel.low:
        case AdditiveConcernLevel.unknown:
          low++;
        case AdditiveConcernLevel.moderate:
          moderate++;
        case AdditiveConcernLevel.higher:
          high++;
      }
    }
    final parts = <String>[];
    if (high > 0) parts.add('$high high concern');
    if (moderate > 0) parts.add('$moderate moderate');
    if (low > 0) parts.add('$low low');
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
    int? beforeCap,
    List<AdditiveConcern> concerns,
    int? novaGroup,
    bool organic,
  ) {
    final buffer = StringBuffer('Score $score out of 100 — ')
      ..write(
        grade != null
            ? 'nutrition $nutritionPts/$nutritionWeight (Nutri-Score ${grade.letter}${estimated ? ', estimated from its nutrients' : ''})'
            : 'nutrition $nutritionPts/$nutritionWeight (incomplete data)',
      )
      ..write(', additives $additivePts/$additiveWeight')
      ..write(' and processing & ingredients $processingPts/$processingWeight (${_processingSummary(novaGroup, organic)}).');

    if (beforeCap != null) {
      final names = concerns.where(_isHighRisk).map((c) => c.code.isNotEmpty ? c.code : c.name).take(2).join(', ');
      buffer.write(' It would have scored $beforeCap, but $names ${concerns.where(_isHighRisk).length == 1 ? 'is' : 'are'} classed high-concern, which caps any product at $highRiskCap.');
    }
    return buffer.toString();
  }
}
