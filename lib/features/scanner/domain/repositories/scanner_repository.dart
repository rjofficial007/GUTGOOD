import 'dart:typed_data';

import 'package:gutgood/core/models/ai_analysis_result.dart';
import 'package:gutgood/core/models/off_product.dart';
import 'package:gutgood/core/models/scan_result.dart';

abstract class ScannerRepository {
  /// Personal barcode cache window (P0-3): entries older than this fall
  /// through to a full OFF + AI analysis, which refreshes the entry on save.
  static const Duration barcodeCacheMaxAge = Duration(days: 30);

  Future<OffProduct?> getProductByBarcode(String barcode);

  /// Returns the stored scan for [barcode] when a fresh-enough entry exists,
  /// re-scored by the deterministic engine and re-flagged against the current
  /// [sensitivities]. Records a chat message + analytics only — no new
  /// scan_history or journal docs (a cache hit is a view, not a new log).
  /// Returns null on miss/staleness/error: callers fall through to the full
  /// pipeline. Never throws.
  Future<ScanResult?> getCachedBarcodeScan({required String barcode, required List<String> sensitivities});
  Future<AiAnalysisResult> analyzeProductWithAi({
    required OffProduct product,
    required List<String> goals,
    required List<String> sensitivities,
    required List<String> lifestyle,
    required String cyclePhase,
    List<OffProduct>? alternatives,
  });
  Future<AiAnalysisResult> analyzeImageWithAi({
    required Uint8List imageBytes,
    required String mode,
    required List<String> goals,
    required List<String> sensitivities,
    required List<String> lifestyle,
    required String cyclePhase,
    String? userText,
  });
  Future<void> saveScanResult(AiAnalysisResult result, {String? userImageUrl, String? scanId});
}

