import 'package:flutter/material.dart';

/// One of the six bento surfaces from the v4 Insights design.
///
/// Names follow the source mock (`uploads/v4.html`, `.bento-peach` …
/// `.bento-white`) so the Dart maps 1:1 onto the reference.
enum BentoTone { peach, mint, coral, amber, purple, white }

/// The six colour slots a bento card paints: a two-stop background ramp, a
/// hairline border, the tag chip, and the footer rule/label.
@immutable
class BentoPalette {
  const BentoPalette({
    required this.gradientStart,
    required this.gradientEnd,
    required this.border,
    required this.tagBackground,
    required this.tagForeground,
    required this.footForeground,
    required this.shadowTint,
  });

  final Color gradientStart;
  final Color gradientEnd;
  final Color border;
  final Color tagBackground;
  final Color tagForeground;
  final Color footForeground;
  final Color shadowTint;

  /// v4 paints `linear-gradient(145deg, …)`. Flutter gradients run along an
  /// alignment pair; top-left → bottom-right reproduces that diagonal.
  static const Alignment begin = Alignment(-0.7, -1);
  static const Alignment end = Alignment(0.7, 1);

  LinearGradient get gradient => LinearGradient(
    begin: begin,
    end: end,
    colors: [gradientStart, gradientEnd],
  );

  /// Flat variant, for callers that cannot take a gradient.
  Color get flat => Color.alphaBlend(gradientEnd, gradientStart);
}

/// Insights-scoped design tokens for the bento grid.
///
/// Deliberately **not** folded into `AppPalette`/`AppColorScheme`: the bento
/// palette is a local visual language for the Insights feature only, and the
/// rest of the app must not drift to match it. Registered as a
/// [ThemeExtension] so `light`/`dark` resolve through the ambient theme and no
/// widget has to branch on brightness.
///
/// Light values are transcribed verbatim from `uploads/v4.html`. Dark values
/// are derived, not guessed — see `.artifacts/derive_dark_palette.py`, which
/// holds the single HSL mapping rule used for every dark entry.
@immutable
class InsightBentoTheme extends ThemeExtension<InsightBentoTheme> {
  const InsightBentoTheme({
    required this.screenBackground,
    required this.cardBackground,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textQuaternary,
    required this.mint,
    required this.coral,
    required this.gold,
    required this.purple,
    required this.orange,
    required this.positive,
    required this.negative,
    required this.statusBadgeBackground,
    required this.statusBadgeForeground,
    required this.statusBadgeBorder,
    required this.deltaPillBackground,
    required this.deltaPillForeground,
    required this.ctaBackground,
    required this.ctaForeground,
    required this.tickLit,
    required this.tickUnlit,
    required this.heroGlowWarm,
    required this.heroGlowCool,
    required this.scoreTrackStart,
    required this.scoreTrackMid,
    required this.scoreTrackEnd,
    required this.tileBackground,
    required this.bentos,
  });

  // --- Surfaces & neutral ink (v4 --bg/--card/--border/--t1..--t4) ---
  final Color screenBackground;
  final Color cardBackground;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textQuaternary;

  // --- Core accents (v4 --mint/--coral/--gold/--purple/--orange) ---
  final Color mint;
  final Color coral;
  final Color gold;
  final Color purple;
  final Color orange;

  /// Point-delta colours: `#059669` up / `#DC2626` down in the mock.
  final Color positive;
  final Color negative;

  // --- Score hero chrome ---
  final Color statusBadgeBackground;
  final Color statusBadgeForeground;
  final Color statusBadgeBorder;
  final Color deltaPillBackground;
  final Color deltaPillForeground;

  /// `linear-gradient(90deg,#EA580C,#F59E0B 40%,#10B981)` on the score track.
  final Color scoreTrackStart;
  final Color scoreTrackMid;
  final Color scoreTrackEnd;

  /// The `::after` radial glow behind the score hero's top-right corner.
  final Color heroGlowWarm;
  final Color heroGlowCool;

  // --- Misc components ---
  final Color ctaBackground;
  final Color ctaForeground;
  final Color tickLit;
  final Color tickUnlit;
  final Color tileBackground;

  final Map<BentoTone, BentoPalette> bentos;

  BentoPalette bento(BentoTone tone) => bentos[tone]!;

  /// v4 uses Inter Tight 300–800; registered in `pubspec.yaml`.
  static const String fontFamily = 'InterTight';

