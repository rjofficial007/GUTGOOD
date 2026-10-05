/// Confidence-gating thresholds for AI-derived data.
///
/// GutGood auto-saves AI-extracted data straight into the user's permanent
/// history (scan_history / journal_logs) with no manual confirmation step.
/// For ordinary meal/symptom extraction, low confidence is kept chat-only so
/// it cannot silently corrupt gut-health pattern detection; concrete scans are
/// the deliberate consumed-food exception and retain their evidence metadata.
class AiConfidenceThresholds {
  AiConfidenceThresholds._();

  /// Minimum `metadata.confidence` (0.0-1.0) required before non-scan
  /// meal/symptom data extracted by the AI is auto-persisted as confirmed
  /// history. Concrete scans intentionally bypass this gate: the product
  /// records every completed scan as both scan history and consumed food,
  /// while retaining the confidence value as provenance.
  static const double minPersistenceConfidence = 0.6;
}

class ImageMode {
  ImageMode._();

  static const String food = 'FOOD';
  static const String restaurantMenu = 'RESTAURANT_MENU';
  static const String productBarcode = 'PRODUCT_BARCODE';
  static const String ingredientsLabel = 'INGREDIENTS_LABEL';
  static const String nutritionLabel = 'NUTRITION_LABEL';
  static const String packagedProduct = 'PACKAGED_PRODUCT';
  static const String foodRecipe = 'FOOD_RECIPE';
  static const String other = 'OTHER';
  static const String unknown = 'UNKNOWN';

  static const List<String> all = [
    food,
    restaurantMenu,
    productBarcode,
    ingredientsLabel,
    nutritionLabel,
    packagedProduct,
    foodRecipe,
    other,
    unknown,
  ];
}

class UserIntent {
  UserIntent._();

  static const String mealRecognition = 'MEAL_RECOGNITION';
  static const String mealRating = 'MEAL_RATING';
  static const String healthAssessment = 'HEALTH_ASSESSMENT';
  static const String improvementRequest = 'IMPROVEMENT_REQUEST';
  static const String swapRequest = 'SWAP_REQUEST';
  static const String completeAnalysis = 'COMPLETE_ANALYSIS';
  static const String ingredientAnalysis = 'INGREDIENT_ANALYSIS';
  static const String nutritionAnalysis = 'NUTRITION_ANALYSIS';
  static const String productIdentification = 'PRODUCT_IDENTIFICATION';
  static const String menuRecommendation = 'MENU_RECOMMENDATION';
  static const String nutritionComparison = 'NUTRITION_COMPARISON';
  static const String generalFoodQuestion = 'GENERAL_FOOD_QUESTION';
  static const String generalWellness = 'GENERAL_WELLNESS';
  static const String generalImageAnalysis = 'GENERAL_IMAGE_ANALYSIS';
  static const String symptomAnalysis = 'SYMPTOM_ANALYSIS';
  static const String mealPlanning = 'MEAL_PLANNING';
  static const String generalChat = 'GENERAL_CHAT';

  /// Canonical list of every intent value GutGood's prompts/classifiers can
  /// produce. This is the single source of truth: `schema_definitions.dart`'s
  /// [GUTGOOD_DATA].intent enum, `intent_detection_prompt.dart`'s category
  /// list, and any code that switches on an intent string should all trace
  /// back to these constants instead of hand-writing their own copy (three
  /// independently drifting vocabularies previously existed here).
  static const List<String> all = [
    mealRecognition,
    mealRating,
    healthAssessment,
    improvementRequest,
    swapRequest,
    completeAnalysis,
    ingredientAnalysis,
    nutritionAnalysis,
    productIdentification,
    menuRecommendation,
    nutritionComparison,
    generalFoodQuestion,
    generalWellness,
    generalImageAnalysis,
    symptomAnalysis,
    mealPlanning,
    generalChat,
  ];
}

/// Schema/envelope versioning (§17). Every AI-produced durable doc stamps
/// [schemaVersion] as `v` (tolerant readers ignore unknown fields; future
/// writers bump this when a shape changes). The [GUTGOOD_DATA] envelope may
/// also carry `v`; [AiResponseValidator] rejects envelopes newer than this.
class AiVersions {
  AiVersions._();

  static const int schemaVersion = 1;

  /// Insights-prompt version, stamped on insight docs (P2-9/P2-10).
  /// 2 = de-presented schema: the LLM emits data only, Dart owns visuals.
  /// 3 = v2 Real Tokens UI blocks (`improving`, `watch`, `smartSwap`,
  ///     `topHealing/topTrigger.whyPoints`). All tolerant reads.
  /// 7 = evidence-gated Insights output: combination candidates, deterministic
  ///     food-impact balance, and no unsupported mechanism fields.
  /// 8 = food-swap categories describe each alternative's food type for useful filters.
  /// 9 = request grounded, structured benefits for every food-swap alternative.
  static const int insightPromptVersion = 9;

  /// J-4 §17: chat builder (`Prompts.chatSystemInstruction`) version, stamped
  /// on ChatMessage + the scan/meal/symptom records extracted from chat turns.
  /// 1 = first versioned baseline (post-J-3 dedupe). Bump on any wording change.
  static const int chatPromptVersion = 1;

  /// J-4 §17: one-shot analysis builders (`visionAnalysisSystemInstruction`,
  /// `barcodeAnalysisSystemInstruction`, `productAnalysisPrompt`) version,
  /// stamped on ScanResults from the scanner flows. Builder identity comes
  /// from `ScanResult.source` ('chat' vs image-mode/barcode values).
  static const int visionPromptVersion = 1;

  // NOTE: the classifier (`imageClassificationInstruction`,
  // `intentDetectionInstruction`) and summarizer builders are intentionally
  // unversioned — routing-only / rolling summary, no versioned artifact.
}

/// §F envelope verdict: what the analyzed content fundamentally IS.
/// `non_food` (and explicit `uncertain`) blocks record persistence — the turn
/// stays chat-only. Absent verdict = legacy prompt output, allowed through.
class Verdict {
  Verdict._();

  static const String food = 'food';
  static const String nonFood = 'non_food';
  static const String uncertain = 'uncertain';

  static const List<String> all = [food, nonFood, uncertain];
}

/// Provenance of a journal log's [occurredAt] event time (P1-2).
/// Separate from [RecordProvenance]: this says where the TIME came from.
class OccurrenceProvenance {
  OccurrenceProvenance._();

  /// The user stated or picked the time.
  static const String user = 'user';

  /// The AI estimated the time from context ("last night", "at lunch").
  static const String aiEstimated = 'ai_estimated';
}

/// Provenance of a symptom record itself (P2-4): how it was detected.
/// `keyword_fallback` records are excluded from pattern corroboration until a
/// confirmation flow exists; they still render in chat/history.
class RecordProvenance {
  RecordProvenance._();

  /// Manually entered by the user.
  static const String user = 'user';

  /// Extracted from a structured AI data block.
  static const String aiExtracted = 'ai_extracted';

  /// Guessed by keyword-regex over user text (no structured AI entry).
  static const String keywordFallback = 'keyword_fallback';
}
