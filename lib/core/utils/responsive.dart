import 'dart:math' as math;

import 'package:flutter/material.dart';

class Responsive {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;

  // Base design dimensions (iPhone 14/15/16 - 393x852)
  static const double _baseWidth = 393.0;
  static const double _baseHeight = 852.0;

  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
  }

  static double get scaleWidth => screenWidth / _baseWidth;
  static double get scaleHeight => screenHeight / _baseHeight;

  // Use the smaller scale factor to ensure content fits on both axes without extreme stretching
  static double get scaleText => math.min(scaleWidth, scaleHeight);

  // Scaled pixel (for fonts)
  static double sp(double size) => size * scaleText;

  // Relative width
  static double w(double width) => width * scaleWidth;

  // Relative height
  static double h(double height) => height * scaleHeight;

  // Radius (typically follows width scaling or min of both)
  static double r(double radius) => radius * scaleText;
}

extension ResponsiveExtension on num {
  double get w => Responsive.w(toDouble());
  double get h => Responsive.h(toDouble());
  static double _sp(num val) => Responsive.sp(val.toDouble());
  double get sp => _sp(this);
  double get r => Responsive.r(toDouble());
}
