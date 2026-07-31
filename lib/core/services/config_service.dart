import 'package:gutgood/core/constants/api_constants.dart';

abstract class ConfigService {
  String get appName;
  String get aboutUsUrl;
  String get privacyPolicyUrl;
  String get termsConditionUrl;
  String get iosAppId;
  String get magicLinkUrl;
  String get googleServerClientId;
}


class ConfigServiceImpl implements ConfigService {
  @override
  String get appName => "GutGood";
  @override
  String get aboutUsUrl => "https://gutgood.app/about";
  @override
  String get privacyPolicyUrl => "https://gutgood.app/privacy";
  @override
  String get termsConditionUrl => "https://gutgood.app/terms";
  @override
  String get iosAppId => "0000000000";
  @override
  String get magicLinkUrl => ApiConstants.magicLinkUrl;
  @override
  String get googleServerClientId => ApiConstants.googleServerClientId;
}
