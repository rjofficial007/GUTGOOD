import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/network_error_classifier.dart';
import 'package:gutgood/features/auth/domain/repositories/auth_repository.dart';
import 'package:gutgood/features/insights/application/usecases/generate_insight_usecase.dart';
import 'package:gutgood/features/insights/domain/repositories/insight_repository.dart';
import 'package:gutgood/infrastructure/firebase/analytics_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/gut_score_firestore_service.dart';
import 'package:rxdart/rxdart.dart';

class InsightsNotifier with ChangeNotifier {
  InsightsNotifier(this._repository, this._appStateService, this._authRepository, this._analyticsService, this._generateInsightUseCase, [this._gutScoreFirestoreService]) {
    _initDashboardStream();
    // Client-owned cadence: regenerate (debounced) whenever chat or profile
    // data changes; the dashboard stream below only renders stored state.
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
  int get todayFoodScans => _todayScans + _todayMeals;

  String? _loadError;
  String? _generationError;
  String? get errorMessage => _loadError ?? _countsError ?? _generationError;
  bool _disposed = false;
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
    await generateNewInsight();
  }

  bool _isLoading = false;
  bool _isGenerating = false;
  bool _bootstrapAttempted = false;
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
            _state = newState;
            _loadError = null;

            // Release-gated single-line state summary (replaces the old debugPrint
            // dump, which also ran in production builds).
            AppLogger.debug(
              'Insights state: meals=${_state.totalMeals} symptoms=${_state.totalSymptoms} '
              'scans=${_state.totalScans} patterns=${_state.patterns.length} '
              'alerts=${_state.alerts.length} sufficient=$isSufficient',
            );

            _appStateService.setInsightsData(_state.latestInsight);

            // One-shot bootstrap for users who crossed the threshold but have
            // no insight yet (reactive listeners cover steady state; this just
            // shortens first-run latency). Session-flagged, never loops.
            if (_state.latestInsight == null && !_isGenerating && isSufficient && !_bootstrapAttempted) {
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

  /// Returns 3-5 most meaningful insights prioritized by confidence and frequency.
  /// 🟢 NEW: Deduplicates patterns by trigger and type before returning.
  List<BodyPattern> get prioritizedPatterns {
    final seenKeys = <String>{};
    final uniquePatterns = <BodyPattern>[];

    final sorted = [..._state.patterns]
      ..sort((a, b) {
        // 1. Evidence Ratio (Impact Probability)
        if (a.evidenceRatio != b.evidenceRatio) {
          return b.evidenceRatio.compareTo(a.evidenceRatio);
        }
        // 2. Statistical Confidence (rank map: High > Medium > Low — P1-7)
        if (a.confidence != b.confidence) {
          int rank(String c) => c == BodyPattern.confidenceHigh ? 0 : (c == BodyPattern.confidenceMedium ? 1 : 2);
          return rank(a.confidence).compareTo(rank(b.confidence));
        }
        // 3. Frequency
        if (a.frequency != b.frequency) {
          return b.frequency.compareTo(a.frequency);
        }
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
    try {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final results = await Future.wait([_repository.getRecentMeals(startOfToday), _repository.getRecentSymptoms(startOfToday), _repository.getRecentScans(startOfToday)]);
      _todayMeals = (results[0] as List<MealLog>).length;
      _todaySymptoms = (results[1] as List<SymptomLog>).length;
      _todayScans = (results[2] as List<ScanResult>).length;
      _countsError = null;
      _todayCountsLoaded = true;
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
  int get totalFoodScans => _state.totalScans + _state.totalMeals;

  /// Daily baseline threshold: 3 Food Scans/Meals AND 1 Symptom Log logged today (resets every day).
  bool get isSufficient => todayFoodScans >= 3 && todaySymptoms >= 1;

  bool get isLoading => _isLoading || !_todayCountsLoaded;
  bool get isGenerating => _isGenerating;

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

  /// Runs the on-device pipeline (24h cadence + threshold gates inside the
  /// use case). Called debounced from data listeners, once from bootstrap,
  /// and directly for manual refresh.
  Future<void> generateNewInsight() async {
    if (_isGenerating) return;
    _isGenerating = true;
    _generationError = null;
    notifyListeners();

    AppLogger.insights('InsightsNotifier: generation started');
    try {
      await _analyticsService.logEvent(name: 'insight_generation_requested');
      await _generateInsightUseCase.execute();
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
    _generationDebounce?.cancel();
    _generationDebounce = Timer(const Duration(seconds: 5), () {
      generateNewInsight().catchError((e, st) {
        AppLogger.error('InsightsNotifier: background generation failed', error: e, stackTrace: st);
      });
    });
  }

  void _onSessionReset() {
    _generationDebounce?.cancel();
    _bootstrapAttempted = false;
    _todayMeals = 0;
    _todayCountsLoaded = false;
    _countsError = null;
    _todaySymptoms = 0;
    _todayScans = 0;
    _loadError = null;
    _generationError = null;
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
