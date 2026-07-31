import 'package:gutgood/core/models/ai_insight.dart';

abstract class InsightRepository {
  Future<AIInsight?> getLatestInsight();
  Future<List<AIInsight>> getInsightHistory();
  Future<void> saveInsight(AIInsight insight);
  Future<void> generateNewInsight();
}
