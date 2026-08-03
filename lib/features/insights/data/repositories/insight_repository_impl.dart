import 'dart:convert';

import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/symptom_log.dart';
import 'package:gutgood/core/services/ai_service.dart';
import 'package:gutgood/core/services/firestore_service.dart';
import 'package:gutgood/core/services/notification_service.dart';
import 'package:gutgood/core/services/pattern_engine_service.dart';
import 'package:gutgood/core/services/prompts.dart';
import 'package:gutgood/core/utils/date_time_utils.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/features/insights/domain/repositories/insight_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InsightRepositoryImpl implements InsightRepository {
  final FirestoreService _firestoreService;
  final AiService _aiService;
  final SharedPreferences _prefs;
  final NotificationService _notificationService;
  final PatternEngineService _patternEngineService;

  InsightRepositoryImpl({
    required FirestoreService firestoreService,
    required AiService aiService,
    required SharedPreferences prefs,
    required NotificationService notificationService,
    required PatternEngineService patternEngineService,
  }) : _firestoreService = firestoreService,
       _aiService = aiService,
       _prefs = prefs,
       _notificationService = notificationService,
       _patternEngineService = patternEngineService;

  @override
  Future<AIInsight?> getLatestInsight() async {
    final cloud = await _firestoreService.getLatestInsights();
    if (cloud != null) return cloud;

    final cached = _prefs.getString('gutgood_insights_cache');
    if (cached != null) {
      return AIInsight.fromMap(jsonDecode(cached));
    }

    return null;
  }

  @override
  Future<List<AIInsight>> getInsightHistory() async {
    return await _firestoreService.getInsightsHistory();
  }

  @override
  Future<void> saveInsight(AIInsight insight) async {
    await _firestoreService.saveInsights(insight);
  }

  @override
  Future<void> generateNewInsight() async {
    final lastRunStr = _prefs.getString('last_insight_run');
    final lastRun = lastRunStr != null ? DateTimeUtils.parse(lastRunStr) : DateTime.fromMillisecondsSinceEpoch(0);

    // 🟢 PRD Section 8.2 Alignment: At least 24 hours since last insight
    final hoursSinceLastRun = DateTime.now().difference(lastRun).inHours;
    if (hoursSinceLastRun < 24) {
      Log.d('InsightRepo: Last insight was generated $hoursSinceLastRun hours ago. Skipping.');
      return;
    }

    final int scanCount = await _firestoreService.getScansCountSince(lastRun);
    final int mealCount = await _firestoreService.getMealLogsCountSince(lastRun);
    final int symptomCount = await _firestoreService.getSymptomsCountSince(lastRun);

    if (scanCount < 3 && mealCount < 1 && symptomCount < 1) {
      Log.d('InsightRepo: Not enough new data for analysis.');
      return;
    }

    final profile = await _firestoreService.getUserMetadata();
    final List<String> userGoals = profile?.goals ?? _prefs.getStringList('user_goals') ?? [];
    final List<String> userSensitivities = profile?.sensitivities ?? _prefs.getStringList('user_sensitivities') ?? [];
    final List<String> userLifestyle = profile?.lifestyle ?? _prefs.getStringList('user_lifestyle') ?? [];

    final bool cycleSyncEnabled = profile?.cycleSyncEnabled ?? _prefs.getBool('cycle_sync_enabled') ?? false;
    final String cyclePhase = cycleSyncEnabled ? (profile?.cyclePhase ?? _prefs.getString('cycle_phase') ?? 'Luteal Phase') : 'Not specified';

    final List<MealLog> recentMeals = await _firestoreService.getRecentMealLogs(limit: 30);
    final List<SymptomLog> symptomLogs = await _firestoreService.getRecentSymptomLogs(limit: 30);
    final List<ScanResult> recentScans = await _firestoreService.getRecentScans(limit: 20);

    final String historyJson = "[]"; // Omitting chat history for simplicity in this migration step
    final String mealsJson = jsonEncode(recentMeals.map((m) => m.toMap()).toList());
    final String symptomsJson = jsonEncode(symptomLogs.map((m) => m.toMap()).toList());
    // 🟢 Fix: Use toAiMap() for scans to avoid 502/payload errors
    final String scansJson = jsonEncode(recentScans.map((s) => s.toAiMap()).toList());

    final List<AIInsight> history = await _firestoreService.getInsightsHistory();
    // Take the last 6 scores, ensure they are in ASCENDING chronological order (Oldest -> Newest)
    final String scoreHistory = history.take(6).toList().reversed.map((i) => i.gutScore).join(', ');

    try {
      Log.i('InsightRepo: Generating insight. History: ${scoreHistory.isEmpty ? "None" : scoreHistory}');

      final cleanJson = await _aiService.generateContent(
        prompt: Prompts.insightsAnalysisPrompt(
          userGoals: userGoals,
          userSensitivities: userSensitivities,
          userLifestyle: userLifestyle,
          cyclePhase: cyclePhase,
          historyJson: historyJson,
          mealsJson: mealsJson,
          symptomsJson: symptomsJson,
          scansJson: scansJson,
          scoreHistory: scoreHistory.isEmpty ? null : scoreHistory,
        ),
      );

      final decoded = jsonDecode(cleanJson);
      final insight = AIInsight.fromMap(decoded);

      await _prefs.setString('gutgood_insights_cache', cleanJson);
      await _prefs.setString('last_insight_run', DateTime.now().toIso8601String());
      await _firestoreService.saveInsights(insight);

      _notificationService.showInsightGeneratedNotification();

      if (profile != null) {
        final updatedProfile = profile.copyWith(gutScore: insight.gutScore, updatedAt: DateTime.now());
        await _firestoreService.updateUserProfile(updatedProfile);
      }

      _patternEngineService.runAnalysis();
    } catch (e) {
      Log.e('InsightRepo: AI Analysis failed', error: e);
      rethrow;
    }
  }
}
