import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../constants/logger_string.dart';

/// Centralized logging utility for the GutGood app.
/// This class provides categorized logging with custom prefixes and emojis.
class Log {
  Log._();

  /// Initialization log that bypasses the kReleaseMode check for diagnostics.
  static void initDiagnostics() {
    developer.log('Logger Diagnostics Started (Force)', name: 'GUTGOOD');
  }

  /// Logs a debug message.
  static void debug(Object? message, {Object? error, StackTrace? stackTrace}) {
    _printLog(AppLoggerStrings.logDebug, message, error, stackTrace);
  }

  /// Alias for [debug] to maintain compatibility with existing code.
  static void d(Object? message) => debug(message);

  /// Logs an informational message.
  static void info(Object? message) {
    _printLog(AppLoggerStrings.logInfo, message, null, null);
  }

  /// Alias for [info] to maintain compatibility with existing code.
  static void i(Object? message) => info(message);

  /// Logs a success message.
  static void success(Object? message) {
    _printLog(AppLoggerStrings.logSuccess, message, null, null);
  }

  /// Logs an error message.
  static void error(Object? message, {Object? error, StackTrace? stackTrace}) {
    _printLog(AppLoggerStrings.logError, message, error, stackTrace);
  }

  /// Alias for [error] to maintain compatibility with existing code.
  static void e(Object? message, {dynamic error, StackTrace? stackTrace}) => Log.error(message, error: error, stackTrace: stackTrace);

  /// Logs a warning message.
  static void w(Object? message) {
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

  /// Helper method to format and print the log message.
  static void _printLog(Object? prefix, Object? message, Object? error, StackTrace? stackTrace) {
    if (kReleaseMode) return;

    final logMessage = StringBuffer('${AppLoggerStrings.logPrefix} $prefix $message');
    if (error != null) {
      logMessage.write('\nError: $error');
    }
    if (stackTrace != null) {
      logMessage.write('\nStackTrace: $stackTrace');
    }

    // 🟢 1. Use developer.log for direct VM service capture (Most reliable for IDEs)
    developer.log(logMessage.toString(), name: 'GUTGOOD', error: error, stackTrace: stackTrace);

    // 🟢 2. Keep debugPrint as a fallback for stdout capture
    debugPrint(logMessage.toString());
  }
}

/// Alias [Logger] to [Log] for consistency with user request while maintaining project compatibility.
typedef Logger = Log;
