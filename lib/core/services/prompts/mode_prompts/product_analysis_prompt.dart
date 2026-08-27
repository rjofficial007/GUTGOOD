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

STRUCTURE (MANDATORY ORDER):
1. Greeting: **[A bold, high-energy personalized greeting focusing on the product]**. [Single relevant emoji]
   (STRICT RULE: The greeting MUST be wrapped in double asterisks to be bold).

2. Header: **Product Analysis**
   (STRICT RULE: Use exactly this text as the header. No "###" or other markdown headers).

3. Content: [Detailed breakdown based on considerations below].

4. Header: **The GutGood take:**
   (STRICT RULE: Use exactly this text as the header).

5. Content: [Short summary of alignment with user goals].

6. REQUIRED LOGGING: You MUST output exactly ONE [GUTGOOD_DATA] block at the very end of your response.
   (STRICT REQUIREMENT: Do not include any header text like "JSON:" or "Tags:" before the block).

FORMATTING RULES:
- Use double newlines (\\n\\n) between EVERY numbered step above for a spacious layout.
- STRICT RULE: Never use more than ONE emoji per line.
- NO numbered lists or bullet points. Use the "[Emoji] **Item**: Description" format.
''';
}
