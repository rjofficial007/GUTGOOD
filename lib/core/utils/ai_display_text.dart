/// Removes structured AI data and legacy tags from text shown to users.
String stripAiStructuredDataForDisplay(String text) {
  final match = RegExp(r'\[(GUTGOOD_DATA|INTENT|SYMPTOM|MEAL|SCAN|SWAPS|SCAN_CONTEXT)\]', caseSensitive: false).firstMatch(text);
  if (match == null) return text;

  var startIndex = match.start;
  while (startIndex > 0 && (text[startIndex - 1] == '#' || text[startIndex - 1] == ' ' || text[startIndex - 1] == '\n' || text[startIndex - 1] == '\r')) {
    startIndex--;
  }
  return text.substring(0, startIndex).trim();
}
