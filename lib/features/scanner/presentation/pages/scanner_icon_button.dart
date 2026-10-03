part of 'super_scanner_screen.dart';

/// Scanner icon-button component.

class _SimpleIconButton extends StatelessWidget {
  const _SimpleIconButton({required this.icon, this.iconColor = AppPalette.white, required this.onTap});
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {
      unawaited(HapticFeedback.lightImpact());
      onTap();
    },
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Icon(icon, color: iconColor, size: 24),
    ),
  );
}
