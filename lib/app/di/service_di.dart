import 'package:gutgood/app/di/ai_di.dart';
import 'package:gutgood/app/di/external_di.dart';
import 'package:gutgood/app/di/feature_service_di.dart';
import 'package:gutgood/app/di/firebase_di.dart';
import 'package:gutgood/app/di/platform_di.dart';
import 'package:gutgood/core/router/notification_navigation_port.dart';

/// Registers non-provider services in explicit infrastructure/application
/// groups while preserving the existing GetIt singleton registrations.
void initServiceDI({required NotificationNavigationPort notificationNavigation}) {
  initPlatformDI();
  initAiDI();
  initFirebaseDI(notificationNavigation: notificationNavigation);
  initExternalDI();
  initFeatureServiceDI();
}
