import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/data/additive_concern_db.dart';
import 'package:gutgood/core/utils/yuka_score.dart';

/// Helper: build an additive concern at a given level.
AdditiveConcern concern(AdditiveConcernLevel level) => AdditiveConcern(code: 'E999', name: 'Test additive', whatItIs: 'test', whyUsed: 'test', level: level, whyFlagged: 'test', explanation: 'test');

void main() {
  group('Nutri-Score (original algorithm, as published by Yuka)', () {
    test('grade thresholds for solid foods', () {
      expect(YukaScore.gradeFromPoints(-5), NutriScoreGrade.a);
      expect(YukaScore.gradeFromPoints(-1), NutriScoreGrade.a);
      expect(YukaScore.gradeFromPoints(0), NutriScoreGrade.b);
      expect(YukaScore.gradeFromPoints(2), NutriScoreGrade.b);
      expect(YukaScore.gradeFromPoints(3), NutriScoreGrade.c);
      expect(YukaScore.gradeFromPoints(10), NutriScoreGrade.c);
      expect(YukaScore.gradeFromPoints(11), NutriScoreGrade.d);
      expect(YukaScore.gradeFromPoints(18), NutriScoreGrade.d);
      expect(YukaScore.gradeFromPoints(19), NutriScoreGrade.e);
    });

    test('a product with no unfavourable nutrients scores best-grade A', () {
      final result = YukaScore.computeNutriScore(energyKj: 100, sugarsG: 0, saturatedFatG: 0, sodiumMg: 0, fiberG: 5, proteinG: 10, fruitVegPct: 90);

      expect(result, isNotNull);
      // N = 0, P = 5 (fibre) + 5 (protein) + 5 (fruit/veg) = 15 → 0 - 15 = -15
      expect(result!.points, -15);
      expect(result.grade, NutriScoreGrade.a);
    });

    test('protein stops counting once the unfavourable component reaches 11', () {
      // High sugars alone push N to 11.
      final n11 = YukaScore.computeNutriScore(
        energyKj: 100,
        sugarsG: 50, // > 45 → 10 points
        saturatedFatG: 2, // > 1 → 1 point
        sodiumMg: 0,
        fiberG: 0,
        proteinG: 10, // would be 5 points if counted
        fruitVegPct: 0,
      );

      expect(n11, isNotNull);
      expect(n11!.points, 11, reason: 'N = 11 and no favourable points apply, so protein must be dropped.');

      final n10 = YukaScore.computeNutriScore(
        energyKj: 100,
        sugarsG: 50, // 10 points
        saturatedFatG: 0,
        sodiumMg: 0,
        fiberG: 0,
        proteinG: 10, // 5 points, counted because N < 11
        fruitVegPct: 0,
      );
      expect(n10!.points, 5, reason: 'N = 10, so protein points are subtracted: 10 - 5 = 5.');
    });

    test('returns null when the unfavourable values are incomplete', () {
      expect(YukaScore.computeNutriScore(energyKj: 100, sugarsG: 1, saturatedFatG: 1, sodiumMg: null), isNull, reason: 'A Nutri-Score built on partial inputs would be worse than none.');
    });
  });

  group('Yuka-style composition', () {
    test('components are weighted 60 / 30 / 10', () {
      final breakdown = YukaScore.evaluate(nutriscore: 'a', additiveConcerns: const [], isOrganic: true, novaGroup: 1);

      expect(breakdown.hasData, isTrue);
      // Nutrition (Nutri-Score A) ≈ 88/100 → 53 of 60
      expect(breakdown.factors.first.delta, 53);
      // No additives → full 30
      expect(breakdown.factors[1].delta, 30);
      // Processing & Ingredients (NOVA 1 + Organic) → full 10
      expect(breakdown.factors[2].delta, 10);
      expect(breakdown.score, 93);
    });

    test('processing and ingredient quality respects NOVA group and organic bonus', () {
      final unprocessedOrganic = YukaScore.evaluate(nutriscore: 'c', additiveConcerns: const [], isOrganic: true, novaGroup: 1);
      final ultraProcessedNonOrganic = YukaScore.evaluate(nutriscore: 'c', additiveConcerns: const [], isOrganic: false, novaGroup: 4);

      expect(unprocessedOrganic.score, greaterThan(ultraProcessedNonOrganic.score));
      expect(unprocessedOrganic.factors[2].delta, 10);
      expect(ultraProcessedNonOrganic.factors[2].delta, 0);
    });

    test('a poor Nutri-Score drags the score down', () {
      final a = YukaScore.evaluate(nutriscore: 'a', additiveConcerns: const []);
      final e = YukaScore.evaluate(nutriscore: 'e', additiveConcerns: const []);

      expect(a.score, greaterThan(70));
      expect(e.score, lessThan(40));
      expect(e.score, lessThan(a.score));
      // Note: an additive-free product still earns the full 30 additive points
      // even at Nutri-Score E — that is what the published 60/30/10 weighting
      // produces, and it is why Yuka's own E-grade sugar scores ~33, not 0.
    });

    test('additives are penalised by concern, not by count', () {
      final threeLow = YukaScore.evaluate(nutriscore: 'c', additiveConcerns: [concern(AdditiveConcernLevel.low), concern(AdditiveConcernLevel.low), concern(AdditiveConcernLevel.low)]);
      final oneModerate = YukaScore.evaluate(nutriscore: 'c', additiveConcerns: [concern(AdditiveConcernLevel.moderate)]);

      expect(oneModerate.score, lessThan(threeLow.score), reason: 'One moderate concern must outweigh three low ones.');
    });

    test('low-concern penalties are capped so a long list cannot run away with the score', () {
      final many = YukaScore.evaluate(nutriscore: 'b', additiveConcerns: List.generate(20, (_) => concern(AdditiveConcernLevel.low)));
      final few = YukaScore.evaluate(nutriscore: 'b', additiveConcerns: List.generate(4, (_) => concern(AdditiveConcernLevel.low)));

      expect(many.score, equals(few.score), reason: 'Both exceed the low-concern band cap of 12.');
    });
  });

  group('high-concern additives', () {
    test('high concern reduces the additive component without overriding the weights', () {
      final breakdown = YukaScore.evaluate(nutriscore: 'a', additiveConcerns: [concern(AdditiveConcernLevel.higher)], isOrganic: true);

      expect(breakdown.score, greaterThan(49));
      expect(breakdown.factors.map((factor) => factor.delta).reduce((a, b) => a + b), breakdown.score);
      expect(breakdown.factors[1].label, contains('E999'));
      expect(breakdown.factors[1].label, contains('7 lost'));
    });
  });

  group('additive evidence', () {
    test('unknown additives are tracked but do not reduce the score', () {
      final withoutUnknown = YukaScore.evaluate(nutriscore: 'b', additiveConcerns: const []);
      final withUnknown = YukaScore.evaluate(nutriscore: 'b', additiveConcerns: [concern(AdditiveConcernLevel.unknown)]);

      expect(withUnknown.additiveSubscore, 100);
      expect(withUnknown.score, withoutUnknown.score);
      expect(withUnknown.factors[1].label, contains('no deduction'));
    });
  });

  test('plain sparkling water with zero calories and sugar scores very highly', () {
    final isWater = YukaScore.isPlainWater(productName: 'Saratoga Sparkling Water', category: 'en:sparkling-waters', energyKcal: 0, sugarG: 0);
    final breakdown = YukaScore.evaluate(
      energyKcal: 0,
      sugarG: 0,
      saturatedFatG: 0,
      saltG: 0.01,
      additiveConcerns: const [],
      novaGroup: 1,
      isBeverage: true,
      isWater: isWater,
    );

    expect(isWater, isTrue);
    expect(breakdown.grade, NutriScoreGrade.a);
    expect(breakdown.score, 100);
  });

  group('missing data', () {
    test('reports no data rather than inventing a score', () {
      final breakdown = YukaScore.evaluate();

      expect(breakdown.hasData, isFalse);
      expect(breakdown.factors, isEmpty);
    });

    test('additive information alone is enough to score', () {
      final breakdown = YukaScore.evaluate(additiveConcerns: [concern(AdditiveConcernLevel.moderate)]);

      expect(breakdown.hasData, isTrue);
      expect(breakdown.score, greaterThanOrEqualTo(0));
    });

    test('derives a Nutri-Score from nutrients when no grade is supplied', () {
      final breakdown = YukaScore.evaluate(
        energyKcal: 150, // ≈ 628 kJ → 1 point
        sugarG: 2, // > 1 → 1 point... (4.5 threshold → 0)
        saltG: 0.2, // 80 mg sodium → 0 points
        saturatedFatG: 0.5, // 0 points
        fiberG: 6, // 5 points
        proteinG: 12, // 5 points
      );

      expect(breakdown.hasData, isTrue);
      expect(breakdown.grade, isNotNull);
      expect(breakdown.gradeEstimated, isTrue);
      expect(breakdown.explanation, contains('estimated from its nutrients'));
    });
  });

  group('organic label detection', () {
    test('recognises recognised certifications', () {
      expect(YukaScore.detectOrganic(['organic']), isTrue);
      expect(YukaScore.detectOrganic(['en:eu-organic']), isTrue);
      expect(YukaScore.detectOrganic(['en:ab-agriculture-biologique']), isTrue);
      expect(YukaScore.detectOrganic(['en:usda-organic']), isTrue);
    });

    test('does not treat vague marketing words as certification', () {
      expect(YukaScore.detectOrganic(['natural-flavouring']), isFalse);
      expect(YukaScore.detectOrganic(['no-preservatives']), isFalse);
      expect(YukaScore.detectOrganic(null), isFalse);
      expect(YukaScore.detectOrganic([]), isFalse);
    });
  });
}
