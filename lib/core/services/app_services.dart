import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gutgood/core/services/app_version_services.dart';
import 'package:gutgood/core/services/config_service.dart';
import 'package:gutgood/core/services/device_info_services.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:http/http.dart' as http;
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
  final AppVersionService _appVersionService;
  final DeviceInfoService _deviceInfoService;
  final ConfigService _configService;
  final http.Client _httpClient;

  AppServiceImpl({required AppVersionService appVersionService, required DeviceInfoService deviceInfoService, required ConfigService configService, required http.Client httpClient})
    : _appVersionService = appVersionService,
      _deviceInfoService = deviceInfoService,
      _configService = configService,
      _httpClient = httpClient;

  @override
  String get shareWithFriendsText =>
      '''Hey! I’ve been using ${_configService.appName}, it's my personalized gut health assistant! 🌿 Each scan helps me understand what foods actually work for my body. You should try it!.\n\nhttps://play.google.com/store/apps/details?id=${_appVersionService.packageName}\n\nhttps://apps.apple.com/app/id${_configService.iosAppId}''';

  @override
  Future<void> urlLauncher(BuildContext context, String urlString, {LaunchMode mode = LaunchMode.platformDefault}) async {
    final Uri url = Uri.parse(urlString);
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
    Log.d("AppService: Preparing to send email...");

    final String email = Uri.encodeComponent("support@gutgood.app");
    final String subject = Uri.encodeComponent(
      "${_configService.appName}\n${Platform.isAndroid ? "Android" : "iOS"} ${isFromReview ? "Review" : "Feedback"} v${_appVersionService.appVersion} (${_deviceInfoService.deviceName} ${_deviceInfoService.model}, v${_deviceInfoService.deviceOsVersion})",
    );
    final String body = Uri.encodeComponent(
      "$mailContent\n\n\n\n\n--------------------------------------------------------\nModel : ${_deviceInfoService.deviceName} ${_deviceInfoService.model} \n System version : ${_deviceInfoService.deviceOsVersion} \n Country : $_countryCode",
    );

    final Uri mail = Uri.parse("mailto:$email?subject=$subject&body=$body");

    if (await canLaunchUrl(mail)) {
      try {
        await launchUrl(mail, mode: LaunchMode.platformDefault);
      } catch (e) {
        Log.e("AppService: Error launching mail client", error: e);
      }
    } else {
      Log.e("AppService: Unable to launch mail client.");
    }
  }

  String _countryCode = "";

  @override
  void shareWithFriends(BuildContext context) async {
    try {
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      final Rect? origin = box != null ? (box.localToGlobal(Offset.zero) & box.size) : null;

      await SharePlus.instance.share(ShareParams(sharePositionOrigin: origin, text: shareWithFriendsText));
    } catch (e) {
      Log.e('AppService: Share failed', error: e);
    }
  }

  @override
  Future<void> lookupUserCountry() async {
    if (_countryCode.isEmpty) {
      try {
        // Audit Fix: Use HTTPS for geo-IP lookup to comply with iOS ATS requirements.
        // ip-api.com requires a paid tier for HTTPS; ipapi.co provides a free tier with HTTPS.
        final response = await _httpClient.get(Uri.parse('https://ipapi.co/json/'));

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          _countryCode = jsonResponse['country_code'] ?? "Unknown";
          Log.d("AppService: Fetched country code: $_countryCode");
        }
      } catch (e) {
        Log.e("AppService: Error fetching country code", error: e);
      }
    }
  }

  @override
  Future<void> requestReview() async {
    final InAppReview inAppReview = InAppReview.instance;
    try {
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      } else {
        await inAppReview.openStoreListing(appStoreId: _configService.iosAppId);
      }
    } catch (e) {
      Log.e('AppService: Error requesting review', error: e);
    }
  }
}
