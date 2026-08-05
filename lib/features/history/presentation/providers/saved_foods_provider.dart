import 'package:flutter/material.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/features/history/domain/repositories/history_repository.dart';

class SavedFoodsProvider with ChangeNotifier {
  SavedFoodsProvider({
    required HistoryRepository repository,
    required AppStateService appStateService,
  })  : _repository = repository,
        _appStateService = appStateService {
    _loadSavedFoods();
    _appStateService.savedFoodsUpdated.addListener(_loadSavedFoods);
  }

  final HistoryRepository _repository;
  final AppStateService _appStateService;

  List<ScanResult> _savedFoods = [];
  bool _isLoading = false;

  List<ScanResult> get savedFoods => _savedFoods;
  bool get isLoading => _isLoading;

  Future<void> _loadSavedFoods() async {
    _isLoading = true;
    notifyListeners();
    try {
      _savedFoods = await _repository.getSavedFoods();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isSaved(String? productName, {String? barcode}) {
    if (barcode != null && barcode.isNotEmpty) {
      return _savedFoods.any((f) => f.barcode == barcode);
    }
    return _savedFoods.any((f) => f.productName == productName);
  }

  Future<void> toggleSave(ScanResult scanData) async {
    await _repository.toggleSaveFood(scanData);
    await _loadSavedFoods();
    _appStateService.notifySavedFoodsUpdated();
  }

  @override
  void dispose() {
    _appStateService.savedFoodsUpdated.removeListener(_loadSavedFoods);
    super.dispose();
  }
}
