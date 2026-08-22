/// Pure business logic to verify if the user has reached the minimum data
/// threshold for a reliable gut health analysis.
///
/// Threshold Logic (PRD Section 8.2):
/// - At least 3 Scans
/// OR
/// - At least 3 Meals AND 1 Symptom
class CheckInsightThresholdUseCase {
  const CheckInsightThresholdUseCase();

  bool execute({
    required int scanCount,
    required int mealCount,
    required int symptomCount,
  }) {
    // 🟢 Threshold: Either 3 Scans OR (3 Meals AND 1 Symptom).
    // This matches the UI progress indicator requirement.
    if (scanCount >= 3) return true;
    if (mealCount >= 3 && symptomCount >= 1) return true;

    return false;
  }
}
