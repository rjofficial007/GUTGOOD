import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/network_error_classifier.dart';
import 'package:gutgood/features/auth/domain/repositories/auth_repository.dart';
import 'package:gutgood/features/insights/domain/repositories/insight_repository.dart';
import 'package:gutgood/features/insights/domain/usecases/generate_insight_usecase.dart';
import 'package:rxdart/rxdart.dart';

class InsightsNotifier with ChangeNotifier {
  InsightsNotifier(this._repository, this._appStateService, this._authRepository, this._analyticsService, this._generateInsightUseCase) {
    _initDashboardStream();
    // Client-owned cadence: regenerate (debounced) whenever chat or profile
    // data changes; the dashboard stream below only renders stored state.
    _appStateService.chatUpdated.addListener(_onDataUpdated);
    _appStateService.profileUpdated.addListener(_onDataUpdated);
    _appStateService.sessionReset.addListener(_onSessionReset);

    // 🟢 Reactive Data Loading: Restart stream whenever auth state changes
    _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        _initDashboardStream();
      } else {
        _onSessionReset();
      }
    });
  }

  final InsightRepository _repository;
  final AppStateService _appStateService;
  final AuthRepository _authRepository;
  final AnalyticsService _analyticsService;
  final GenerateInsightUseCase _generateInsightUseCase;

  InsightsDashboardState _state = const InsightsDashboardState();
  List<AIInsight> _insightHistory = [];

  bool _isLoading = false;
  bool _isGenerating = false;
  bool _bootstrapAttempted = false;
  Timer? _generationDebounce;
  StreamSubscription<InsightsDashboardState>? _dashboardSub;

  void _initDashboardStream() {
    _dashboardSub?.cancel();
    _isLoading = true;
    notifyListeners();

    _fetchHistory();

    _dashboardSub = _repository
        .getDashboardStateStream()
        .debounceTime(const Duration(milliseconds: 500))
        .listen(
          (newState) {
            final oldInsight = _state.latestInsight;
            _state = newState;

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
      if (_state.latestInsight == null && _insightHistory.isNotEmpty) {
        notifyListeners();
      }
    } catch (e) {
      AppLogger.error('InsightsNotifier: Failed to fetch history', error: e);
    }
  }

  AIInsight? get latestInsight => _state.latestInsight ?? (_insightHistory.isNotEmpty ? _insightHistory.first : null);
  List<AIInsight> get insightHistory => _insightHistory;

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

  int get totalMeals => _state.totalMeals;
  int get totalSymptoms => _state.totalSymptoms;
  int get totalScans => _state.totalScans;

  bool get isSufficient => _state.totalScans >= 3 || (_state.totalMeals >= 3 && _state.totalSymptoms >= 1);

  bool get isLoading => _isLoading;
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

  @override
  void dispose() {
    _generationDebounce?.cancel();
    _dashboardSub?.cancel();
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
    notifyListeners();

    AppLogger.insights('InsightsNotifier: generation started');
    await _analyticsService.logEvent(name: 'insight_generation_requested');

    try {
      await _generateInsightUseCase.execute();
      AppLogger.insights('InsightsNotifier: generation successful');
    } catch (e) {
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
    _state = const InsightsDashboardState();
    _insightHistory = [];
    _dashboardSub?.cancel();
    notifyListeners();
  }
}
