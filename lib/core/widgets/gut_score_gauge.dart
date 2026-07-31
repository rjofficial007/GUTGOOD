import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';

class GutScoreGauge extends StatelessWidget {
  final int score;
  final double size;

  const GutScoreGauge({super.key, required this.score, this.size = 200});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: score),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, animatedScore, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size,
              height: size / 1.5,
              child: CustomPaint(
                painter: _GaugePainter(
                  score: animatedScore,
                  trackColor: context.appColorScheme.border.withValues(alpha: 0.5),
                  progressColor: animatedScore >= 80 ? AppPalette.lime : AppPalette.purple,
                ),
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
                          Text(
                            '$animatedScore',
                            style: context.h1.copyWith(fontSize: 48.0.sp, fontWeight: FontWeight.w900, height: 1),
                          ),
                          Text(
                            'Gut Score',
                            style: context.caption.copyWith(color: context.appColorScheme.textMuted, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final int score;
  final Color trackColor;
  final Color progressColor;

  _GaugePainter({required this.score, required this.trackColor, required this.progressColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;
    final strokeWidth = 12.0;

    // Background Arc (Dotted style)
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double startAngle = pi;
    final double sweepAngle = pi;

    // Draw small lines for track
    final int subdivisions = 40;
    for (int i = 0; i <= subdivisions; i++) {
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

    final double progressSweep = (score / 100) * sweepAngle;
    final int activeSubdivisions = ((score / 100) * subdivisions).round();

    for (int i = 0; i <= activeSubdivisions; i++) {
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
