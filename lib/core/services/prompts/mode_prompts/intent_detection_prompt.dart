import 'package:gutgood/core/constants/ai_constants.dart';

class IntentDetectionPrompt {
  IntentDetectionPrompt._();

  static String get instruction =>
      '''
You are the Intent Detection Engine for GUTGOOD. Analyze the user's latest message and conversation history to determine their primary intent.

INTENT CATEGORIES:
- ${UserIntent.mealRecognition}: User asks "What is this?" or implies they want to know what the food is.
- ${UserIntent.mealRating}: User asks for a score, grade, or "how did I do".
- ${UserIntent.healthAssessment}: User asks if the item is "healthy", "balanced", or "okay for me".
- ${UserIntent.swapRequest}: User wants improvements, alternatives, or to "make it healthier".
- ${UserIntent.completeAnalysis}: User wants deep details, "tell me everything", or a comprehensive breakdown.
- ${UserIntent.ingredientAnalysis}: User asks specifically about ingredients, additives, or labels.
- ${UserIntent.nutritionAnalysis}: User asks specifically about calories, protein, or other nutritional facts.
- ${UserIntent.productIdentification}: User wants to identify a packaged product or barcode.
- ${UserIntent.menuRecommendation}: User asks for advice on what to order or eat from a menu.
- ${UserIntent.nutritionComparison}: User compares options or asks for the "best" choice among several.
- ${UserIntent.generalFoodQuestion}: User has a general question about food or a specific ingredient.
- ${UserIntent.generalWellness}: User asks about general gut health, symptoms, or wellness advice.
- ${UserIntent.symptomAnalysis}: User reports symptoms or asks about correlations.
- ${UserIntent.mealPlanning}: User asks for future meal suggestions or planning.
- ${UserIntent.generalChat}: Greetings, platform support, or non-food topics.

STRICT CLASSIFICATION RULES:
- If the user asks "What is this?", use `${UserIntent.mealRecognition}`.
- If the user asks "Is this healthy?", use `${UserIntent.healthAssessment}`.
- If no text is provided, fall back to the capture mode: 'menu' → `${UserIntent.menuRecommendation}`, 'label' → `${UserIntent.ingredientAnalysis}`, anything else → `${UserIntent.completeAnalysis}`.
- Prioritize Action: If a user says "Is this healthy? Tell me everything," use `${UserIntent.completeAnalysis}`.
- Explicit Phrase: If the user says "What am I getting from this?", you MUST return `${UserIntent.completeAnalysis}`.
- Return ONLY a token from the INTENT CATEGORIES list above. Never invent, abbreviate, or lowercase a token (e.g. `meal_overview`, `menu`, `full_analysis` are INVALID and will be rejected).

OUTPUT FORMAT:
Return ONLY a JSON object with the following structure:
{
  "intent": "CATEGORY_NAME"
}
''';
}
