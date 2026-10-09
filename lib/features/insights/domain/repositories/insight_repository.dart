import 'package:gutgood/core/models/models.dart';

abstract class InsightRepository {
  Future<List<AIInsight>> getInsightHistory();
  Future<void> saveInsight(AIInsight insight);
  Future<bool> saveAiInterpretation(AIInsight insight, InsightAiInterpretation interpretation);
  Future<void> markAlertsAsRead(List<String> alertIds);
  Future<void> saveHealthAlert(HealthAlert alert);

  /// Returns a consolidated stream of all dashboard reactive data.
  Stream<InsightsDashboardState> getDashboardStateStream();

  // Active Gut Experiments
  Future<void> saveActiveExperiment(GutExperiment experiment);
  Future<GutExperiment?> getActiveExperiment();
  Stream<GutExperiment?> getActiveExperimentStream();
  Future<void> updateExperimentCheckIn(String experimentId, String dateKey, bool adhered, bool hadSymptoms);
  Future<void> completeExperiment(String experimentId, String outcomeSummary);

  // Data fetching for analysis
  Future<List<MealLog>> getRecentMeals(DateTime since);
  Future<List<SymptomLog>> getRecentSymptoms(DateTime since);
  Future<List<ScanResult>> getRecentScans(DateTime since);
  Future<List<ScanResult>> getScansByIds(List<String> scanIds);
  Future<List<BodyPattern>> getLatestPatterns();
}
