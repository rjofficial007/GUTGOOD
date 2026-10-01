import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/features/insights/domain/usecases/check_insight_threshold_usecase.dart';

void main() {
  group('CheckInsightThresholdUseCase Tests', () {
    const useCase = CheckInsightThresholdUseCase();

    test('daily gate includes midnight and compares stored UTC times locally', () {
      final midnight = DateTime(2026, 10, 1);
      expect(CheckInsightThresholdUseCase.isSameLocalDay(midnight.toUtc(), midnight), isTrue);
      expect(CheckInsightThresholdUseCase.isSameLocalDay(midnight.subtract(const Duration(microseconds: 1)).toUtc(), midnight), isFalse);
      expect(CheckInsightThresholdUseCase.isSameLocalDay(DateTime(2026, 10, 2).toUtc(), midnight), isFalse);
    });

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
