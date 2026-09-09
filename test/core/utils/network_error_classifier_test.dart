import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/utils/network_error_classifier.dart';

DioException _dio(DioExceptionType type, {Object? inner}) => DioException(requestOptions: RequestOptions(path: '/x'), type: type, error: inner);

void main() {
  group('isOfflineError', () {
    test('raw socket and timeout failures are offline', () {
      expect(isOfflineError(const SocketException('unreachable')), isTrue);
      expect(isOfflineError(TimeoutException('timed out')), isTrue);
    });

    test('dio connection and timeout types are offline', () {
      expect(isOfflineError(_dio(DioExceptionType.connectionError)), isTrue);
      expect(isOfflineError(_dio(DioExceptionType.connectionTimeout)), isTrue);
      expect(isOfflineError(_dio(DioExceptionType.sendTimeout)), isTrue);
      expect(isOfflineError(_dio(DioExceptionType.receiveTimeout)), isTrue);
    });

    test('dio unknown wrapping a socket failure is offline, otherwise not', () {
      expect(isOfflineError(_dio(DioExceptionType.unknown, inner: const SocketException('x'))), isTrue);
      expect(isOfflineError(_dio(DioExceptionType.unknown, inner: StateError('app bug'))), isFalse);
      expect(isOfflineError(_dio(DioExceptionType.unknown)), isFalse);
    });

    test('server responses, certs, and cancels are NOT offline', () {
      expect(isOfflineError(_dio(DioExceptionType.badResponse)), isFalse);
      expect(isOfflineError(_dio(DioExceptionType.badCertificate)), isFalse);
      expect(isOfflineError(_dio(DioExceptionType.cancel)), isFalse);
    });

    test('app errors and null are NOT offline', () {
      expect(isOfflineError(StateError('bug')), isFalse);
      expect(isOfflineError('some string'), isFalse);
      expect(isOfflineError(null), isFalse);
    });
  });
}
