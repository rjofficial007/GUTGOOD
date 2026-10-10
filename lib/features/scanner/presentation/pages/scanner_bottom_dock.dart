part of 'super_scanner_screen.dart';

/// Scanner bottom-dock component.

class _ScannerBottomDock extends StatelessWidget {
  const _ScannerBottomDock({
    required this.modePageController,
    required this.currentMode,
    required this.isProcessing,
    required this.modes,
    required this.onGalleryTap,
    required this.onShutterTap,
    required this.onModeChanged,
  });

  final PageController modePageController;
  final ScannerMode currentMode;
  final bool isProcessing;
  final List<ScannerModeOption> modes;
  final VoidCallback onGalleryTap;
  final VoidCallback onShutterTap;
  final Function(int) onModeChanged;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        height: 44,
        child: PageView.builder(
          controller: modePageController,
          itemCount: modes.length,
          onPageChanged: onModeChanged,
          padEnds: true,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            final modeItem = modes[index];
            final isActive = currentMode == modeItem.mode;
            return Center(
              child: Opacity(
                opacity: isActive ? 1.0 : 0.4,
                child: Text(
                  modeItem.label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(fontSize: 11.0.sp, color: AppPalette.white, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SimpleIconButton(icon: AppIcons.image, onTap: onGalleryTap),
            _ShutterButton(onTap: isProcessing ? null : onShutterTap, isActive: true, isProcessing: isProcessing),
            _SimpleIconButton(
              icon: AppIcons.refreshCw,
              onTap: () {
                final state = context.findAncestorStateOfType<_SuperScannerScreenState>();
                state?._scannerController.switchCamera();
              },
            ),
          ],
        ),
      ),
    ],
  );
}
