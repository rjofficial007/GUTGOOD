import 'package:flutter/material.dart';

/// Font resolution mirrored from `docs/insight_genz_formatted.html`:
/// SF Pro Rounded, ui-rounded, Inter, Helvetica Neue, Arial, system-ui, sans-serif.
/// Flutter cannot represent CSS generic families directly, so Android's
/// `sans-serif-rounded` is inserted as the platform equivalent of `ui-rounded`.
class GenzFonts {
  static const String primary = 'SF Pro Rounded';
  static const List<String> fallback = <String>[
    'ui-rounded',
    'sans-serif-rounded',
    'Inter',
    'Helvetica Neue',
    'Arial',
    'system-ui',
    'sans-serif',
  ];
}

class GenzColors {
  // Constant Palette Colors
  static const Color lime = Color(0xFFC9FF3B);
  static const Color pink = Color(0xFFFF5FA8);
  static const Color blue = Color(0xFF4F6BFF);
  static const Color orange = Color(0xFFFF8A1F);
  static const Color lilac = Color(0xFFB9A2FF);
  static const Color butter = Color(0xFFFFE45C);
  static const Color paper = Color(0xFFFBF8F1);
  static const Color ink = Color(0xFF0B0B12);

  // Theme-Aware Dynamic Colors (Dark vs Light mode)
  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  static Color bg(BuildContext context) => isDark(context) ? const Color(0xFF0B0B12) : const Color(0xFFF3F1EC);
  static Color sf(BuildContext context) => isDark(context) ? const Color(0xFF171722) : Colors.white;
  static Color sf2(BuildContext context) => isDark(context) ? const Color(0xFF22222F) : const Color(0xFFE9E6DF);
  static Color tx(BuildContext context) => isDark(context) ? Colors.white : const Color(0xFF0B0B12);
  static Color mu(BuildContext context) => isDark(context) ? const Color(0xFF9B9BB0) : const Color(0xFF6C6C7C);
  static Color ln(BuildContext context) => isDark(context) ? const Color(0x1CFFFFFF) : const Color(0x1C0B0B12);
  static Color nav(BuildContext context) => isDark(context) ? const Color(0xFF171722) : const Color(0xFF0B0B12);
  static Color scaffoldBg(BuildContext context) => bg(context);
  static Color tileInk(BuildContext context) => isDark(context) ? const Color(0xFF1A1A27) : const Color(0xFF0B0B12);
}

class GenzStyles {
  static TextStyle h1(BuildContext context) => TextStyle(
        fontFamily: GenzFonts.primary,
        fontFamilyFallback: GenzFonts.fallback,
        fontSize: 38,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.8,
        height: 0.98,
        color: GenzColors.tx(context),
      );

  static TextStyle eyebrow(BuildContext context) => TextStyle(
        fontFamily: GenzFonts.primary,
        fontFamilyFallback: GenzFonts.fallback,
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: GenzColors.mu(context),
      );

  static TextStyle h2(BuildContext context) => TextStyle(
        fontFamily: GenzFonts.primary,
        fontFamilyFallback: GenzFonts.fallback,
        fontSize: 22,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.8,
        color: GenzColors.tx(context),
      );

  static const TextStyle big = TextStyle(
    fontFamily: GenzFonts.primary,
    fontFamilyFallback: GenzFonts.fallback,
    fontSize: 104,
    fontWeight: FontWeight.w900,
    letterSpacing: -6,
    height: 0.82,
    color: GenzColors.ink,
  );

  static const TextStyle title = TextStyle(
    fontFamily: GenzFonts.primary,
    fontFamilyFallback: GenzFonts.fallback,
    fontSize: 30,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.3,
    height: 1.0,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: GenzFonts.primary,
    fontFamilyFallback: GenzFonts.fallback,
    fontSize: 14.5,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );
}
