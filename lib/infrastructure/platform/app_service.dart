import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/services/config_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/infrastructure/platform/app_version_service.dart';
import 'package:gutgood/infrastructure/platform/device_info_service.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

abstract class AppService {
  String get shareWithFriendsText;
  Future<void> urlLauncher(BuildContext context, String urlString, {LaunchMode mode = LaunchMode.platformDefault});
  Future<void> sendingMails({required String mailContent, required bool isFromReview});
  void shareWithFriends(BuildContext context);
  Future<void> lookupUserCountry();
  Future<void> requestReview();
}

class AppServiceImpl implements AppService {
  AppServiceImpl({required AppVersionService appVersionService, required DeviceInfoService deviceInfoService, required ConfigService configService, required Dio dio})
    : _appVersionService = appVersionService,
      _deviceInfoService = deviceInfoService,
      _configService = configService,
      _dio = dio;
  final AppVersionService _appVersionService;
  final DeviceInfoService _deviceInfoService;
  final ConfigService _configService;
  final Dio _dio;

  @override
  String get shareWithFriendsText =>
      '''Maybe we don’t need another diet. Maybe we just need to understand our food better.\n\nGutGood. Food is information.\n\nhttps://apps.apple.com/app/id${_configService.iosAppId}''';

  @override
  Future<void> urlLauncher(BuildContext context, String urlString, {LaunchMode mode = LaunchMode.platformDefault}) async {
    final url = Uri.parse(urlString);
    if (Platform.isIOS && urlString.contains('apps.apple.com')) {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } else {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: mode);
      }
    }
  }

  @override
  Future<void> sendingMails({required String mailContent, required bool isFromReview}) async {
    AppLogger.debug('Preparing to send email...');

    final email = Uri.encodeComponent(_configService.email);
    final subject = Uri.encodeComponent(
      '${_configService.appName}\n${Platform.isAndroid ? 'Android' : 'iOS'} ${isFromReview ? 'Review' : 'Feedback'} v${_appVersionService.appVersion} (${_deviceInfoService.deviceName} ${_deviceInfoService.model}, v${_deviceInfoService.deviceOsVersion})',
    );
    final body = Uri.encodeComponent(
      '$mailContent\n\n\n\n\n--------------------------------------------------------\nModel : ${_deviceInfoService.deviceName} ${_deviceInfoService.model} \n System version : ${_deviceInfoService.deviceOsVersion} \n Country : $_countryCode',
    );

    final mail = Uri.parse('mailto:$email?subject=$subject&body=$body');

    if (await canLaunchUrl(mail)) {
      try {
        await launchUrl(mail, mode: LaunchMode.platformDefault);
      } catch (e) {
        AppLogger.error('Error launching mail client', error: e);
      }
    } else {
      AppLogger.error('Unable to launch mail client.');
    }
  }

  String _countryCode = '';

  @override
  Future<void> shareWithFriends(BuildContext context) async {
    try {
      final box = context.findRenderObject() as RenderBox?;
      final origin = box != null ? (box.localToGlobal(Offset.zero) & box.size) : null;

      await SharePlus.instance.share(ShareParams(sharePositionOrigin: origin, text: shareWithFriendsText));
    } catch (e) {
      AppLogger.error('Share failed', error: e);
    }
  }

  @override
  Future<void> lookupUserCountry() async {
    // Don't fetch again if already available.
    if (_countryCode.isNotEmpty) return;

    try {
      final response = await _dio.get(
        'http://ip-api.com/json',
        options: Options(receiveTimeout: const Duration(seconds: 5), sendTimeout: const Duration(seconds: 5)),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic> && data['status'] == 'success') {
          _countryCode = (data['countryCode'] as String?)?.toUpperCase() ?? 'US';
          AppLogger.network('Country code: $_countryCode');
          return;
        }

        AppLogger.network('Invalid geo lookup response: $data');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        AppLogger.network('Geo lookup rate limited.');
      } else {
        AppLogger.network('Geo lookup failed', error: e);
      }
    } catch (e) {
      AppLogger.error('Unexpected error', error: e);
    }

    // Fallback to device locale.
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    _countryCode = (locale.countryCode ?? 'US').toUpperCase();
    AppLogger.network('Fallback country code: $_countryCode');
  }

  @override
  Future<void> requestReview() async {
    final inAppReview = InAppReview.instance;
    try {
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      } else {
        await inAppReview.openStoreListing(appStoreId: _configService.iosAppId);
      }
    } catch (e) {
      AppLogger.error('Error requesting review', error: e);
    }
  }
}
