import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/saved_food_key.dart';
import 'package:gutgood/features/auth/domain/repositories/auth_repository.dart';
import 'package:gutgood/features/history/domain/repositories/history_repository.dart';

class SavedFoodsProvider with ChangeNotifier {
  SavedFoodsProvider({
    required HistoryRepository repository,
    required AppStateService appStateService,
    required AuthRepository authRepository,
  }) : _repository = repository,
       _appStateService = appStateService {
    _loadSavedFoods();
    _appStateService.savedFoodsUpdated.addListener(_onSavedFoodsUpdated);
    _appStateService.sessionReset.addListener(_resetSession);
    _authSubscription = authRepository.authStateChanges.listen((user) {
      _resetSession();
      if (user != null) _loadSavedFoods();
    });
  }

  final HistoryRepository _repository;
  final AppStateService _appStateService;

  List<ScanResult> _savedFoods = [];
  bool _isLoading = false;
  bool _disposed = false;
  int _loadVersion = 0;
  int _sessionVersion = 0;
  StreamSubscription<AuthUser?>? _authSubscription;
  Future<void>? _pendingRefresh;

  List<ScanResult> get savedFoods => _savedFoods;
  bool get isLoading => _isLoading;

  void _onSavedFoodsUpdated() {
    _pendingRefresh = _loadSavedFoods();
  }

  Future<void> _loadSavedFoods() async {
    if (_disposed) return;
    final version = ++_loadVersion;
    _isLoading = true;
    notifyListeners();
    try {
      final foods = await _repository.getSavedFoods();
      if (_disposed || version != _loadVersion) return;
      _savedFoods = foods;
    } catch (e, st) {
      AppLogger.error('Failed to load saved foods', error: e, stackTrace: st);
    } finally {
      if (!_disposed && version == _loadVersion) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  bool isSaved(String? productName, {String? barcode}) {
    final key = savedFoodKey(barcode: barcode, productName: productName ?? '');
    return _savedFoods.any(
      (f) =>
          savedFoodKey(barcode: f.barcode, productName: f.productName) == key,
    );
  }

  Future<void> toggleSave(ScanResult scanData) async {
    if (_disposed) return;
    final session = _sessionVersion;
    await _repository.toggleSaveFood(scanData);
    if (_disposed || session != _sessionVersion) return;
    _appStateService.notifySavedFoodsUpdated();
    await _pendingRefresh;
  }

  void _resetSession() {
    if (_disposed) return;
    _sessionVersion++;
    _loadVersion++;
    _savedFoods = [];
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _authSubscription?.cancel();
    _appStateService.savedFoodsUpdated.removeListener(_onSavedFoodsUpdated);
    _appStateService.sessionReset.removeListener(_resetSession);
    super.dispose();
  }
}
