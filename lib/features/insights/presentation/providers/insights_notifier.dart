import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gutgood/core/ai/client/ai_exceptions.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/network_error_classifier.dart';
import 'package:gutgood/features/auth/domain/repositories/auth_repository.dart';
import 'package:gutgood/features/insights/application/usecases/generate_insight_ai_interpretation_usecase.dart';
import 'package:gutgood/features/insights/application/usecases/generate_insight_usecase.dart';
import 'package:gutgood/features/insights/domain/repositories/insight_repository.dart';
import 'package:gutgood/infrastructure/firebase/analytics_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/gut_score_firestore_service.dart';
import 'package:rxdart/rxdart.dart';

class InsightsNotifier with ChangeNotifier {
  InsightsNotifier(this._repository, this._appStateService, this._authRepository, this._analyticsService, this._generateInsightUseCase, this._generateInsightAiInterpretationUseCase, [this._gutScoreFirestoreService]) {
    _initDashboardStream();
    // Client-owned refresh: chat, manual journal, scanner, or profile writes
    // emit the existing data-change pulse; generation is debounced while the
    // client is active. The dashboard stream remains the rendering source.
    _appStateService.chatUpdated.addListener(_onDataUpdated);
    _appStateService.profileUpdated.addListener(_onDataUpdated);
    _appStateService.sessionReset.addListener(_onSessionReset);

    // 🟢 Reactive Data Loading: Restart stream whenever auth state changes
    _authSub = _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        if (_activeUid != null && _activeUid != user.uid) _onSessionReset();
        _activeUid = user.uid;
        _initDashboardStream();
      } else {
        _activeUid = null;
        _onSessionReset();
      }
    });
  }

  final InsightRepository _repository;
  final AppStateService _appStateService;
  final AuthRepository _authRepository;
  final AnalyticsService _analyticsService;
  final GenerateInsightUseCase _generateInsightUseCase;
  final GenerateInsightAiInterpretationUseCase _generateInsightAiInterpretationUseCase;
  final GutScoreFirestoreService? _gutScoreFirestoreService;

  InsightsDashboardState _state = const InsightsDashboardState();
  List<AIInsight> _insightHistory = [];
  GutExperiment? _activeExperiment;
  GutScoreRecord? _latestScoreRecord;

  GutScoreRecord? get latestScoreRecord => _latestScoreRecord;

  int _todayMeals = 0;
  bool _todayCountsLoaded = false;
  String? _countsError;
  int _todaySymptoms = 0;
  int _todayScans = 0;

  int get todayMeals => _todayMeals;
  int get todaySymptoms => _todaySymptoms;
  int get todayScans => _todayScans;
  int get todayFoodScans => _todayMeals;

  String? _loadError;
  String? _generationError;
  String? get errorMessage => _loadError ?? _countsError ?? _generationError;
  bool _disposed = false;
  int _sessionEpoch = 0;
  StreamSubscription<dynamic>? _authSub;
  String? _activeUid;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  Future<void> retry() async {
    if (_isLoading || _isGenerating) return;
    _todayCountsLoaded = false;
    _countsError = null;
    _initDashboardStream();
    await generateNewInsight(force: true);
  }

  bool _isLoading = false;
  bool _isGenerating = false;
  bool _isGeneratingAiInterpretation = false;
  String? _aiInterpretationError;
  InsightAiInterpretation? _lastAiInterpretation;
  String? _lastAiInterpretationUid;
  String? _lastAiInterpretationInsightId;
  DateTime? _lastAiInterpretationPeriodTo;
  bool _bootstrapAttempted = false;
  bool _hasSeenDashboardState = false;
  Timer? _generationDebounce;
  StreamSubscription<InsightsDashboardState>? _dashboardSub;
  StreamSubscription<GutExperiment?>? _experimentSub;
  StreamSubscription<GutScoreRecord?>? _scoreSub;

  void _initDashboardStream() {
    _dashboardSub?.cancel();
    _experimentSub?.cancel();
    _scoreSub?.cancel();
    _isLoading = true;
    _loadError = null;
    notifyListeners();

    _fetchHistory();
    _fetchTodayCounts();
    _fetchActiveExperiment();
    _initExperimentStream();
    _initScoreStream();

    _dashboardSub = _repository
        .getDashboardStateStream()
        .debounceTime(const Duration(milliseconds: 500))
        .listen(
          (newState) {
            final oldInsight = _state.latestInsight;
            final hasNewJournalCounts = _hasSeenDashboardState && (newState.totalMeals != _state.totalMeals || newState.totalSymptoms != _state.totalSymptoms || newState.totalScans != _state.totalScans);
            _state = newState;
            _hasSeenDashboardState = true;
            _loadError = null;
            if (hasNewJournalCounts) _scheduleGeneration();

            // Release-gated single-line state summary (replaces the old debugPrint
            // dump, which also ran in production builds).
            AppLogger.debug(
              'Insights state: meals=${_state.totalMeals} symptoms=${_state.totalSymptoms} '
              'scans=${_state.totalScans} patterns=${_state.patterns.length} '
              'alerts=${_state.alerts.length} sufficient=$isSufficient',
            );

            _appStateService.setInsightsData(_state.latestInsight);

            // Deterministic generation can build a useful baseline from any
            // stored history; the daily learning-progress threshold must not
            // block first-run generation. Session-flagged, never loops.
            if (_state.latestInsight == null && !_isGenerating && !_bootstrapAttempted) {
              _bootstrapAttempted = true;
              generateNewInsight();
            }

            if (oldInsight != _state.latestInsight) {
              _fetchHistory();
            }

            _isLoading = false;
            notifyListeners();
          },
          onError: (e) {
            AppLogger.error('InsightsNotifier: Stream error', error: e);
            _loadError = 'Could not load insights';
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<void> _fetchHistory() async {
    try {
      _insightHistory = await _repository.getInsightHistory();
      await _analyticsService.logEvent(name: 'insight_history_viewed', parameters: {'count': _insightHistory.length});

      // If we have history but no stream data yet, notify so UI can show the latest cached insight
      notifyListeners();
    } catch (e) {
      AppLogger.error('InsightsNotifier: Failed to fetch history', error: e);
    }
  }

  Future<void> _fetchActiveExperiment() async {
    try {
      _activeExperiment = await _repository.getActiveExperiment();
      notifyListeners();
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        AppLogger.debug('InsightsNotifier: Fetch active experiment skipped (permission-denied)');
      } else {
        AppLogger.error('InsightsNotifier: Failed to fetch active experiment', error: e);
      }
    }
  }

  void _initExperimentStream() {
    _experimentSub?.cancel();
    _experimentSub = _repository.getActiveExperimentStream().listen(
      (experiment) {
        _activeExperiment = experiment;
        notifyListeners();
      },
      onError: (e) {
        if (e.toString().contains('permission-denied')) {
          AppLogger.debug('InsightsNotifier: Experiment stream permission denied');
        } else {
          AppLogger.error('InsightsNotifier: Experiment stream error', error: e);
        }
      },
    );
  }

  void _initScoreStream() {
    _scoreSub?.cancel();
    final scoreService = _gutScoreFirestoreService;
    if (scoreService != null) {
      _scoreSub = scoreService.watchLatestGutScore().listen(
        (record) {
          _latestScoreRecord = record;
          notifyListeners();
        },
        onError: (e) {
          AppLogger.error('InsightsNotifier: Score stream error', error: e);
        },
      );
    }
  }

  AIInsight? get latestInsight => _state.latestInsight ?? (_insightHistory.isNotEmpty ? _insightHistory.first : null);
  List<AIInsight> get insightHistory => _insightHistory;
  GutExperiment? get activeExperiment => _activeExperiment;

  /// Returns up to five observations prioritized by repeated log count and recency.
  /// 🟢 NEW: Deduplicates patterns by trigger and type before returning.
  List<BodyPattern> get prioritizedPatterns {
    final seenKeys = <String>{};
    final uniquePatterns = <BodyPattern>[];

    final sorted = [..._state.patterns]
      ..sort((a, b) {
        if (a.frequency != b.frequency) return b.frequency.compareTo(a.frequency);
        return b.updatedAt.compareTo(a.updatedAt);
      });

    for (final p in sorted) {
      final key = '${p.type}_${p.trigger.toLowerCase().trim()}';
      if (seenKeys.add(key)) {
        uniquePatterns.add(p);
      }
    }

    return uniquePatterns.take(5).toList();
  }

  List<HealthAlert> get healthAlerts => _state.alerts;

  Future<void> _fetchTodayCounts() async {
    final hadCounts = _todayCountsLoaded;
    final oldMeals = _todayMeals;
    final oldSymptoms = _todaySymptoms;
    final oldScans = _todayScans;
    try {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final results = await Future.wait([_repository.getRecentMeals(startOfToday), _repository.getRecentSymptoms(startOfToday), _repository.getRecentScans(startOfToday)]);
      final todayMealLogs = results[0] as List<MealLog>;
      final todayScans = results[2] as List<ScanResult>;
      _todayMeals = confirmedFoodMeals(meals: todayMealLogs, scans: todayScans).length;
      _todaySymptoms = (results[1] as List<SymptomLog>).length;
      _todayScans = todayScans.length;
      _countsError = null;
      _todayCountsLoaded = true;
      if (hadCounts && (oldMeals != _todayMeals || oldSymptoms != _todaySymptoms || oldScans != _todayScans)) {
        _scheduleGeneration();
      }
      notifyListeners();
    } catch (e) {
      _countsError = 'Could not load today’s log counts';
      _todayCountsLoaded = true;
      AppLogger.error('InsightsNotifier: Failed to fetch today counts', error: e);
      notifyListeners();
    }
  }

  int get totalMeals => _state.totalMeals;
  int get totalSymptoms => _state.totalSymptoms;
  int get totalScans => _state.totalScans;
  /// Only journaled meals count toward personal food-learning progress;
  /// informational scans remain visible in scan history but are not meals.
  int get totalFoodScans => _state.totalMeals;

  /// Learning-screen progress only; deterministic analysis is not gated on this daily threshold.
  bool get isSufficient => todayFoodScans >= 3 && todaySymptoms >= 1;

  bool get isLoading => _isLoading || !_todayCountsLoaded;
  bool get isGenerating => _isGenerating;
  bool get isGeneratingAiInterpretation => _isGeneratingAiInterpretation;
  String? get aiInterpretationError => _aiInterpretationError;

  InsightAiInterpretation? aiInterpretationFor(AIInsight insight) {
    final persisted = insight.aiInterpretation;
    if (persisted != null) return persisted;

    final local = _lastAiInterpretation;
    final periodTo = insight.periodTo;
    if (local == null || periodTo == null || _lastAiInterpretationUid != insight.uid || _lastAiInterpretationInsightId != insight.firestoreId) return null;
    return _lastAiInterpretationPeriodTo?.isAtSameMomentAs(periodTo) == true ? local : null;
  }

  Future<void> markAllAlertsAsRead() async {
    final unreadIds = _state.alerts.where((a) => !a.isRead).map((a) => a.id).toList();
    if (unreadIds.isEmpty) return;

    // Local optimistic update
    final updatedAlerts = _state.alerts.map((a) => unreadIds.contains(a.id) ? a.copyWith(isRead: true) : a).toList();
    _state = _state.copyWith(alerts: updatedAlerts);
    notifyListeners();

    try {
      await _repository.markAlertsAsRead(unreadIds);
    } catch (e) {
      AppLogger.error('InsightsNotifier: Error marking alerts as read', error: e);
    }
  }

  Future<void> startExperiment(InsightAction action, {int targetDays = 7, String? triggerFood}) async {
    final now = DateTime.now();
    final experiment = GutExperiment(
      id: 'exp_${now.millisecondsSinceEpoch}',
      actionId: action.id,
      title: action.title,
      hypothesis: action.description,
      targetDays: targetDays,
      startDate: now,
      endDate: now.add(Duration(days: targetDays)),
      status: 'active',
      triggerFood: triggerFood ?? (action.relatedFoodIds.isNotEmpty ? action.relatedFoodIds.first : null),
      baselineSymptomRate: action.impactLevel,
    );

    _activeExperiment = experiment;
    notifyListeners();

    try {
      await _repository.saveActiveExperiment(experiment);
      await _analyticsService.logEvent(name: 'gut_experiment_started', parameters: {'title': action.title, 'target_days': targetDays});
    } catch (e) {
      AppLogger.error('InsightsNotifier: Failed to save active experiment', error: e);
    }
  }

  Future<void> recordDailyCheckIn({required bool adhered, required bool hadSymptoms, String? notes}) async {
    final experiment = _activeExperiment;
    if (experiment == null) return;

    final now = DateTime.now();
    final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final checkIn = ExperimentDailyCheckIn(date: dateKey, adhered: adhered, hadSymptoms: hadSymptoms, notes: notes);
    final updatedCheckIns = Map<String, ExperimentDailyCheckIn>.from(experiment.checkIns)..[dateKey] = checkIn;
    final updatedExperiment = experiment.copyWith(checkIns: updatedCheckIns);

    _activeExperiment = updatedExperiment;
    notifyListeners();

    try {
      await _repository.updateExperimentCheckIn(experiment.id, dateKey, adhered, hadSymptoms);
      await _analyticsService.logEvent(name: 'gut_experiment_check_in', parameters: {'experiment_id': experiment.id, 'adhered': adhered, 'had_symptoms': hadSymptoms});

      if (updatedExperiment.completedCheckInsCount >= updatedExperiment.targetDays) {
        final adheredDays = updatedExperiment.adheredCount;
        final freeDays = updatedExperiment.symptomFreeCount;
        final outcome = 'Completed $adheredDays of ${updatedExperiment.targetDays} test days successfully. Enjoyed $freeDays symptom-free days!';
        await completeActiveExperiment(outcomeSummary: outcome);
      }
    } catch (e) {
      AppLogger.error('InsightsNotifier: Failed to record experiment check-in', error: e);
    }
  }

  Future<void> completeActiveExperiment({String? outcomeSummary}) async {
    final experiment = _activeExperiment;
    if (experiment == null) return;

    final outcome = outcomeSummary ?? 'Test successfully completed!';
    _activeExperiment = experiment.copyWith(status: 'completed', completedOutcome: outcome);
    notifyListeners();

    try {
      await _repository.completeExperiment(experiment.id, outcome);
      await _analyticsService.logEvent(name: 'gut_experiment_completed', parameters: {'experiment_id': experiment.id});
    } catch (e) {
      AppLogger.error('InsightsNotifier: Failed to complete experiment', error: e);
    }
  }

  Future<void> cancelActiveExperiment() async {
    final experiment = _activeExperiment;
    if (experiment == null) return;

    _activeExperiment = null;
    notifyListeners();

    try {
      await _repository.completeExperiment(experiment.id, 'Cancelled');
      await _analyticsService.logEvent(name: 'gut_experiment_cancelled', parameters: {'experiment_id': experiment.id});
    } catch (e) {
      AppLogger.error('InsightsNotifier: Failed to cancel experiment', error: e);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _authSub?.cancel();
    _generationDebounce?.cancel();
    _dashboardSub?.cancel();
    _experimentSub?.cancel();
    _scoreSub?.cancel();
    _appStateService.chatUpdated.removeListener(_onDataUpdated);
    _appStateService.profileUpdated.removeListener(_onDataUpdated);
    _appStateService.sessionReset.removeListener(_onSessionReset);
    super.dispose();
  }

  /// Runs one user-requested AI synthesis over existing deterministic findings.
  /// This is intentionally separate from [generateNewInsight] and is never
  /// called during background or lifecycle refreshes.
  Future<void> generateAiInterpretation(AIInsight insight) async {
    if (_isGeneratingAiInterpretation || insight.aiInterpretation != null) return;
    final requestUid = insight.uid;
    if (requestUid == null || requestUid.isEmpty || (_activeUid != null && _activeUid != requestUid)) {
      _aiInterpretationError = 'Refresh Insights and try again with the current saved findings.';
      notifyListeners();
      return;
    }
    final requestEpoch = _sessionEpoch;
    if (_isGenerating) {
      _aiInterpretationError = 'Wait for the current Insight refresh to finish, then try again.';
      notifyListeners();
      return;
    }

    _isGeneratingAiInterpretation = true;
    _aiInterpretationError = null;
    notifyListeners();

    try {
      final patternCount = GenerateInsightAiInterpretationUseCase.eligiblePatterns(insight).length;
      await _analyticsService.logEvent(name: 'insight_ai_interpretation_requested', parameters: {'pattern_count': patternCount});
      final interpretation = await _generateInsightAiInterpretationUseCase.execute(insight);
      if (requestEpoch == _sessionEpoch) {
        _lastAiInterpretation = interpretation;
        _lastAiInterpretationUid = insight.uid;
        _lastAiInterpretationInsightId = insight.firestoreId;
        _lastAiInterpretationPeriodTo = insight.periodTo;
      }
    } catch (error) {
      if (requestEpoch == _sessionEpoch) {
        if (error is AiQuotaExceededException) {
          _aiInterpretationError = 'The AI explanation limit was reached. Your rule-based findings are unchanged.';
        } else if (error is AiAuthException) {
          _aiInterpretationError = 'Please sign in to request an AI explanation.';
        } else if (error is StateError && error.message.toString().contains('changed before')) {
          _aiInterpretationError = 'Your Insight refreshed while this was running. Review the latest findings and try again.';
        } else {
          _aiInterpretationError = 'The AI explanation could not be generated. Your rule-based findings are unchanged.';
        }
      }
      AppLogger.insights('Optional AI Insight explanation failed; deterministic Insight remains available.');
    } finally {
      if (requestEpoch == _sessionEpoch) {
        _isGeneratingAiInterpretation = false;
        notifyListeners();
      }
    }
  }

  /// Runs the on-device deterministic pipeline. Called after journal/profile
  /// updates, dashboard-counter changes, screen bootstrap, and manual refresh.
  Future<void> generateNewInsight({bool force = false}) async {
    if (_isGenerating) return;
    _isGenerating = true;
    _generationError = null;
    _aiInterpretationError = null;
    _lastAiInterpretation = null;
    _lastAiInterpretationUid = null;
    _lastAiInterpretationInsightId = null;
    _lastAiInterpretationPeriodTo = null;
    notifyListeners();

    AppLogger.insights('InsightsNotifier: generation started');
    try {
      await _analyticsService.logEvent(name: 'insight_generation_requested');
      await _generateInsightUseCase.execute(force: force);
      AppLogger.insights('InsightsNotifier: generation successful');
    } catch (e) {
      _generationError = 'Could not refresh insights';
      // Background-only generation: the UI keeps showing the cached
      // dashboard. Classify so offline failures read as offline in logs.
      if (isOfflineError(e)) {
        AppLogger.insights('InsightsNotifier: generation skipped (offline); cached dashboard kept');
      } else {
        AppLogger.error('InsightsNotifier: generation failed', error: e);
      }
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  void _onDataUpdated() {
    _fetchTodayCounts();
    _scheduleGeneration();
  }

  void _scheduleGeneration() {
    _generationDebounce?.cancel();
    _generationDebounce = Timer(const Duration(seconds: 5), () {
      generateNewInsight().catchError((e, st) {
        AppLogger.error('InsightsNotifier: background generation failed', error: e, stackTrace: st);
      });
    });
  }

  void _onSessionReset() {
    _sessionEpoch++;
    _generationDebounce?.cancel();
    _bootstrapAttempted = false;
    _hasSeenDashboardState = false;
    _todayMeals = 0;
    _todayCountsLoaded = false;
    _countsError = null;
    _todaySymptoms = 0;
    _todayScans = 0;
    _loadError = null;
    _generationError = null;
    _aiInterpretationError = null;
    _isGeneratingAiInterpretation = false;
    _lastAiInterpretation = null;
    _lastAiInterpretationUid = null;
    _lastAiInterpretationInsightId = null;
    _lastAiInterpretationPeriodTo = null;
    _isLoading = false;
    _state = const InsightsDashboardState();
    _insightHistory = [];
    _activeExperiment = null;
    _latestScoreRecord = null;
    _dashboardSub?.cancel();
    _experimentSub?.cancel();
    _scoreSub?.cancel();
    notifyListeners();
  }
}
