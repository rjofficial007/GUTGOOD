library;

import 'package:gutgood/core/utils/gut_score_utils.dart';

/// Post-processing for AI-authored narrative text before it is displayed or
/// persisted to chat.
///
/// Two rules, both driven by product reality rather than prompt obedience:
///
/// 1. **No bracket-wrapped emoji** (`[🫐]`). Models love decorating item
///    lines with them; prompts keep drifting back, so we strip them here,
///    once, universally.
/// 2. **The rating is injected locally.** The model may include a rating that
///    matches its structured score, but scan screens can recalculate that
///    score. Before display, replace the model line with the authoritative
///    engine value used by the score gauge.
class NarrativeText {
  NarrativeText._();

  static final RegExp _existingRatingLine = RegExp(r'^[^\n]*GutGood Rating:[^\n]*(?:\n|$)', caseSensitive: false, multiLine: true);

  /// Matches whitespace + one or more emoji-ish codepoints (pictographs,
  /// ZWJ chains, variation selectors, skin tones) inside square brackets,
  /// e.g. `[🫐]`, `[🧇‍🥞]`.
  static final RegExp _emojiBrackets = RegExp(r'\[(?:[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{1F3FB}-\u{1F3FF}\u{200D}\u{FE0F}\s]+)\]\s*', unicode: true);

  /// Removes bracket-wrapped emoji decorations and tidies the whitespace
  /// they leave behind. Standalone emoji (e.g. a greeting's 🥞) are kept —
  /// only the bracket form was flagged as noise.
  static String sanitize(String text) => text.replaceAll(_emojiBrackets, '').replaceAll(RegExp(r'[ \t]{2,}'), ' ').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();

  /// The canonical rating line — single source for the prose version of the
  /// deterministic engine score.
  static String ratingLine(int score) => '**GutGood Rating: $score/100 — ${GutScoreBand.fromScore(score).label}**';

  /// Inserts the engine rating directly under the bold greeting paragraph,
  /// replacing any model-authored rating so the displayed number always
  /// matches the engine.
  static String injectRating(String text, int score) {
    final sanitized = sanitize(text).replaceAll(_existingRatingLine, '').trim();
    if (sanitized.isEmpty) return ratingLine(score);
    final firstBreak = sanitized.indexOf('\n');
    if (firstBreak == -1) return '$sanitized\n\n${ratingLine(score)}';
    return '${sanitized.substring(0, firstBreak).trimRight()}\n\n${ratingLine(score)}${sanitized.substring(firstBreak)}';
  }
}
