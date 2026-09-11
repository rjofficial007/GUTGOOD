import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/models/journal_entry.dart';
import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/symptom_log.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/features/history/domain/repositories/history_repository.dart';

enum HistoryFilter { all, scans, body }

class HistoryNotifier with ChangeNotifier {
  HistoryNotifier({required HistoryRepository repository, required AppStateService appStateService, required FirebaseAuth auth})
    : _repository = repository,
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

  HistoryFilter _currentFilter = HistoryFilter.all;
  HistoryFilter get currentFilter => _currentFilter;

  void setFilter(HistoryFilter filter) {
    if (_currentFilter == filter) return;
    _currentFilter = filter;
    notifyListeners();
  }

  // Scans
  final List<ScanResult> _scans = [];
  bool _scansLoading = true;
  bool _scansLoadingMore = false;
  bool _scansHasMore = true;

  // Label Scans
  final List<ScanResult> _labelScans = [];
  bool _labelScansLoading = true;

  // Menu Scans
  final List<ScanResult> _menuScans = [];
  bool _menuScansLoading = true;

  // Meals
  final List<MealLog> _meals = [];
  bool _mealsLoading = true;
  final bool _mealsLoadingMore = false;

  // Symptoms
  final List<SymptomLog> _symptoms = [];
  bool _symptomsLoading = true;
  bool _symptomsLoadingMore = false;
  bool _symptomsHasMore = true;

  static const int _pageSize = 20;

  List<ScanResult> get scans => List.unmodifiable(_scans);

  /// Combined list of all scans (Product, Label, and Menu) sorted by date.
  List<ScanResult> get allScans {
    final scanMap = <String, ScanResult>{};
    for (final s in _scans) {
      if (s.scanId != null) scanMap[s.scanId!] = s;
    }
    for (final s in _labelScans) {
      if (s.scanId != null) scanMap[s.scanId!] = s;
    }
    for (final s in _menuScans) {
      if (s.scanId != null) scanMap[s.scanId!] = s;
    }

    final combined = scanMap.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return combined;
  }

  bool get scansLoading => _scansLoading || _labelScansLoading || _menuScansLoading;
  bool get scansLoadingMore => _scansLoadingMore;

  List<MealLog> get meals => List.unmodifiable(_meals);
  bool get mealsLoadingMore => _mealsLoadingMore;

  List<SymptomLog> get symptoms => List.unmodifiable(_symptoms);
  bool get symptomsLoadingMore => _symptomsLoadingMore;

  List<JournalEntry> get filteredEntries {
    final entriesMap = <String, JournalEntry>{};

    if (_currentFilter == HistoryFilter.all || _currentFilter == HistoryFilter.scans) {
      // 🚀 Professional Deduplication: Use scanId as the unique key to prevent
      // items from appearing twice if they exist in multiple source streams.
      for (final s in _scans) {
        final id = s.scanId ?? 'scan_${s.createdAt.millisecondsSinceEpoch}';
        entriesMap[id] = JournalEntry(id: id, type: JournalEntryType.scan, createdAt: s.createdAt, scan: s);
      }
      for (final s in _labelScans) {
        final id = s.scanId ?? 'label_${s.createdAt.millisecondsSinceEpoch}';
        entriesMap[id] = JournalEntry(id: id, type: JournalEntryType.scan, createdAt: s.createdAt, scan: s);
      }
      for (final s in _menuScans) {
        final id = s.scanId ?? 'menu_${s.createdAt.millisecondsSinceEpoch}';
        entriesMap[id] = JournalEntry(id: id, type: JournalEntryType.scan, createdAt: s.createdAt, scan: s);
      }
    }

    if (_currentFilter == HistoryFilter.all) {
      for (final m in _meals) {
        final id = m.firestoreId ?? m.id?.toString() ?? 'meal_${m.createdAt.millisecondsSinceEpoch}';
        entriesMap[id] = JournalEntry(id: id, type: JournalEntryType.meal, createdAt: m.eventTime, meal: m);
      }
    }

    if (_currentFilter == HistoryFilter.all || _currentFilter == HistoryFilter.body) {
      for (final s in _symptoms) {
        final id = s.firestoreId ?? s.id?.toString() ?? 'symptom_${s.createdAt.millisecondsSinceEpoch}';
        entriesMap[id] = JournalEntry(id: id, type: JournalEntryType.symptom, createdAt: s.eventTime, symptom: s);
      }
    }

    final allEntries = entriesMap.values.toList()
      // Sort chronologically (Newest first)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return allEntries;
  }

