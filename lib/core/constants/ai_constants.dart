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
  static const String healthAssessment = 'HEALTH_ASSESSMENT';
  static const String mealRating = 'MEAL_RATING';
  static const String swapRequest = 'SWAP_REQUEST';
  static const String completeAnalysis = 'COMPLETE_ANALYSIS';
  static const String ingredientAnalysis = 'INGREDIENT_ANALYSIS';
  static const String productIdentification = 'PRODUCT_IDENTIFICATION';
  static const String nutritionComparison = 'NUTRITION_COMPARISON';
  static const String foodRecommendation = 'FOOD_RECOMMENDATION';
  static const String generalImageAnalysis = 'GENERAL_IMAGE_ANALYSIS';

  static const List<String> all = [
    mealRecognition,
    healthAssessment,
    mealRating,
    swapRequest,
    completeAnalysis,
    ingredientAnalysis,
    productIdentification,
    nutritionComparison,
    foodRecommendation,
    generalImageAnalysis,
  ];
}
