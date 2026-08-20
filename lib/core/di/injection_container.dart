import 'dart:async';

import 'package:gutgood/core/di/core_di.dart';
import 'package:gutgood/core/di/feature_di.dart';
import 'package:gutgood/core/di/service_di.dart';
import 'package:gutgood/core/di/usecase_di.dart';

export 'package:gutgood/core/di/di_instance.dart';

Future<void> init() async {
  //! 1. External & Infrastructure
  await initCoreDI();

  //! 2. Core Services
  initServiceDI();

  //! 3. Feature Layer (Repositories & Notifiers)
  initFeatureDI();

  //! 4. UseCases
  initUseCaseDI();
}
