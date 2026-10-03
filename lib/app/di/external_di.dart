import 'package:gutgood/core/di/di_instance.dart';
import 'package:gutgood/infrastructure/open_food_facts/off_service.dart';
import 'package:gutgood/infrastructure/payments/purchase_service.dart';

/// Registers non-Firebase external service adapters.
void initExternalDI() {
  sl
    ..registerLazySingleton<OffService>(() => OffServiceImpl(dio: sl()))
    ..registerLazySingleton<PurchaseService>(PurchaseServiceImpl.new);
}
