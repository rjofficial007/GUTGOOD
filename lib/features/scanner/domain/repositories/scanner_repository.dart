import 'dart:typed_data';

import 'package:gutgood/core/models/ai_analysis_result.dart';
import 'package:gutgood/core/models/off_product.dart';

abstract class ScannerRepository {
  Future<OffProduct?> getProductByBarcode(String barcode);
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

class ScanAnalysisException implements Exception {
  ScanAnalysisException(this.product);
  final OffProduct product;

  @override
  String toString() => 'ScanAnalysisException: AI analysis failed for ${product.productName}';
}
