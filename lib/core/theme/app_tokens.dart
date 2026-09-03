import 'package:flutter/material.dart';

/// Centralized design tokens for spacing, corner radii, and box shadows.
abstract class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;

  static const EdgeInsets insetSm = EdgeInsets.all(sm);
  static const EdgeInsets insetMd = EdgeInsets.all(md);
  static const EdgeInsets insetLg = EdgeInsets.all(lg);

  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
}

abstract class AppRadius {
  static const double r8 = 8.0;
  static const double r12 = 12.0;
  static const double r16 = 16.0;
  static const double r20 = 20.0;
  static const double r24 = 24.0;

  static const BorderRadius card = BorderRadius.all(Radius.circular(r16));
  static const BorderRadius button = BorderRadius.all(Radius.circular(r12));
  static const BorderRadius sheet = BorderRadius.vertical(top: Radius.circular(r24));
  static const BorderRadius badge = BorderRadius.all(Radius.circular(r20));
}

abstract class AppShadows {
  static List<BoxShadow> subtle(Color color) => [
        BoxShadow(
          color: color.withAlpha(15),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> medium(Color color) => [
        BoxShadow(
          color: color.withAlpha(30),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];
}
