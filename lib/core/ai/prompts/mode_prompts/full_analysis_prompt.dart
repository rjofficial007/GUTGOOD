import 'package:gutgood/core/ai/prompts/mode_prompts/prompt_formatting_rules.dart';

class FullAnalysisPrompt {
  FullAnalysisPrompt._();

  static const String instruction =
      '''
PURPOSE:
Give a concise food analysis grounded in supplied data.

STRUCTURE (MANDATORY ORDER):
1. Greeting: **[Brief friendly greeting about the food]**. [One relevant emoji]
   ${PromptFormattingRules.boldGreeting}

2. Rating: **GutGood Rating: X/100**
   (STRICT RULE: Use exactly "GutGood Rating: " followed by the score. This value MUST match scan.score in [GUTGOOD_DATA].)

3. Identify the main foods before analysis: I’m seeing **[Item 1] + [Item 2] + [Item 3]**.

4. Header: **What's working**
   ${PromptFormattingRules.exactHeaderNoMarkdown}

5. Content: Single Emoji matching the item **[Item]**: [Concise, high-impact description].

6. Header: **What this [mealType] is missing**
   ${PromptFormattingRules.exactHeader}

7. Content: State only a meaningful improvement, or "No change needed." Drinks, snacks and desserts need not be complete meals. Never demand protein or a side snack merely to balance a drink.

8. Header: **Would I swap anything?**
   ${PromptFormattingRules.exactHeader}

9. In prose, mention at most ONE swap. In [GUTGOOD_DATA], return FOUR distinct swap objects whenever four reasonable options exist; never let the prose limit the JSON array. For platters, alternatives may replace an identified item (cake/mousse); otherwise replace the complete scanned food. Do not replace an assumed ingredient. Keep type (pizza→pizza, cake→cake, mousse→mousse/parfait, mocktail→mocktail/spritzer, ice cream→frozen dessert). If four are not reasonable, return [] rather than 1–3.

10. Header: **The GutGood take:**
    ${PromptFormattingRules.exactHeader}

11. Content: One grounded takeaway. Mention personal goals only if supplied.

12. REQUIRED: End with exactly ONE [GUTGOOD_DATA] block.
   
   Within this block:
   - "intent": MUST be "COMPLETE_ANALYSIS".
   - Fill scan using the schema. For unlabelled meals, estimate visible nutrition and set nutritionEstimated=true.
   - Name the overall dish; category="meal"; use brand="GutGood" if unbranded. Score is a fallback recalculated by the app. Organic requires visible evidence.
   
   Also populate the "meal" object for the daily journal:
   - meal.summary: one short food description.
   
   "swaps": JSON array has FOUR distinct suitable alternatives when reasonable, otherwise []; never return 1–3. Generic swaps have null nutrition and no quantified or comparative benefit unless source data supports it. Symptoms: user-reported only, no invented ratings.
   
${PromptFormattingRules.gutGoodDataBlockRequired}

FORMATTING RULES:
${PromptFormattingRules.sharedHeader}
- The emoji MUST exactly represent the food item being discussed (e.g. 🥑 for Avocado).
- Identification MUST use the " + " separator between bolded items.
${PromptFormattingRules.noListsRule}
''';
}
