part of 'super_scanner_screen.dart';

/// Scanner top-bar component.

class _ScannerTopBar extends StatelessWidget {
  const _ScannerTopBar({required this.scannerController, required this.currentMode, required this.modes});
  final MobileScannerController scannerController;
  final ScannerMode currentMode;
  final List<ScannerModeOption> modes;

  @override
  Widget build(BuildContext context) {
    final modeLabel = modes.firstWhere((m) => m.mode == currentMode).label;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _SimpleIconButton(icon: AppIcons.x, onTap: () => context.pop()),
        Text(
          modeLabel.toUpperCase(),
          style: AppTextStyles.bodySm.copyWith(color: AppPalette.white, fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
        ValueListenableBuilder(
          valueListenable: scannerController,
          builder: (context, state, child) {
            final isTorchOn = state.torchState == TorchState.on;
            return _SimpleIconButton(icon: isTorchOn ? AppIcons.zap : AppIcons.zapOff, iconColor: isTorchOn ? AppPalette.lime : AppPalette.white, onTap: scannerController.toggleTorch);
          },
        ),
      ],
    );
  }
}
