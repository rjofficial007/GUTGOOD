import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/features/auth/domain/repositories/auth_repository.dart';
import 'package:gutgood/features/insights/domain/repositories/insight_repository.dart';

import '../../../../core/services/firestore_service.dart';

class InsightsNotifier with ChangeNotifier {
  final InsightRepository _repository;
  final FirestoreService _firestoreService;
  final AppStateService _appStateService;
  final AuthRepository _authRepository;

  AIInsight? _latestInsight;
  List<AIInsight> _insightHistory = [];
  bool _isLoading = false;
  bool _isGenerating = false;
  Timer? _debounceTimer;
  StreamSubscription<AIInsight?>? _insightSub;

  InsightsNotifier(this._repository, this._firestoreService, this._appStateService, this._authRepository) {
    _initInsightStream();
    _appStateService.chatUpdated.addListener(_onDataUpdated);
    _appStateService.profileUpdated.addListener(_onDataUpdated);
    _appStateService.sessionReset.addListener(_onSessionReset);

    // 🟢 Reactive Data Loading: Restart stream whenever auth state changes
    _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        _initInsightStream();
      }
    });
  }

  void _initInsightStream() {
    _insightSub?.cancel();
    _isLoading = true;
    notifyListeners();

    _fetchHistory();

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
        Log.e('InsightsNotifier: Stream error', error: e);
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> _fetchHistory() async {
    try {
      _insightHistory = await _repository.getInsightHistory();
      notifyListeners();
    } catch (e) {
      Log.e('InsightsNotifier: Failed to fetch history', error: e);
    }
  }

  AIInsight? get latestInsight => _latestInsight;
  List<AIInsight> get insightHistory => _insightHistory;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _insightSub?.cancel();
    _appStateService.chatUpdated.removeListener(_onDataUpdated);
    _appStateService.profileUpdated.removeListener(_onDataUpdated);
    _appStateService.sessionReset.removeListener(_onSessionReset);
    super.dispose();
  }

  void _onDataUpdated() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 5), () {
      generateNewInsight().catchError((e, st) {
        Log.e('InsightsNotifier: background generation failed', error: e, stackTrace: st);
      });
    });
  }

  Future<void> generateNewInsight() async {
    if (_isGenerating) return;
    _isGenerating = true;
    notifyListeners();

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
    _insightSub?.cancel();
    notifyListeners();
  }
}
