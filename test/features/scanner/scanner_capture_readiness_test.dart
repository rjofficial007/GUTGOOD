import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/features/scanner/presentation/utils/scanner_capture_readiness.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  test('waits for the camera to start before allowing a capture', () async {
    final scannerState = ValueNotifier(const MobileScannerState.uninitialized());

    final readiness = waitForScannerReady(scannerState);
    scannerState.value = scannerState.value.copyWith(isInitialized: true, isRunning: true);

    expect(await readiness, isTrue);
    scannerState.dispose();
  });

  test('does not allow capture when the camera fails to start', () async {
    final scannerState = ValueNotifier(const MobileScannerState.uninitialized());

    final readiness = waitForScannerReady(scannerState, timeout: const Duration(milliseconds: 1));

    expect(await readiness, isFalse);
    scannerState.dispose();
  });
}