  @override
  InsightBentoTheme copyWith({
    Color? screenBackground,
    Color? cardBackground,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textQuaternary,
    Color? mint,
    Color? coral,
    Color? gold,
    Color? purple,
    Color? orange,
    Color? positive,
    Color? negative,
    Color? statusBadgeBackground,
    Color? statusBadgeForeground,
    Color? statusBadgeBorder,
    Color? deltaPillBackground,
    Color? deltaPillForeground,
    Color? ctaBackground,
    Color? ctaForeground,
    Color? tickLit,
    Color? tickUnlit,
    Color? heroGlowWarm,
    Color? heroGlowCool,
    Color? scoreTrackStart,
    Color? scoreTrackMid,
    Color? scoreTrackEnd,
    Color? tileBackground,
    Map<BentoTone, BentoPalette>? bentos,
  }) => InsightBentoTheme(
    screenBackground: screenBackground ?? this.screenBackground,
    cardBackground: cardBackground ?? this.cardBackground,
    border: border ?? this.border,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textTertiary: textTertiary ?? this.textTertiary,
    textQuaternary: textQuaternary ?? this.textQuaternary,
    mint: mint ?? this.mint,
    coral: coral ?? this.coral,
    gold: gold ?? this.gold,
    purple: purple ?? this.purple,
    orange: orange ?? this.orange,
    positive: positive ?? this.positive,
    negative: negative ?? this.negative,
    statusBadgeBackground: statusBadgeBackground ?? this.statusBadgeBackground,
    statusBadgeForeground: statusBadgeForeground ?? this.statusBadgeForeground,
    statusBadgeBorder: statusBadgeBorder ?? this.statusBadgeBorder,
    deltaPillBackground: deltaPillBackground ?? this.deltaPillBackground,
    deltaPillForeground: deltaPillForeground ?? this.deltaPillForeground,
    ctaBackground: ctaBackground ?? this.ctaBackground,
    ctaForeground: ctaForeground ?? this.ctaForeground,
    tickLit: tickLit ?? this.tickLit,
    tickUnlit: tickUnlit ?? this.tickUnlit,
    heroGlowWarm: heroGlowWarm ?? this.heroGlowWarm,
    heroGlowCool: heroGlowCool ?? this.heroGlowCool,
    scoreTrackStart: scoreTrackStart ?? this.scoreTrackStart,
    scoreTrackMid: scoreTrackMid ?? this.scoreTrackMid,
    scoreTrackEnd: scoreTrackEnd ?? this.scoreTrackEnd,
    tileBackground: tileBackground ?? this.tileBackground,
    bentos: bentos ?? this.bentos,
  );

  @override
  InsightBentoTheme lerp(
    covariant ThemeExtension<InsightBentoTheme>? other,
    double t,
  ) {
    if (other is! InsightBentoTheme) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    final merged = <BentoTone, BentoPalette>{};
    for (final tone in BentoTone.values) {
      final a = bento(tone);
      final b = other.bento(tone);
      merged[tone] = BentoPalette(
        gradientStart: l(a.gradientStart, b.gradientStart),
        gradientEnd: l(a.gradientEnd, b.gradientEnd),
        border: l(a.border, b.border),
        tagBackground: l(a.tagBackground, b.tagBackground),
        tagForeground: l(a.tagForeground, b.tagForeground),
        footForeground: l(a.footForeground, b.footForeground),
        shadowTint: l(a.shadowTint, b.shadowTint),
      );
    }
    return InsightBentoTheme(
      screenBackground: l(screenBackground, other.screenBackground),
      cardBackground: l(cardBackground, other.cardBackground),
      border: l(border, other.border),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textTertiary: l(textTertiary, other.textTertiary),
      textQuaternary: l(textQuaternary, other.textQuaternary),
      mint: l(mint, other.mint),
      coral: l(coral, other.coral),
      gold: l(gold, other.gold),
      purple: l(purple, other.purple),
      orange: l(orange, other.orange),
      positive: l(positive, other.positive),
      negative: l(negative, other.negative),
      statusBadgeBackground: l(
        statusBadgeBackground,
        other.statusBadgeBackground,
      ),
      statusBadgeForeground: l(
        statusBadgeForeground,
        other.statusBadgeForeground,
      ),
      statusBadgeBorder: l(statusBadgeBorder, other.statusBadgeBorder),
      deltaPillBackground: l(deltaPillBackground, other.deltaPillBackground),
      deltaPillForeground: l(deltaPillForeground, other.deltaPillForeground),
      ctaBackground: l(ctaBackground, other.ctaBackground),
      ctaForeground: l(ctaForeground, other.ctaForeground),
      tickLit: l(tickLit, other.tickLit),
      tickUnlit: l(tickUnlit, other.tickUnlit),
      heroGlowWarm: l(heroGlowWarm, other.heroGlowWarm),
      heroGlowCool: l(heroGlowCool, other.heroGlowCool),
      scoreTrackStart: l(scoreTrackStart, other.scoreTrackStart),
      scoreTrackMid: l(scoreTrackMid, other.scoreTrackMid),
      scoreTrackEnd: l(scoreTrackEnd, other.scoreTrackEnd),
      tileBackground: l(tileBackground, other.tileBackground),
      bentos: merged,
    );
  }

