/// Pure business logic to verify if the user has reached the minimum data
/// threshold for a reliable gut health analysis.
///
/// Threshold Logic (matching InsightBentoLearning):
/// - At least 3 Food Scans/Meals AND 1 Symptom Log
class CheckInsightThresholdUseCase {
  const CheckInsightThresholdUseCase();

  /// Both cadence and log eligibility use the user's local calendar day.
  static bool isSameLocalDay(DateTime value, DateTime now) {
    final local = value.toLocal();
    final today = now.toLocal();
    return local.year == today.year && local.month == today.month && local.day == today.day;
  }

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
