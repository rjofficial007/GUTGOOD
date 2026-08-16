import 'dart:async';
import 'dart:convert';

import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/health_alert.dart';
import 'package:gutgood/core/services/ai_service.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/services/crashlytics_service.dart';
import 'package:gutgood/core/services/firestore/auth_firestore_service.dart';
import 'package:gutgood/core/services/firestore/chat_firestore_service.dart';
import 'package:gutgood/core/services/firestore/history_firestore_service.dart';
import 'package:gutgood/core/services/firestore/insight_firestore_service.dart';
import 'package:gutgood/core/services/notification_service.dart';
import 'package:gutgood/core/services/pattern_engine_service.dart';
import 'package:gutgood/core/services/prompts.dart';
import 'package:gutgood/core/utils/date_time_utils.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/model_utils.dart';
import 'package:gutgood/features/insights/domain/repositories/insight_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InsightRepositoryImpl implements InsightRepository {
  InsightRepositoryImpl({
    required AuthFirestoreService authFirestoreService,
    required HistoryFirestoreService historyFirestoreService,
    required InsightFirestoreService insightFirestoreService,
    required ChatFirestoreService chatFirestoreService,
    required AiService aiService,
    required SharedPreferences prefs,
    required NotificationService notificationService,
    required PatternEngineService patternEngineService,
    required AnalyticsService analyticsService,
    required CrashlyticsService crashlyticsService,
  }) : _authFirestoreService = authFirestoreService,
       _historyFirestoreService = historyFirestoreService,
       _insightFirestoreService = insightFirestoreService,
       _chatFirestoreService = chatFirestoreService,
       _aiService = aiService,
       _prefs = prefs,
       _notificationService = notificationService,
       _patternEngineService = patternEngineService,
       _analyticsService = analyticsService,
       _crashlyticsService = crashlyticsService;
  final AuthFirestoreService _authFirestoreService;
  final HistoryFirestoreService _historyFirestoreService;
  final InsightFirestoreService _insightFirestoreService;
  final ChatFirestoreService _chatFirestoreService;
  final AiService _aiService;
  final SharedPreferences _prefs;
  final NotificationService _notificationService;
  final PatternEngineService _patternEngineService;
  final AnalyticsService _analyticsService;
  final CrashlyticsService _crashlyticsService;

  @override
  Future<AIInsight?> getLatestInsight() async {
    final cloud = await _insightFirestoreService.getLatestInsights();
    if (cloud != null) return cloud;

    final cached = _prefs.getString('gutgood_insights_cache');
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
  Future<void> generateNewInsight() async {
    final lastRunStr = _prefs.getString('last_insight_run');
    DateTime lastRun;

    if (lastRunStr != null) {
      lastRun = DateTimeUtils.parseToUtc(lastRunStr);
    } else {
      // 🟢 Fix: Fallback to Firestore to prevent duplicate generation on fresh login/new device.
      final latestCloud = await _insightFirestoreService.getLatestInsights();
      lastRun = latestCloud?.updatedAt.toUtc() ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      AppLogger.info('InsightRepo: No local lastRun found. Fallback to Firestore: $lastRun');
    }

    // 🟢 PRD Section 8.2 Alignment: At least 24 hours since last insight
    final nowUtc = DateTime.now().toUtc();
    final hoursSinceLastRun = nowUtc.difference(lastRun).inHours;

    if (hoursSinceLastRun < 24) {
      AppLogger.debug('InsightRepo: Last insight was generated $hoursSinceLastRun hours ago. Skipping duplicate generation.');
      return;
    }

    final scanCount = await _historyFirestoreService.getTotalScansCount();
    final mealCount = await _historyFirestoreService.getTotalMealLogsCount();
    final symptomCount = await _historyFirestoreService.getTotalSymptomsCount();

    // 🟢 Non-Negotiable: Do not generate insight until minimum data threshold is reached.
    // Logic: Either 3 Scans OR (3 Meals AND 1 Symptom). 
    // This matches the UI progress indicator requirement.
    if (scanCount < 3 && (mealCount < 3 || symptomCount < 1)) {
      AppLogger.debug('InsightRepo: Insufficient data for first analysis. (Scans: $scanCount/3, Meals: $mealCount/3, Symptoms: $symptomCount/1). Skipping.');
      return;
    }

    final profile = await _authFirestoreService.getUserMetadata();
    final userGoals = profile?.goals ?? _prefs.getStringList('user_goals') ?? [];
    final userSensitivities = profile?.sensitivities ?? _prefs.getStringList('user_sensitivities') ?? [];
    final userLifestyle = profile?.lifestyle ?? _prefs.getStringList('user_lifestyle') ?? [];

    final cycleSyncEnabled = profile?.cycleSyncEnabled ?? _prefs.getBool('cycle_sync_enabled') ?? false;
    final cyclePhase = cycleSyncEnabled ? (profile?.cyclePhase ?? _prefs.getString('cycle_phase') ?? 'Luteal Phase') : 'Not specified';

    // 🟢 Fetch and Filter Chat History for Insight Engine
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final chatHistory = await _chatFirestoreService.getMessages(limit: 50, since: sevenDaysAgo);

    // Only include messages that mention food or symptoms to keep tokens low
    final relevantChat = chatHistory.where((m) => m.foodMentions.isNotEmpty || m.symptomMentions.isNotEmpty).toList();

    final historyJson = jsonEncode(relevantChat.map((m) => m.toAiMap()).toList());
    final historySummary = profile?.chatSummary;

    final recentMeals = await _historyFirestoreService.getRecentMealLogs(limit: 30);
    final symptomLogs = await _historyFirestoreService.getRecentSymptomLogs(limit: 30);
    final recentScans = await _historyFirestoreService.getRecentScans(limit: 20);

    // 🟢 Fix: Do not generate insight if the core data streams are insufficient for analysis.
    // A "Cause & Effect" analysis requires at least some meals or scans to analyze.
    if (recentMeals.isEmpty && recentScans.isEmpty) {
      AppLogger.debug('InsightRepo: Insufficient total data for analysis. (Meals: ${recentMeals.length}, Scans: ${recentScans.length}). Skipping.');
      return;
    }

    final mealsJson = jsonEncode(recentMeals.map((m) => m.toMap()).toList());
    final symptomsJson = jsonEncode(symptomLogs.map((m) => m.toMap()).toList());
    // 🟢 Fix: Use toAiMap() for scans to avoid 502/payload errors
    final scansJson = jsonEncode(recentScans.map((s) => s.toAiMap()).toList());

    final history = await _insightFirestoreService.getInsightsHistory();
    // Take the last 6 scores, ensure they are in ASCENDING chronological order (Oldest -> Newest)
    final scoreHistory = history.take(6).toList().reversed.map((i) => i.gutScore).join(', ');

    try {
      AppLogger.info('InsightRepo: Generating insight. History: ${scoreHistory.isEmpty ? "None" : scoreHistory}');
      final startTime = DateTime.now();

      final cleanJson = await _aiService.generateContent(
        prompt: Prompts.insightsAnalysisPrompt(
          userGoals: userGoals,
          userSensitivities: userSensitivities,
          userLifestyle: userLifestyle,
          cyclePhase: cyclePhase,
          historyJson: historyJson,
          historySummary: historySummary,
          mealsJson: mealsJson,
          symptomsJson: symptomsJson,
          scansJson: scansJson,
          scoreHistory: scoreHistory.isEmpty ? null : scoreHistory,
        ),
      );

      final jsonStr = ModelUtils.extractJson(cleanJson);
      if (jsonStr == null) {
        throw Exception('InsightRepo: Could not parse AI insight result');
      }

      final decoded = jsonDecode(jsonStr);
      final insight = AIInsight.fromMap(decoded);

      final duration = DateTime.now().difference(startTime).inSeconds;
      await _analyticsService.logEvent(name: 'insight_generated', parameters: {'gut_score': insight.gutScore, 'duration_sec': duration});

      await _prefs.setString('gutgood_insights_cache', cleanJson);
      await _prefs.setString('last_insight_run', DateTime.now().toUtc().toIso8601String());
      await _insightFirestoreService.saveInsights(insight);

      // 🟢 Fix: Save HealthAlert locally now that Cloud Function is removed
      unawaited(
        _insightFirestoreService.saveHealthAlert(
          HealthAlert(
            id: '',
            title: 'Gut Insight Ready',
            message: 'Your latest personalized gut health analysis is ready. Open to see your new score!',
            type: 'insight_ready',
            time: DateTime.now(),
            isRead: false,
          ),
        ),
      );

      unawaited(_notificationService.showInsightGeneratedNotification());

      if (profile != null) {
        final updatedProfile = profile.copyWith(gutScore: insight.gutScore, updatedAt: DateTime.now());
        await _authFirestoreService.updateUserProfile(updatedProfile);
      }

      unawaited(_patternEngineService.runAnalysis());
    } catch (e, st) {
      AppLogger.error('InsightRepo: AI Analysis failed', error: e);
      await _analyticsService.logEvent(name: 'insight_generation_failed', parameters: {'error': e.toString()});
      await _crashlyticsService.recordError(e, st, reason: 'AI Insight generation failed');
      rethrow;
    }
  }
}