  // ---------------------------------------------------------------------
  // LIGHT — verbatim from v4.html :root and the .bento-* rules.
  // ---------------------------------------------------------------------
  static const InsightBentoTheme light = InsightBentoTheme(
    screenBackground: Color(0xFFF8F9FA),
    cardBackground: Color(0xFFFFFFFF),
    border: Color(0xFFE5E7EB),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF374151),
    textTertiary: Color(0xFF6B7280),
    textQuaternary: Color(0xFF9CA3AF),
    mint: Color(0xFF10B981),
    coral: Color(0xFFEF4444),
    gold: Color(0xFFF59E0B),
    purple: Color(0xFF8B5CF6),
    orange: Color(0xFFEA580C),
    positive: Color(0xFF059669),
    negative: Color(0xFFDC2626),
    statusBadgeBackground: Color(0xFFF0FDF4),
    statusBadgeForeground: Color(0xFF047857),
    statusBadgeBorder: Color(0xFFDCFCE7),
    deltaPillBackground: Color(0xFFECFDF5),
    deltaPillForeground: Color(0xFF059669),
    scoreTrackStart: Color(0xFFEA580C),
    scoreTrackMid: Color(0xFFF59E0B),
    scoreTrackEnd: Color(0xFF10B981),
    heroGlowWarm: Color(0x1FEA580C),
    heroGlowCool: Color(0x1410B981),
    ctaBackground: Color(0xFF111827),
    ctaForeground: Color(0xFFFFFFFF),
    tickLit: Color(0xFF111827),
    tickUnlit: Color(0xFFE5E7EB),
    tileBackground: Color(0xFFFFFFFF),
    bentos: _lightBentos,
  );

  static const Map<BentoTone, BentoPalette> _lightBentos = {
    BentoTone.peach: BentoPalette(
      gradientStart: Color(0xFFFFF7ED),
      gradientEnd: Color(0xFFFFEDD5),
      border: Color(0xFFFED7AA),
      tagBackground: Color(0xFFFED7AA),
      tagForeground: Color(0xFF9A3412),
      footForeground: Color(0xFFC2410C),
      shadowTint: Color(0xFFEA580C),
    ),
    BentoTone.mint: BentoPalette(
      gradientStart: Color(0xFFF0FDF4),
      gradientEnd: Color(0xFFDCFCE7),
      border: Color(0xFFBBF7D0),
      tagBackground: Color(0xFFDCFCE7),
      tagForeground: Color(0xFF065F46),
      footForeground: Color(0xFF059669),
      shadowTint: Color(0xFF10B981),
    ),
    BentoTone.coral: BentoPalette(
      gradientStart: Color(0xFFFFF1F2),
      gradientEnd: Color(0xFFFFE4E6),
      border: Color(0xFFFECDD3),
      tagBackground: Color(0xFFFFE4E6),
      tagForeground: Color(0xFF9F1239),
      footForeground: Color(0xFFE11D48),
      shadowTint: Color(0xFFEF4444),
    ),
    BentoTone.amber: BentoPalette(
      gradientStart: Color(0xFFFFFBEB),
      gradientEnd: Color(0xFFFEF3C7),
      border: Color(0xFFFDE68A),
      tagBackground: Color(0xFFFEF3C7),
      tagForeground: Color(0xFF92400E),
      footForeground: Color(0xFFD97706),
      shadowTint: Color(0xFFF59E0B),
    ),
    BentoTone.purple: BentoPalette(
      gradientStart: Color(0xFFF5F3FF),
      gradientEnd: Color(0xFFEDE9FE),
      border: Color(0xFFDDD6FE),
      tagBackground: Color(0xFFEDE9FE),
      tagForeground: Color(0xFF5B21B6),
      footForeground: Color(0xFF7C3AED),
      shadowTint: Color(0xFF8B5CF6),
    ),
    BentoTone.white: BentoPalette(
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFFFFFFF),
      border: Color(0xFFE5E7EB),
      tagBackground: Color(0xFFF3F4F6),
      tagForeground: Color(0xFF374151),
      footForeground: Color(0xFF111827),
      shadowTint: Color(0xFF000000),
    ),
  };

  // ---------------------------------------------------------------------
  // DARK — derived by the HSL rule in .artifacts/derive_dark_palette.py.
  // ---------------------------------------------------------------------
  static const InsightBentoTheme dark = InsightBentoTheme(
    screenBackground: Color(0xFF0B0C0E),
    cardBackground: Color(0xFF121316),
    border: Color(0xFF2A2C31),
    textPrimary: Color(0xFFF5F7FA),
    textSecondary: Color(0xFFC3C9D4),
    textTertiary: Color(0xFF8D96A5),
    textQuaternary: Color(0xFF6E7683),
    mint: Color(0xFF68F3C5),
    coral: Color(0xFFF36868),
    gold: Color(0xFFF3BF68),
    purple: Color(0xFF9268F3),
    orange: Color(0xFFF39868),
    positive: Color(0xFF68F3C8),
    negative: Color(0xFFEE6D6D),
    statusBadgeBackground: Color(0xFF14331F),
    statusBadgeForeground: Color(0xFF68F3CB),
    statusBadgeBorder: Color(0xFF227740),
    deltaPillBackground: Color(0xFF123A2B),
    deltaPillForeground: Color(0xFF68F3C8),
    scoreTrackStart: Color(0xFFF39868),
    scoreTrackMid: Color(0xFFF3BF68),
    scoreTrackEnd: Color(0xFF68F3C5),
    heroGlowWarm: Color(0x24F39868),
    heroGlowCool: Color(0x1A68F3C5),
    ctaBackground: Color(0xFFF5F7FA),
    ctaForeground: Color(0xFF0B0C0E),
    tickLit: Color(0xFFF5F7FA),
    tickUnlit: Color(0xFF2A2C31),
    tileBackground: Color(0xFF17181C),
    bentos: _darkBentos,
  );

  static const Map<BentoTone, BentoPalette> _darkBentos = {
    BentoTone.peach: BentoPalette(
      gradientStart: Color(0xFF4A361C),
      gradientEnd: Color(0xFF362611),
      border: Color(0xFF775022),
      tagBackground: Color(0xFF6F4A20),
      tagForeground: Color(0xFFF3B19B),
      footForeground: Color(0xFFF58F65),
      shadowTint: Color(0xFFF39868),
    ),
    BentoTone.mint: BentoPalette(
      gradientStart: Color(0xFF1C4A2A),
      gradientEnd: Color(0xFF11361E),
      border: Color(0xFF227740),
      tagBackground: Color(0xFF206F3B),
      tagForeground: Color(0xFF95F8DD),
      footForeground: Color(0xFF61FACA),
      shadowTint: Color(0xFF68F3C5),
    ),
    BentoTone.coral: BentoPalette(
      gradientStart: Color(0xFF4A1C1F),
      gradientEnd: Color(0xFF361114),
      border: Color(0xFF77222D),
      tagBackground: Color(0xFF6F2026),
      tagForeground: Color(0xFFF49AB3),
      footForeground: Color(0xFFEC6E8A),
      shadowTint: Color(0xFFF36868),
    ),
    BentoTone.amber: BentoPalette(
      gradientStart: Color(0xFF4A411C),
      gradientEnd: Color(0xFF362F11),
      border: Color(0xFF776622),
      tagBackground: Color(0xFF6F5F20),
      tagForeground: Color(0xFFF5BC99),
      footForeground: Color(0xFFFBB360),
      shadowTint: Color(0xFFF3BF68),
    ),
    BentoTone.purple: BentoPalette(
      gradientStart: Color(0xFF241C4A),
      gradientEnd: Color(0xFF181136),
      border: Color(0xFF312277),
      tagBackground: Color(0xFF2F206F),
      tagForeground: Color(0xFFBEA0EE),
      footForeground: Color(0xFF9C69F1),
      shadowTint: Color(0xFF9268F3),
    ),
    BentoTone.white: BentoPalette(
      gradientStart: Color(0xFF121316),
      gradientEnd: Color(0xFF121316),
      border: Color(0xFF2A2C31),
      tagBackground: Color(0xFF26282D),
      tagForeground: Color(0xFFC3C9D4),
      footForeground: Color(0xFFF5F7FA),
      shadowTint: Color(0xFF000000),
    ),
  };
}

extension InsightBentoThemeX on BuildContext {
  /// The bento tokens for the current brightness, falling back to light so a
  /// screen never hard-crashes if the extension is missing from the theme.
  InsightBentoTheme get bentoTheme =>
      Theme.of(this).extension<InsightBentoTheme>() ?? InsightBentoTheme.light;
}
