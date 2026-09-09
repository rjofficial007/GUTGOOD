import 'package:flutter/material.dart';

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;

  double get width => MediaQuery.sizeOf(this).width;
  double get height => MediaQuery.sizeOf(this).height;

  EdgeInsets get padding => MediaQuery.paddingOf(this);
  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);

  // Spacing convenience
}

extension StringExtensions on String {

  bool get isValidEmail => RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
  ).hasMatch(this);
}

extension WidgetExtensions on Widget {
  Widget center() => Center(child: this);
}
