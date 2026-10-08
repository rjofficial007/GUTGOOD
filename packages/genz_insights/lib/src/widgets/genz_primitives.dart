import 'package:flutter/material.dart';

class GenzDashedDivider extends StatelessWidget {
  const GenzDashedDivider({
    super.key,
    required this.color,
    this.thickness = 1.5,
    this.dashWidth = 4,
    this.gap = 4,
  });

  final Color color;
  final double thickness;
  final double dashWidth;
  final double gap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: thickness,
        child: CustomPaint(
          painter: _GenzDashedLinePainter(
            color: color,
            thickness: thickness,
            dashWidth: dashWidth,
            gap: gap,
          ),
        ),
      );
}

class _GenzDashedLinePainter extends CustomPainter {
  const _GenzDashedLinePainter({
    required this.color,
    required this.thickness,
    required this.dashWidth,
    required this.gap,
  });

  final Color color;
  final double thickness;
  final double dashWidth;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.butt;
    final y = size.height / 2;
    var x = 0.0;
    while (x < size.width) {
      final end = (x + dashWidth).clamp(0.0, size.width);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += dashWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _GenzDashedLinePainter oldDelegate) =>
      color != oldDelegate.color ||
      thickness != oldDelegate.thickness ||
      dashWidth != oldDelegate.dashWidth ||
      gap != oldDelegate.gap;
}

class GenzReceiptClipper extends CustomClipper<Path> {
  const GenzReceiptClipper({this.topRadius = 22, this.toothWidth = 16, this.toothHeight = 8});

  final double topRadius;
  final double toothWidth;
  final double toothHeight;

  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, topRadius)
      ..quadraticBezierTo(0, 0, topRadius, 0)
      ..lineTo(size.width - topRadius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, topRadius)
      ..lineTo(size.width, size.height - toothHeight);

    var x = size.width;
    while (x > 0) {
      final tip = (x - toothWidth / 2).clamp(0.0, size.width);
      final valley = (x - toothWidth).clamp(0.0, size.width);
      path
        ..lineTo(tip, size.height)
        ..lineTo(valley, size.height - toothHeight);
      x -= toothWidth;
    }

    path
      ..lineTo(0, topRadius)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant GenzReceiptClipper oldClipper) =>
      topRadius != oldClipper.topRadius ||
      toothWidth != oldClipper.toothWidth ||
      toothHeight != oldClipper.toothHeight;
}
