import 'dart:convert';
import 'dart:typed_data';

import 'package:gutgood/core/ai/client/ai_client.dart';
import 'package:gutgood/core/ai/prompts/prompt_catalog.dart';
import 'package:gutgood/core/ai/protocol/ai_constants.dart';
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
  /// Classifies an image turn. [modeHint] is the UI entry point
  /// (`ScannerMode.name` / attachment source): when it names a known mode,
  /// the vision round-trip is skipped and only the text intent resolves
  /// (keyword fast-path first, model only on miss). Null/unknown hints —
  /// gallery, legacy callers — still run the full vision classification.
  Future<AiClassificationResult> classifyImage({required Uint8List imageBytes, String? userText, String? modeHint});
  Future<String> classifyTextIntent({required String userText, String? historySummary});
}

class AiClassifierServiceImpl implements AiClassifierService {
  AiClassifierServiceImpl({required AiClient aiService}) : _aiService = aiService;
  final AiClient _aiService;

  /// UI entry-point → image-mode map (K-3/P2-3). The scanner's dedicated
  /// modes already know what the bytes are — re-detecting that with a vision
  /// call doubles vision bytes/tokens on the turn. Anything unmapped (gallery,
  /// unknown, legacy) returns null and keeps the vision classification.
  static String? _imageModeForHint(String? hint) => switch (hint?.trim().toLowerCase()) {
    'food' => ImageMode.food,
    'menu' => ImageMode.restaurantMenu,
    'label' => ImageMode.ingredientsLabel,
    'barcode' => ImageMode.productBarcode,
    _ => null,
  };

  @override
  Future<AiClassificationResult> classifyImage({required Uint8List imageBytes, String? userText, String? modeHint}) async {
    AppLogger.ai('AiClassifier: Starting image classification');

    // 🚀 Professional Override: If the user sends the default gallery/food prompt,
    // force COMPLETE_ANALYSIS immediately to save tokens and ensure 100% consistency.
    final normalizedText = userText?.trim().toLowerCase() ?? '';
    if (normalizedText == 'what am i getting from this?' || normalizedText == 'what do you think of this meal?') {
      AppLogger.ai('AiClassifier: Detected default food/gallery prompt. Forcing COMPLETE_ANALYSIS.');
      return const AiClassificationResult(imageMode: 'FOOD', intent: 'COMPLETE_ANALYSIS', confidence: 1.0);
    }

    // K-3: trust the UI mode hint. Intent still resolves from text (free
    // keyword fast-path, model only on miss), but the vision round-trip —
    // the blocking, token-heavy half of the old call — is gone.
    final hintedMode = _imageModeForHint(modeHint);
    if (hintedMode != null) {
      final trimmed = userText?.trim() ?? '';
      final intent = trimmed.isEmpty ? UserIntent.completeAnalysis : await classifyTextIntent(userText: userText!);
      AppLogger.ai('AiClassifier: UI hint "$modeHint" → $hintedMode (vision call skipped).');
      return AiClassificationResult(imageMode: hintedMode, intent: intent, confidence: 1.0, reason: 'ui-hint');
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

  /// Phrasings resolved on-device instead of by a model call.
  ///
  /// Every text-only turn used to pay a full round trip to the model purely to
  /// pick a prompt, and streaming cannot start until that returns (~0.5-1.5 s
  /// of dead time before the first token). These patterns cover the phrasings
  /// that dominate real traffic. Unmatched wording falls back to the general
  /// analysis prompt, avoiding a second model round trip before chat. Ordered
  /// most-specific first.
  static const Map<String, List<String>> _intentKeywords = {
    UserIntent.mealRating: ['rate my', 'rate this', 'how did i do', 'give me a score', 'score this', 'grade this', 'out of ten', 'how is my lunch', 'thoughts on that lunch', 'thoughts on my lunch'],
    UserIntent.healthAssessment: ['is this healthy', 'is this balanced', 'is this good for me', 'good for my gut', 'should i eat this'],
    UserIntent.nutritionAnalysis: ['how many calories', 'how much protein', 'how many carbs', 'how much sugar', 'nutrition facts', 'macros'],
    UserIntent.mealPlanning: ['what should i eat', 'what can i have for', 'plan my', 'meal plan'],
    UserIntent.menuRecommendation: ['what should i order', 'what to order', 'best thing on the menu'],
    UserIntent.swapRequest: ['what should i improve', 'suggest a swap', 'what to swap', 'make it healthier', 'healthier alternative', 'instead of this', 'better option'],
    UserIntent.symptomAnalysis: ['bloat', 'cramp', 'nausea', 'constipat', 'diarrh', 'heartburn', 'acid reflux', 'stomach', 'symptom', 'how am i doing', 'i feel', 'feeling', 'tired'],
  };

  @override
  Future<String> classifyTextIntent({required String userText, String? historySummary}) {
    AppLogger.ai('AiClassifier: Starting text intent detection');

    final normalizedText = userText.trim().toLowerCase();

    // Fast-path client overrides for common user intent phrases
    if (normalizedText == 'what am i getting from this?' || normalizedText == 'what do you think of this meal?') {
      return Future.value(UserIntent.completeAnalysis);
    }

    for (final entry in _intentKeywords.entries) {
      for (final keyword in entry.value) {
        if (normalizedText.contains(keyword)) {
          // No model call, so the reply can start streaming immediately.
          AppLogger.ai('AiClassifier: fast-path intent ${entry.key} (matched "$keyword")');
          return Future.value(entry.key);
        }
      }
    }

    // Intent is only used to choose a prompt. If no deterministic rule matches,
    // let the main response model handle the request with the general analysis
    // prompt instead of paying for a second AI round trip first.
    AppLogger.ai('AiClassifier: no local intent match; using ${UserIntent.completeAnalysis} without a classifier call.');
    return Future.value(UserIntent.completeAnalysis);
  }
}
