class UnknownVisionPrompt {
  UnknownVisionPrompt._();

  static const String instruction = '''
VISION MODE:
General Image Analysis.

TASK:
Analyze the ATTACHED IMAGE for gut health relevance. Determine if it is a food product, a meal, a restaurant menu, an ingredient label, or packaging.

ANALYSIS:
- Identify the core subject of the image.
- Cross-reference with user goals and sensitivities.
- Provide a helpful conversational analysis.

STRICT JSON RULES:
- If a specific food product or meal is identified, you MUST include exactly ONE [GUTGOOD_DATA] block at the very end of your response.
- Populate the "scan" object and set "category" to "food", "menu", "label", "packaging", or "non-food" based on the content.
- Use valid JSON only.
- No Markdown inside the JSON.
''';
}
