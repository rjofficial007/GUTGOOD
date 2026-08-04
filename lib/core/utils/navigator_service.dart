import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gutgood/core/router/app_router.dart';

final GlobalKey<NavigatorState> navigatorKey = rootNavigatorKey;

class AppNavigator {
  static Future<void> push(String path, {Object? extra}) async {
    unawaited(AppRouter.router.push(path, extra: extra));
  }

  static void go(String path, {Object? extra}) {
    AppRouter.router.go(path, extra: extra);
  }

  static void pop() {
    AppRouter.router.pop();
  }
}
