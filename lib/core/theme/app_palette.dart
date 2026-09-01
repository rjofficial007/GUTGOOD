import 'package:flutter/material.dart';

/// Centralized color palette for the GutGood app.
/// This class contains atomic hex values and base semantic colors.
class AppPalette {
  const AppPalette._();

  // --- Atomic Palette (Grays) ---
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF0A0A0A);
  static const gray25 = Color(0xFFFCFCFD);
  static const gray50 = Color(0xFFF7F7F8);
  static const gray100 = Color(0xFFF0F0F2);
  static const gray200 = Color(0xFFE4E4E8);
  static const gray300 = Color(0xFFCFCFD4);
  static const gray400 = Color(0xFF9CA0AB);
  static const gray500 = Color(0xFF6E7280);
  static const gray600 = Color(0xFF4A4E5A);
  static const gray700 = Color(0xFF2D3039);
  static const gray800 = Color(0xFF1A1C22);

  // --- Dark Theme Primatives ---
  static const darkPrimary = Color(0xFF000000);
  static const darkSecondary = Color(0xFF0A0A0A);
  static const darkTertiary = Color(0xFF121212);
  static const darkCard = Color(0xFF0D0D0D);
  static const darkElevated = Color(0xFF1A1A1A);
  static const darkBorder = Color(0xFF1F1F1F);
  static const darkTextPrimary = Color(0xFFF5F7FA);
  static const darkTextSecondary = Color(0xFFB8C0CC);
  static const darkTextMuted = Color(0xFF8D96A5);

  // --- Semantic Colors ---
  static const greenSoft = Color(0xFFE7F6E7);
  static const redSoft = Color(0xFFFFF1F0);
  static const orangeSoft = Color(0xFFFFF4E5);
  static const lavender = Color(0xFFF1F0FF);
  static const lavenderDark = Color(0xFF6750A4);

  static const green = Color(0xFF1F7A3D);
  static const green500 = Color(0xFF22C55E);
  static const greenLight = Color(0xFFE8F5EC);
  static const greenBg = Color(0xFFF0F9F3);

  static const red = Color(0xFFC4302B);
  static const redLight = Color(0xFFFEE9E7);
  static const redBg = Color(0xFFFFF4F3);

  static const orange = Color(0xFFFFAB40);
  static const orangeLight = Color(0xFFFEF3E2);

  static const yellow = Color(0xFFEAB308);
  static const yellowLight = Color(0xFFFEF9C3);

  static const blue = Color(0xFF1D4ED8);
  static const blueLight = Color(0xFFDBEAFE);

  static const purple = Color(0xFF7C3AED);
  static const purpleLight = Color(0xFFEDE9FE);

  static const pink = Color(0xFFDB2777);
  static const pinkLight = Color(0xFFFCE7F3);
  static const pinkDark = Color(0xFFF472B6);
  static const greenPastel = Color(0xFFB4F1B4);
  static const purplePastel = Color(0xFFC4B5FD);
  static const bluePastel = Color(0xFF98B7FF);
  static const darkGrey = Color(0xFF181818);

  // --- Nutri-Score ---
  static const nutriGreen = Color(0xFF038141);
  static const nutriLightGreen = Color(0xFF85BB2F);
  static const nutriYellow = Color(0xFFFECB02);
  static const nutriOrange = Color(0xFFEE8100);
  static const nutriRed = Color(0xFFE63E11);

  // --- Accents ---
  static const lime = Color(0xFFD9FF30);
  static const softBlue = Color(0xFF98B7FF);
  static const blueLink = Color(0xFF3897F0);

  // --- Misc ---
  static const splashBg = Color(0xFF060606);
  static const transparent = Colors.transparent;
  static const scrim = Color(0x1A000000);
  static const overlay = Color(0x66000000);
  static const white15 = Color(0x26FFFFFF);

  // --- Material Colors (Static equivalents) ---
  static const white70 = Color(0xB3FFFFFF);
  static const black12 = Color(0x1F000000);
  static const aiResponseBackground = Color(0xFFF7F7F7);

  static Color shimmerBase(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? gray800 : gray200;
  static Color shimmerHighlight(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? gray700 : gray50;
}
