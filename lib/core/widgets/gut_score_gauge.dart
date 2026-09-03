import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';

class GutScoreGauge extends StatelessWidget {
  const GutScoreGauge({super.key, required this.score, this.size = 200});
  final int score;
  final double size;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<int>(
    tween: IntTween(begin: 0, end: score),
    duration: const Duration(milliseconds: 1200),
    curve: Curves.easeOutCubic,
    builder: (context, animatedScore, _) => Semantics(
      label: 'Gut Score',
      value: score.toString(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size / 1.5,
            child: CustomPaint(
              painter: _GaugePainter(score: animatedScore, trackColor: context.appColorScheme.borderSubtle, progressColor: context.appColorScheme.textPrimary),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$animatedScore', style: context.displayHero.copyWith(fontSize: 48.0.sp, height: 1)),
                        Text('Gut Score', style: context.caption),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.score, required this.trackColor, required this.progressColor});
  final int score;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;
    const strokeWidth = 12.0;

    // Background Arc (Dotted style)
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = pi;
    const sweepAngle = pi;

    // Draw small lines for track
    const subdivisions = 40;
    for (var i = 0; i <= subdivisions; i++) {
      final angle = startAngle + (i / subdivisions) * sweepAngle;
      final innerRadius = radius - strokeWidth;
      final outerRadius = radius;

      final p1 = Offset(center.dx + innerRadius * cos(angle), center.dy + innerRadius * sin(angle));
      final p2 = Offset(center.dx + outerRadius * cos(angle), center.dy + outerRadius * sin(angle));
      canvas.drawLine(p1, p2, trackPaint);
    }

    // Active segments
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressSweep = (score / 100) * sweepAngle;
    final activeSubdivisions = ((score / 100) * subdivisions).round();

    for (var i = 0; i <= activeSubdivisions; i++) {
      final angle = startAngle + (i / subdivisions) * sweepAngle;
      final innerRadius = radius - strokeWidth - 4;
      final outerRadius = radius + 2;

      final p1 = Offset(center.dx + innerRadius * cos(angle), center.dy + innerRadius * sin(angle));
      final p2 = Offset(center.dx + outerRadius * cos(angle), center.dy + outerRadius * sin(angle));
      canvas.drawLine(p1, p2, progressPaint);
    }

    // Needle or indicator
    final needlePaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.fill;

    final needleAngle = startAngle + progressSweep;
    final needleRadius = radius + 15;
    final needlePos = Offset(center.dx + needleRadius * cos(needleAngle), center.dy + needleRadius * sin(needleAngle));

    canvas.drawCircle(needlePos, 4, needlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
