import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/models/health_alert.dart';
import 'package:gutgood/core/models/insights_dashboard_state.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/features/auth/domain/repositories/auth_repository.dart';
import 'package:gutgood/features/insights/domain/repositories/insight_repository.dart';
import 'package:gutgood/features/insights/domain/usecases/generate_insight_usecase.dart';
import 'package:rxdart/rxdart.dart';

class InsightsNotifier with ChangeNotifier {
  InsightsNotifier(this._repository, this._appStateService, this._authRepository, this._analyticsService, this._generateInsightUseCase) {
    _initDashboardStream();
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

            debugPrint('--- InsightsNotifier: New State Received ---');
            debugPrint('Total Meals: ${_state.totalMeals}');
            debugPrint('Total Symptoms: ${_state.totalSymptoms}');
            debugPrint('Total Scans: ${_state.totalScans}');
            debugPrint('Latest Insight Firestore ID: ${_state.latestInsight?.firestoreId}');
            if (_state.latestInsight != null) {
              debugPrint('Insight Gut Score: ${_state.latestInsight!.gutScore}');
              debugPrint('Insight Healing Foods: ${_state.latestInsight!.healingFoods.length}');
              debugPrint('Insight Trigger Foods: ${_state.latestInsight!.triggerFoods.length}');
              debugPrint('Insight Detected Patterns: ${_state.latestInsight!.detectedPatterns.length}');
            }
            debugPrint('Global Body Patterns Count: ${_state.patterns.length}');
            if (_state.patterns.isNotEmpty) {
              for (var i = 0; i < _state.patterns.length; i++) {
                final p = _state.patterns[i];
                debugPrint('Global Pattern [$i]: ${p.trigger} -> ${p.type} (${p.confidence})');
              }
            }
            debugPrint('Health Alerts Count: ${_state.alerts.length}');
            debugPrint('Is Sufficient for generation: $isSufficient');
            debugPrint('--------------------------------------------');

            _appStateService.setInsightsData(_state.latestInsight);

            // 🟢 Fix: Only auto-generate if we have enough data to actually succeed
            if (_state.latestInsight == null && !_isGenerating && isSufficient) {
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
      notifyListeners();
    } catch (e) {
      AppLogger.error('InsightsNotifier: Failed to fetch history', error: e);
    }
  }

  AIInsight? get latestInsight => _state.latestInsight;
  List<AIInsight> get insightHistory => _insightHistory;
  List<BodyPattern> get bodyPatterns => _state.patterns;

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
        // 2. Statistical Confidence
        if (a.confidence != b.confidence) {
          return a.confidence == BodyPattern.confidenceHigh ? -1 : 1;
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

  void _onDataUpdated() {
    _generationDebounce?.cancel();
    _generationDebounce = Timer(const Duration(seconds: 5), () {
      generateNewInsight().catchError((e, st) {
        AppLogger.error('InsightsNotifier: background generation failed', error: e, stackTrace: st);
      });
    });
  }

  Future<void> generateNewInsight() async {
    if (_isGenerating) return;
    _isGenerating = true;
    notifyListeners();

    debugPrint('--- InsightsNotifier: Generation Started ---');
    await _analyticsService.logEvent(name: 'insight_generation_requested');

    try {
      await _generateInsightUseCase.execute();
      debugPrint('--- InsightsNotifier: Generation Successful ---');
    } catch (e) {
      debugPrint('--- InsightsNotifier: Generation FAILED: $e ---');
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  void _onSessionReset() {
    _generationDebounce?.cancel();
    _state = const InsightsDashboardState();
    _insightHistory = [];
    _dashboardSub?.cancel();
    notifyListeners();
  }
}
