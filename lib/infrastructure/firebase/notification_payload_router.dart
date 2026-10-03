import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/router/notification_navigation_port.dart';
import 'package:gutgood/core/utils/logger_service.dart';

/// Maps notification payloads to app-owned destinations without coupling the
/// notification service to a concrete router implementation.
class NotificationPayloadRouter {
  NotificationPayloadRouter({required NotificationNavigationPort navigation}) : _navigation = navigation;

  final NotificationNavigationPort _navigation;

  void handle(String? payload) {
    if (payload == null) return;
    AppLogger.notifs('Handling tap for payload: $payload');

    if (payload == 'symptom_check' || payload == 'daily_reminder' || payload == 'streak_saver') {
      _navigation.push(AppRoutes.chat);
    } else if (payload.startsWith('meal_reminder_') || payload == 'no_meal_logged') {
      _navigation.push(AppRoutes.chat);
    } else if (payload == 'insight_generated') {
      _navigation.push(AppRoutes.insights);
    } else if (payload == 'scan_reminder' || payload == 'restaurant_reminder') {
      _navigation.push(AppRoutes.chat);
    } else if (payload == 'health_alert' || payload == 'processed_food') {
      _navigation.push(AppRoutes.notificationArchive);
    } else {
      AppLogger.warning('NotificationService: Unknown payload type tapped: $payload');
      _navigation.push(AppRoutes.chat);
    }
  }
}
