import 'package:flutter/material.dart';

/// Design tokens for the "Real Tokens" Insights language.
///
/// Transcribed verbatim from the Insights design mock (`:root` block):
/// scaffold `#FCFCFD` · card `#FFFFFF` · border `#E4E4E8` · ink `#0A0A0A` /
/// `#4A4E5A` / `#6E7280` · success `#1F7A3D` · error `#C4302B` ·
/// warning `#FFAB40` · purple `#7C3AED` · lime `#D9FF30`.
///
/// Like [InsightBentoTheme] before it, this is deliberately **not** folded
/// into the global `AppPalette`: the Insights design language is a distinct design system
/// that is registered once and shared by the screens that use it. Registered
/// as a [ThemeExtension] so light/dark resolve through the ambient theme and
/// no widget branches on brightness.
///
/// Radii follow the mock's system: cards r20 · tiles r14 · pills use a full radius.
@immutable
class InsightTheme extends ThemeExtension<InsightTheme> {
  const InsightTheme({
    required this.scaffold,
    required this.card,
    required this.cardSubtle,
    required this.border,
    required this.borderSubtle,
    required this.surfaceSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.success,
    required this.successSoft,
    required this.error,
    required this.errorSoft,
    required this.warning,
    required this.warningSoft,
    required this.purple,
    required this.purplePastel,
    required this.lime,
    required this.overlayBarrier,
  });

  // --- Surfaces (Insights --scaffold / --card / --border) ---
  /// Screen background — `#FCFCFD`.
  final Color scaffold;

  /// Card surface — `#FFFFFF`.
  final Color card;

  /// Nested surface (`--card-2`): timeline rows, food tiles, swap halves.
  final Color cardSubtle;

  /// Hairline border — `#E4E4E8`.
  final Color border;

  /// `--border-subtle`: rgba(228,228,232,.5).
  final Color borderSubtle;

  /// `--surface-subtle`: rgba(10,10,10,.03).
  final Color surfaceSubtle;

  // --- Ink (Insights --t1 / --t2 / --t3) ---
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  // --- Accents ---
  /// `#1F7A3D` — healing foods, positive deltas, "What's Improving".
  final Color success;

  /// `#E7F6E7` — soft success wash behind badges.
  final Color successSoft;

  /// `#C4302B` — triggers, "Something to Watch".
  final Color error;

  /// `#FFF1F0` — soft error wash behind badges.
  final Color errorSoft;

  /// `#FFAB40` — caution accents.
  final Color warning;

  /// `#FFF4E5` — soft warning wash.
  final Color warningSoft;

  /// `#7C3AED` — AI/discovery accents.
  final Color purple;

  /// `#C4B5FD` — pastel purple wash.
  final Color purplePastel;

  /// `#D9FF30` — lime highlight.
  final Color lime;

  /// Scrim behind the dark recommendation card icon tile.
  final Color overlayBarrier;

  /// Body face (design mock's SF Pro stack → the app's Inter Tight).
  static const String fontFamily = 'InterTight';

  /// display face for the big editorial titles ("Insights", hero numbers
  /// sections). Transcribed from `font-family:'Instrument Serif',serif`.
  static const String displayFont = 'InstrumentSerif';

  // --- Radii (design: Bento r20 · Chip r14 · Button r12) ---
  static const double radiusCard = 20;
  static const double radiusTile = 14;
  static const double radiusPill = 999;

  @override
  InsightTheme copyWith({
    Color? scaffold,
    Color? card,
    Color? cardSubtle,
    Color? border,
    Color? borderSubtle,
    Color? surfaceSubtle,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? success,
    Color? successSoft,
    Color? error,
    Color? errorSoft,
    Color? warning,
    Color? warningSoft,
    Color? purple,
    Color? purplePastel,
    Color? lime,
    Color? overlayBarrier,
  }) => InsightTheme(
    scaffold: scaffold ?? this.scaffold,
    card: card ?? this.card,
    cardSubtle: cardSubtle ?? this.cardSubtle,
    border: border ?? this.border,
    borderSubtle: borderSubtle ?? this.borderSubtle,
    surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textTertiary: textTertiary ?? this.textTertiary,
    success: success ?? this.success,
    successSoft: successSoft ?? this.successSoft,
    error: error ?? this.error,
    errorSoft: errorSoft ?? this.errorSoft,
    warning: warning ?? this.warning,
    warningSoft: warningSoft ?? this.warningSoft,
    purple: purple ?? this.purple,
    purplePastel: purplePastel ?? this.purplePastel,
    lime: lime ?? this.lime,
    overlayBarrier: overlayBarrier ?? this.overlayBarrier,
  );

  @override
  InsightTheme lerp(covariant ThemeExtension<InsightTheme>? other, double t) {
    if (other is! InsightTheme) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return InsightTheme(
      scaffold: l(scaffold, other.scaffold),
      card: l(card, other.card),
      cardSubtle: l(cardSubtle, other.cardSubtle),
      border: l(border, other.border),
      borderSubtle: l(borderSubtle, other.borderSubtle),
      surfaceSubtle: l(surfaceSubtle, other.surfaceSubtle),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textTertiary: l(textTertiary, other.textTertiary),
      success: l(success, other.success),
      successSoft: l(successSoft, other.successSoft),
      error: l(error, other.error),
      errorSoft: l(errorSoft, other.errorSoft),
      warning: l(warning, other.warning),
      warningSoft: l(warningSoft, other.warningSoft),
      purple: l(purple, other.purple),
      purplePastel: l(purplePastel, other.purplePastel),
      lime: l(lime, other.lime),
      overlayBarrier: l(overlayBarrier, other.overlayBarrier),
    );
  }

