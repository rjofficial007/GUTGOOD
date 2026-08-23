import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/symptom_log.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/features/history/domain/repositories/history_repository.dart';

class HistoryNotifier with ChangeNotifier {
  HistoryNotifier({
    required HistoryRepository repository,
    required AppStateService appStateService,
    required FirebaseAuth auth,
  }) : _repository = repository,
       _appStateService = appStateService,
       _auth = auth {
    _appStateService.chatUpdated.addListener(refreshAll);
    _appStateService.sessionReset.addListener(clearAll);
    
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        refreshAll();
      } else {
        clearAll();
      }
    });
    
    refreshAll();
  }

  final HistoryRepository _repository;
  final AppStateService _appStateService;
  final FirebaseAuth _auth;

  // Scans
  final List<ScanResult> _scans = [];
  bool _scansLoading = true;
  bool _scansLoadingMore = false;
  bool _scansHasMore = true;

  // Meals
  final List<MealLog> _meals = [];
  bool _mealsLoading = true;
  bool _mealsLoadingMore = false;
  bool _mealsHasMore = true;

  // Symptoms
  final List<SymptomLog> _symptoms = [];
  bool _symptomsLoading = true;
  bool _symptomsLoadingMore = false;
  bool _symptomsHasMore = true;

  static const int _pageSize = 20;

  List<ScanResult> get scans => List.unmodifiable(_scans);
  bool get scansLoading => _scansLoading;
  bool get scansLoadingMore => _scansLoadingMore;
  bool get scansHasMore => _scansHasMore;

  List<MealLog> get meals => List.unmodifiable(_meals);
  bool get mealsLoading => _mealsLoading;
  bool get mealsLoadingMore => _mealsLoadingMore;
  bool get mealsHasMore => _mealsHasMore;

  List<SymptomLog> get symptoms => List.unmodifiable(_symptoms);
  bool get symptomsLoading => _symptomsLoading;
  bool get symptomsLoadingMore => _symptomsLoadingMore;
  bool get symptomsHasMore => _symptomsHasMore;

  @override
  void dispose() {
    _appStateService.chatUpdated.removeListener(refreshAll);
    _appStateService.sessionReset.removeListener(clearAll);
    super.dispose();
  }

  void clearAll() {
    _scans.clear();
    _meals.clear();
    _symptoms.clear();
    _scansLoading = false;
    _mealsLoading = false;
    _symptomsLoading = false;
    _scansHasMore = true;
    _mealsHasMore = true;
    _symptomsHasMore = true;
    notifyListeners();
  }

  Future<void> refreshAll() async {
    await Future.wait([
      refreshScans(),
      refreshMeals(),
      refreshSymptoms(),
    ]);
  }

  Future<void> refreshScans() async {
    _scansLoading = true;
    _scansHasMore = true;
    notifyListeners();

    try {
      final results = await _repository.getScanHistory(limit: _pageSize);
      _scans..clear()
      ..addAll(results);
      if (results.length < _pageSize) _scansHasMore = false;
    } catch (e) {
      AppLogger.error('HistoryNotifier: Failed to refresh scans', error: e);
    } finally {
      _scansLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreScans() async {
    if (_scansLoadingMore || !_scansHasMore || _scans.isEmpty) return;

    _scansLoadingMore = true;
    notifyListeners();

    try {
      final lastTime = _scans.last.time;
      if (lastTime == null) {
        _scansHasMore = false;
        return;
      }

      final results = await _repository.getScanHistory(
        limit: _pageSize,
        before: lastTime,
      );

      if (results.length < _pageSize) _scansHasMore = false;
      _scans.addAll(results);
    } finally {
      _scansLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> refreshMeals() async {
    _mealsLoading = true;
    _mealsHasMore = true;
    notifyListeners();

    try {
      final results = await _repository.getRecentMealLogs(limit: _pageSize);
      _meals..clear()
      ..addAll(results);
      if (results.length < _pageSize) _mealsHasMore = false;
    } catch (e) {
      AppLogger.error('HistoryNotifier: Failed to refresh meals', error: e);
    } finally {
      _mealsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreMeals() async {
    if (_mealsLoadingMore || !_mealsHasMore || _meals.isEmpty) return;

    _mealsLoadingMore = true;
    notifyListeners();

    try {
      final results = await _repository.getRecentMealLogs(
        limit: _pageSize,
        before: _meals.last.time,
      );

      if (results.length < _pageSize) _mealsHasMore = false;
      _meals.addAll(results);
    } finally {
      _mealsLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> refreshSymptoms() async {
    _symptomsLoading = true;
    _symptomsHasMore = true;
    notifyListeners();

    try {
      final results = await _repository.getRecentSymptomLogs(limit: _pageSize);
      _symptoms..clear()
      ..addAll(results);
      if (results.length < _pageSize) _symptomsHasMore = false;
    } catch (e) {
      AppLogger.error('HistoryNotifier: Failed to refresh symptoms', error: e);
    } finally {
      _symptomsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreSymptoms() async {
    if (_symptomsLoadingMore || !_symptomsHasMore || _symptoms.isEmpty) return;

    _symptomsLoadingMore = true;
    notifyListeners();

    try {
      final results = await _repository.getRecentSymptomLogs(
        limit: _pageSize,
        before: _symptoms.last.time,
      );

      if (results.length < _pageSize) _symptomsHasMore = false;
      _symptoms.addAll(results);
    } finally {
      _symptomsLoadingMore = false;
      notifyListeners();
    }
  }
}
