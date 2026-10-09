import 'package:gutgood/core/ai/prompts/mode_prompts/prompt_formatting_rules.dart';

class ProductAnalysisPrompt {
  ProductAnalysisPrompt._();

  static const String instruction =
      '''
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
- List EVERY additive from PRODUCT DATA as separate short labels in "additiveItems" (E-codes first, e.g. "E621", else names like "Palm Oil"); [] if none.
- Set "isOrganic" from the supplied product data; use null when unknown.
- Recommend exactly 4 distinct swaps using the shared schema when four supplied alternatives offer meaningful improvements; otherwise return []. Explain the comparison and relevant tradeoffs. Do not invent product facts or pad with unsuitable options.
- Each swap must match the scanned whole-dish family: pizza→pizza; burger/fast food→complete burger, sandwich, filled wrap, or bowl. Missing nutrients never change type. Never use sides, ingredients, or plain wraps as full-meal swaps. Give a supported advantage and tradeoff.
- Set swaps[].replaces to the exact scanned dish or product name.
- Do not diagnose allergies or intolerances.
- Do not use fear-based language or call products "toxic".

STRUCTURE (MANDATORY ORDER):
1. Greeting: **[A bold, high-energy personalized greeting focusing on the product]**. [Single relevant emoji]
   ${PromptFormattingRules.boldGreeting}

2. Header: **Product Analysis**
   ${PromptFormattingRules.exactHeaderNoMarkdown}

3. Content: [Detailed breakdown based on considerations below].

4. Header: **The GutGood take:**
   ${PromptFormattingRules.exactHeader}

5. Content: [Short summary of alignment with user goals].

6. REQUIRED LOGGING: You MUST output exactly ONE [GUTGOOD_DATA] block at the very end of your response.
   (STRICT REQUIREMENT: Do not include any header text like "JSON:" or "Tags:" before the block).

FORMATTING RULES:
${PromptFormattingRules.sharedHeader}
${PromptFormattingRules.noListsRule}
''';
}
