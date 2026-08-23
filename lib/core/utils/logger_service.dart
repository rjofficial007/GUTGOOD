import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:gutgood/core/constants/logger_string.dart';
import 'package:gutgood/core/di/di_instance.dart';
import 'package:gutgood/core/services/crashlytics_service.dart';

/// Centralized logging utility for the GutGood app.
/// This class provides categorized logging with custom prefixes and emojis.
class AppLogger {
  AppLogger._();

  // --- Standard Severity Logs ---

  static void debug(Object? message, {Object? error, StackTrace? stackTrace}) {
    _printLog(AppLoggerStrings.logDebug, message, error, stackTrace);
  }

  static void info(Object? message) {
    _printLog(AppLoggerStrings.logInfo, message, null, null);
  }

  static void success(Object? message) {
    _printLog(AppLoggerStrings.logSuccess, message, null, null);
  }

  static void error(Object? message, {Object? error, StackTrace? stackTrace}) {
    _printLog(AppLoggerStrings.logError, message, error, stackTrace);
  }

  static void warning(Object? message, {Object? error, StackTrace? stackTrace}) {
    _printLog(AppLoggerStrings.logWarning, message, error, stackTrace);
  }

  // --- Feature Categorized Logs ---

  static void auth(Object? message, {Object? error, StackTrace? stackTrace}) {
    _printLog(AppLoggerStrings.logAuth, message, error, stackTrace);
  }

  static void firestore(Object? message, {Object? error, StackTrace? stackTrace}) {
    _printLog(AppLoggerStrings.logFirestore, message, error, stackTrace);
  }

  static void ai(Object? message, {Object? error, StackTrace? stackTrace}) {
    _printLog(AppLoggerStrings.logAi, message, error, stackTrace);
  }

  static void scanner(Object? message, {Object? error, StackTrace? stackTrace}) {
    _printLog(AppLoggerStrings.logScanner, message, error, stackTrace);
  }

  static void storage(Object? message, {Object? error, StackTrace? stackTrace}) {
    _printLog(AppLoggerStrings.logStorage, message, error, stackTrace);
  }

  static void insights(Object? message, {Object? error, StackTrace? stackTrace}) {
    _printLog(AppLoggerStrings.logInsights, message, error, stackTrace);
  }

  static void payments(Object? message, {Object? error, StackTrace? stackTrace}) {
    _printLog(AppLoggerStrings.logPayments, message, error, stackTrace);
  }

  static void premium(Object? message) {
    _printLog(AppLoggerStrings.logPremium, message, null, null);
  }

  static void notifs(Object? message, {Object? error, StackTrace? stackTrace}) {
    _printLog(AppLoggerStrings.logNotifications, message, error, stackTrace);
  }

  static void network(Object? message, {Object? error, StackTrace? stackTrace}) {
    _printLog(AppLoggerStrings.logConnectivity, message, error, stackTrace);
  }

  static void router(Object? message) {
    _printLog(AppLoggerStrings.logNavigation, message, null, null);
  }

  static void remoteConfig(Object? message, {Object? error, StackTrace? stackTrace}) {
    _printLog(AppLoggerStrings.logRemoteConfig, message, error, stackTrace);
  }

  static void theme(Object? message) {
    _printLog(AppLoggerStrings.logTheme, message, null, null);
  }

  static void deepLink(Object? message, {Object? error, StackTrace? stackTrace}) {
    _printLog(AppLoggerStrings.logDeepLink, message, error, stackTrace);
  }

  static void lifecycle(Object? message) {
    _printLog(AppLoggerStrings.logLifecycle, message, null, null);
  }

  static void mock(Object? message) {
    _printLog(AppLoggerStrings.logMock, message, null, null);
  }

  // --- Specialized Data & Action Logs ---

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

    final severitySuffix = error != null ? ' ${AppLoggerStrings.logError}' : '';
    final logMessage = StringBuffer('${AppLoggerStrings.logPrefix} $prefix$severitySuffix $message');
    
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
