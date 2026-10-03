import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gutgood/app/router/app_router.dart';
import 'package:gutgood/core/router/notification_navigation_port.dart';

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

/// Adapter supplied by the app layer so core notification infrastructure can
/// request navigation without importing GoRouter or the app router.
final class AppNotificationNavigation implements NotificationNavigationPort {
  const AppNotificationNavigation();

  @override
  void push(String path) {
    unawaited(AppNavigator.push(path));
  }
}
