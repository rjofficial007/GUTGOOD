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
  ];
}
