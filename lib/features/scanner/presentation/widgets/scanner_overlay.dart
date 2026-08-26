import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/features/scanner/domain/models/scanner_mode.dart';

enum ScanningState { searching, detected, ready, scanning, error }

class ScannerOverlay extends StatelessWidget {
  const ScannerOverlay({super.key, required this.mode, required this.state, this.errorText});

  final ScannerMode mode;
  final ScanningState state;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final frameSize = getFrameSize(size, mode);

    return Stack(
      children: [
        // Optimized Cutout Overlay using CustomPainter
        Positioned.fill(
          child: CustomPaint(
            painter: _CutoutPainter(frameSize: frameSize, borderRadius: AppSizes.r32, overlayColor: Colors.black38),
          ),
        ),

        // Scanning frame borders
        Center(
          child: _ScannerFrameBorders(width: frameSize.width, height: frameSize.height, state: state),
        ),

        // Guidance & Status (Now on top)
        _GuidanceOverlay(mode: mode, state: state, errorText: errorText, frameHeight: frameSize.height),
      ],
    );
  }

  static Size getFrameSize(Size screenSize, ScannerMode mode) {
    switch (mode) {
      case ScannerMode.barcode:
        return Size(screenSize.width * 0.85, 150);
      case ScannerMode.label:
        return Size(screenSize.width * 0.85, 240);
      case ScannerMode.menu:
        return Size(screenSize.width * 0.85, screenSize.height * 0.5);
      case ScannerMode.food:
        return Size(screenSize.width * 0.85, screenSize.width * 0.85);
    }
  }

  static Rect getCutoutRect(Size screenSize, ScannerMode mode) {
    final frameSize = getFrameSize(screenSize, mode);
    return Rect.fromCenter(center: Offset(screenSize.width / 2, screenSize.height / 2), width: frameSize.width, height: frameSize.height);
  }
}

class _CutoutPainter extends CustomPainter {
  _CutoutPainter({required this.frameSize, required this.borderRadius, required this.overlayColor});

  final Size frameSize;
  final double borderRadius;
  final Color overlayColor;

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutRect = Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: frameSize.width, height: frameSize.height);

    final cutoutPath = Path()..addRRect(RRect.fromRectAndRadius(cutoutRect, Radius.circular(borderRadius)));

    final finalPath = Path.combine(PathOperation.difference, backgroundPath, cutoutPath);

    canvas.drawPath(finalPath, Paint()..color = overlayColor);
  }

  @override
  bool shouldRepaint(covariant _CutoutPainter oldDelegate) => frameSize != oldDelegate.frameSize || borderRadius != oldDelegate.borderRadius;
}

class _ScannerFrameBorders extends StatefulWidget {
  const _ScannerFrameBorders({required this.width, required this.height, required this.state});

  final double width;
  final double height;
  final ScanningState state;

  @override
  State<_ScannerFrameBorders> createState() => _ScannerFrameBordersState();
}

