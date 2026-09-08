import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:gutgood/core/utils/logger_service.dart';

abstract class CrashlyticsService {
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    bool fatal = false,
  });
  Future<void> log(String message);
  Future<void> setUserId(String id);
  Future<void> setCustomKey(String key, Object value);
  Future<void> setCrashlyticsCollectionEnabled(bool enabled);
}

class CrashlyticsServiceImpl implements CrashlyticsService {
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    bool fatal = false,
  }) async {
    if (kDebugMode) {
      AppLogger.debug('Crashlytics [Error]: $exception, reason: $reason, fatal: $fatal');
    }
    await _crashlytics.recordError(
      exception,
      stack,
      reason: reason,
      fatal: fatal,
    );
  }

  @override
  Future<void> log(String message) async {
    if (kDebugMode) {
      AppLogger.debug('Crashlytics [Log]: $message');
    }
    await _crashlytics.log(message);
  }

  @override
  Future<void> setUserId(String id) async {
    await _crashlytics.setUserIdentifier(id);
  }

  @override
  Future<void> setCustomKey(String key, Object value) async {
    await _crashlytics.setCustomKey(key, value);
  }

  @override
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
  }
}
