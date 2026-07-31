import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/features/insights/domain/repositories/insight_repository.dart';

import '../../../../core/services/firestore_service.dart';

class InsightsNotifier with ChangeNotifier {
  final InsightRepository _repository;
  final FirestoreService _firestoreService;
  final AppStateService _appStateService;

  AIInsight? _latestInsight;
  bool _isLoading = false;
  bool _isGenerating = false;
  Timer? _debounceTimer;
  StreamSubscription<AIInsight?>? _insightSub;

  InsightsNotifier({required InsightRepository repository, required FirestoreService firestoreService, required AppStateService appStateService})
    : _repository = repository,
      _firestoreService = firestoreService,
      _appStateService = appStateService {
    _initInsightStream();
    _appStateService.chatUpdated.addListener(_onDataUpdated);
    _appStateService.profileUpdated.addListener(_onDataUpdated);
    _appStateService.sessionReset.addListener(_onSessionReset);
  }

  void _initInsightStream() {
    _insightSub?.cancel();
    _isLoading = true;
    notifyListeners();

    _insightSub = _firestoreService.getLatestInsightsStream().listen(
      (insight) {
        _latestInsight = insight;
        _appStateService.setInsightsData(_latestInsight);

        if (_latestInsight == null && !_isGenerating) {
          generateNewInsight();
        }

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

  AIInsight? get latestInsight => _latestInsight;
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
    _initInsightStream();
  }
}
