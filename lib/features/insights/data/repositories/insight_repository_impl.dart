import 'dart:async';
import 'dart:convert';

import 'package:gutgood/core/constants/storage_keys.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/models/chat_message.dart';
import 'package:gutgood/core/models/health_alert.dart';
import 'package:gutgood/core/models/history_counts.dart';
import 'package:gutgood/core/models/insights_dashboard_state.dart';
import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/symptom_log.dart';
import 'package:gutgood/core/services/ai_service.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/services/crashlytics_service.dart';
import 'package:gutgood/core/services/firestore/chat_firestore_service.dart';
import 'package:gutgood/core/services/firestore/history_firestore_service.dart';
import 'package:gutgood/core/services/firestore/insight_firestore_service.dart';
import 'package:gutgood/core/services/prompts.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/model_utils.dart';
import 'package:gutgood/features/insights/domain/repositories/insight_repository.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InsightRepositoryImpl implements InsightRepository {
  InsightRepositoryImpl({
    required HistoryFirestoreService historyFirestoreService,
    required InsightFirestoreService insightFirestoreService,
    required ChatFirestoreService chatFirestoreService,
    required AiService aiService,
    required SharedPreferences prefs,
    required AnalyticsService analyticsService,
    required CrashlyticsService crashlyticsService,
  }) : _historyFirestoreService = historyFirestoreService,
       _insightFirestoreService = insightFirestoreService,
       _chatFirestoreService = chatFirestoreService,
       _aiService = aiService,
       _prefs = prefs,
       _analyticsService = analyticsService,
       _crashlyticsService = crashlyticsService;

  final HistoryFirestoreService _historyFirestoreService;
  final InsightFirestoreService _insightFirestoreService;
  final ChatFirestoreService _chatFirestoreService;
  final AiService _aiService;
  final SharedPreferences _prefs;
  final AnalyticsService _analyticsService;
  final CrashlyticsService _crashlyticsService;

  @override
  Future<AIInsight?> getLatestInsight() async {
    final cloud = await _insightFirestoreService.getLatestInsights();
    if (cloud != null) return cloud;

    final cached = _prefs.getString(StorageKeys.gutgoodInsightsCache);
    if (cached != null) {
      return AIInsight.fromMap(jsonDecode(cached));
    }

    return null;
  }

  @override
  Future<List<AIInsight>> getInsightHistory() async => _insightFirestoreService.getInsightsHistory();

  @override
  Future<void> saveInsight(AIInsight insight) async {
    await _insightFirestoreService.saveInsights(insight);
  }

  @override
  Future<void> markAlertsAsRead(List<String> alertIds) async {
    await _insightFirestoreService.markAlertsAsRead(alertIds);
  }

  @override
  Future<void> saveHealthAlert(HealthAlert alert) async {
    await _insightFirestoreService.saveHealthAlert(alert);
  }

  @override
  Stream<InsightsDashboardState> getDashboardStateStream() => Rx.combineLatest4(
    _insightFirestoreService.getLatestInsightsStream(),
    _insightFirestoreService.getPatternDataStream(),
    _insightFirestoreService.getHealthAlertsStream(),
    // Single-doc counters read replaces three full-collection live snapshots.
    _historyFirestoreService.watchHistoryCounts(),
    (AIInsight? latestInsight, List<BodyPattern> patterns, List<HealthAlert> alerts, HistoryCounts counts) =>
        InsightsDashboardState(latestInsight: latestInsight, patterns: patterns, alerts: alerts, totalMeals: counts.meals, totalSymptoms: counts.symptoms, totalScans: counts.scans),
  ).distinct();

  @override
  Future<List<MealLog>> getRecentMeals(DateTime since) async => _historyFirestoreService.getRecentMealLogs(since: since);

  @override
  Future<List<SymptomLog>> getRecentSymptoms(DateTime since) async => _historyFirestoreService.getRecentSymptomLogs(since: since);

  @override
  Future<List<ScanResult>> getRecentScans(DateTime since) async => _historyFirestoreService.getRecentScans(since: since);

  @override
  Future<List<BodyPattern>> getLatestPatterns() async => _insightFirestoreService.getLatestPatterns();

  @override
  Future<List<ChatMessage>> getRecentChat(DateTime since) async {
    final chatHistory = await _chatFirestoreService.getMessages(since: since);
    // Only include messages that mention food or symptoms to keep tokens low
    return chatHistory.where((m) => m.foodMentions.isNotEmpty || m.symptomMentions.isNotEmpty).toList();
  }

  @override
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
  }) async {
    final historyJson = ModelUtils.safeJsonEncode(chatHistory.map((m) => m.toAiMap()).toList());
    final preComputedPatternCandidates = patternCandidates.isNotEmpty ? ModelUtils.safeJsonEncode(patternCandidates.map((p) => p.toMap()).toList()) : null;

    try {
      AppLogger.insights('Generating insight. History: $scoreHistory');
      final startTime = DateTime.now();

      final cleanJson = await _aiService.generateContent(
        prompt: Prompts.insightsAnalysisPrompt(
          userGoals: goals,
          userSensitivities: sensitivities,
          userLifestyle: lifestyle,
          cyclePhase: cyclePhase,
          historyJson: historyJson,
          historySummary: chatSummary,
          recentJournalText: recentJournalText,
          historicalJournalSummary: historicalJournalSummary,
          scoreHistory: scoreHistory,
          preComputedPatternCandidates: preComputedPatternCandidates,
        ),
      );

      final jsonStr = ModelUtils.extractJson(cleanJson);
      if (jsonStr == null) {
        throw Exception('InsightRepo: Could not parse AI insight result');
      }

      final decoded = Map<String, dynamic>.from(jsonDecode(jsonStr) as Map);
      // Deterministic score delta (drives the "↑ 6 from last week" pill). The
      // repo already receives lastScore — previously it was never used.
      if (lastScore != null) {
        final newScore = (decoded['gutScore'] as num?)?.toInt() ?? 0;
        final diff = newScore - lastScore;
        decoded['scoreDiff'] = diff >= 0 ? '+$diff' : '$diff';
      }
      final insight = AIInsight.fromMap(decoded);

      final duration = DateTime.now().difference(startTime).inSeconds;
      await _analyticsService.logEvent(name: 'insight_generated', parameters: {'gut_score': insight.gutScore, 'duration_sec': duration});

      await _prefs.setString(StorageKeys.gutgoodInsightsCache, jsonEncode(decoded));
      return insight;
    } catch (e, st) {
      AppLogger.error('InsightRepo: AI Analysis failed', error: e);
      await _analyticsService.logEvent(name: 'insight_generation_failed', parameters: {'error': e.toString()});
      await _crashlyticsService.recordError(e, st, reason: 'AI Insight generation failed');
      rethrow;
    }
  }
}
