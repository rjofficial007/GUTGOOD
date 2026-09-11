import 'package:flutter/material.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/utils/responsive.dart';

class AppTextStyles {
  const AppTextStyles._();

  // Typography Scale - No hardcoded colors here by default to allow theme inheritance
  static TextStyle get displayHero => TextStyle(fontSize: 72.0.sp, fontWeight: FontWeight.w900, letterSpacing: -0.05, height: 1.0);
  static TextStyle get displayLg => TextStyle(fontSize: 56.0.sp, fontWeight: FontWeight.w900, letterSpacing: -0.04, height: 1.1);
  static TextStyle get displayMd => TextStyle(fontSize: 44.0.sp, fontWeight: FontWeight.w900, letterSpacing: -0.04, height: 1.1);
  static TextStyle get displaySm => TextStyle(fontSize: 34.0.sp, fontWeight: FontWeight.w800, letterSpacing: -0.03, height: 1.1);

  static TextStyle get headingLg => TextStyle(fontSize: 28.0.sp, fontWeight: FontWeight.w800, letterSpacing: -0.02, height: 1.25);
  static TextStyle get headingMd => TextStyle(fontSize: 24.0.sp, fontWeight: FontWeight.w700, letterSpacing: -0.02, height: 1.25);
  static TextStyle get headingSm => TextStyle(fontSize: 20.0.sp, fontWeight: FontWeight.w700, letterSpacing: -0.02, height: 1.25);

  static TextStyle get title => const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.02, height: 1.25);

  static TextStyle get bodyLg => TextStyle(fontSize: 16.0.sp, fontWeight: FontWeight.w400, letterSpacing: -0.01, height: 1.5);
  static TextStyle get body => TextStyle(fontSize: 15.0.sp, fontWeight: FontWeight.w400, letterSpacing: -0.01, height: 1.4);
  static TextStyle get bodySm => TextStyle(fontSize: 13.0.sp, fontWeight: FontWeight.w400, letterSpacing: -0.01, height: 1.5);

  static TextStyle get label => TextStyle(fontSize: 13.0.sp, fontWeight: FontWeight.w500, letterSpacing: -0.01, height: 1.4);
  static TextStyle get labelBold => TextStyle(fontSize: 11.0.sp, fontWeight: FontWeight.w900, letterSpacing: -0.01, height: 1.4);
  static TextStyle get caption => TextStyle(fontSize: 10.0.sp, fontWeight: FontWeight.w500, letterSpacing: 0.01, height: 1.4);
  static TextStyle get captionBold => TextStyle(fontSize: 8.5.sp, fontWeight: FontWeight.w900, letterSpacing: 0.01, height: 1.2);
  static TextStyle get captionTiny => TextStyle(fontSize: 7.0.sp, fontWeight: FontWeight.w900, letterSpacing: 0.01, height: 1.2);
  static TextStyle get captionMicro => TextStyle(fontSize: 6.0.sp, fontWeight: FontWeight.w800, letterSpacing: 0.01, height: 1.1);
  static TextStyle get overline => TextStyle(fontSize: 11.0.sp, fontWeight: FontWeight.w700, letterSpacing: 0.1, height: 1.4);
  static TextStyle get eyebrow => TextStyle(fontSize: 10.0.sp, fontWeight: FontWeight.w900, letterSpacing: 1.5, height: 1.2);

  // Aliases & Legacy mappings
  static TextStyle get h1 => displaySm;
  static TextStyle get h2 => headingMd;
  static TextStyle get h3 => title;
  static TextStyle get bodyBold => TextStyle(fontSize: 14.0.sp, fontWeight: FontWeight.w700, letterSpacing: -0.1);
  static TextStyle get underline => const TextStyle(decoration: TextDecoration.underline);
}

extension AppTextStylesX on BuildContext {
  TextStyle get displayHero => AppTextStyles.displayHero.copyWith(color: appColorScheme.textPrimary);
  TextStyle get displayLg => AppTextStyles.displayLg.copyWith(color: appColorScheme.textPrimary);
  TextStyle get displayMd => AppTextStyles.displayMd.copyWith(color: appColorScheme.textPrimary);
  TextStyle get displaySm => AppTextStyles.displaySm.copyWith(color: appColorScheme.textPrimary);

  TextStyle get headingLg => AppTextStyles.headingLg.copyWith(color: appColorScheme.textPrimary);
  TextStyle get headingMd => AppTextStyles.headingMd.copyWith(color: appColorScheme.textPrimary);
  TextStyle get headingSm => AppTextStyles.headingSm.copyWith(color: appColorScheme.textPrimary);

  TextStyle get title => AppTextStyles.title.copyWith(color: appColorScheme.textPrimary);

  TextStyle get bodyLg => AppTextStyles.bodyLg.copyWith(color: appColorScheme.textPrimary);
  TextStyle get body => AppTextStyles.body.copyWith(color: appColorScheme.textPrimary);
  TextStyle get bodySm => AppTextStyles.bodySm.copyWith(color: appColorScheme.textPrimary);

  TextStyle get h1 => AppTextStyles.h1.copyWith(color: appColorScheme.textPrimary);
  TextStyle get h2 => AppTextStyles.h2.copyWith(color: appColorScheme.textPrimary);
  TextStyle get h3 => AppTextStyles.h3.copyWith(color: appColorScheme.textPrimary);

  TextStyle get label => AppTextStyles.label.copyWith(color: appColorScheme.textPrimary);
  TextStyle get labelBold => AppTextStyles.labelBold.copyWith(color: appColorScheme.textPrimary);
  TextStyle get caption => AppTextStyles.caption.copyWith(color: appColorScheme.textSecondary);
  TextStyle get captionBold => AppTextStyles.captionBold.copyWith(color: appColorScheme.textSecondary);
  TextStyle get captionTiny => AppTextStyles.captionTiny.copyWith(color: appColorScheme.textSecondary);
  TextStyle get captionMicro => AppTextStyles.captionMicro.copyWith(color: appColorScheme.textMuted);
  TextStyle get overline => AppTextStyles.overline.copyWith(color: appColorScheme.textMuted);
  TextStyle get eyebrow => AppTextStyles.eyebrow.copyWith(color: appColorScheme.textMuted);

  TextStyle get bodyBold => AppTextStyles.bodyBold.copyWith(color: appColorScheme.textPrimary);
  TextStyle get underline => AppTextStyles.underline.copyWith(color: appColorScheme.textPrimary);
}
