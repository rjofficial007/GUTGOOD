part of 'insights_feed.dart';

class _FoodImpactBalanceHeroCard extends StatelessWidget {
  const _FoodImpactBalanceHeroCard({this.balance, this.foodImpacts = const []});

  final FoodImpactBalance? balance;
  final List<FoodImpact> foodImpacts;

  static const _positive = Color(0xFF22C55E);
  static const _neutral = Color(0xFFF59E0B);
  static const _negative = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    var positive = balance?.positivePercent ?? 0;
    var neutral = balance?.neutralPercent ?? 0;
    var negative = balance?.negativePercent ?? 0;

    if ((balance == null || (positive == 0 && neutral == 0 && negative == 0)) && foodImpacts.isNotEmpty) {
      var positiveCount = 0;
      var negativeCount = 0;
      for (final impact in foodImpacts) {
        if (impact.impactType == 'positive') positiveCount++;
        if (impact.impactType == 'negative') negativeCount++;
      }
      positive = (positiveCount * 100 / foodImpacts.length).round();
      negative = (negativeCount * 100 / foodImpacts.length).round();
      neutral = (100 - positive - negative).clamp(0, 100);
    }

    positive = positive.clamp(0, 100);
    neutral = neutral.clamp(0, 100);
    negative = negative.clamp(0, 100);
    final total = positive + neutral + negative;
    if (total > 0 && total != 100) {
      positive = (positive * 100 / total).round();
      negative = (negative * 100 / total).round();
      neutral = 100 - positive - negative;
    }

    final border = context.insightColor(const Color(0xFFE2E8F0));
    final secondary = context.insightColor(const Color(0xFF64748B));
    final hasData = positive + neutral + negative > 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.insightTheme.card,
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: border),
        boxShadow: [BoxShadow(color: context.insightColor(const Color(0xFF0F172A)).withValues(alpha: 0.03), blurRadius: 10.w, offset: Offset(0, 2.w))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Card Content ---
          if (hasData)
            Padding(
              padding: EdgeInsets.all(14.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Left Donut Chart
                      Expanded(
                        flex: 5,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final size = math.min(constraints.maxWidth, 116.w);
                            return SizedBox(
                              width: size,
                              height: size,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CustomPaint(
                                    size: Size(size, size),
                                    painter: _FoodImpactDonutPainter(
                                      positiveRatio: positive / 100,
                                      neutralRatio: neutral / 100,
                                      negativeRatio: negative / 100,
                                      positiveColor: _positive,
                                      neutralColor: _neutral,
                                      negativeColor: _negative,
                                      emptyColor: border,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Gap.w14,
                      // Right Vertical Legend Stack
                      Expanded(
                        flex: 5,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ImpactBalanceLegend(color: _positive, label: 'Positive Impact', value: positive),
                            Gap.h8,
                            _ImpactBalanceLegend(color: _neutral, label: 'Neutral Impact', value: neutral),
                            Gap.h8,
                            _ImpactBalanceLegend(color: _negative, label: 'Negative Impact', value: negative),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (foodImpacts.isNotEmpty) ...[
                    Gap.h8,
                    Text(
                      'Based on ${foodImpacts.length} logged meal–response observations. Associations do not prove cause.',
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.sp, height: 1.3, color: secondary),
                    ),
                  ],
                ],
              ),
            )
          else
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                children: [
                  Icon(LucideIcons.pieChart, size: 20.w, color: secondary),
                  Gap.w12,
                  Expanded(
                    child: Text(
                      'Log meals and how you feel to build your food impact analytics view.',
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, height: 1.35, color: secondary),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ImpactBalanceLegend extends StatelessWidget {
  const _ImpactBalanceLegend({required this.color, required this.label, required this.value});

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Gap.w6,
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w500, color: context.insightColor(const Color(0xFF64748B))),
            ),
          ),
        ],
      ),
      Padding(
        padding: EdgeInsets.only(left: 14.w, top: 2.w),
        child: Text(
          '$value%',
          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 15.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
        ),
      ),
    ],
  );
}

class _FoodImpactDonutPainter extends CustomPainter {
  _FoodImpactDonutPainter({
    required this.positiveRatio,
    required this.neutralRatio,
    required this.negativeRatio,
    required this.positiveColor,
    required this.neutralColor,
    required this.negativeColor,
    required this.emptyColor,
  });

  final double positiveRatio;
  final double neutralRatio;
  final double negativeRatio;
  final Color positiveColor;
  final Color neutralColor;
  final Color negativeColor;
  final Color emptyColor;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.22;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final totalRatio = positiveRatio + neutralRatio + negativeRatio;

    if (totalRatio <= 0) {
      paint.color = emptyColor;
      canvas.drawArc(rect, 0, 2 * math.pi, false, paint);
      return;
    }

    var startAngle = -math.pi / 2; // Top center angle

    void drawArcSegment(double ratio, Color color) {
      if (ratio <= 0) return;
      final sweepAngle = 2 * math.pi * ratio;
      paint.color = color;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }

    drawArcSegment(positiveRatio, positiveColor);
    drawArcSegment(neutralRatio, neutralColor);
    drawArcSegment(negativeRatio, negativeColor);
  }

  @override
  bool shouldRepaint(covariant _FoodImpactDonutPainter oldDelegate) =>
      oldDelegate.positiveRatio != positiveRatio ||
      oldDelegate.neutralRatio != neutralRatio ||
      oldDelegate.negativeRatio != negativeRatio ||
      oldDelegate.positiveColor != positiveColor ||
      oldDelegate.neutralColor != neutralColor ||
      oldDelegate.negativeColor != negativeColor ||
      oldDelegate.emptyColor != emptyColor;
}
