/// Applies the chat assistant's existing medical-safety disclaimer rule.
///
/// Kept outside the presentation notifier so the policy is deterministic,
/// independently testable, and reusable by other chat response paths without
/// introducing Flutter or SDK dependencies.
abstract final class ChatSafetyGuardrails {
  const ChatSafetyGuardrails._();

  static const List<String> _forbiddenWords = [
    'diagnose',
    'cure',
    'treat',
    'prescription',
    'medical condition',
    'disease',
  ];

  static const String _disclaimer =
      '**Disclaimer:** I am an AI, not a doctor. This analysis identifies patterns in your reports for educational purposes and is not a medical diagnosis. Always consult a healthcare professional for medical advice.';

  /// Returns [text] unchanged when it already contains a disclaimer or does
  /// not contain a restricted medical claim; otherwise appends the existing
  /// user-facing disclaimer.
  static String apply(String text) {
    if (text.contains('Disclaimer:') || text.contains('**Disclaimer:**')) return text;

    final lowerText = text.toLowerCase();
    final containsForbiddenWord = _forbiddenWords.any(lowerText.contains);
    if (!containsForbiddenWord) return text;

    return '$text\n\n$_disclaimer';
  }
}
