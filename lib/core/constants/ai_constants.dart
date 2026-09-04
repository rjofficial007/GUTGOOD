/// Confidence-gating thresholds for AI-derived data.
///
/// GutGood auto-saves AI-extracted scan/meal/symptom data straight into the
/// user's permanent history (scan_history / journal_logs) with no manual
/// confirmation step. If the model itself reports low confidence in what it
/// extracted (e.g. a blurry photo, an unidentifiable product), we must NOT
/// silently treat that guess as confirmed ground truth — it would corrupt
/// gut-health pattern detection and insights built on top of it.
class AiConfidenceThresholds {
  AiConfidenceThresholds._();

  /// Minimum `metadata.confidence` (0.0-1.0) required before a scan/meal/
  /// symptom extracted by the AI is auto-persisted as confirmed history.
  /// Below this, the data is still shown to the user in chat (so nothing is
  /// hidden), but it is not written to scan_history/journal_logs, and the
  /// gut-health pattern engine's independent 3+ occurrence corroboration
  /// requirement (see PatternEngineService) is left untouched.
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

  static const List<String> all = [food, restaurantMenu, productBarcode, ingredientsLabel, nutritionLabel, packagedProduct, foodRecipe, other, unknown];
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
