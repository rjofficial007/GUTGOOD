import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/features/product_details/presentation/widgets/scan_result_widgets.dart';

class ScoreDataPoint {
  const ScoreDataPoint({
    required this.dayLabel,
    required this.score,
    this.hasSymptom = false,
  });

  final String dayLabel;
  final int score;
  final bool hasSymptom;
}

class GutTrendChartCard extends StatelessWidget {
  const GutTrendChartCard({
    super.key,
    required this.dataPoints,
    required this.currentScore,
    this.scoreChangeText = '+4 pts',
    this.timeframeLabel = 'LAST 7 DAYS',
    this.onTap,
  });

  final List<ScoreDataPoint> dataPoints;
  final int currentScore;
  final String? scoreChangeText;
  final String timeframeLabel;
  final VoidCallback? onTap;

  Color get _accentColor {
    if (currentScore >= 70) return AppPalette.green;
    if (currentScore >= 50) return AppPalette.orange;
    return AppPalette.red;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _accentColor;
    final cardBg = isDark ? AppPalette.black : scheme.cardBackground;

    final points = dataPoints.isEmpty
        ? const [
            ScoreDataPoint(dayLabel: 'M', score: 65),
            ScoreDataPoint(dayLabel: 'T', score: 68),
            ScoreDataPoint(dayLabel: 'W', score: 70),
            ScoreDataPoint(dayLabel: 'T', score: 72),
            ScoreDataPoint(dayLabel: 'F', score: 75),
            ScoreDataPoint(dayLabel: 'S', score: 78),
            ScoreDataPoint(dayLabel: 'S', score: 80),
          ]
        : dataPoints;

    final avgScore = (points.map((p) => p.score).reduce((a, b) => a + b) / points.length).round();

    return BentoCard(
      padding: const EdgeInsets.all(20),
      backgroundColor: cardBg,
      borderColor: isDark ? AppPalette.white.withAlpha(20) : scheme.borderSubtle,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeframeLabel.toUpperCase(),
                      style: context.captionBold.copyWith(
                        color: scheme.textMuted,
                        fontSize: 9.sp,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gut Score Trend',
                      style: context.headingSm.copyWith(
                        color: scheme.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                if (scoreChangeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: accent.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accent.withAlpha(60), width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          scoreChangeText!.startsWith('-') ? Icons.arrow_downward : Icons.arrow_upward,
                          size: 12,
                          color: accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          scoreChangeText!,
                          style: context.captionBold.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w900,
                            fontSize: 10.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            Gap.h20,

            // Trend Curve Chart Area
            SizedBox(
              height: 120.h,
              width: double.infinity,
              child: CustomPaint(
                painter: _TrendCurvePainter(
                  points: points,
                  lineColor: accent,
                  isDark: isDark,
                  textColor: scheme.textMuted,
                ),
              ),
            ),

            Gap.h16,

            // Metric Summary Bar below Chart
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: scheme.elevatedSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: scheme.borderSubtle),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryMetric(
                    label: 'CURRENT',
                    value: '$currentScore',
                    accentColor: accent,
                  ),
                  Container(width: 1, height: 24, color: scheme.borderSubtle),
                  _SummaryMetric(
                    label: 'WEEKLY AVG',
                    value: '$avgScore',
                    accentColor: scheme.textPrimary,
                  ),
                  Container(width: 1, height: 24, color: scheme.borderSubtle),
                  _SummaryMetric(
                    label: 'TRAJECTORY',
                    value: currentScore >= avgScore ? 'Improving' : 'Attention',
                    accentColor: currentScore >= avgScore ? AppPalette.green : AppPalette.orange,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: context.captionMicro.copyWith(
            color: scheme.textMuted,
            fontWeight: FontWeight.w900,
            fontSize: 7.sp,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: context.labelBold.copyWith(
            color: accentColor,
            fontWeight: FontWeight.w900,
            fontSize: 13.sp,
          ),
        ),
      ],
    );
  }
}

class _TrendCurvePainter extends CustomPainter {
  _TrendCurvePainter({
    required this.points,
    required this.lineColor,
    required this.isDark,
    required this.textColor,
  });

  final List<ScoreDataPoint> points;
  final Color lineColor;
  final bool isDark;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final chartHeight = size.height - 24;
    final chartWidth = size.width;
    final stepX = chartWidth / (points.length - 1);

    const minScore = 40.0;
    const maxScore = 100.0;

    double getY(int score) {
      final normalized = ((score - minScore) / (maxScore - minScore)).clamp(0.0, 1.0);
      return chartHeight - (normalized * chartHeight);
    }

    final path = Path();
    final canvasPoints = <Offset>[];

    for (var i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = getY(points[i].score);
      canvasPoints.add(Offset(x, y));
    }

    // Draw Smooth Spline
    path.moveTo(canvasPoints.first.dx, canvasPoints.first.dy);
    for (var i = 0; i < canvasPoints.length - 1; i++) {
      final p1 = canvasPoints[i];
      final p2 = canvasPoints[i + 1];
      final controlP1 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p1.dy);
      final controlP2 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p2.dy);
      path.cubicTo(controlP1.dx, controlP1.dy, controlP2.dx, controlP2.dy, p2.dx, p2.dy);
    }

    // Gradient Fill Under Curve
    final fillPath = Path.from(path)
      ..lineTo(canvasPoints.last.dx, chartHeight)
      ..lineTo(canvasPoints.first.dx, chartHeight)
      ..close();

    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        lineColor.withAlpha(isDark ? 90 : 50),
        lineColor.withAlpha(0),
      ],
    );

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(Rect.fromLTWH(0, 0, chartWidth, chartHeight));
    canvas.drawPath(fillPath, fillPaint);

    // Curve Line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Points & Day Labels
    final textStyle = TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold);

    for (var i = 0; i < points.length; i++) {
      final pt = canvasPoints[i];
      final isLast = i == points.length - 1;

      // Draw Day Label
      final tp = TextPainter(
        text: TextSpan(text: points[i].dayLabel, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pt.dx - tp.width / 2, size.height - 14));

      // Draw Data Point Dot
      if (isLast) {
        final glowPaint = Paint()
          ..color = lineColor.withAlpha(140)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(pt, 8, glowPaint);
        canvas.drawCircle(pt, 4, Paint()..color = Colors.white);
      } else if (points[i].hasSymptom) {
        canvas.drawCircle(pt, 4, Paint()..color = AppPalette.pink);
      } else {
        canvas.drawCircle(pt, 2.5, Paint()..color = lineColor.withAlpha(120));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
