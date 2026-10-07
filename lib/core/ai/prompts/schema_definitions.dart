import 'package:gutgood/core/ai/protocol/ai_constants.dart';

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
  /// `quantity` is optional but important: dose is what separates a meaningful
  /// concern from a trace ingredient, and it is the single most common
  /// complaint about competing scanners (they flag presence, ignore amount).
  static const String ingredientSchema = '''
    {
      "name": "string",
      "impact": "string",
      "colorName": "red|orange|low",
      "confidence": 0.0,
      "quantity": "string|null"
    }''';

  static String get unifiedDataSchema =>
      '''
[GUTGOOD_DATA]
{
  "image_mode": "${ImageMode.all.join('|')}",
  "intent": "${UserIntent.all.join('|')}",
  "v": 1,
  "verdict": "food|non_food|uncertain",
  "scan": {
    "productName": "string|null",
    "brand": "string|null",
    "category": "food|meal|menu|label|packaging|non-food",
    "badge": "string|null",
    "score": 0,
    "impactType": "positive|neutral|negative",
    "nutriscore": "A|B|C|D|E|null",
    "novaGroup": 1,
    "isOrganic": null,
    "nutritionEstimated": false,
    "nutritionBasis": "per_serving|per_100g|per_100ml|pictured_portion|null",
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
    "servingSize": "string|null",
    "servingsPerPack": "number|null",
    "portionEaten": "string|null",
    "allergens": "summary string",
    "additives": "summary string",
    "additiveItems": ["E-code or additive name per item, e.g. E621, E150d, Palm Oil"],
    "impacts": [{"title": "string", "level": "string", "color": "green|gold|red"}],
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
        "gutImpact": "string|null"
      }
    ],
    "detectedText": "string|null",
    "location": "string|null"
  },
  "meal": {
    "mealType": "string",
    "items": [{"name": "string", "confidence": 0.0, "observation": "string"}],
    "foodTags": ["dairy"],
    "time": "ISO8601 string (only when explicitly stated by the user; otherwise omit)",
    "balance": {"protein": "string", "fiber": "string", "fat": "string"},
    "workingWell": ["string"],
    "missingOrCouldAdd": ["string"],
    "sensitivityNotes": ["string"],
    "summary": "string"
  },
  "symptoms": [
    {
      "symptom": "string",
      "time": "ISO8601 string (only when explicitly stated by the user; otherwise omit)",
      "mood": "string (only when explicitly stated by the user)",
      "sleep": "string (only when explicitly stated by the user)",
      "notes": "string (user-reported details only)"
    }
  ],
  "swaps": [
    {
      "name": "specific alternative food or product",
      "reason": "short explanation for the card",
      "category": "food category",
      "tag": "short supported benefit or ALTERNATIVE",
      "imageKeyword": "food search phrase",
      "imageUrl": null,
      "barcode": null,
      "nutriscore": null,
      "benefitTags": ["short supported benefit"],
      "structuredBenefits": [{"title": "short label", "description": "supported explanation", "icon": "leaf|dumbbell|arrow_down|flame"}],
      "whyBetterOption": "specific comparison with the original food, including relevant tradeoffs",
      "nutrition": {"calories": null, "protein": null, "totalFat": null, "fiber": null, "basis": null}
    }
  ],
  "insight": {
    "summary": "ONE sentence: the single most useful thing to know about this food",
    "positives": [
      {"title": "short label", "detail": "why it is genuinely good here, grounded in the detected data"}
    ],
    "concerns": [
      {
        "title": "short label",
        "detail": "what the concern is and how significant it is in THIS portion",
        "severity": "minor|moderate|important|higher"
      }
    ],
    "nutritionInsights": [
      {"nutrient": "e.g. Sodium", "observation": "what the data shows", "whyItMatters": "plain-language relevance"}
    ],
    "personalizedInsights": [
      {"observation": "what this means for this user", "basedOn": "the exact profile fact or past scan it relies on"}
    ],
    "warnings": ["medical/allergen cautions only — empty array when none apply"]
  },
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
- v: envelope version, always the integer 1 for now.
- verdict: "food" when the analyzed content is food/drink/supplement, "non_food" when it is definitively something else (cosmetics, medicine packaging, random objects), "uncertain" when you cannot tell. non_food/uncertain turns are shown in chat but never saved to history — answer honestly.
- category: "food", "meal", "menu", "label", "packaging", or "non-food".
- novaGroup: integer 1-4, or JSON null.
- scan.score: integer 0-100 fallback only. GutGood recalculates the displayed score from available product or meal data. In COMPLETE_ANALYSIS and MEAL_RATING, the required prose rating must match scan.score; the app may replace it with the final engine score before display.
- nutriscore: "A","B","C","D","E", or JSON null.
- meal.time and symptoms[].time: omit unless the user explicitly stated when the event happened; when included, use ISO 8601. Never estimate event time from message or scan time.
- symptoms: ALWAYS an array of OBJECTS (not strings). Each object MUST have at minimum a "symptom" field.
- swaps: return exactly 4 distinct, practical alternatives when four suitable improvements are supported; otherwise return []. Never pad the list. All swap fields describe the alternative, not the original food. The app assigns IDs and source food; do not invent foodId, relatedPatternId or impactLevel.
- swaps[].reason and whyBetterOption: explain the actual substitution and supported comparison. Respect the supplied allergies, sensitivities and dietary preferences; do not claim guaranteed tolerance, symptom relief or gut healing. Unknown allergen information is not proof of safety.
- swaps[].benefitTags and structuredBenefits: include up to 3 supported benefits, or []. Avoid generic filler. Keep each description to one short sentence.
- swaps[].imageKeyword: a real search phrase matching name, never "string". Copy barcode, nutriscore and imageUrl only from supplied product data; otherwise null. A generic food must not be presented as a verified branded product.
- swaps[].nutrition: use only supplied nutrition with an explicit basis (e.g. "per 100 g" or "per 150 g serving"). Calories are numeric kcal; protein, totalFat and fiber are strings with units. If values or their basis are unknown, use null. Do not invent estimates or compare different portion bases.
- For food-photo or barcode scans, meal may describe a candidate food event and its supported foodTags; a scan is not proof it was eaten, and the app asks the user before counting it. For text-only turns, populate meal only when the user reports eating it. A swap request or meal plan alone is not a meal log.
- symptoms[].severity: omit unless the user explicitly supplied a 1-10 severity. Never assign a default rating.
- symptoms[].mood, symptoms[].sleep and symptoms[].notes: include only details the user explicitly reported; otherwise omit them.
- Any value you cannot determine uses JSON null (or [] for arrays).
- To prevent response truncation, limit ingredients to top 10 items.
- scan.additiveItems: array of short labels, ONE per additive found (prefer E-codes/INS numbers like "E621" when known, else plain names like "Palm Oil"). Use [] when none are detected. This powers per-additive detail screens, so never merge items into one string.
- metadata.confidence: REQUIRED float 0.0-1.0 representing how confident you are in the scan/meal/symptom data you extracted (not the conversational text). Use LOW confidence (below 0.6) when the image is blurry/ambiguous, the product could not be identified, or you are guessing at nutrition/ingredients without real evidence. The app will not silently count low-confidence scan candidates as eaten, so err on the side of an honest, lower number rather than inflating it.
- scan.servingSize: the label's serving (e.g. "40 g"). scan.servingsPerPack: number of servings in the pack when shown. scan.portionEaten: how much the user actually appears to be eating, when the photo makes it clear (e.g. "1 of 4 cookies"). Use JSON null when unknown — NEVER invent a portion.
- ingredients[].quantity: amount when the label or image shows it (e.g. "12 g added sugar per serving", "trace"). Use JSON null when unknown. Judge significance against the amount, not mere presence.
- insight.positives: at most 3, and only factors that are genuinely notable for THIS product. An empty array is acceptable; filler is not.
- insight.concerns: at most 3, ordered most-significant first, each with a severity of exactly "minor", "moderate", "important" or "higher". "minor" is for things not worth changing behaviour over; reserve "important"/"higher" for factors that would matter to most people at this portion size. Do not pad the list.
- insight.nutritionInsights: only nutrients where the value is actually notable (high, low, or unusual for the category). No generic restatements of the nutrition panel.
- insight.personalizedInsights: ONLY when the user profile or scan history supplied in context genuinely supports it, and "basedOn" must quote that supporting fact. If there is no supporting data, return an empty array — never infer goals, preferences, history, or values that were not provided.
- insight.warnings: allergy, medical or safety cautions only. Empty array when none apply.
- insight.scoreFactors and insight.scoreExplanation are computed by GutGood's scoring engine after your response. Do NOT emit them. Only include a numeric GutGood score in the required rating line for COMPLETE_ANALYSIS or MEAL_RATING, and make it match scan.score.
- scan.nutritionBasis: identify the basis actually used by scan.nutrients: per_serving, per_100g, per_100ml, or pictured_portion. Prefer supplied servingNutrients for per_serving; otherwise preserve the source nutrientDataPer basis. Use pictured_portion for a visual meal estimate. Use null if unknown; never relabel per-100-g facts as per-serving values.
- scan.nutrients: numeric values using scan.nutritionBasis. For home-cooked meals, values refer to the estimated pictured portion. Calories are kcal and other values use grams. NOTE: "salt" MUST be in grams (g) e.g. 0.6 or 1.5 (NEVER milligrams mg like 600).
- scan.isOrganic: boolean or JSON null. Set to true when the product or meal carries an organic certification label (USDA Organic, EU Bio, AB) or is explicitly organic.
- scan.nutritionEstimated: REQUIRED boolean. Set this to `true` whenever the "nutrients"/"nutrientLevels"/"novaGroup" fields are a visually-grounded APPROXIMATION rather than a label-sourced/barcode-sourced fact (this is the normal case for any home-cooked or unpackaged meal identified from a photo — see the estimation exception above). Set it to `false` only when those values came from an actual product label, barcode lookup, or menu nutrition data. The app uses this flag to visually label estimated macros as "Estimated" instead of presenting them with the same authority as a scanned fact.
''';
}
