/// Pure business logic to verify if the user has reached the minimum data
/// threshold for a reliable gut health analysis.
///
/// Threshold Logic (matching InsightBentoLearning):
/// - At least 3 Food Scans/Meals AND 1 Symptom Log
class CheckInsightThresholdUseCase {
  const CheckInsightThresholdUseCase();

  bool execute({
    required int scanCount,
    required int mealCount,
    required int symptomCount,
  }) {
    final totalFoodLogs = scanCount + mealCount;
    // 🟢 Baseline threshold: 3 Food Scans/Meals AND 1 Symptom Log
    return totalFoodLogs >= 3 && symptomCount >= 1;
  }
}
