import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/utils/model_utils.dart';

void main() {
  group('ModelUtils.computeDeterministicScore', () {
    test('Calculates perfect score for Nutri-Score A, NOVA 1, high fiber', () {
      final score = ModelUtils.computeDeterministicScore(
        nutriscore: 'A',
        novaGroup: 1,
        fiberG: 6,
        proteinG: 12,
      );
      // Base 50 + A(25) + NOVA 1(10) + fiber(5) + protein(3) = 93
      expect(score, 93);
    });

    test('Calculates low score for Nutri-Score E, NOVA 4, high sugar', () {
      final score = ModelUtils.computeDeterministicScore(
        nutriscore: 'E',
        novaGroup: 4,
        sugarG: 30,
        saltG: 2.0,
      );
      // Base 50 - E(25) - NOVA 4(10) - sugar(5) - salt(5) = 5
      expect(score, 5);
    });

    test('Handles null inputs gracefully', () {
      final score = ModelUtils.computeDeterministicScore();
      expect(score, 50);
    });
  });
}
