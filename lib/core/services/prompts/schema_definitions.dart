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

  static String get scanSchema =>
      '''
[SCAN]
{
  "productName": "string|null",
  "brand": "string|null",
  "category": "food|menu|label|packaging|non-food",
  "badge": "string|null",
  "score": 0,
  "time": "ISO8601 string",
  "impactType": "positive|neutral|negative",
  "nutriscore": "A|B|C|D|E|null",
  "novaGroup": 1,
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
  "allergens": "A short summary string of detected allergens",
  "additives": "A short summary string of detected additives (e.g. E407, E415)",
  "impacts": [
    "A concise gut-health impact label, e.g., 'Probiotic Rich' or 'Added Sugars'"
  ],
  "ingredients": [
$ingredientSchema
  ],
  "impact": "A narrative summary of the overall gut health impact",
  "cycleInsight": null,
  "swaps": []
}
[/SCAN]''';

  static const String mealSchema = '''
[MEAL]
{
  "mealType": "string",
  "items": [
    {
      "name": "string",
      "confidence": 0.0,
      "observation": "string"
    }
  ],
  "time": "ISO8601 string",
  "balance": {
    "protein": "low|moderate|good|unknown",
    "fiber": "low|moderate|good|unknown",
    "fat": "low|moderate|good|unknown"
  },
  "workingWell": ["string"],
  "missingOrCouldAdd": ["string"],
  "sensitivityNotes": ["string"],
  "summary": "string"
}
[/MEAL]''';

  static const String symptomSchema = '''
[SYMPTOM]
{
  "symptom": "string",
  "severity": 1,
  "energyLevel": 1,
  "time": "ISO8601 string",
  "mood": "string",
  "notes": "string"
}
[/SYMPTOM]''';

  static const String swapsSchema = '''
[SWAPS]
[
  {
    "title": "string",
    "subtitle": "string",
    "tag": "BETTER CHOICE",
    "badge": "string",
    "imageKeyword": "string",
    "isBlackBadge": true
  }
]
[/SWAPS]''';

  /// Explicit type rules to stop the "1-4" vs `1`, "unknown" vs `null`
  /// drift from creeping back in as prompts get edited over time.
  static const String typeRules =
      '''
SCHEMA TYPE RULES (apply to every JSON block in this prompt)
- category is a string: "food", "menu", "label", "packaging", or "non-food".
- novaGroup is an integer 1-4, or JSON null. Never a string, never a range like "1-4".
- score is an integer 0-100. Never null. If truly unknown, output 0 and set impactType to "neutral".
- nutriscore is exactly one of "A","B","C","D","E", or JSON null. Never lowercase, never omitted.
- time is ALWAYS a string in ISO 8601 format. If the user mentions "last night", "this morning", etc., calculate the exact estimated timestamp relative to the CURRENT TIME provided in your system instructions. Never use relative strings like "yesterday" inside the JSON time field.
- items in [MEAL] MUST be a list of objects, each containing a "name" field (e.g. {"name": "Pizza", "confidence": 0.9}).
- Every ingredient object uses this exact shape (colorName is REQUIRED, not optional):
$ingredientSchema
- Any value you cannot determine from the input uses JSON null (or [] for arrays/lists).
  Never use the string "unknown" inside a field typed as a number, and never invent a
  placeholder value to avoid using null.
- To prevent response truncation, limit the "ingredients" list to the top 10 most relevant items.
''';
}
