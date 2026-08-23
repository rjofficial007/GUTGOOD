import 'dart:typed_data';

import 'package:gutgood/core/models/off_product.dart';
import 'package:gutgood/core/models/scan_result.dart';

abstract class ScannerRepository {
  Future<OffProduct?> getProductByBarcode(String barcode);
  Future<ScanResult> analyzeProductWithAi({
    required OffProduct product,
    required List<String> goals,
    required List<String> sensitivities,
    required List<String> lifestyle,
    required String cyclePhase,
    List<OffProduct>? alternatives,
  });
  Future<ScanResult> analyzeImageWithAi({
    required Uint8List imageBytes,
    required String mode,
    required List<String> goals,
    required List<String> sensitivities,
    required List<String> lifestyle,
    required String cyclePhase,
  });
  Future<void> saveScanResult(ScanResult result, {String? userImageUrl, String? scanId});
}

class ScanAnalysisException implements Exception {
  ScanAnalysisException(this.product);
  final OffProduct product;

  @override
  String toString() => r'ScanAnalysisException: AI analysis failed for ${product.productName}';
}
