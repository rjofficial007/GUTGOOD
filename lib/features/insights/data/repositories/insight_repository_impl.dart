import 'dart:async';
import 'dart:convert';

import 'package:gutgood/core/constants/storage_keys.dart';
import 'package:gutgood/core/models/models.dart';
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
  Future<void> saveActiveExperiment(GutExperiment experiment) async {
    await _prefs.setString('active_gut_experiment_cache', jsonEncode(experiment.toMap()));
    await _insightFirestoreService.saveActiveExperiment(experiment);
  }

  @override
  Future<GutExperiment?> getActiveExperiment() async {
    final cloud = await _insightFirestoreService.getActiveExperiment();
    if (cloud != null) {
      await _prefs.setString('active_gut_experiment_cache', jsonEncode(cloud.toMap()));
      return cloud;
    }
    final cached = _prefs.getString('active_gut_experiment_cache');
    if (cached != null) {
      try {
        return GutExperiment.fromMap(jsonDecode(cached) as Map<String, dynamic>);
      } catch (_) {}
    }
    return null;
  }

  @override
  Stream<GutExperiment?> getActiveExperimentStream() => _insightFirestoreService.getActiveExperimentStream();

  @override
  Future<void> updateExperimentCheckIn(String experimentId, String dateKey, bool adhered, bool hadSymptoms) async {
    await _insightFirestoreService.updateExperimentCheckIn(experimentId, dateKey, adhered, hadSymptoms);
    // Update cache
    final cached = _prefs.getString('active_gut_experiment_cache');
    if (cached != null) {
      try {
        final exp = GutExperiment.fromMap(jsonDecode(cached) as Map<String, dynamic>);
        final updated = exp.copyWith(
          checkIns: {
            ...exp.checkIns,
            dateKey: ExperimentDailyCheckIn(date: dateKey, adhered: adhered, hadSymptoms: hadSymptoms),
          },
        );
        await _prefs.setString('active_gut_experiment_cache', jsonEncode(updated.toMap()));
      } catch (_) {}
    }
  }

  @override
  Future<void> completeExperiment(String experimentId, String outcomeSummary) async {
    await _insightFirestoreService.completeExperiment(experimentId, outcomeSummary);
    final cached = _prefs.getString('active_gut_experiment_cache');
    if (cached != null) {
      try {
        final exp = GutExperiment.fromMap(jsonDecode(cached) as Map<String, dynamic>);
        final updated = exp.copyWith(status: 'completed', completedOutcome: outcomeSummary);
        await _prefs.setString('active_gut_experiment_cache', jsonEncode(updated.toMap()));
      } catch (_) {}
    }
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
      final rawGutScore = decoded['gutScore'];
      final newScore = rawGutScore is Map<String, dynamic>
          ? ((rawGutScore['score'] as num?)?.toInt() ?? 0)
          : ((rawGutScore as num?)?.toInt() ?? 0);
      if (lastScore != null) {
        final diff = newScore - lastScore;
        decoded['scoreDiff'] = diff >= 0 ? '+$diff' : '$diff';
      }
      var insight = AIInsight.fromMap(decoded);

      // Enrich synthesized insight with user's uploaded food photos
      insight = await _enrichInsightWithUserPhotos(insight);

      final duration = DateTime.now().difference(startTime).inSeconds;
      await _analyticsService.logEvent(name: 'insight_generated', parameters: {'gut_score': insight.gutScore, 'duration_sec': duration});

      await _prefs.setString(StorageKeys.gutgoodInsightsCache, ModelUtils.safeJsonEncode(insight.toMap()));
      return insight;
    } catch (e, st) {
      AppLogger.error('InsightRepo: AI Analysis failed', error: e);
      await _analyticsService.logEvent(name: 'insight_generation_failed', parameters: {'error': e.toString()});
      await _crashlyticsService.recordError(e, st, reason: 'AI Insight generation failed');
      rethrow;
    }
  }

  Future<AIInsight> _enrichInsightWithUserPhotos(AIInsight insight) async {
    try {
      final recentScans = await getRecentScans(DateTime.now().subtract(const Duration(days: 30)));
      if (recentScans.isEmpty) return insight;

      final scanImageMap = <String, ScanResult>{};
      for (final scan in recentScans) {
        final url = scan.userImageUrl ?? scan.imageUrl;
        if (url != null && url.isNotEmpty) {
          final key = scan.productName.toLowerCase().trim();
          if (key.isNotEmpty && !scanImageMap.containsKey(key)) {
            scanImageMap[key] = scan;
          }
        }
      }

      if (scanImageMap.isEmpty) return insight;

      ScanResult? findMatchingScan(String foodName) {
        final norm = foodName.toLowerCase().trim();
        if (norm.isEmpty) return null;
        if (scanImageMap.containsKey(norm)) return scanImageMap[norm];
        for (final entry in scanImageMap.entries) {
          if (norm.contains(entry.key) || entry.key.contains(norm)) {
            return entry.value;
          }
        }
        return null;
      }

      var enrichedTopHealing = insight.topHealing;
      if (enrichedTopHealing != null && (enrichedTopHealing.userImageUrl == null || enrichedTopHealing.userImageUrl!.isEmpty)) {
        final match = findMatchingScan(enrichedTopHealing.food);
        final matchUrl = match?.userImageUrl ?? match?.imageUrl;
        if (match != null && matchUrl != null) {
          enrichedTopHealing = TopHighlight(
            food: enrichedTopHealing.food,
            effects: enrichedTopHealing.effects,
            timeframe: enrichedTopHealing.timeframe,
            frequency: enrichedTopHealing.frequency,
            emoji: enrichedTopHealing.emoji,
            imageUrl: enrichedTopHealing.imageUrl ?? matchUrl,
            userImageUrl: matchUrl,
            foodScanId: match.scanId,
          );
        }
      }

      var enrichedTopTrigger = insight.topTrigger;
      if (enrichedTopTrigger != null && (enrichedTopTrigger.userImageUrl == null || enrichedTopTrigger.userImageUrl!.isEmpty)) {
        final match = findMatchingScan(enrichedTopTrigger.food);
        final matchUrl = match?.userImageUrl ?? match?.imageUrl;
        if (match != null && matchUrl != null) {
          enrichedTopTrigger = TopHighlight(
            food: enrichedTopTrigger.food,
            effects: enrichedTopTrigger.effects,
            timeframe: enrichedTopTrigger.timeframe,
            frequency: enrichedTopTrigger.frequency,
            emoji: enrichedTopTrigger.emoji,
            imageUrl: enrichedTopTrigger.imageUrl ?? matchUrl,
            userImageUrl: matchUrl,
            foodScanId: match.scanId,
          );
        }
      }

      final enrichedHealingFoods = insight.healingFoods.map((hf) {
        if (hf.userImageUrl != null && hf.userImageUrl!.isNotEmpty) return hf;
        final match = findMatchingScan(hf.name);
        final matchUrl = match?.userImageUrl ?? match?.imageUrl;
        if (match != null && matchUrl != null) {
          return HealingFood(name: hf.name, effect: hf.effect, emoji: hf.emoji, imageUrl: hf.imageUrl ?? matchUrl, userImageUrl: matchUrl, foodScanId: match.scanId);
        }
        return hf;
      }).toList();

      final enrichedTriggerFoods = insight.triggerFoods.map((tf) {
        if (tf.userImageUrl != null && tf.userImageUrl!.isNotEmpty) return tf;
        final match = findMatchingScan(tf.name);
        final matchUrl = match?.userImageUrl ?? match?.imageUrl;
        if (match != null && matchUrl != null) {
          return TriggerFood(name: tf.name, effect: tf.effect, emoji: tf.emoji, imageUrl: tf.imageUrl ?? matchUrl, userImageUrl: matchUrl, foodScanId: match.scanId);
        }
        return tf;
      }).toList();

      final enrichedFoodImpacts = insight.foodImpacts.map((fi) {
        if (fi.userImageUrl != null && fi.userImageUrl!.isNotEmpty) return fi;
        final match = findMatchingScan(fi.food);
        final matchUrl = match?.userImageUrl ?? match?.imageUrl;
        if (match != null && matchUrl != null) {
          return FoodImpact(
            food: fi.food,
            dateLabel: fi.dateLabel,
            effect: fi.effect,
            timeframeLabel: fi.timeframeLabel,
            emoji: fi.emoji,
            impactType: fi.impactType,
            imageUrl: fi.imageUrl ?? matchUrl,
            userImageUrl: matchUrl,
            foodScanId: match.scanId,
          );
        }
        return fi;
      }).toList();

      return insight.copyWith(topHealing: enrichedTopHealing, topTrigger: enrichedTopTrigger, healingFoods: enrichedHealingFoods, triggerFoods: enrichedTriggerFoods, foodImpacts: enrichedFoodImpacts);
    } catch (e) {
      AppLogger.warning('Failed to enrich insight with user photos: $e');
      return insight;
    }
  }
}
