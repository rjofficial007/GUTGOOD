import 'package:gutgood/core/constants/api_constants.dart';

abstract class ConfigService {
  String get appName;
  String get aboutUsUrl;
  String get privacyPolicyUrl;
  String get termsConditionUrl;
  String get email;
  String get iosAppId;
  String get magicLinkUrl;
  String get googleServerClientId;
}

class ConfigServiceImpl implements ConfigService {
  @override
  String get appName => 'GutGood';
  @override
  String get aboutUsUrl => 'https://macymind.com';
  @override
  String get privacyPolicyUrl => 'https://macymind.com';
  @override
  String get termsConditionUrl => 'https://macymind.com';
  @override
  String get email => 'info@macymind.com';
  @override
  String get iosAppId => '0000000000';
  @override
  String get magicLinkUrl => ApiConstants.magicLinkUrl;
  @override
  String get googleServerClientId => ApiConstants.googleServerClientId;
}
