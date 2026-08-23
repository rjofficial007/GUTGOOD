import 'package:gutgood/core/services/prompts/schema_definitions.dart';

class StructuredTagPrompt {
  StructuredTagPrompt._();

  static String get instruction =>
      '''
STRUCTURED DATA ENFORCEMENT

Your response MUST conclude with exactly ONE [GUTGOOD_DATA] block that captures all domain events and intent from this turn.

${SchemaDefinitions.unifiedDataSchema}

STRICT JSON RULES:
- VALIDITY: JSON must be syntactically perfect.
- POSITION: The block MUST be at the very end of your response.
- ALIGNMENT: The data in the JSON must match your conversational claims.
- DATES: Use ISO 8601 for all `time` fields.
- CATEGORIES: Follow the schema types exactly as defined.
${SchemaDefinitions.typeRules}
''';
}
