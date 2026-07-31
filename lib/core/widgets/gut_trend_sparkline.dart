import 'package:flutter/material.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/utils/responsive.dart';

class GutTrendSparkline extends StatelessWidget {
  final List<int> data;
  final double width;
  final double height;
  final Color? color;

  const GutTrendSparkline({
    super.key,
    required this.data,
    this.width = 100,
    this.height = 30,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: Responsive.w(width),
      height: Responsive.h(height),
      child: CustomPaint(
        painter: _SparklinePainter(
          data: data,
          color: color ?? context.appColorScheme.success,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<int> data;
  final Color color;

  _SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    
    final minVal = data.reduce((a, b) => a < b ? a : b).toDouble();
    final maxVal = data.reduce((a, b) => a > b ? a : b).toDouble();
    final range = (maxVal - minVal == 0) ? 1.0 : (maxVal - minVal);

    final widthStep = size.width / (data.length - 1);
    
    for (var i = 0; i < data.length; i++) {
      final x = i * widthStep;
      final normalizedY = (data[i] - minVal) / range;
      // Invert Y because canvas Y grows downwards
      final y = size.height - (normalizedY * size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
