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
/// 2. **The rating is injected locally.** The model must never invent a
///    number (it doesn't know the engine result), so the client adds the
///    authoritative `GutGood Rating: X/100 — Band` line computed from the
///    SAME deterministic engine value the rest of the app shows. That is the
///    only way "the rating in the narrative" can never contradict the score
///    gauge beside it.
class NarrativeText {
  NarrativeText._();

  /// Matches whitespace + one or more emoji-ish codepoints (pictographs,
  /// ZWJ chains, variation selectors, skin tones) inside square brackets,
  /// e.g. `[🫐]`, `[🧇‍🥞]`.
  static final RegExp _emojiBrackets = RegExp(
    '\\[(?:[\\u{1F000}-\\u{1FAFF}\\u{2600}-\\u{27BF}\\u{2B00}-\\u{2BFF}\\u{1F3FB}-\\u{1F3FF}\\u{200D}\\u{FE0F}\\s]+)\\]\\s*',
    unicode: true,
  );

  /// Removes bracket-wrapped emoji decorations and tidies the whitespace
  /// they leave behind. Standalone emoji (e.g. a greeting's 🥞) are kept —
  /// only the bracket form was flagged as noise.
  static String sanitize(String text) => text
      .replaceAll(_emojiBrackets, '')
      .replaceAll(RegExp('[ \\t]{2,}'), ' ')
      .replaceAll(RegExp('\\n{3,}'), '\n\n')
      .trim();

  /// The canonical rating line — single source for the prose version of the
  /// deterministic engine score.
  static String ratingLine(int score) => '**GutGood Rating: $score/100 — ${GutScoreBand.fromScore(score).label}**';

  /// Inserts the engine rating directly under the bold greeting paragraph,
  /// so the number readers see is always the one the engine computed.
  static String injectRating(String text, int score) {
    final sanitized = text.trimRight();
    if (sanitized.isEmpty) return ratingLine(score);
    final firstBreak = sanitized.indexOf('\n');
    if (firstBreak == -1) return '$sanitized\n\n${ratingLine(score)}';
    return '${sanitized.substring(0, firstBreak).trimRight()}\n\n${ratingLine(score)}${sanitized.substring(firstBreak)}';
  }
}
