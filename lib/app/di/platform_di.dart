import 'package:gutgood/core/di/di_instance.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/config_service.dart';
import 'package:gutgood/infrastructure/platform/app_service.dart';
import 'package:gutgood/infrastructure/platform/app_version_service.dart';
import 'package:gutgood/infrastructure/platform/device_info_service.dart';
import 'package:gutgood/infrastructure/platform/internet_connection_checker.dart';

/// Registers application-facing platform integrations and shared app state.
///
/// Concrete platform implementations stay outside [core], while the
/// composition root keeps their lifetimes and construction centralized.
void initPlatformDI() {
  sl
    ..registerLazySingleton<ConfigService>(ConfigServiceImpl.new)
    ..registerLazySingleton<AppVersionService>(AppVersionServiceImpl.new)
    ..registerLazySingleton<DeviceInfoService>(() => DeviceInfoServiceImpl(deviceInfoPlugin: sl()))
    ..registerLazySingleton<AppService>(() => AppServiceImpl(appVersionService: sl(), deviceInfoService: sl(), configService: sl(), dio: sl()))
    ..registerLazySingleton<AppStateService>(AppStateServiceImpl.new)
    ..registerLazySingleton<InternetConnectionChecker>(InternetConnectionCheckerImpl.new);
}
