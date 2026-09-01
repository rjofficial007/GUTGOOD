import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';

class ModernGutScoreCard extends StatelessWidget {
  const ModernGutScoreCard({super.key, required this.score, this.scoreDiff, required this.onTap});

  final int score;
  final String? scoreDiff;
  final VoidCallback onTap;

  String get _status {
    if (score >= 80) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 50) return 'Fair';
    return 'Poor';
  }

  Color get _statusColor {
    if (score >= 70) return AppPalette.green500;
    if (score >= 50) return AppPalette.orange;
    return AppPalette.red;
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(AppSizes.p16),
    decoration: BoxDecoration(
      color: const Color(0xFF0D1217),
      borderRadius: BorderRadius.circular(AppSizes.r20),
      boxShadow: [BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 15, offset: const Offset(0, 8))],
    ),
    child: IntrinsicHeight(
      child: Row(
        children: [
          // Left Content: Score & Stats
          Expanded(
            flex: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(AppIcons.activity, size: 12, color: _statusColor),
                    Gap.w8,
                    Text(
                      'GUT SCORE',
                      style: context.captionBold.copyWith(color: Colors.white.withAlpha(120), letterSpacing: 1.1, fontSize: 9.sp),
                    ),
                  ],
                ),
                Gap.h12,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$score',
                      style: context.displayHero.copyWith(color: Colors.white, fontSize: 64.sp, height: 0.9, letterSpacing: -2),
                    ),
                    if (scoreDiff != null) ...[
                      Gap.w10,
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: _statusColor.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              Icon(Icons.arrow_upward, size: 10, color: _statusColor),
                              Gap.w4,
                              Text(
                                scoreDiff!,
                                style: context.captionBold.copyWith(color: _statusColor, fontSize: 11.sp),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Gap.h4,
                Row(
                  children: [
                    Text(
                      _status,
                      style: context.headingSm.copyWith(color: _statusColor, fontWeight: FontWeight.bold, fontSize: 20.sp),
                    ),
                    Gap.w6,
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _statusColor,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: _statusColor.withAlpha(100), blurRadius: 6)],
                      ),
                    ),
                  ],
                ),
                Gap.h8,
                Text('Great choices. Keep it up!', style: context.bodySm.copyWith(color: Colors.white.withAlpha(150))),
                const Spacer(),
                Gap.h16,
                InkWell(
                  onTap: onTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Detailed insights',
                        style: context.captionBold.copyWith(color: Colors.white, fontSize: 12.sp),
                      ),
                      Gap.w4,
                      const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Right Content: Integrated Gauge
          Expanded(
            flex: 8,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(130.h, 130.h),
                  painter: GaugePainter(score: score, color: _statusColor),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class GaugePainter extends CustomPainter {
  GaugePainter({required this.score, required this.color, this.scoreDiff});
  final int score;
  final Color color;
  final String? scoreDiff;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw background segments (arc)
    final segmentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.w
      ..strokeCap = StrokeCap.round;

    const totalSegments = 40;
    const startAngle = 3 * math.pi / 4;
    const sweepAngle = 3 * math.pi / 2;

    for (var i = 0; i < totalSegments; i++) {
      final angle = startAngle + (i / totalSegments) * sweepAngle;
      final isFilled = (i / totalSegments) * 100 <= score;

      segmentPaint.color = isFilled ? color.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.1);

      final innerP = Offset(center.dx + (radius - 15.w) * math.cos(angle), center.dy + (radius - 15.w) * math.sin(angle));
      final outerP = Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));

      canvas.drawLine(innerP, outerP, segmentPaint);
    }

    // Draw the trend line inside
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.w
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final points = [
      Offset(radius * 0.4, radius * 1.2),
      Offset(radius * 0.6, radius * 1.1),
      Offset(radius * 0.8, radius * 1.3),
      Offset(radius * 1.0, radius * 0.9),
      Offset(radius * 1.2, radius * 1.0),
      Offset(radius * 1.4, radius * 0.7),
      Offset(radius * 1.6, radius * 0.8),
    ];

    path.moveTo(points[0].dx, points[0].dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    // Gradient below the line
    final fillPath = Path.from(path);
    fillPath.lineTo(points.last.dx, radius * 1.5);
    fillPath.lineTo(points.first.dx, radius * 1.5);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.3), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // Draw a glow point at the end
    final glowPaint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(points.last, 6.w, glowPaint);
    canvas.drawCircle(points.last, 3.w, Paint()..color = Colors.white);

    // DRAW SCORE DIFF TEXT
    if (scoreDiff != null) {
      final isPositive = !scoreDiff!.startsWith('-');
      final diffColor = isPositive ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
      final arrow = isPositive ? '↑' : '↓';
      final cleanDiff = scoreDiff!.replaceAll('+', '').replaceAll('-', '');

      final tp = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$arrow $cleanDiff pts\n',
              style: TextStyle(color: diffColor, fontSize: 11.sp, fontWeight: FontWeight.w900, height: 1.2),
            ),
            TextSpan(
              text: 'this week',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 8.sp, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy + radius * 0.4));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
