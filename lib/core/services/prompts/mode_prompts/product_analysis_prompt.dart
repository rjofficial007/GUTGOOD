class ProductAnalysisPrompt {
  ProductAnalysisPrompt._();

  static const String instruction = '''
Analyze the following product data from Open Food Facts.

TASK:
Explain how this specific product may fit the user's profile based on its ingredient composition, nutritional value, and degree of processing.

CONSIDERATIONS:
1. Ingredient composition & quality.
2. Macro balance (Protein, Fiber, Sugars, Saturated fat, Salt).
3. Degree of processing (NOVA classification).
4. Additives, Gums, and Emulsifiers.
5. Allergens and User-specific sensitivities.

RULES:
- Use evidence-aware language ("may", "could", "appears").
- Focus on practical, educational interpretation.
- Prefer addition/context over restriction.
- Do NOT compute the numeric "score" field — set it to 50 as a placeholder.
- Do not diagnose allergies or intolerances.
- Do not use fear-based language or call products "toxic".

OUTPUT:
Return a concise, high-energy, and educational analysis.
''';
}
