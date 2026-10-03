import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/data/additive_concern_db.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';

/// Shared concern-level palette for the additives list + detail screens.
class AdditiveLevelColors {
  const AdditiveLevelColors({required this.background, required this.accent, required this.pillBackground, required this.iconBackground, required this.mainCardBackground});

  /// Card/Tile background (insight cards).
  final Color background;

  /// Primary color (icons, active text, etc.).
  final Color accent;

  /// Pill background (dot + label sit on this).
  final Color pillBackground;

  /// Large header icon background.
  final Color iconBackground;

  /// Background for the entire screen's main card.
  final Color mainCardBackground;

  /// Flask for high-risk additives, leaf for everything else.
  static IconData iconFor(AdditiveConcernLevel level) => level == AdditiveConcernLevel.higher ? AppIcons.flaskConical : AppIcons.leaf;

  static AdditiveLevelColors of(BuildContext context, AdditiveConcernLevel level) {
    final scheme = context.appColorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    switch (level) {
      case AdditiveConcernLevel.higher:
        return AdditiveLevelColors(
          accent: dark ? scheme.error : const Color(0xFFE52B2B),
          background: dark ? scheme.softError : const Color(0xFFFFF0F1),
          pillBackground: dark ? scheme.cardBackground : const Color(0xFFFFDDE0),
          iconBackground: dark ? scheme.surfaceSubtle : const Color(0xFFFFE6E8),
          mainCardBackground: dark ? scheme.cardBackground : const Color(0xFFFFF8F8),
        );
      case AdditiveConcernLevel.moderate:
        return AdditiveLevelColors(
          accent: dark ? scheme.warning : const Color(0xFFECAA17),
          background: dark ? scheme.softWarning : const Color(0xFFFFF8E7),
          pillBackground: dark ? scheme.cardBackground : const Color(0xFFFBE8C8),
          iconBackground: dark ? scheme.surfaceSubtle : const Color(0xFFFFF6E6),
          mainCardBackground: dark ? scheme.cardBackground : const Color(0xFFFFFBF0),
        );
      case AdditiveConcernLevel.low:
        return AdditiveLevelColors(
          accent: dark ? scheme.success : const Color(0xFF087B4D),
          background: dark ? scheme.softSuccess : const Color(0xFFF0F8F3),
          pillBackground: dark ? scheme.cardBackground : const Color(0xFFE8F6EE),
          iconBackground: dark ? scheme.surfaceSubtle : const Color(0xFFE0F2E9),
          mainCardBackground: dark ? scheme.cardBackground : const Color(0xFFF7FDF9),
        );
      case AdditiveConcernLevel.unknown:
        return AdditiveLevelColors(
          accent: scheme.textSecondary,
          background: dark ? scheme.surfaceSubtle : const Color(0xFFF4F5F7),
          pillBackground: dark ? scheme.cardBackground : const Color(0xFFE4E6EA),
          iconBackground: dark ? scheme.surfaceSubtle : const Color(0xFFE8EAEF),
          mainCardBackground: dark ? scheme.cardBackground : const Color(0xFFFCFCFC),
        );
    }
  }
}

/// Label pill used on additive cards and the detail header.
