import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_strings.dart';
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

  /// Maps a symptom name to a relevant [IconData].
  static IconData getSymptomIcon(String? symptom) {
    if (symptom == null) return AppIcons.activity;
    final s = symptom.toLowerCase();
    if (s.contains('bloat')) return AppIcons.frown;
    if (s.contains('gas')) return AppIcons.wind;
    if (s.contains('energy')) return AppIcons.zap;
    if (s.contains('fatigue')) return AppIcons.batteryLow;
    if (s.contains('headache')) return AppIcons.brain;
    if (s.contains('pain') || s.contains('cramp')) return AppIcons.alertTriangle;
    if (s.contains('skin')) return AppIcons.sparkles;
    if (s.contains('mood')) return AppIcons.smile;
    return AppIcons.activity;
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
  static Color getPatternColor(String type) => switch (type) {
    BodyPattern.typeBloating => AppPalette.green,
    BodyPattern.typeEnergy => AppPalette.yellow,
    BodyPattern.typeHeadache => AppPalette.red,
    BodyPattern.typeDigestion => AppPalette.orange,
    BodyPattern.typeFullness => AppPalette.blue,
    BodyPattern.typeSleep => AppPalette.purple,
    _ => AppPalette.black,
  };

  /// Returns a soft pastel shade for a specific pattern category (ideal for Bento cards).
  static Color getPatternPastelColor(String type) => switch (type) {
    BodyPattern.typeBloating => AppPalette.greenPastel,
    BodyPattern.typeEnergy => AppPalette.yellowLight,
    BodyPattern.typeHeadache => AppPalette.redSoft,
    BodyPattern.typeDigestion => AppPalette.orangeSoft,
    BodyPattern.typeFullness => AppPalette.bluePastel,
    BodyPattern.typeSleep => AppPalette.purplePastel,
    _ => AppPalette.gray100,
  };

  /// Returns the proper display name for a pattern category.
  static String getPatternName(String type) => switch (type) {
    BodyPattern.typeBloating => AppStrings.bloatingPattern,
    BodyPattern.typeEnergy => AppStrings.energyPattern,
    BodyPattern.typeHeadache => AppStrings.headachePattern,
    BodyPattern.typeDigestion => AppStrings.digestionPattern,
    BodyPattern.typeFullness => AppStrings.fullnessPattern,
    BodyPattern.typeSleep => AppStrings.sleepPattern,
    _ => AppStrings.discoveryPattern,
  };

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
