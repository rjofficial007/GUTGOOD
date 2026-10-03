import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/router/notification_navigation_port.dart';
import 'package:gutgood/infrastructure/firebase/notification_payload_router.dart';

class _FakeNotificationNavigation implements NotificationNavigationPort {
  final pushedRoutes = <String>[];

  @override
  void push(String path) => pushedRoutes.add(path);
}

void main() {
  late _FakeNotificationNavigation navigation;
  late NotificationPayloadRouter router;

  setUp(() {
    navigation = _FakeNotificationNavigation();
    router = NotificationPayloadRouter(navigation: navigation);
  });

  test('routes activity reminders to chat', () {
    router.handle('meal_reminder_dinner');

    expect(navigation.pushedRoutes, [AppRoutes.chat]);
  });

  test('routes generated insights to Insights', () {
    router.handle('insight_generated');

    expect(navigation.pushedRoutes, [AppRoutes.insights]);
  });

  test('routes health alerts to the notification archive', () {
    router.handle('health_alert');

    expect(navigation.pushedRoutes, [AppRoutes.notificationArchive]);
  });

  test('falls back to chat for unknown payloads', () {
    router.handle('unknown_payload');

    expect(navigation.pushedRoutes, [AppRoutes.chat]);
  });

  test('does nothing when payload is absent', () {
    router.handle(null);

    expect(navigation.pushedRoutes, isEmpty);
  });
}
