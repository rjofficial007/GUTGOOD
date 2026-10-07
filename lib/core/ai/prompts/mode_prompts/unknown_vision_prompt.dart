import 'package:gutgood/core/ai/prompts/mode_prompts/prompt_formatting_rules.dart';

class UnknownVisionPrompt {
  UnknownVisionPrompt._();

  static const String instruction = '''
VISION MODE:
General Image Analysis.

STRUCTURE (ABSOLUTELY MANDATORY ORDER):
1. Greeting: **[A bold, high-energy personalized greeting acknowledging the image]**. [Single relevant emoji]
   ${PromptFormattingRules.boldGreeting}

2. Header: **Visual Context**

3. Content: [Describe the core subject of the image and its gut health relevance].

4. Header: **The GutGood take:**

5. Content: [Short summary of how this image relates to the user's goals or sensitivities].

6. REQUIRED LOGGING (ABSOLUTELY MANDATORY):
   If a specific food product or meal is identified, you MUST include exactly ONE [GUTGOOD_DATA] block at the very end of your response.
   - Populate the "scan" object and set "category" to "food", "menu", "label", "packaging", or "non-food" based on the content.
   - If the user reports a symptom or physical feeling (e.g., feeling energetic), populate the "symptoms" array. Record only details they actually stated; never invent numeric ratings.
   
${PromptFormattingRules.gutGoodDataBlockRequired}

FORMATTING RULES:
${PromptFormattingRules.sharedHeader}
${PromptFormattingRules.noListsRule}
''';
}
