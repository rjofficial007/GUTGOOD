import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:gutgood/core/constants/logger_string.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/services/crashlytics_service.dart';

/// Centralized logging utility for the GutGood app.
/// This class provides categorized logging with custom prefixes and emojis.
class AppLogger {
  AppLogger._();

  /// Logs a debug message.
  static void debug(Object? message, {Object? error, StackTrace? stackTrace}) {
    _printLog(AppLoggerStrings.logDebug, message, error, stackTrace);
  }

  /// Logs an informational message.
  static void info(Object? message) {
    _printLog(AppLoggerStrings.logInfo, message, null, null);
  }

  /// Logs a success message.
  static void success(Object? message) {
    _printLog(AppLoggerStrings.logSuccess, message, null, null);
  }

  /// Logs an error message.
  static void error(Object? message, {Object? error, StackTrace? stackTrace}) {
    _printLog(AppLoggerStrings.logError, message, error, stackTrace);
  }

  /// Logs a warning message.
  static void warning(Object? message) {
    _printLog(AppLoggerStrings.logError, message, null, null);
  }

  /// Logs a premium feature related message.
  static void premium(Object? message) {
    _printLog(AppLoggerStrings.logPremium, message, null, null);
  }

  /// Logs an internet connectivity related message.
  static void internet(Object? message) {
    _printLog(AppLoggerStrings.logInternet, message, null, null);
  }

  /// Logs an advertisement related message.
  static void advertise(Object? message) {
    _printLog(AppLoggerStrings.logAdvertise, message, null, null);
  }

  /// Logs a firebase remote config related message.
  static void firebaseRemoteConfig(Object? message) {
    _printLog(AppLoggerStrings.logFirebaseRemoteConfig, message, null, null);
  }

  /// Specialized method to dump raw backend data objects to the console.
  static void data(String screenName, dynamic rawData) {
    if (kReleaseMode) return;

    String prettyData;
    try {
      prettyData = const JsonEncoder.withIndent('  ').convert(rawData);
    } catch (e) {
      prettyData = rawData.toString();
    }

    final buffer = StringBuffer()
      ..writeln('------------------------------------------------------------')
      ..writeln('📊 BACKEND DATA DUMP: $screenName')
      ..writeln('------------------------------------------------------------')
      ..writeln(prettyData)
      ..writeln('------------------------------------------------------------');
    developer.log(buffer.toString(), name: 'GUTGOOD_DATA');
  }

  /// Helper method to format and print the log message.
  static void _printLog(Object? prefix, Object? message, Object? error, StackTrace? stackTrace) {
    // 🔴 1. Record errors to Crashlytics (even if logs are suppressed locally)
    if (error != null) {
      try {
        unawaited(sl<CrashlyticsService>().recordError(error, stackTrace, reason: message));
      } catch (e) {
        // Fallback if sl is not initialized yet
      }
    }

    // 🟢 2. Local/Debug logging
    if (kReleaseMode) return;

    final logMessage = StringBuffer('${AppLoggerStrings.logPrefix} $prefix $message');
    if (error != null) {
      logMessage.write('\nError: $error');
    }
    if (stackTrace != null) {
      logMessage.write('\nStackTrace: $stackTrace');
    }

    // Use developer.log for direct VM service capture (Most reliable for IDEs)
    developer.log(logMessage.toString(), name: 'GUTGOOD', error: error, stackTrace: stackTrace);
  }
}

/// Alias [Logger] to [AppLogger] for consistency with user request while maintaining project compatibility.
typedef Logger = AppLogger;
