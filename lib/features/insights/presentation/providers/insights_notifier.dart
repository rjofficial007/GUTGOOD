import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/models/health_alert.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/firestore/insight_firestore_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/features/auth/domain/repositories/auth_repository.dart';
import 'package:gutgood/features/insights/domain/repositories/insight_repository.dart';

class InsightsNotifier with ChangeNotifier {
  InsightsNotifier(this._repository, this._firestoreService, this._appStateService, this._authRepository, this._analyticsService) {
    _initInsightStream();
    _appStateService.chatUpdated.addListener(_onDataUpdated);
    _appStateService.profileUpdated.addListener(_onDataUpdated);
    _appStateService.sessionReset.addListener(_onSessionReset);

    // 🟢 Reactive Data Loading: Restart stream whenever auth state changes
    _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        _initInsightStream();
      } else {
        _onSessionReset();
      }
    });
  }

  final InsightRepository _repository;
  final InsightFirestoreService _firestoreService;
  final AppStateService _appStateService;
  final AuthRepository _authRepository;
  final AnalyticsService _analyticsService;

  AIInsight? _latestInsight;
  List<AIInsight> _insightHistory = [];
  List<BodyPattern> _bodyPatterns = [];
  List<HealthAlert> _healthAlerts = [];
  bool _isLoading = false;
  bool _isGenerating = false;
  Timer? _debounceTimer;
  StreamSubscription<AIInsight?>? _insightSub;
  StreamSubscription<List<BodyPattern>>? _patternSub;
  StreamSubscription<List<HealthAlert>>? _alertSub;

  void _initInsightStream() {
    _insightSub?.cancel();
    _patternSub?.cancel();
    _alertSub?.cancel();
    _isLoading = true;
    notifyListeners();

    _fetchHistory();

    _patternSub = _firestoreService.getPatternDataStream().listen((patterns) {
      _bodyPatterns = patterns;
      notifyListeners();
    });

    _alertSub = _firestoreService.getHealthAlertsStream().listen((alerts) {
      _healthAlerts = alerts;
      notifyListeners();
    });

    _insightSub = _firestoreService.getLatestInsightsStream().listen(
      (insight) {
        _latestInsight = insight;
        _appStateService.setInsightsData(_latestInsight);

        if (_latestInsight == null && !_isGenerating) {
          generateNewInsight();
        }

        _fetchHistory(); // Refresh history when latest changes
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

  AIInsight? get latestInsight => _latestInsight;
  List<AIInsight> get insightHistory => _insightHistory;
  List<BodyPattern> get bodyPatterns => _bodyPatterns;
  List<HealthAlert> get healthAlerts => _healthAlerts;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;

  Future<void> markAllAlertsAsRead() async {
    final unreadIds = _healthAlerts.where((a) => !a.isRead).map((a) => a.id).toList();
    if (unreadIds.isEmpty) return;

    // Optimistic UI update
    _healthAlerts = _healthAlerts.map((a) => unreadIds.contains(a.id) ? a.copyWith(isRead: true) : a).toList();
    notifyListeners();

    try {
      await _firestoreService.markAlertsAsRead(unreadIds);
    } catch (e) {
      AppLogger.error('InsightsNotifier: Error marking alerts as read', error: e);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _insightSub?.cancel();
    _patternSub?.cancel();
    _alertSub?.cancel();
    _appStateService.chatUpdated.removeListener(_onDataUpdated);
    _appStateService.profileUpdated.removeListener(_onDataUpdated);
    _appStateService.sessionReset.removeListener(_onSessionReset);
    super.dispose();
  }

  void _onDataUpdated() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 5), () {
      generateNewInsight().catchError((e, st) {
        AppLogger.error('InsightsNotifier: background generation failed', error: e, stackTrace: st);
      });
    });
  }

  Future<void> generateNewInsight() async {
    if (_isGenerating) return;
    _isGenerating = true;
    notifyListeners();

    await _analyticsService.logEvent(name: 'insight_generation_requested');

    try {
      await _repository.generateNewInsight();
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  void _onSessionReset() {
    _debounceTimer?.cancel();
    _latestInsight = null;
    _bodyPatterns = [];
    _healthAlerts = [];
    _insightSub?.cancel();
    _patternSub?.cancel();
    _alertSub?.cancel();
    notifyListeners();
  }
}
