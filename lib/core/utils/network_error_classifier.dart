import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

/// True when [error] looks like a reachability failure (device offline, DNS
/// blocked, server unreachable, timeout) rather than an application error.
///
/// Used to show "you're offline" messaging instead of generic failure copy —
/// and, equally, to NOT blame the network for app bugs. Conservative by
/// design: anything unrecognized returns false.
bool isOfflineError(Object? error) {
  if (error is SocketException || error is TimeoutException) return true;
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return true;
      case DioExceptionType.unknown:
        // Dio wraps raw socket failures as `unknown` — only count those.
        return error.error is SocketException;
      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
      case DioExceptionType.cancel:
      case DioExceptionType.transformTimeout:
        // Transformer timeout (dio >= 5.11): bytes arrived but local response
        // processing timed out — connectivity is fine, so not offline.
        return false;
    }
  }
  return false;
}
