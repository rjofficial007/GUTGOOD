import 'package:gutgood/core/services/prompts/schema_definitions.dart';

class StructuredTagPrompt {
  StructuredTagPrompt._();

  static String get instruction =>
      '''
STRUCTURED DATA ENFORCEMENT

Your response MUST conclude with the appropriate structured data blocks if relevant to the turn. 
Do not emit a block if the category was not discussed.

0. [INTENT]: MANDATORY for every turn. Identify what the user is trying to achieve.
${SchemaDefinitions.intentSchema}

1. [SCAN]: Use for ingredient labels, barcodes, single-product analysis, or food items identified from photos.
${SchemaDefinitions.scanSchema}

2. [MEAL]: Use for complete plates, restaurant meals, or home-cooked food.
${SchemaDefinitions.mealSchema}

3. [SYMPTOM]: Use if the user reports a feeling, mood, or physical symptom.
${SchemaDefinitions.symptomSchema}

4. [SWAPS]: Use if you have recommended alternatives.
${SchemaDefinitions.swapsSchema}

STRICT JSON RULES:
- VALIDITY: JSON must be syntactically perfect.
- POSITION: Tags MUST be the very last thing in your response.
- ALIGNMENT: The data in the JSON must match your conversational claims.
- DATES: Use ISO 8601 for all `time` fields.
- CATEGORIES: Follow the schema types exactly as defined.
${SchemaDefinitions.typeRules}
''';
}
