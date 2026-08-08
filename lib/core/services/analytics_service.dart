import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

abstract class AnalyticsService {
  Future<void> logEvent({
    required String name,
    Map<String, Object?>? parameters,
  });
  Future<void> logScreenView({required String screenName, String? screenClass});
  Future<void> setUserId(String? id);
  Future<void> setUserProperty({required String name, required String? value});
  FirebaseAnalyticsObserver getObserver();
}

class AnalyticsServiceImpl implements AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object?>? parameters,
  }) async {
    if (kDebugMode) {
      print('Analytics [Event]: $name, params: $parameters');
    }

    Map<String, Object>? cleanParams;
    if (parameters != null) {
      cleanParams = {};
      parameters.forEach((key, value) {
        if (value != null) {
          if (value is bool) {
            cleanParams![key] = value ? 1 : 0;
          } else if (value is String || value is num) {
            cleanParams![key] = value;
          } else {
            cleanParams![key] = value.toString();
          }
        }
      });
    }

    await _analytics.logEvent(name: name, parameters: cleanParams);
  }

  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (kDebugMode) {
      print('Analytics [Screen]: $screenName, class: $screenClass');
    }
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  @override
  Future<void> setUserId(String? id) async {
    await _analytics.setUserId(id: id);
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  @override
  FirebaseAnalyticsObserver getObserver() =>
      FirebaseAnalyticsObserver(analytics: _analytics);
}
