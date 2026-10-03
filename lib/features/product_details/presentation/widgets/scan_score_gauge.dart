part of 'scan_result_widgets.dart';

/// Score gauge presentation component.

class ScoreGauge extends StatelessWidget {
  const ScoreGauge({super.key, required this.score, required this.color, this.label = 'GUT SCORE', this.fontSize});
  final int score;
  final Color color;
  final String label;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final textColor = (color == AppPalette.darkGrey) ? AppPalette.white : t.textPrimary;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score.toDouble()),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutQuart,
      builder: (context, value, _) => LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth;

          return SizedBox(
            height: size,
            width: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(size, size),
                  painter: _GaugePainter(score: value.toInt(), color: color),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${value.toInt()}',
                      style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: fontSize ?? (size * 0.28).clamp(24, 42).sp, fontWeight: FontWeight.w700, height: 0.9, color: textColor),
                    ),
                    Text(
                      label,
                      style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 8.sp, fontWeight: FontWeight.w700, color: textColor.withAlpha(127)),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.score, required this.color});
  final int score;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 8.0;

    final bgPaint = Paint()
      ..color = (color == AppPalette.darkGrey ? AppPalette.white : color).withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    if (score > 0) {
      const startAngle = -1.5708;
      final sweepAngle = (score / 100) * 6.28319;

      canvas.drawArc(Rect.fromCircle(center: center, radius: radius - strokeWidth / 2), startAngle, sweepAngle, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) => oldDelegate.score != score;
}

/// 🌟 Section 1: Food identity header (photo + brand + name + summary).
