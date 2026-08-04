import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:gutgood/core/utils/logger_service.dart';

abstract class DeviceInfoService {
  Future<void> fetchDeviceInfo();
  String get deviceOsVersion;
  String get deviceName;
  String get model;
  IosDeviceInfo? get iosBaseDeviceInfo;
  AndroidDeviceInfo? get androidBaseDeviceInfo;
  int? get androidSdkVersion;
}

class DeviceInfoServiceImpl implements DeviceInfoService {

  DeviceInfoServiceImpl({required DeviceInfoPlugin deviceInfoPlugin}) : _deviceInfoPlugin = deviceInfoPlugin;
  final DeviceInfoPlugin _deviceInfoPlugin;

  @override
  IosDeviceInfo? iosBaseDeviceInfo;
  @override
  AndroidDeviceInfo? androidBaseDeviceInfo;
  @override
  int? androidSdkVersion;
  @override
  String deviceOsVersion = '';
  @override
  String deviceName = '';
  @override
  String model = '';

  @override
  Future<void> fetchDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfoPlugin.androidInfo;
        androidBaseDeviceInfo = info;
        androidSdkVersion = info.version.sdkInt;
        deviceName = info.brand;
        model = info.model;
        deviceOsVersion = info.version.release;
      } else if (Platform.isIOS) {
        final info = await _deviceInfoPlugin.iosInfo;
        iosBaseDeviceInfo = info;
        deviceName = info.name;
        model = info.model;
        deviceOsVersion = info.systemVersion;
      }
    } catch (e) {
      AppLogger.error('DeviceInfoService: Error fetching device info', error: e);
    }
  }
}
