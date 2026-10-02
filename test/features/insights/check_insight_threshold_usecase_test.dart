import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/features/insights/domain/usecases/check_insight_threshold_usecase.dart';

void main() {
  group('CheckInsightThresholdUseCase Tests', () {
    const useCase = CheckInsightThresholdUseCase();

    test('returns false when food logs < 3 or symptom logs < 1', () {
      expect(useCase.execute(scanCount: 0, mealCount: 0, symptomCount: 0), isFalse);
      expect(useCase.execute(scanCount: 1, mealCount: 1, symptomCount: 1), isFalse);
      expect(useCase.execute(scanCount: 2, mealCount: 1, symptomCount: 0), isFalse);
    });

    test('returns true when food logs >= 3 AND symptom logs >= 1', () {
      expect(useCase.execute(scanCount: 3, mealCount: 0, symptomCount: 1), isTrue);
      expect(useCase.execute(scanCount: 1, mealCount: 2, symptomCount: 1), isTrue);
      expect(useCase.execute(scanCount: 3, mealCount: 2, symptomCount: 2), isTrue);
    });
  });
}
