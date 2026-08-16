import 'package:flutter/material.dart';

import 'package:gutgood/core/theme/app_palette.dart';

class AppColorScheme extends ThemeExtension<AppColorScheme> {
  const AppColorScheme({
    required this.cardBackground,
    required this.elevatedSurface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.success,
    required this.error,
    required this.warning,
    required this.info,
    required this.aiResponseBackground,
  });

  final Color cardBackground;
  final Color elevatedSurface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color success;
  final Color error;
  final Color warning;
  final Color info;
  final Color aiResponseBackground;

  @override
  ThemeExtension<AppColorScheme> copyWith({
    Color? cardBackground,
    Color? elevatedSurface,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? success,
    Color? error,
    Color? warning,
    Color? info,
    Color? aiResponseBackground,
  }) =>
      AppColorScheme(
        cardBackground: cardBackground ?? this.cardBackground,
        elevatedSurface: elevatedSurface ?? this.elevatedSurface,
        border: border ?? this.border,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textMuted: textMuted ?? this.textMuted,
        success: success ?? this.success,
        error: error ?? this.error,
        warning: warning ?? this.warning,
        info: info ?? this.info,
        aiResponseBackground: aiResponseBackground ?? this.aiResponseBackground,
      );

  @override
  ThemeExtension<AppColorScheme> lerp(
    ThemeExtension<AppColorScheme>? other,
    double t,
  ) {
    if (other is! AppColorScheme) return this;
    return AppColorScheme(
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      elevatedSurface: Color.lerp(elevatedSurface, other.elevatedSurface, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      aiResponseBackground: Color.lerp(aiResponseBackground, other.aiResponseBackground, t)!,
    );
  }

  static const light = AppColorScheme(
    cardBackground: AppPalette.white,
    elevatedSurface: AppPalette.white,
    border: AppPalette.gray200,
    textPrimary: AppPalette.black,
    textSecondary: AppPalette.gray600,
    textMuted: AppPalette.gray500,
    success: AppPalette.green,
    error: AppPalette.red,
    warning: AppPalette.orange,
    info: AppPalette.blue,
    aiResponseBackground: AppPalette.gray50,
  );

  static const dark = AppColorScheme(
    cardBackground: AppPalette.darkPrimary,
    elevatedSurface: AppPalette.darkCard,
    border: AppPalette.darkBorder,
    textPrimary: AppPalette.darkTextPrimary,
    textSecondary: AppPalette.darkTextSecondary,
    textMuted: AppPalette.darkTextMuted,
    success: AppPalette.green500,
    error: AppPalette.red,
    warning: AppPalette.orange,
    info: AppPalette.blue,
    aiResponseBackground: AppPalette.darkElevated,
  );
}

extension AppColorSchemeX on BuildContext {
  AppColorScheme get appColorScheme {
    final extension = Theme.of(this).extension<AppColorScheme>();
    if (extension != null) return extension;

    // Fallback to light scheme if not found (prevents crash)
    return AppColorScheme.light;
  }
}
