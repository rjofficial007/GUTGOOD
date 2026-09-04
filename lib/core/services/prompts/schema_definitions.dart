import 'package:gutgood/core/constants/ai_constants.dart';

/// Canonical JSON schema definitions shared by EVERY prompt builder.
///
/// Why this file exists:
/// Previously `prompts.dart` and `mode_prompts.dart` each hand-wrote their
/// own copy of the SCAN / MEAL / SYMPTOM / SWAPS schemas, and they drifted
/// out of sync (novaGroup as `"1-4"` string in one place, `1` int in
/// another; ingredients as bare strings in one place, `{name, impact,
/// colorName, confidence}` in another). That drift is what made
/// `_ITag`/`getIngredientImpactLabel` in the UI silently fall back to
/// "uncolored" ingredient chips for scans that came from a prompt variant
/// that never asked for `colorName`.
///
/// Single source of truth from now on: every prompt builder interpolates
/// these constants instead of writing its own JSON example.
///
/// `image_mode` and `intent` enum values below are generated from
/// [ImageMode.all] / [UserIntent.all] (`ai_constants.dart`) rather than
/// hand-typed, so this schema, the image classification prompt, and the
/// intent detection prompt can never drift into three different vocabularies
/// again.
class SchemaDefinitions {
  SchemaDefinitions._();

  /// Canonical ingredient shape. `colorName` MUST always be present so the
  /// UI can key off it consistently regardless of which mode produced it.
  static const String ingredientSchema = '''
    {
      "name": "string",
      "impact": "string",
      "colorName": "red|orange|low",
      "confidence": 0.0
    }''';

  static String get unifiedDataSchema =>
      '''
[GUTGOOD_DATA]
{
  "image_mode": "${ImageMode.all.join('|')}",
  "intent": "${UserIntent.all.join('|')}",
  "scan": {
    "productName": "string|null",
    "brand": "string|null",
    "category": "food|meal|menu|label|packaging|non-food",
    "servingSize": "string|null",
    "badge": "string|null",
    "score": 0,
    "time": "ISO8601 string",
    "impactType": "positive|neutral|negative",
    "nutriscore": "A|B|C|D|E|null",
    "novaGroup": 1,
    "nutritionEstimated": false,
    "nutrientLevels": {
      "sugars": "low|moderate|high|unknown",
      "salt": "low|moderate|high|unknown",
      "fat": "low|moderate|high|unknown",
      "saturated-fat": "low|moderate|high|unknown"
    },
    "nutrients": {
      "calories": null,
      "fat": null,
      "saturatedFat": null,
      "carbs": null,
      "sugars": null,
      "fiber": null,
      "proteins": null,
      "salt": null
    },
    "allergens": "summary string",
    "additives": "summary string",
    "impacts": ["string"],
    "ingredients": [
$ingredientSchema
    ],
    "impact": "narrative summary",
    "cycleInsight": {
      "phase": "string",
      "description": "string",
      "tags": [
        {
          "text": "string",
          "icon": "zap|leaf|sparkle|activity",
          "color": "string"
        }
      ]
    }
  },
  "menu": {
    "restaurantName": "string|null",
    "categories": ["string"],
    "menuItems": [
      {
        "name": "string",
        "description": "string",
        "price": "string|null",
        "category": "string|null",
        "ingredients": ["string"],
        "dietaryTags": ["string"],
        "estimatedNutrition": "object|null",
        "gutImpact": "string|null"
      }
    ],
    "detectedText": "string|null",
    "location": "string|null"
  },
  "meal": {
    "mealType": "string",
    "items": [{"name": "string", "confidence": 0.0, "observation": "string"}],
    "time": "ISO8601 string",
    "balance": {"protein": "string", "fiber": "string", "fat": "string"},
    "workingWell": ["string"],
    "missingOrCouldAdd": ["string"],
    "sensitivityNotes": ["string"],
    "summary": "string"
  },
  "symptoms": [
    {
      "symptom": "string",
      "severity": 1,
      "energyLevel": 1,
      "time": "ISO8601 string",
      "mood": "string",
      "notes": "string"
    }
  ],
  "swaps": [
    {
      "title": "string",
      "subtitle": "string",
      "tag": "BETTER CHOICE",
      "badge": "string",
      "imageKeyword": "string",
      "isBlackBadge": true
    }
  ],
  "metadata": {
    "confidence": 0.0,
    "requiresPersistence": true
  }
}
[/GUTGOOD_DATA]''';

  static String get typeRules =>
      '''
SCHEMA TYPE RULES (apply to [GUTGOOD_DATA] JSON block)
- image_mode: one of ${ImageMode.all.map((v) => '"$v"').join(', ')}.
- intent: one of ${UserIntent.all.map((v) => '"$v"').join(', ')}.
- category: "food", "meal", "menu", "label", "packaging", or "non-food".
- novaGroup: integer 1-4, or JSON null.
- score: integer 0-100. Never null. For meals or unidentified products, you MUST ESTIMATE a score based on metabolic balance, processing levels, and ingredients.
- nutriscore: "A","B","C","D","E", or JSON null.
- time: ALWAYS ISO 8601 format string.
- symptoms: ALWAYS an array of OBJECTS (not strings). Each object MUST have at minimum a "symptom" field.
- Any value you cannot determine uses JSON null (or [] for arrays).
- To prevent response truncation, limit ingredients to top 10 items.
- metadata.confidence: REQUIRED float 0.0-1.0 representing how confident you are in the scan/meal/symptom data you extracted (not the conversational text). Use LOW confidence (below 0.6) when the image is blurry/ambiguous, the product could not be identified, or you are guessing at nutrition/ingredients without real evidence. The app will NOT silently save low-confidence data as confirmed history, so err on the side of an honest, lower number rather than inflating it.
- scan.nutritionEstimated: REQUIRED boolean. Set this to `true` whenever the "nutrients"/"nutrientLevels"/"novaGroup" fields are a visually-grounded APPROXIMATION rather than a label-sourced/barcode-sourced fact (this is the normal case for any home-cooked or unpackaged meal identified from a photo — see the estimation exception above). Set it to `false` only when those values came from an actual product label, barcode lookup, or menu nutrition data. The app uses this flag to visually label estimated macros as "Estimated" instead of presenting them with the same authority as a scanned fact.
''';
}
