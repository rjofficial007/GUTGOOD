import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/theme/app_palette.dart';

/// UI Mappings for AI-generated insight data.
class InsightUiUtils {
  const InsightUiUtils._();



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


}
