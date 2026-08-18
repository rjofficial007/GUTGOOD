import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/theme/app_palette.dart';

/// UI Mappings for AI-generated insight data.
class InsightUiUtils {
  const InsightUiUtils._();

  /// Maps an icon name or emoji to a relevant [IconData].
  static IconData getReactionIcon(String source) {
    final s = source.toLowerCase();
    return switch (s) {
      _ when s.contains('🥗') || s.contains('🥬') || s.contains('🥦') || s.contains('leaf') => AppIcons.leaf,
      _ when s.contains('⚡') || s.contains('🔋') || s.contains('zap') => AppIcons.zap,
      _ when s.contains('💨') || s.contains('🌬️') || s.contains('wind') => AppIcons.wind,
      _ when s.contains('🍕') || s.contains('🍔') || s.contains('🍟') || s.contains('utensils') => AppIcons.utensils,
      _ when s.contains('🥛') || s.contains('🧀') || s.contains('milk') => AppIcons.milk,
      _ when s.contains('🍬') || s.contains('🍭') || s.contains('🍩') || s.contains('candy') => AppIcons.candy,
      _ when s.contains('🥩') || s.contains('🍖') || s.contains('beef') => AppIcons.beef,
      _ when s.contains('🥚') || s.contains('egg') => AppIcons.egg,
      _ when s.contains('🥜') || s.contains('nut') => AppIcons.nut,
      _ when s.contains('🐟') || s.contains('fish') => AppIcons.fish,
      _ when s.contains('💪') || s.contains('dumbbell') => AppIcons.dumbbell,
      _ when s.contains('🧠') || s.contains('brain') => AppIcons.brain,
      _ when s.contains('⚠️') || s.contains('🚫') || s.contains('alert') => AppIcons.alertTriangle,
      _ when s.contains('🌟') || s.contains('⭐') || s.contains('star') => AppIcons.star,
      _ when s.contains('🏆') || s.contains('trophy') => AppIcons.trophy,
      _ => AppIcons.salad,
    };
  }

  static IconData getPatternTypeIcon(String type) => switch (type) {
    BodyPattern.typeBloating => AppIcons.wind,
    BodyPattern.typeEnergy => AppIcons.zap,
    BodyPattern.typeHeadache => AppIcons.activity,
    BodyPattern.typeDigestion => AppIcons.alertCircle,
    BodyPattern.typeFullness => AppIcons.utensils,
    BodyPattern.typeSleep => AppIcons.moon,
    _ => AppIcons.lightbulb,
  };

  /// Returns a branding-consistent color for a specific pattern category.
  /// Minimalist approach: use a unified dark/neutral color.
  static Color getPatternColor(String type) => AppPalette.black;

  /// Maps ingredient risk levels (red, orange, green) to theme colors.
  static Color getIngredientColor(String colorName, {required Color error, required Color warning, required Color success}) => switch (colorName.toLowerCase()) {
    'red' || 'error' => error,
    'orange' || 'warning' || 'gold' => warning,
    'green' || 'success' => success,
    _ => success,
  };

  /// Maps ingredient risk levels to appropriate icons.
  static IconData getIngredientIcon(String colorName) => switch (colorName.toLowerCase()) {
    'red' => AppIcons.alertTriangle,
    'orange' => AppIcons.alertCircle,
    _ => AppIcons.leaf,
  };
}
