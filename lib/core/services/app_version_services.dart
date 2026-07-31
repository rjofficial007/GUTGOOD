import 'package:package_info_plus/package_info_plus.dart';
import 'package:gutgood/core/utils/logger_service.dart';

abstract class AppVersionService {
  Future<void> fetchAppInfo();
  String get appName;
  String get packageName;
  String get appVersion;
  String get buildVersion;
}

class AppVersionServiceImpl implements AppVersionService {
  String _appName = "";
  String _packageName = "";
  String _appVersion = "";
  String _buildVersion = "";

  @override
  String get appName => _appName;
  @override
  String get packageName => _packageName;
  @override
  String get appVersion => _appVersion;
  @override
  String get buildVersion => _buildVersion;

  @override
  Future<void> fetchAppInfo() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      _appName = packageInfo.appName;
      _packageName = packageInfo.packageName;
      _appVersion = packageInfo.version;
      _buildVersion = packageInfo.buildNumber;
    } catch (e) {
      Log.e("AppVersionService: Error fetching app info", error: e);
    }
  }
}
