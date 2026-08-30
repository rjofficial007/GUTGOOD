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
    required this.moderate,
    required this.softModerate,
    required this.info,
    required this.softInfo,
    required this.lavender,
    required this.lavenderDark,
    required this.aiResponseBackground,
    required this.borderSubtle,
    required this.surfaceSubtle,
    required this.textDisabled,
    required this.successSubtle,
    required this.errorSubtle,
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
  final Color moderate;
  final Color softModerate;
  final Color info;
  final Color softInfo;
  final Color lavender;
  final Color lavenderDark;
  final Color aiResponseBackground;
  final Color borderSubtle;
  final Color surfaceSubtle;
  final Color textDisabled;
  final Color successSubtle;
  final Color errorSubtle;

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
    Color? moderate,
    Color? softModerate,
    Color? info,
    Color? softInfo,
    Color? lavender,
    Color? lavenderDark,
    Color? aiResponseBackground,
    Color? borderSubtle,
    Color? surfaceSubtle,
    Color? textDisabled,
    Color? successSubtle,
    Color? errorSubtle,
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
    moderate: moderate ?? this.moderate,
    softModerate: softModerate ?? this.softModerate,
    info: info ?? this.info,
    softInfo: softInfo ?? this.softInfo,
    lavender: lavender ?? this.lavender,
    lavenderDark: lavenderDark ?? this.lavenderDark,
    aiResponseBackground: aiResponseBackground ?? this.aiResponseBackground,
    borderSubtle: borderSubtle ?? this.borderSubtle,
    surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
    textDisabled: textDisabled ?? this.textDisabled,
    successSubtle: successSubtle ?? this.successSubtle,
    errorSubtle: errorSubtle ?? this.errorSubtle,
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
      moderate: Color.lerp(moderate, other.moderate, t)!,
      softModerate: Color.lerp(softModerate, other.softModerate, t)!,
      info: Color.lerp(info, other.info, t)!,
      softInfo: Color.lerp(softInfo, other.softInfo, t)!,
      lavender: Color.lerp(lavender, other.lavender, t)!,
      lavenderDark: Color.lerp(lavenderDark, other.lavenderDark, t)!,
      aiResponseBackground: Color.lerp(aiResponseBackground, other.aiResponseBackground, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      successSubtle: Color.lerp(successSubtle, other.successSubtle, t)!,
      errorSubtle: Color.lerp(errorSubtle, other.errorSubtle, t)!,
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
    moderate: AppPalette.yellow,
    softModerate: AppPalette.yellowLight,
    info: AppPalette.blue,
    softInfo: AppPalette.blueLight,
    lavender: AppPalette.lavender,
    lavenderDark: AppPalette.lavenderDark,
    aiResponseBackground: AppPalette.aiResponseBackground,
    borderSubtle: Color(0x80E4E4E8),
    surfaceSubtle: Color(0x080A0A0A),
    textDisabled: Color(0x806E7280),
    successSubtle: Color(0x0D1F7A3D),
    errorSubtle: Color(0x14C4302B),
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
    moderate: AppPalette.yellow,
    softModerate: Color(0xFF3A361E),
    info: AppPalette.blue,
    softInfo: Color(0xFF1E2A3A),
    lavender: Color(0xFF2A2E3A),
    lavenderDark: AppPalette.purpleLight,
    aiResponseBackground: AppPalette.darkElevated,
    borderSubtle: Color(0x801F1F1F),
    surfaceSubtle: Color(0x08F5F7FA),
    textDisabled: Color(0x808D96A5),
    successSubtle: Color(0x1A22C55E),
    errorSubtle: Color(0x26C4302B),
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
