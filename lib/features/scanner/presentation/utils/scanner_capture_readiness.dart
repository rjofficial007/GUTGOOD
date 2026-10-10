import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

Future<bool> waitForScannerReady(
  ValueListenable<MobileScannerState> scannerState, {
  Duration timeout = const Duration(seconds: 12),
}) async {
  bool isReady() => scannerState.value.isInitialized && scannerState.value.isRunning;

  if (isReady()) return true;

  final ready = Completer<bool>();
  void checkState() {
    if (ready.isCompleted) return;
    final state = scannerState.value;
    if (state.error != null) {
      ready.complete(false);
    } else if (state.isInitialized && state.isRunning) {
      ready.complete(true);
    }
  }

  scannerState.addListener(checkState);
  checkState();
  try {
    return await ready.future.timeout(timeout, onTimeout: () => false);
  } finally {
    scannerState.removeListener(checkState);
  }
}
