import 'package:gutgood/core/services/prompts/schema_definitions.dart';

class StructuredTagPrompt {
  StructuredTagPrompt._();

  static String get instruction =>
      '''
TAG ENFORCEMENT

For structured food/product responses:
${SchemaDefinitions.scanSchema}

${SchemaDefinitions.mealSchema}

For symptom logging:
If the user reports a physical feeling, symptom, or mood (e.g., "I'm bloated", "my stomach hurts", "I'm tired"), you MUST output the [SYMPTOM] tag.
${SchemaDefinitions.symptomSchema}

For swap responses:
${SchemaDefinitions.swapsSchema}

For restaurant menus:
DO NOT output any structured tags.

${SchemaDefinitions.typeRules}

JSON RULES

Whenever JSON is required:
- JSON must be valid.
- Use double quotes.
- Do not add comments.
- Do not add trailing commas.
- Do not output Markdown inside the JSON.
- Always close the corresponding [TAG].
- Never put explanatory text inside a structured block unless the schema
  explicitly provides a field for it.
''';
}
