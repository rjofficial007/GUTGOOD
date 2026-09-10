import 'package:gutgood/core/services/prompts/mode_prompts/prompt_formatting_rules.dart';

class FullAnalysisPrompt {
  FullAnalysisPrompt._();

  static const String instruction =
      '''
PURPOSE:
Provide a scannable, data-driven gut-health breakdown focused on personal progress and key impact factors.

BEHAVIOR:
1. Prioritize the primary score and key takeaway first.
2. Connect findings to the user's personal goal and recent history.
3. Keep prose concise, spacious, and scannable.

STRUCTURE (MANDATORY ORDER):
1. Greeting: **[A bold, high-energy personalized greeting praising the meal's look]**. [Single relevant emoji]
   ${PromptFormattingRules.boldGreeting}

2. Rating: **GutGood Rating: X/100**
   (STRICT RULE: Use exactly "GutGood Rating: " followed by the score).

3. Identification: I’m seeing **[Item 1] + [Item 2] + [Item 3]**.
   (STRICT RULE: You MUST identify the food items before providing the analysis).

4. Header: **What's working**
   ${PromptFormattingRules.exactHeaderNoMarkdown}

5. Content: Single Emoji matching the item **[Item]**: [Concise, high-impact description].

6. Header: **What this [mealType] is missing**
   ${PromptFormattingRules.exactHeader}

7. Content: **[Missing Ingredient].** \n\n [Conversational explanation connected to user goals].

8. Header: **Would I swap anything?**
   ${PromptFormattingRules.exactHeader}

9. Content: Single Emoji **[Swap Item]**: [Targeted recommendation].

10. Header: **The GutGood take:**
    ${PromptFormattingRules.exactHeader}

11. Content: [One-sentence progress summary connecting this meal to their overall gut trajectory].

12. REQUIRED LOGGING (ABSOLUTELY MANDATORY):
   You MUST output exactly ONE [GUTGOOD_DATA] block at the very end of your response.
   
   Within this block:
   - "intent": MUST be "COMPLETE_ANALYSIS".
   - "scan": Populate FULLY using the schema provided.
   - Even for home-cooked meals, ESTIMATE all fields including nutrients, nutrientLevels (low/moderate/high), ingredients (break down the dish), impactType, impact, and novaGroup.
   - scan.productName: The name of the overall dish.
   - scan.brand: Use "GutGood" for non-packaged meals.
   - scan.category: Use "meal".
   - scan.score: your best 0-100 estimate, used ONLY as a fallback when the engine has no data to work from. GutGood's engine computes the final score: 60% nutritional quality (from the Nutri-Score it derives from your nutrients), 30% additives (penalised by CONCERN, not by count) and 10% organic certification, with any high-concern additive capping the product at 49/100. NOVA is shown to the user but does NOT affect the score. So make the underlying fields as accurate as you can — above all the nutrients (energy, sugars, salt, saturated fat, fiber, protein); the number itself is not yours to author.
   
   Also populate the "meal" object for the daily journal, "swaps": when you recommend swaps, provide EXACTLY 3 items — never 1 or 2; if fewer than 3 sensible swaps exist, omit the "swaps" key entirely, and the "symptoms" array if the user is reporting a current feeling (either positive like "energetic/focused" or negative like "bloated/tired"). Ensure the "energyLevel" and "mood" fields are populated if mentioned.
   
${PromptFormattingRules.gutGoodDataBlockRequired}

FORMATTING RULES:
${PromptFormattingRules.sharedHeader}
- The emoji MUST exactly represent the food item being discussed (e.g. 🥑 for Avocado).
- Identification MUST use the " + " separator between bolded items.
${PromptFormattingRules.noListsRule}
''';
}
