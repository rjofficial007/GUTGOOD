part of 'super_scanner_screen.dart';

/// Scanner shutter component.

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({this.onTap, required this.isActive, required this.isProcessing});
  final VoidCallback? onTap;
  final bool isActive;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppStrings.capturePhoto,
    button: true,
    enabled: isActive && !isProcessing,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        if (isActive && !isProcessing) unawaited(HapticFeedback.mediumImpact());
      },
      onTap: onTap,
      child: Container(
        width: AppSizes.w80,
        height: AppSizes.w80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppPalette.white, width: 5),
        ),
        padding: const EdgeInsets.all(4),
        child: DecoratedBox(
          decoration: BoxDecoration(color: isProcessing ? AppPalette.white70 : AppPalette.white, shape: BoxShape.circle),
          child: isProcessing ? const Center(child: CircularProgressIndicator(color: AppPalette.black, strokeWidth: 2)) : null,
        ),
      ),
    ),
  );
}
