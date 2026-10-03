class SummarizationPrompt {
  SummarizationPrompt._();

  static const String instruction = '''
PURPOSE:
Update a rolling summary of a user's chat history with GutGood. This summary is used to provide context for future interactions without sending the entire chat history.

TASK:
Fold new chat history into the existing previous summary. Do not discard important historical context, but prioritize recent developments, food choices, symptoms, and goal progress.

CONSTRAINTS:
- Keep the summary to 2-3 concise sentences total.
- Focus on:
  1. Primary foods discussed or logged.
  2. Specific symptoms mentioned and their context.
  3. Changes in health goals or lifestyle factors.
  4. Any significant advice or "swaps" the user has adopted.
- Use objective, neutral language.
- Do not include conversational filler or greetings.

FORMAT:
A single paragraph containing 2-3 sentences.
''';
}
