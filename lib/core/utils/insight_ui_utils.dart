import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/theme/app_palette.dart';

/// UI Mappings for AI-generated insight data.
class InsightUiUtils {
  const InsightUiUtils._();

  /// Maps an icon name or emoji to a relevant [IconData].
  static IconData getReactionIcon(String source) {
    final s = source.toLowerCase();
    if (s.contains('🥗') || s.contains('🥬') || s.contains('🥦') || s.contains('leaf')) return AppIcons.leaf;
    if (s.contains('⚡') || s.contains('🔋') || s.contains('zap')) return AppIcons.zap;
    if (s.contains('💨') || s.contains('🌬️') || s.contains('wind')) return AppIcons.wind;
    if (s.contains('🍕') || s.contains('🍔') || s.contains('🍟') || s.contains('utensils')) return AppIcons.utensils;
    if (s.contains('🥛') || s.contains('🧀') || s.contains('milk')) return AppIcons.milk;
    if (s.contains('🍬') || s.contains('🍭') || s.contains('🍩') || s.contains('candy')) return AppIcons.candy;
    if (s.contains('🥩') || s.contains('🍖') || s.contains('beef')) return AppIcons.beef;
    if (s.contains('🥚') || s.contains('egg')) return AppIcons.egg;
    if (s.contains('🥜') || s.contains('nut')) return AppIcons.nut;
    if (s.contains('🐟') || s.contains('fish')) return AppIcons.fish;
    if (s.contains('💪') || s.contains('dumbbell')) return AppIcons.dumbbell;
    if (s.contains('🧠') || s.contains('brain')) return AppIcons.brain;
    if (s.contains('⚠️') || s.contains('🚫') || s.contains('alert')) return AppIcons.alertTriangle;
    return AppIcons.sparkles;
  }

  /// Returns a branding-consistent color for a specific pattern category.
  static Color getPatternColor(String iconName) => AppPalette.black;

  /// Maps ingredient risk levels (red, orange, green) to theme colors.
  static Color getIngredientColor(String colorName, {required Color error, required Color warning, required Color success}) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return error;
      case 'orange':
        return warning;
      default:
        return success;
    }
  }

  /// Maps ingredient risk levels to appropriate icons.
  static IconData getIngredientIcon(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return AppIcons.alertTriangle;
      case 'orange':
        return AppIcons.alertCircle;
      default:
        return AppIcons.leaf;
    }
  }
}
