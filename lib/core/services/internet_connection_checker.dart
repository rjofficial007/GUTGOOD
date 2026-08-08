import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:gutgood/core/utils/logger_service.dart';

enum InternetConnectionStatus { connected, disconnected }

abstract class InternetConnectionChecker {
  ValueNotifier<bool> get isInternetAvailable;
  void startListening({VoidCallback? onConnectionRestored});
  void stopListening();
  Future<void> checkConnection();
}

class InternetConnectionCheckerImpl implements InternetConnectionChecker {
  @override
  final ValueNotifier<bool> isInternetAvailable = ValueNotifier<bool>(true);

  final _checker = _InternalChecker.createInstance();
  StreamSubscription<InternetConnectionStatus>? _subscription;
  int _failureCount = 0;
  static const int _maxFailuresBeforeOffline = 2;

  @override
  void startListening({VoidCallback? onConnectionRestored}) {
    if (_subscription != null) return;

    AppLogger.debug('InternetConnectionChecker: Starting listener');
    _subscription = _checker.onStatusChange.listen((status) {
      final connected = (status == InternetConnectionStatus.connected);

      if (connected) {
        _failureCount = 0;
        if (!isInternetAvailable.value) {
          isInternetAvailable.value = true;
          AppLogger.info('InternetConnectionChecker: Connected');
          onConnectionRestored?.call();
        }
      } else {
        _failureCount++;
        if (_failureCount >= _maxFailuresBeforeOffline &&
            isInternetAvailable.value) {
          isInternetAvailable.value = false;
          AppLogger.warning('InternetConnectionChecker: Disconnected');
        }
      }
    });
  }

  @override
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  Future<void> checkConnection() async {
    final hasConn = await _checker.hasConnection;
    if (hasConn) {
      _failureCount = 0;
      isInternetAvailable.value = true;
    }
  }
}

class _InternalChecker {
  _InternalChecker.createInstance({List<InternetAddress>? addresses})
    : addresses =
          addresses ??
          [
            InternetAddress('1.1.1.1', type: InternetAddressType.IPv4),
            InternetAddress('8.8.4.4', type: InternetAddressType.IPv4),
          ],
      checkInterval = const Duration(seconds: 10) {
    _statusController.onListen = _maybeEmitStatusUpdate;
    _statusController.onCancel = () {
      _timerHandle?.cancel();
      _lastStatus = null;
    };
  }
  final List<InternetAddress> addresses;
  final Duration checkInterval;

  Future<bool> get hasConnection async {
    try {
      final futures = addresses.map(_isReachable).toList();
      final results = await Future.wait(futures);
      return results.any((success) => success);
    } catch (_) {
      return false;
    }
  }

  Future<bool> _isReachable(InternetAddress addr) async {
    try {
      final socket = await Socket.connect(
        addr,
        53,
        timeout: const Duration(seconds: 4),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  InternetConnectionStatus? _lastStatus;
  Timer? _timerHandle;
  final StreamController<InternetConnectionStatus> _statusController =
      StreamController.broadcast();

  Stream<InternetConnectionStatus> get onStatusChange =>
      _statusController.stream;

  Future<void> _maybeEmitStatusUpdate() async {
    _timerHandle?.cancel();
    final currentStatus = await hasConnection
        ? InternetConnectionStatus.connected
        : InternetConnectionStatus.disconnected;
    if (_lastStatus != currentStatus && _statusController.hasListener) {
      _statusController.add(currentStatus);
    }
    if (_statusController.hasListener) {
      _timerHandle = Timer(checkInterval, _maybeEmitStatusUpdate);
    }
    _lastStatus = currentStatus;
  }
}
