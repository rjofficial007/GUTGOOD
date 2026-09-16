import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/insight_bento_theme.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_theme.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppPalette.gray25,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppPalette.black,
      brightness: Brightness.light,
      surface: AppPalette.white,
      onSurface: AppPalette.black,
      primary: AppPalette.black,
      onPrimary: AppPalette.white,
      secondary: AppPalette.gray600,
      onSecondary: AppPalette.white,
      error: AppPalette.red,
      onError: AppPalette.white,
      outline: AppPalette.gray200,
    ),
    dividerTheme: const DividerThemeData(
      color: AppPalette.gray100,
      thickness: 1,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppPalette.white,
      surfaceTintColor: AppPalette.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppPalette.black,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: AppPalette.black),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppPalette.black,
        foregroundColor: AppPalette.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppPalette.black,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppPalette.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppPalette.gray200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppPalette.gray200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppPalette.black, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppPalette.red),
      ),
      hintStyle: const TextStyle(color: AppPalette.gray400, fontSize: 16),
    ),
    extensions: const [
      AppColorScheme.light,
      InsightBentoTheme.light,
      InsightV2Theme.light,
    ],
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppPalette.darkPrimary,
    colorScheme: const ColorScheme.dark(
      surface: AppPalette.darkSecondary,
      onSurface: AppPalette.darkTextPrimary,
      primary: AppPalette.white,
      onPrimary: AppPalette.black,
      secondary: AppPalette.darkTextSecondary,
      onSecondary: AppPalette.black,
      error: AppPalette.red,
      onError: AppPalette.white,
      outline: AppPalette.darkBorder,
    ),
    dividerTheme: const DividerThemeData(
      color: AppPalette.darkBorder,
      thickness: 1,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppPalette.darkPrimary,
      surfaceTintColor: AppPalette.darkPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppPalette.darkTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: AppPalette.darkTextPrimary),
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppPalette.white,
        foregroundColor: AppPalette.black,
        elevation: 0,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppPalette.darkTextPrimary,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppPalette.darkSecondary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppPalette.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppPalette.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppPalette.white, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppPalette.red),
      ),
      hintStyle: const TextStyle(
        color: AppPalette.darkTextSecondary,
        fontSize: 16,
      ),
    ),
    extensions: const [
      AppColorScheme.dark,
      InsightBentoTheme.dark,
      InsightV2Theme.dark,
    ],
  );
}
