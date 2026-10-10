import 'package:gutgood/core/data/additive_concern_db.dart';
import 'package:gutgood/core/models/scans/scan_result.dart';
import 'package:gutgood/core/utils/model_utils.dart';
import 'package:gutgood/core/utils/yuka_score.dart';

/// Optional diagnostic sink supplied by the infrastructure caller.
///
/// Scoring remains deterministic and free of logging dependencies; the
/// repository can continue sending the same diagnostics to `AppLogger`.
typedef ScannerDiagnosticLogger = void Function(Object? message);

/// Applies the deterministic scanner score and sensitivity overlays.
///
/// This is deliberately separate from [ScannerRepositoryImpl]'s orchestration
/// of Open Food Facts, AI, Firestore, analytics, and persistence. It has no
/// network, Firebase, Flutter, or storage dependencies and can be tested with
/// plain scan fixtures.
class ScannerScoreService {
  const ScannerScoreService();

  /// Adds current sensitivity matches without removing the model's existing
  /// flags. Union semantics preserve warnings the model may have inferred
  /// through synonyms while allowing newly configured sensitivities to appear
  /// on a cached scan.
  List<String> reflagWithSensitivities(ScanResult scan, List<String> sensitivities) {
    final flags = <String>{...scan.flaggedIngredients};
    if (sensitivities.isEmpty) return flags.toList();

    final haystacks = [
      ...scan.ingredients.map((ingredient) => ingredient.name),
      ...scan.additiveItems,
      if (scan.allergens != null) scan.allergens!,
    ].map((value) => value.toLowerCase()).toList();

    for (final term in sensitivities) {
      final needle = term.toLowerCase().trim();
      if (needle.isEmpty) continue;
      if (haystacks.any((haystack) => haystack.contains(needle))) {
        flags.add(term);
      }
    }
    return flags.toList();
  }

  /// Runs the deterministic scoring engine and attaches an engine-authored
  /// score and explanation to the scan's insight.
  ///
  /// Product requirement §7 asks for `Data → Scoring Engine → Score → AI
  /// Explanation` rather than `Data → LLM → arbitrary score`. The model
  /// supplies structured inputs; it never authors the number, and the
  /// explanation is composed from the engine's signed factors.
  ///
  /// When trusted [nutriscore], [novaGroup], or nutrient values are supplied,
  /// they take precedence over values already present on [scan].
  ScanResult applyEngineScore(
    ScanResult scan, {
    String? nutriscore,
    int? nutriscoreScore,
    int? novaGroup,
    num? energyKcal,
    num? fiberG,
    num? proteinG,
    num? sugarG,
    num? saltG,
    num? saturatedFatG,
    List<String>? additiveItems,
    bool? isOrganic,
    bool deferToModelWhenNoData = false,
    bool refreshExplanation = false,
    List<String>? miscTags,
    ScannerDiagnosticLogger? onDiagnostic,
  }) {
    final resolvedAdditives = <String>{...?additiveItems, ...scan.additiveItems};
    final additiveConcerns = AdditiveConcernDb.resolveAll(resolvedAdditives);
    final resolvedEnergy = energyKcal ?? scan.nutrients?.calories;
    final resolvedSugar = sugarG ?? scan.nutrients?.sugars;

    final breakdown = YukaScore.evaluate(
      nutriscore: nutriscore ?? scan.nutriscore,
      nutriscoreScore: nutriscoreScore ?? scan.nutriscoreScore,
      energyKcal: energyKcal ?? scan.nutrients?.calories,
      fiberG: fiberG ?? scan.nutrients?.fiber,
      proteinG: proteinG ?? scan.nutrients?.proteins,
      sugarG: sugarG ?? scan.nutrients?.sugars,
      saltG: saltG ?? scan.nutrients?.salt,
      saturatedFatG: saturatedFatG ?? scan.nutrients?.saturatedFat,
      additiveConcerns: additiveConcerns,
      isOrganic: isOrganic ?? scan.isOrganic,
      novaGroup: novaGroup ?? int.tryParse(scan.novaGroup ?? ''),
      isBeverage: YukaScore.isBeverageCategory(scan.category),
      isWater: YukaScore.isPlainWater(productName: scan.productName, category: scan.category, energyKcal: resolvedEnergy, sugarG: resolvedSugar),
    );

    // Photo scans may have a useful model score even when no numeric engine
    // inputs are available. Preserve that score rather than making every such
    // scan appear neutral.
    if (!breakdown.hasData && deferToModelWhenNoData) {
      onDiagnostic?.call('ScannerRepository: engine had no usable inputs — keeping model score ${scan.score}');
      return scan.copyWith(impact: 'Provisional visual score: there is not enough nutrition data to explain exact point deductions.');
    }

    // No signal at all and no model score to defer to: stay neutral, but keep
    // the existing explanation/fallback reason so the UI can explain why.
    if (!breakdown.hasData) {
      final reason = ModelUtils.unscorableReason(miscTags);
      return scan.copyWith(score: 50, impact: reason ?? scan.impact);
    }

    final score = breakdown.score;
    onDiagnostic?.call('ScannerRepository: engine score $score (nutrition ${breakdown.nutritionSubscore}, additives ${breakdown.additiveSubscore}, organic ${breakdown.organicSubscore})');

    return scan.copyWith(score: score, impact: refreshExplanation || scan.impact.isEmpty ? breakdown.explanation : scan.impact);
  }
}
