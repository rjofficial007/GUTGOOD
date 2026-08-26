import 'dart:convert';
import 'dart:typed_data';

import 'package:gutgood/core/services/ai_service.dart';
import 'package:gutgood/core/services/prompts.dart';
import 'package:gutgood/core/utils/logger_service.dart';

class AiClassificationResult {
  const AiClassificationResult({
    required this.imageMode,
    required this.intent,
    required this.confidence,
    this.reason,
  });

  factory AiClassificationResult.fromMap(Map<String, dynamic> map) => AiClassificationResult(
    imageMode: map['image_mode'] as String? ?? 'UNKNOWN',
    intent: map['intent'] as String? ?? 'GENERAL_IMAGE_ANALYSIS',
    confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
    reason: map['reason'] as String?,
  );

  final String imageMode;
  final String intent;
  final double confidence;
  final String? reason;

  Map<String, dynamic> toMap() => {
    'image_mode': imageMode,
    'intent': intent,
    'confidence': confidence,
    'reason': reason,
  };

  @override
  String toString() => 'AiClassificationResult(mode: $imageMode, intent: $intent, confidence: $confidence)';
}

abstract class AiClassifierService {
  Future<AiClassificationResult> classifyImage({required Uint8List imageBytes, String? userText});
}

class AiClassifierServiceImpl implements AiClassifierService {
  AiClassifierServiceImpl({required AiService aiService}) : _aiService = aiService;
  final AiService _aiService;

  @override
  Future<AiClassificationResult> classifyImage({required Uint8List imageBytes, String? userText}) async {
    AppLogger.ai('AiClassifier: Starting image classification');
    
    final prompt = userText != null && userText.isNotEmpty 
        ? 'Analyze this image. User message: "$userText"' 
        : 'Analyze this image.';

    try {
      final jsonResponse = await _aiService.generateContent(
        imageBytes: imageBytes,
        systemInstruction: Prompts.imageClassificationInstruction,
        prompt: prompt,
        usageType: 'system', // Use system type for classification calls
      );

      final decoded = jsonDecode(jsonResponse) as Map<String, dynamic>;
      final result = AiClassificationResult.fromMap(decoded);
      
      AppLogger.info('AiClassifier: Result -> $result');
      return result;
    } catch (e) {
      AppLogger.error('AiClassifier: Classification failed', error: e);
      // Fallback to unknown
      return const AiClassificationResult(
        imageMode: 'UNKNOWN',
        intent: 'GENERAL_IMAGE_ANALYSIS',
        confidence: 0.0,
        reason: 'Classification error',
      );
    }
  }
}
