import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/errors/app_failure.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/network_error_classifier.dart';
import 'package:gutgood/features/scanner/domain/repositories/scanner_repository.dart';
import 'package:gutgood/infrastructure/firebase/firestore/auth_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/storage_service.dart';
import 'package:gutgood/infrastructure/open_food_facts/off_service.dart';
import 'package:uuid/uuid.dart';

class ScannerNotifier with ChangeNotifier {
  ScannerNotifier({required ScannerRepository repository, required AuthFirestoreService authFirestoreService, required OffService offService, required StorageService storageService, VoidCallback? onScanCompleted})
    : _repository = repository,
      _authFirestoreService = authFirestoreService,
      _offService = offService,
      _storageService = storageService,
      _onScanCompleted = onScanCompleted;
  final ScannerRepository _repository;
  final AuthFirestoreService _authFirestoreService;
  final OffService _offService;
  final StorageService _storageService;
  final VoidCallback? _onScanCompleted;

  bool _isProcessing = false;
  bool _isAnalyzing = false;
  bool _lastErrorWasOffline = false;
  AppFailure? _lastFailure;

  bool get isProcessing => _isProcessing;
  bool get isAnalyzing => _isAnalyzing;
  AppFailure? get lastFailure => _lastFailure;

  /// True when the most recent scan op failed from a reachability error.
  /// Scan methods return null on ANY failure, erasing the cause — consult
  /// this to show "you're offline" instead of "product not found".
  bool get lastErrorWasOffline => _lastErrorWasOffline;

  void _recordFailure(Object error, StackTrace stackTrace) {
    final isNetworkFailure = isOfflineError(error);
    _lastFailure = AppFailure.fromError(
      error,
      stackTrace: stackTrace,
      type: isNetworkFailure ? FailureType.network : FailureType.unknown,
    );
    _lastErrorWasOffline = isNetworkFailure;
  }

  /// Fetches ground-truth data from Open Food Facts without performing AI analysis.
  Future<OffProduct?> fetchBarcodeProduct(String barcode) async {
    _isProcessing = true;
    _lastErrorWasOffline = false;
    _lastFailure = null;
    notifyListeners();
    try {
      final product = await _repository.getProductByBarcode(barcode);
      return product;
    } catch (e, st) {
      _recordFailure(e, st);
      AppLogger.error('ScannerNotifier: Failed to fetch product data', error: e, stackTrace: st);
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Performs AI orchestration and deterministic scoring for a fetched product.
  Future<ScanResult?> analyzeBarcodeProduct(OffProduct product, {Uint8List? capturedImage}) async {
    _isAnalyzing = true;
    _lastErrorWasOffline = false;
    _lastFailure = null;
    notifyListeners();

    final scanId = const Uuid().v4();

    try {
      final profile = await _authFirestoreService.getUserMetadata();
      final goals = profile?.goals ?? [];
      final sensitivities = profile?.sensitivities ?? [];
      final lifestyle = profile?.lifestyle ?? [];
      final cyclePhase = (profile?.cycleSyncEnabled == true) ? (profile?.cyclePhase ?? 'Luteal Phase') : 'Not specified';

      // P0-3: OFF was already fetched to render the preview, but a fresh
      // personal scan still short-circuits the AI call + upload + new docs.
      final cached = await _repository.getCachedBarcodeScan(barcode: product.barcode ?? '', sensitivities: sensitivities);
      if (cached != null) {
        return cached;
      }

      String? userImageUrl;
      if (capturedImage != null) {
        userImageUrl = await _storageService.uploadFoodImage(capturedImage);
      }

      List<OffProduct>? alternatives;
      try {
        alternatives = await _offService.getBetterAlternatives(product.categoryTag, product.nutriscore);
      } catch (e) {
        AppLogger.warning('ScannerNotifier: Alternatives fetch failed');
      }

      final result = await _repository.analyzeProductWithAi(product: product, goals: goals, sensitivities: sensitivities, lifestyle: lifestyle, cyclePhase: cyclePhase, alternatives: alternatives);

      final scan = result.scan;
      if (scan != null) {
        final finalScan = scan.copyWith(source: 'barcode', userImageUrl: userImageUrl, scanId: scanId);
        final finalResult = result.copyWith(scan: finalScan);

        AppLogger.info('ScannerNotifier: Saving barcode scan result for ${finalScan.productName} (ID: $scanId)');
        await _repository.saveScanResult(finalResult, userImageUrl: userImageUrl, scanId: scanId);

        // 🟢 Trigger streak celebration if one is pending (Scan finished)
        _onScanCompleted?.call();

        return finalScan;
      }
      return null;
    } catch (e, st) {
      _recordFailure(e, st);
      AppLogger.error('ScannerNotifier: AI analysis failed for product ${product.productName}', error: e, stackTrace: st);
      return null;
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  Future<ScanResult?> processImage(Uint8List bytes, {String? mode, String? userText}) async {
    _isProcessing = true;
    _lastErrorWasOffline = false;
    _lastFailure = null;
    notifyListeners();

    final scanId = const Uuid().v4();

    try {
      final userImageUrl = await _storageService.uploadFoodImage(bytes);

      // Compress ONCE for the vision pipeline and reuse these bytes for both
      // the classifier and the analysis call. Previously the raw camera/gallery
      // bytes (1.5-5 MB) were sent twice: the proxy silently dropped images
      // above ~1.2 MB, so the model analysed nothing and the scan still failed.
      final aiBytes = await _storageService.compressForAi(bytes);

      final profile = await _authFirestoreService.getUserMetadata();
      final cyclePhase = (profile?.cycleSyncEnabled == true) ? (profile?.cyclePhase ?? 'Luteal Phase') : 'Not specified';

      final result = await _repository.analyzeImageWithAi(
        imageBytes: aiBytes,
        mode: mode ?? 'unknown',
        goals: profile?.goals ?? [],
        sensitivities: profile?.sensitivities ?? [],
        lifestyle: profile?.lifestyle ?? [],
        cyclePhase: cyclePhase,
        userText: userText,
      );

      final scan = result.scan;
      if (scan != null) {
        final finalScan = scan.copyWith(source: result.imageMode ?? mode ?? 'unknown', userImageUrl: userImageUrl, scanId: scanId);
        final finalResult = result.copyWith(scan: finalScan);

        AppLogger.info('ScannerNotifier: Saving image scan result for ${finalScan.productName} (detected: ${result.imageMode}, ID: $scanId)');
        await _repository.saveScanResult(finalResult, userImageUrl: userImageUrl, scanId: scanId);

        // 🟢 Trigger streak celebration if one is pending (Scan finished)
        _onScanCompleted?.call();

        return finalScan;
      }
      return null;
    } catch (e, st) {
      _recordFailure(e, st);
      AppLogger.error('ScannerNotifier: Image processing failed', error: e, stackTrace: st);
      return null;
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
