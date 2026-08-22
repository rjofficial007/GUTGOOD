import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/models/chat_message.dart';
import 'package:gutgood/core/models/health_alert.dart';
import 'package:gutgood/core/models/insights_dashboard_state.dart';
import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/symptom_log.dart';

abstract class InsightRepository {
  Future<AIInsight?> getLatestInsight();
  Future<List<AIInsight>> getInsightHistory();
  Future<void> saveInsight(AIInsight insight);
  Future<void> markAlertsAsRead(List<String> alertIds);
  Future<void> saveHealthAlert(HealthAlert alert);

  /// Returns a consolidated stream of all dashboard reactive data.
  Stream<InsightsDashboardState> getDashboardStateStream();

  // Data fetching for analysis
  Future<List<MealLog>> getRecentMeals(DateTime since);
  Future<List<SymptomLog>> getRecentSymptoms(DateTime since);
  Future<List<ScanResult>> getRecentScans(DateTime since);
  Future<List<BodyPattern>> getLatestPatterns();
  Future<List<ChatMessage>> getRecentChat(DateTime since);

  // Core AI Analysis
  Future<AIInsight> analyzeGutHealth({
    required List<String> goals,
    required List<String> sensitivities,
    required List<String> lifestyle,
    required String cyclePhase,
    required String? chatSummary,
    required List<ChatMessage> chatHistory,
    required String? recentJournalText,
    required String? historicalJournalSummary,
    required String? scoreHistory,
    required List<BodyPattern> patternCandidates,
    int? lastScore,
  });
}
