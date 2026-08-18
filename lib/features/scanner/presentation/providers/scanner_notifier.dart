import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/off_product.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/services/firestore/auth_firestore_service.dart';
import 'package:gutgood/core/services/off_service.dart';
import 'package:gutgood/core/services/storage_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:gutgood/features/scanner/domain/repositories/scanner_repository.dart';

class ScannerNotifier with ChangeNotifier {
  ScannerNotifier({required ScannerRepository repository, required AuthFirestoreService authFirestoreService, required OffService offService, required StorageService storageService})
    : _repository = repository,
      _authFirestoreService = authFirestoreService,
      _offService = offService,
      _storageService = storageService;
  final ScannerRepository _repository;
  final AuthFirestoreService _authFirestoreService;
  final OffService _offService;
  final StorageService _storageService;

  bool _isProcessing = false;
  ScanResult? _lastResult;

  bool get isProcessing => _isProcessing;
  ScanResult? get lastResult => _lastResult;

  /// Free-tier accounting: the AI call itself is counted server-side by the
  /// aiProxy (type = 'scan'). The client must not double-increment.
  Future<ScanResult?> processBarcode(String barcode, {Uint8List? capturedImage}) async {
    _isProcessing = true;
    notifyListeners();

    try {
      final product = await _repository.getProductByBarcode(barcode);
      if (product == null) return null;

      String? userImageUrl;
      if (capturedImage != null) {
        userImageUrl = await _storageService.uploadFoodImage(capturedImage);
      }

      final profile = await _authFirestoreService.getUserMetadata();
      final goals = profile?.goals ?? [];
      final sensitivities = profile?.sensitivities ?? [];
      final cyclePhase = (profile?.cycleSyncEnabled == true) ? (profile?.cyclePhase ?? 'Luteal Phase') : 'Not specified';

      List<OffProduct>? alternatives;
      try {
        alternatives = await _offService.getBetterAlternatives(product.categoryTag, product.nutriscore);
      } catch (e) {
        AppLogger.warning('ScannerNotifier: Alternatives fetch failed');
      }

      try {
        final result = await _repository.analyzeProductWithAi(product: product, goals: goals, sensitivities: sensitivities, cyclePhase: cyclePhase, alternatives: alternatives);

        final finalResult = result.copyWith(source: 'barcode', userImageUrl: userImageUrl);
        AppLogger.info('ScannerNotifier: Saving barcode scan result for ${finalResult.productName}');
        await _repository.saveScanResult(finalResult, userImageUrl: userImageUrl);

        _lastResult = finalResult;

        // 🟢 Trigger streak celebration if one is pending (Scan finished)
        sl<ProfileNotifier>().triggerPendingCelebration();

        return finalResult;
      } catch (e, st) {
        AppLogger.error('ScannerNotifier: AI analysis failed for known product ${product.productName}', error: e, stackTrace: st);
        throw ScanAnalysisException(product);
      }
    } on ScanAnalysisException {
      rethrow;
    } catch (e) {
      AppLogger.error('ScannerNotifier: Barcode processing failed', error: e);
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<ScanResult?> processImage(Uint8List bytes, {required String mode}) async {
    _isProcessing = true;
    notifyListeners();

    try {
      final userImageUrl = await _storageService.uploadFoodImage(bytes);

      final profile = await _authFirestoreService.getUserMetadata();
      final cyclePhase = (profile?.cycleSyncEnabled == true) ? (profile?.cyclePhase ?? 'Luteal Phase') : 'Not specified';

      final result = await _repository.analyzeImageWithAi(
        imageBytes: bytes,
        mode: mode,
        goals: profile?.goals ?? [],
        sensitivities: profile?.sensitivities ?? [],
        lifestyle: profile?.lifestyle ?? [],
        cyclePhase: cyclePhase,
      );

      final finalResult = result.copyWith(source: mode, userImageUrl: userImageUrl);
      AppLogger.info('ScannerNotifier: Saving image scan result for ${finalResult.productName} (mode: $mode)');
      await _repository.saveScanResult(finalResult, userImageUrl: userImageUrl);

      _lastResult = finalResult;

      // 🟢 Trigger streak celebration if one is pending (Scan finished)
      sl<ProfileNotifier>().triggerPendingCelebration();

      return finalResult;
    } catch (e) {
      AppLogger.error('ScannerNotifier: Image processing failed', error: e);
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
}