  // ---------------------------------------------------------------------
  // LIGHT — verbatim from the design mock :root.
  // ---------------------------------------------------------------------
  static const InsightTheme light = InsightTheme(
    scaffold: Color(0xFFFCFCFD),
    card: Color(0xFFFFFFFF),
    cardSubtle: Color(0xFFF6F6F8),
    border: Color(0xFFE4E4E8),
    borderSubtle: Color(0x80E4E4E8),
    surfaceSubtle: Color(0x08F50F0A),
    textPrimary: Color(0xFF0A0A0A),
    textSecondary: Color(0xFF4A4E5A),
    textTertiary: Color(0xFF6E7280),
    success: Color(0xFF1F7A3D),
    successSoft: Color(0xFFE7F6E7),
    error: Color(0xFFC4302B),
    errorSoft: Color(0xFFFFF1F0),
    warning: Color(0xFFFFAB40),
    warningSoft: Color(0xFFFFF4E5),
    purple: Color(0xFF7C3AED),
    purplePastel: Color(0xFFC4B5FD),
    lime: Color(0xFFD9FF30),
    overlayBarrier: Color(0x140A0A0A),
  );

  // ---------------------------------------------------------------------
  // DARK — same hue family, lifted surfaces and softened accents so the
  // hairline-card language survives inversion (rule: keep luminance deltas,
  // swap ink for paper).
  // ---------------------------------------------------------------------
  static const InsightTheme dark = InsightTheme(
    scaffold: Color(0xFF0B0C0E),
    card: Color(0xFF141518),
    cardSubtle: Color(0xFF1C1E22),
    border: Color(0xFF2A2C31),
    borderSubtle: Color(0x802A2C31),
    surfaceSubtle: Color(0x0AFFFFFF),
    textPrimary: Color(0xFFF5F7FA),
    textSecondary: Color(0xFFC3C9D4),
    textTertiary: Color(0xFF8D96A5),
    success: Color(0xFF6FD694),
    successSoft: Color(0x1F1F7A3D),
    error: Color(0xFFF27B76),
    errorSoft: Color(0x1FC4302B),
    warning: Color(0xFFFFC061),
    warningSoft: Color(0x1FFFAB40),
    purple: Color(0xFFA78BFA),
    purplePastel: Color(0xFF4C3D80),
    lime: Color(0xFFD9FF30),
    overlayBarrier: Color(0x14FFFFFF),
  );
}

extension InsightThemeX on BuildContext {
  /// The Insights tokens for the current brightness, falling back to light so a
  /// screen never hard-crashes when the extension is missing from the theme.
  InsightTheme get insightTheme => Theme.of(this).extension<InsightTheme>() ?? InsightTheme.light;

  /// Resolves colors from the original light Insights mock to their semantic
  /// dark-mode counterpart. This keeps older cards and detail screens readable
  /// while they share the same feature-level design tokens as the current Insights feed.
  Color insightColor(Color lightColor) {
    if (Theme.of(this).brightness != Brightness.dark) return lightColor;

    final t = insightTheme;
    return switch (lightColor.toARGB32()) {
      0xFFFFFFFF => t.card,
      0xFFFCFCFD || 0xFFFAF8F5 || 0xFFFFFDF7 => t.scaffold,
      0xFFF8FAFC || 0xFFF6F6F8 || 0xFFF1F5F9 || 0xFFEFF6FF || 0xFFE0F2FE || 0xFFF0F9FF || 0xFFF0F7FF || 0xFFF4FAF5 || 0xFFF5F7FF || 0xFFF8F5FF || 0xFFFFFDF0 => t.cardSubtle,
      0xFFE2E8F0 || 0xFFE4E4E8 || 0xFFCBD5E1 => t.border,
      0xFF0A0A0A || 0xFF0F172A || 0xFF1E293B || 0xFF17171B => t.textPrimary,
      0xFF334155 || 0xFF475569 || 0xFF4A4E5A => t.textSecondary,
      0xFF64748B || 0xFF6E7280 || 0xFF94A3B8 => t.textTertiary,
      // Soft green washes & badges
      0xFFF0FDF4 || 0xFFECFDF5 || 0xFFE7F6E7 || 0xFFDCFCE7 || 0xFFF4FAF2 || 0xFFF4FAF6 => t.successSoft,
      // Green text & icon accents
      0xFF14532D || 0xFF15803D || 0xFF16A34A || 0xFF166534 || 0xFF059669 || 0xFF22C55E => t.success,
      // Soft red / warning washes & badges
      0xFFFEF2F2 || 0xFFFFF1F0 || 0xFFFFE4E6 || 0xFFFECACA || 0xFFFFF8F6 || 0xFFFFF5F5 || 0xFFFFF5F2 || 0xFFFFF3F2 || 0xFFFECDD3 => t.errorSoft,
      // Red text & icon accents
      0xFF881337 || 0xFF991B1B || 0xFFDC2626 || 0xFFB91C1C || 0xFFEF4444 => t.error,
      // Soft amber / orange washes
      0xFFFFFBEB || 0xFFFFF4E5 || 0xFFFEF3C7 || 0xFFFFFBF5 || 0xFFFFEDD5 || 0xFFFED7AA || 0xFFFDE68A => t.warningSoft,
      // Amber text & icon accents
      0xFFC2410C || 0xFFB45309 || 0xFFD97706 || 0xFFF59E0B => t.warning,
      // Soft blue & purple accents
      0xFF0369A1 || 0xFF0284C7 || 0xFF1D4ED8 || 0xFF3730A3 => t.purple,
      0xFFEDE9FE || 0xFFF5F3FF || 0xFFF3E8FF || 0xFFDBEAFE || 0xFFE0E7FF || 0xFFEADDFF || 0xFFE9D8FD => t.purple.withValues(alpha: 0.18),
      _ => lightColor,
    };
  }
}
