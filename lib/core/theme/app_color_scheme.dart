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
    required this.softSuccess,
    required this.error,
    required this.softError,
    required this.warning,
    required this.softWarning,
    required this.info,
    required this.softInfo,
    required this.lavender,
    required this.lavenderDark,
    required this.aiResponseBackground,
  });

  final Color cardBackground;
  final Color elevatedSurface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color success;
  final Color softSuccess;
  final Color error;
  final Color softError;
  final Color warning;
  final Color softWarning;
  final Color info;
  final Color softInfo;
  final Color lavender;
  final Color lavenderDark;
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
    Color? softSuccess,
    Color? error,
    Color? softError,
    Color? warning,
    Color? softWarning,
    Color? info,
    Color? softInfo,
    Color? lavender,
    Color? lavenderDark,
    Color? aiResponseBackground,
  }) => AppColorScheme(
    cardBackground: cardBackground ?? this.cardBackground,
    elevatedSurface: elevatedSurface ?? this.elevatedSurface,
    border: border ?? this.border,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textMuted: textMuted ?? this.textMuted,
    success: success ?? this.success,
    softSuccess: softSuccess ?? this.softSuccess,
    error: error ?? this.error,
    softError: softError ?? this.softError,
    warning: warning ?? this.warning,
    softWarning: softWarning ?? this.softWarning,
    info: info ?? this.info,
    softInfo: softInfo ?? this.softInfo,
    lavender: lavender ?? this.lavender,
    lavenderDark: lavenderDark ?? this.lavenderDark,
    aiResponseBackground: aiResponseBackground ?? this.aiResponseBackground,
  );

  @override
  ThemeExtension<AppColorScheme> lerp(ThemeExtension<AppColorScheme>? other, double t) {
    if (other is! AppColorScheme) return this;
    return AppColorScheme(
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      elevatedSurface: Color.lerp(elevatedSurface, other.elevatedSurface, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      success: Color.lerp(success, other.success, t)!,
      softSuccess: Color.lerp(softSuccess, other.softSuccess, t)!,
      error: Color.lerp(error, other.error, t)!,
      softError: Color.lerp(softError, other.softError, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      softWarning: Color.lerp(softWarning, other.softWarning, t)!,
      info: Color.lerp(info, other.info, t)!,
      softInfo: Color.lerp(softInfo, other.softInfo, t)!,
      lavender: Color.lerp(lavender, other.lavender, t)!,
      lavenderDark: Color.lerp(lavenderDark, other.lavenderDark, t)!,
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
    softSuccess: AppPalette.greenSoft,
    error: AppPalette.red,
    softError: AppPalette.redSoft,
    warning: AppPalette.orange,
    softWarning: AppPalette.orangeSoft,
    info: AppPalette.blue,
    softInfo: AppPalette.blueLight,
    lavender: AppPalette.lavender,
    lavenderDark: AppPalette.lavenderDark,
    aiResponseBackground: AppPalette.aiResponseBackground,
  );

  static const dark = AppColorScheme(
    cardBackground: AppPalette.darkPrimary,
    elevatedSurface: AppPalette.darkCard,
    border: AppPalette.darkBorder,
    textPrimary: AppPalette.darkTextPrimary,
    textSecondary: AppPalette.darkTextSecondary,
    textMuted: AppPalette.darkTextMuted,
    success: AppPalette.green500,
    softSuccess: Color(0xFF1E3A1E),
    error: AppPalette.red,
    softError: Color(0xFF3A1E1E),
    warning: AppPalette.orange,
    softWarning: Color(0xFF3A2A1E),
    info: AppPalette.blue,
    softInfo: Color(0xFF1E2A3A),
    lavender: Color(0xFF2A2E3A),
    lavenderDark: AppPalette.purpleLight,
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
