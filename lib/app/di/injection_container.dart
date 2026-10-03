import 'dart:async';

import 'package:gutgood/app/di/core_di.dart';
import 'package:gutgood/app/di/feature_di.dart';
import 'package:gutgood/app/di/service_di.dart';
import 'package:gutgood/app/di/usecase_di.dart';
import 'package:gutgood/core/router/notification_navigation_port.dart';

export 'package:gutgood/core/di/di_instance.dart';

Future<void> init({required NotificationNavigationPort notificationNavigation}) async {
  //! 1. External & Infrastructure
  await initCoreDI();

  //! 2. Core Services
  initServiceDI(notificationNavigation: notificationNavigation);

  //! 3. Feature Layer (Repositories & Notifiers)
  initFeatureDI();

  //! 4. UseCases
  initUseCaseDI();
}