class _ScannerFrameBordersState extends State<_ScannerFrameBorders> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color borderColor;

    switch (widget.state) {
      case ScanningState.searching:
        borderColor = AppPalette.white;
        break;
      case ScanningState.detected:
      case ScanningState.ready:
      case ScanningState.scanning:
        borderColor = AppPalette.lime;
        break;
      case ScanningState.error:
        borderColor = AppPalette.red.withValues(alpha: 0.8);
        break;
    }

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = widget.state == ScanningState.ready ? 1.0 + (_pulseController.value * 0.012) : 1.0;
        final opacity = widget.state == ScanningState.searching ? 0.4 + (_pulseController.value * 0.2) : 1.0;

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: SizedBox(
              width: widget.width,
              height: widget.height,
              child: Stack(
                children: [
                  _CornerMarker(quarterTurns: 0, color: borderColor), // Top Left
                  _CornerMarker(quarterTurns: 1, color: borderColor), // Top Right
                  _CornerMarker(quarterTurns: 2, color: borderColor), // Bottom Right
                  _CornerMarker(quarterTurns: 3, color: borderColor), // Bottom Left

                  if (widget.state == ScanningState.scanning) _ScanningLine(width: widget.width, height: widget.height),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CornerMarker extends StatelessWidget {
  const _CornerMarker({required this.quarterTurns, required this.color});
  final int quarterTurns;
  final Color color;

  @override
  Widget build(BuildContext context) => Positioned(
    top: quarterTurns == 0 || quarterTurns == 1 ? 0 : null,
    bottom: quarterTurns == 2 || quarterTurns == 3 ? 0 : null,
    left: quarterTurns == 0 || quarterTurns == 3 ? 0 : null,
    right: quarterTurns == 1 || quarterTurns == 2 ? 0 : null,
    child: RotatedBox(
      quarterTurns: quarterTurns,
      child: CustomPaint(
        size: const Size(40, 40),
        painter: _CornerPainter(color: color, thickness: 3.5, radius: AppSizes.r32),
      ),
    ),
  );
}

class _CornerPainter extends CustomPainter {
  _CornerPainter({required this.color, required this.thickness, required this.radius});
  final Color color;
  final double thickness;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, radius)
      ..quadraticBezierTo(0, 0, radius, 0)
      ..lineTo(size.width, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ScanningLine extends StatefulWidget {
  const _ScanningLine({required this.width, required this.height});
  final double width;
  final double height;

  @override
  State<_ScanningLine> createState() => _ScanningLineState();
}

class _ScanningLineState extends State<_ScanningLine> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) => Positioned(
      top: widget.height * _controller.value,
      left: 10,
      right: 10,
      child: Container(
        height: 2,
        decoration: BoxDecoration(
          color: AppPalette.lime,
          boxShadow: [BoxShadow(color: AppPalette.lime.withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 1)],
        ),
      ),
    ),
  );
}

class _GuidanceOverlay extends StatelessWidget {
  const _GuidanceOverlay({required this.mode, required this.state, this.errorText, required this.frameHeight});

  final ScannerMode mode;
  final ScanningState state;
  final String? errorText;
  final double frameHeight;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final frameTop = (screenHeight - frameHeight) / 2;

    // Calculate top guidance position (between top bar and frame)
    final guidanceTop = (frameTop + topPadding) / 2;

    return Stack(
      children: [
        // Guidance & Status (Positioned above the frame)
        Positioned(
          top: guidanceTop,
          left: AppSizes.p20,
          right: AppSizes.p20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSimpleText(errorText ?? _getPrimaryInstruction(), isBold: true),
              if (_getSecondaryInstruction() != null || errorText != null) ...[
                const SizedBox(height: 6),
                _buildSimpleText(errorText ?? _getSecondaryInstruction() ?? '', isBold: false, opacity: 0.85),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleText(String text, {required bool isBold, double opacity = 1.0}) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 300),
    child: Text(
      text,
      key: ValueKey(text),
      textAlign: TextAlign.center,
      style: AppTextStyles.body.copyWith(
        color: AppPalette.white.withValues(alpha: opacity),
        fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
        fontSize: isBold ? AppSizes.s15 : AppSizes.s14,
        shadows: [Shadow(color: AppPalette.black.withValues(alpha: 0.6), blurRadius: 8, offset: const Offset(0, 1))],
      ),
    ),
  );

  String _getPrimaryInstruction() {
    switch (mode) {
      case ScannerMode.barcode:
        return AppStrings.barcodeGuidancePrimary;
      case ScannerMode.food:
        return AppStrings.mealGuidancePrimary;
      case ScannerMode.label:
        return AppStrings.labelGuidancePrimary;
      case ScannerMode.menu:
        return AppStrings.menuGuidancePrimary;
    }
  }

  String? _getSecondaryInstruction() {
    switch (mode) {
      case ScannerMode.barcode:
        return AppStrings.barcodeGuidanceSecondary;
      case ScannerMode.food:
        return AppStrings.mealGuidanceSecondary;
      case ScannerMode.label:
        return AppStrings.labelGuidanceSecondary;
      case ScannerMode.menu:
        return AppStrings.menuGuidanceSecondary;
    }
  }
}
