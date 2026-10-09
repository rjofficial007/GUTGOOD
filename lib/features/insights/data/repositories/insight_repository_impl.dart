import 'dart:async';
import 'dart:convert';

import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/features/insights/domain/repositories/insight_repository.dart';
import 'package:gutgood/infrastructure/firebase/firestore/history_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/insight_firestore_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InsightRepositoryImpl implements InsightRepository {
  InsightRepositoryImpl({
    required HistoryFirestoreService historyFirestoreService,
    required InsightFirestoreService insightFirestoreService,
    required SharedPreferences prefs,
  }) : _historyFirestoreService = historyFirestoreService,
       _insightFirestoreService = insightFirestoreService,
       _prefs = prefs;

  final HistoryFirestoreService _historyFirestoreService;
  final InsightFirestoreService _insightFirestoreService;
  final SharedPreferences _prefs;

  @override
  Future<List<AIInsight>> getInsightHistory() async => _insightFirestoreService.getInsightsHistory();

  @override
  Future<void> saveInsight(AIInsight insight) async {
    await _insightFirestoreService.saveInsights(insight, useServerTimestamp: insight.origin == AIInsight.originRuleBased);
  }

  @override
  Future<bool> saveAiInterpretation(AIInsight insight, InsightAiInterpretation interpretation) async {
    final uid = insight.uid;
    final insightId = insight.firestoreId;
    final periodTo = insight.periodTo;
    if (uid == null || uid.isEmpty || insightId == null || periodTo == null || insight.origin != AIInsight.originRuleBased) return false;
    return _insightFirestoreService.saveAiInterpretation(uid: uid, insightId: insightId, expectedPeriodTo: periodTo, interpretation: interpretation);
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
  Future<List<ScanResult>> getScansByIds(List<String> scanIds) async {
    final ids = scanIds.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet();
    final scans = await Future.wait(ids.map(_historyFirestoreService.getScanById));
    return scans.whereType<ScanResult>().toList();
  }

  @override
  Future<List<BodyPattern>> getLatestPatterns() async => _insightFirestoreService.getLatestPatterns();
}
