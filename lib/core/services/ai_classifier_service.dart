import 'dart:convert';
import 'dart:typed_data';

import 'package:gutgood/core/services/ai_service.dart';
import 'package:gutgood/core/services/prompts.dart';
import 'package:gutgood/core/utils/logger_service.dart';

class AiClassificationResult {
  const AiClassificationResult({required this.imageMode, required this.intent, required this.confidence, this.reason});

  factory AiClassificationResult.fromMap(Map<String, dynamic> map) => AiClassificationResult(
    imageMode: map['image_mode'] as String? ?? 'UNKNOWN',
    intent: map['intent'] as String? ?? 'COMPLETE_ANALYSIS',
    confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
    reason: map['reason'] as String?,
  );

  final String imageMode;
  final String intent;
  final double confidence;
  final String? reason;

  Map<String, dynamic> toMap() => {'image_mode': imageMode, 'intent': intent, 'confidence': confidence, 'reason': reason};

  @override
  String toString() => 'AiClassificationResult(mode: $imageMode, intent: $intent, confidence: $confidence)';
}

abstract class AiClassifierService {
  Future<AiClassificationResult> classifyImage({required Uint8List imageBytes, String? userText});
  Future<String> classifyTextIntent({required String userText, String? historySummary});
}

class AiClassifierServiceImpl implements AiClassifierService {
  AiClassifierServiceImpl({required AiService aiService}) : _aiService = aiService;
  final AiService _aiService;

  @override
  Future<AiClassificationResult> classifyImage({required Uint8List imageBytes, String? userText}) async {
    AppLogger.ai('AiClassifier: Starting image classification');

    // 🚀 Professional Override: If the user sends the default gallery/food prompt,
    // force COMPLETE_ANALYSIS immediately to save tokens and ensure 100% consistency.
    final normalizedText = userText?.trim().toLowerCase() ?? '';
    if (normalizedText == 'what am i getting from this?' || normalizedText == 'what do you think of this meal?') {
      AppLogger.ai('AiClassifier: Detected default food/gallery prompt. Forcing COMPLETE_ANALYSIS.');
      return const AiClassificationResult(imageMode: 'FOOD', intent: 'COMPLETE_ANALYSIS', confidence: 1.0);
    }

    final prompt = userText != null && userText.isNotEmpty ? 'Analyze this image. User message: "$userText"' : 'Analyze this image.';

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
      // Fallback to Complete Analysis
      return const AiClassificationResult(imageMode: 'UNKNOWN', intent: 'COMPLETE_ANALYSIS', confidence: 0.0, reason: 'Classification error');
    }
  }

  @override
  Future<String> classifyTextIntent({required String userText, String? historySummary}) async {
    AppLogger.ai('AiClassifier: Starting text intent detection');

    final normalizedText = userText.trim().toLowerCase();

    // Fast-path client overrides for common user intent phrases
    if (normalizedText == 'what am i getting from this?' || normalizedText == 'what do you think of this meal?') {
      return 'COMPLETE_ANALYSIS';
    }
    if (normalizedText.contains('rate my') || normalizedText.contains('rate this') || normalizedText.contains('how did i do') || normalizedText.contains('give me a score')) {
      return 'MEAL_RATING';
    }
    if (normalizedText.contains('is this healthy') || normalizedText.contains('is this balanced') || normalizedText.contains('is this good for me')) {
      return 'HEALTH_ASSESSMENT';
    }
    if (normalizedText.contains('bloat') ||
        normalizedText.contains('tired') ||
        normalizedText.contains('symptom') ||
        normalizedText.contains('how am i doing') ||
        normalizedText.contains('stomach') ||
        normalizedText.contains('feeling')) {
      return 'SYMPTOM_ANALYSIS';
    }
    if (normalizedText.contains('what should i improve') || normalizedText.contains('suggest a swap') || normalizedText.contains('what to swap') || normalizedText.contains('make it healthier')) {
      return 'SWAP_REQUEST';
    }

    final prompt = historySummary != null ? 'History Summary: $historySummary\n\nUser Message: "$userText"' : 'User Message: "$userText"';

    try {
      final intent = await _aiService.generateContent(systemInstruction: Prompts.intentDetectionInstruction, prompt: prompt, usageType: 'system');

      final result = intent.trim().toUpperCase();
      AppLogger.info('AiClassifier: Text Intent -> $result');
      return result;
    } catch (e) {
      AppLogger.error('AiClassifier: Text intent detection failed', error: e);
      return 'COMPLETE_ANALYSIS';
    }
  }
}
