part of 'super_scanner_screen.dart';

/// Scanner camera preview component.

class _CameraPreview extends StatelessWidget {
  const _CameraPreview({required this.repaintKey, required this.scannerController, required this.onDetect});
  final GlobalKey repaintKey;
  final MobileScannerController scannerController;
  final Function(BarcodeCapture) onDetect;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    key: repaintKey,
    child: ClipRect(
      child: MobileScanner(controller: scannerController, onDetect: onDetect, fit: BoxFit.cover),
    ),
  );
}
