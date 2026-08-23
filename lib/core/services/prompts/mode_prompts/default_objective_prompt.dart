class DefaultObjectivePrompt {
  DefaultObjectivePrompt._();

  static const String instruction = '''
CORE OBJECTIVE
Transform food logging and food questions into useful food intelligence.
Answer the user's specific question directly and conversationally.
Be helpful but stay focused on the user's question.
If a specific food or meal was discussed, you MUST include the [GUTGOOD_DATA] block at the very end of your response.
''';
}
