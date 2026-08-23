import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/off_product.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/services/firestore/auth_firestore_service.dart';
import 'package:gutgood/core/services/off_service.dart';
import 'package:gutgood/core/services/storage_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:gutgood/features/scanner/domain/repositories/scanner_repository.dart';
import 'package:uuid/uuid.dart';

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

    final scanId = const Uuid().v4();

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
      final lifestyle = profile?.lifestyle ?? [];
      final cyclePhase = (profile?.cycleSyncEnabled == true) ? (profile?.cyclePhase ?? 'Luteal Phase') : 'Not specified';

      List<OffProduct>? alternatives;
      try {
        alternatives = await _offService.getBetterAlternatives(product.categoryTag, product.nutriscore);
      } catch (e) {
        AppLogger.warning('ScannerNotifier: Alternatives fetch failed');
      }

      try {
        final result = await _repository.analyzeProductWithAi(
          product: product,
          goals: goals,
          sensitivities: sensitivities,
          lifestyle: lifestyle,
          cyclePhase: cyclePhase,
          alternatives: alternatives,
        );

        final finalResult = result.copyWith(source: 'barcode', userImageUrl: userImageUrl, scanId: scanId);
        AppLogger.info('ScannerNotifier: Saving barcode scan result for ${finalResult.productName} (ID: $scanId)');
        await _repository.saveScanResult(finalResult, userImageUrl: userImageUrl, scanId: scanId);

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

    final scanId = const Uuid().v4();

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

      final finalResult = result.copyWith(source: mode, userImageUrl: userImageUrl, scanId: scanId);
      AppLogger.info('ScannerNotifier: Saving image scan result for ${finalResult.productName} (mode: $mode, ID: $scanId)');
      await _repository.saveScanResult(finalResult, userImageUrl: userImageUrl, scanId: scanId);

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

  /// Orchestrates barcode scan handling including fallback to vision if allowed.
  Future<void> handleBarcodeScan(
    String barcode, {
    Uint8List? capturedImage,
    required String mode,
    required bool isBatchMode,
    required VoidCallback onScanStart,
    required Function(ScanResult result) onSuccess,
    required VoidCallback onProductNotFound,
    required Function(String message) onError,
    required Function(String message) onInfo,
    required VoidCallback onHaptic,
  }) async {
    _isProcessing = true;
    notifyListeners();
    onHaptic();

    if (!isBatchMode) {
      onScanStart();
    }

    try {
      final result = await processBarcode(barcode, capturedImage: capturedImage);

      if (result != null) {
        onSuccess(result);
      } else {
        // Fallback to image processing if product not in DB but image is available
        if (capturedImage != null) {
          onInfo(AppStrings.productNotFoundAnalyzing);
          final aiResult = await processImage(capturedImage, mode: mode);
          if (aiResult != null) {
            onSuccess(aiResult);
          } else {
            onError(AppStrings.couldNotAnalyzeVision);
          }
        } else {
          onProductNotFound();
        }
      }
    } on ScanAnalysisException {
      onError(AppStrings.productFoundAiFailed);
    } catch (e) {
      AppLogger.error('ScannerNotifier: handleBarcodeScan error', error: e);
      onError(AppStrings.failedToAnalyzeProduct);
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Handles photo capture logic, detecting barcodes if in barcode mode or proceeding with vision.
  Future<void> handlePhotoCapture({
    required Uint8List bytes,
    required String mode,
    required bool isBatchMode,
    required Future<String?> Function(String path) analyzeBarcodeInImage,
    required Function(String barcode, Uint8List image) onBarcodeFound,
    required Function(Uint8List image, String mode) onImageCaptured,
    required Function(String message) onError,
    required VoidCallback onHaptic,
  }) async {
    _isProcessing = true;
    notifyListeners();
    onHaptic();

    try {
      if (mode == 'barcode') {
        final tempFile = File('${Directory.systemTemp.path}/temp_barcode.png');
        await tempFile.writeAsBytes(bytes);

        final code = await analyzeBarcodeInImage(tempFile.path);

        try {
          if (tempFile.existsSync()) tempFile.deleteSync();
        } catch (e) {
          AppLogger.warning('ScannerNotifier: Temp file cleanup failed: $e');
        }

        if (code != null) {
          await onBarcodeFound(code, bytes);
        } else {
          onError(AppStrings.noBarcodeDetected);
        }
      } else {
        onImageCaptured(bytes, mode);
      }
    } catch (e) {
      AppLogger.error('ScannerNotifier: Photo capture error', error: e);
      onError(AppStrings.failedToAnalyzeProduct);
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
}
