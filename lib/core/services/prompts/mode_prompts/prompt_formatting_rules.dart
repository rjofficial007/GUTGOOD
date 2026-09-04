/// Shared, byte-identical formatting boilerplate that used to be hand-copied
/// into 13+ separate `mode_prompts/*_prompt.dart` files (flagged in the AI
/// system audit, §E / §O item 9: "Extract the 13x-duplicated
/// 'STRUCTURE/formatting' boilerplate into one shared prompt fragment").
///
/// This is a **literal extraction only** — every mode prompt's compiled
/// `instruction` string is byte-for-byte identical to what it produced
/// before this refactor (verified via snapshot diff). No wording, ordering,
/// or behavior was changed; only the single source of truth moved here so a
/// future formatting-rule tweak doesn't require editing 13+ files in lockstep.
class PromptFormattingRules {
  PromptFormattingRules._();

  /// Used after "1. Greeting: **[...]**. [Single relevant emoji]" in every
  /// mode prompt's STRUCTURE section.
  static const String boldGreeting = '(STRICT RULE: The greeting MUST be wrapped in double asterisks to be bold).';

  /// Used after a "Header: **...**" step whose text must appear verbatim,
  /// with no markdown "###" heading syntax.
  static const String exactHeaderNoMarkdown = '(STRICT RULE: Use exactly this text as the header. No "###" or other markdown headers).';

  /// Used after a "Header: **...**" step whose text must appear verbatim
  /// (shorter variant used mid-structure, where the "no markdown" caveat is
  /// already established earlier in the same prompt).
  static const String exactHeader = '(STRICT RULE: Use exactly this text as the header).';

  /// Trailing instruction requiring the [GUTGOOD_DATA] tag pair with no
  /// leading header text, used by every mode that DOES emit structured data.
  static const String gutGoodDataBlockRequired =
      'The block MUST start with the opening tag [GUTGOOD_DATA] and end with the closing tag [/GUTGOOD_DATA]. (STRICT REQUIREMENT: Do not include any header text like "JSON:" or "Tags:" before the block).';

  /// The three formatting rules present, byte-for-byte, at the bottom of
  /// every mode prompt: spacing, one-emoji-per-line, and no lists.
  static const String spacingRule = '- Use double newlines (\\n\\n) between EVERY numbered step above for a spacious layout.';
  static const String singleEmojiRule = '- STRICT RULE: Never use more than ONE emoji per line.';
  static const String noListsRule = '- NO numbered lists or bullet points. Use the "[Emoji] **Item**: Description" format.';

  /// Convenience bundle: the two rules shared by literally every mode prompt
  /// (spacing + single-emoji), for prompts that then append their own
  /// mode-specific extra rules before/after `noListsRule`.
  static const String sharedHeader = '$spacingRule\n$singleEmojiRule';
}