  bool get isLoading => _scansLoading || _labelScansLoading || _menuScansLoading || _mealsLoading || _symptomsLoading;

  @override
  void dispose() {
    _appStateService.chatUpdated.removeListener(refreshAll);
    _appStateService.sessionReset.removeListener(clearAll);
    super.dispose();
  }

  void clearAll() {
    _scans.clear();
    _labelScans.clear();
    _menuScans.clear();
    _meals.clear();
    _symptoms.clear();
    _scansLoading = false;
    _labelScansLoading = false;
    _menuScansLoading = false;
    _mealsLoading = false;
    _symptomsLoading = false;
    _scansHasMore = true;
    _symptomsHasMore = true;
    notifyListeners();
  }

  Future<void> refreshAll() async {
    await Future.wait([refreshScans(), refreshLabelScans(), refreshMenuScans(), refreshMeals(), refreshSymptoms()]);
  }

  Future<void> refreshScans() async {
    _scansLoading = true;
    _scansHasMore = true;
    notifyListeners();

    try {
      final results = await _repository.getScanHistory(limit: _pageSize);
      _scans
        ..clear()
        ..addAll(results);
      if (results.length < _pageSize) _scansHasMore = false;
    } catch (e) {
      AppLogger.error('HistoryNotifier: Failed to refresh scans', error: e);
    } finally {
      _scansLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshLabelScans() async {
    _labelScansLoading = true;
    notifyListeners();

    try {
      final results = await _repository.getLabelScans(limit: _pageSize);
      _labelScans
        ..clear()
        ..addAll(results);
    } catch (e) {
      AppLogger.error('HistoryNotifier: Failed to refresh label scans', error: e);
    } finally {
      _labelScansLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshMenuScans() async {
    _menuScansLoading = true;
    notifyListeners();

    try {
      final results = await _repository.getMenuScans(limit: _pageSize);
      _menuScans
        ..clear()
        ..addAll(results);
    } catch (e) {
      AppLogger.error('HistoryNotifier: Failed to refresh menu scans', error: e);
    } finally {
      _menuScansLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreScans() async {
    if (_scansLoadingMore || !_scansHasMore || _scans.isEmpty) return;

    _scansLoadingMore = true;
    notifyListeners();

    try {
      final lastTime = _scans.last.createdAt;

      final results = await _repository.getScanHistory(limit: _pageSize, before: lastTime);

      if (results.length < _pageSize) _scansHasMore = false;
      _scans.addAll(results);
    } finally {
      _scansLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> refreshMeals() async {
    _mealsLoading = true;
    notifyListeners();

    try {
      final results = await _repository.getRecentMealLogs(limit: _pageSize);
      _meals
        ..clear()
        ..addAll(results);
    } catch (e) {
      AppLogger.error('HistoryNotifier: Failed to refresh meals', error: e);
    } finally {
      _mealsLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshSymptoms() async {
    _symptomsLoading = true;
    _symptomsHasMore = true;
    notifyListeners();

    try {
      final results = await _repository.getRecentSymptomLogs(limit: _pageSize);
      _symptoms
        ..clear()
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
      final results = await _repository.getRecentSymptomLogs(limit: _pageSize, before: _symptoms.last.createdAt);

      if (results.length < _pageSize) _symptomsHasMore = false;
      _symptoms.addAll(results);
    } finally {
      _symptomsLoadingMore = false;
      notifyListeners();
    }
  }
}
