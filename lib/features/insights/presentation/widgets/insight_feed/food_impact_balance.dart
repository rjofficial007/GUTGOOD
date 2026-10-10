part of 'insights_feed.dart';

/// Distribution of logged foods and the responses users recorded afterward.
class _FoodImpactBalanceHeroCard extends StatelessWidget {
  const _FoodImpactBalanceHeroCard({this.balance, this.foodImpacts = const []});

  final FoodImpactBalance? balance;
  final List<FoodImpact> foodImpacts;

  static const _positive = Color(0xFF16A765);
  static const _neutral = Color(0xFFF5A623);
  static const _negative = Color(0xFFEF5350);
  static const _unknown = Color(0xFFCBD5E1);

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{'positive': 0, 'neutral': 0, 'negative': 0, 'unknown': 0};
    for (final impact in foodImpacts) {
      if (impact.food.trim().isEmpty) continue;
      final type = switch (impact.impactType.toLowerCase().trim()) {
        'positive' || 'healing' || 'good' || 'supportive' => 'positive',
        'neutral' => 'neutral',
        'negative' || 'trigger' || 'bad' || 'watch' => 'negative',
        _ => 'unknown',
      };
      counts[type] = counts[type]! + 1;
    }

    final observations = counts.values.fold<int>(0, (sum, value) => sum + value);
    final storedTotal = (balance?.positivePercent ?? 0) + (balance?.neutralPercent ?? 0) + (balance?.negativePercent ?? 0);
    int percent(String key, int fallback) => observations > 0 ? (counts[key]! * 100 / observations).round() : fallback.clamp(0, 100).toInt();
    final positive = percent('positive', balance?.positivePercent ?? 0);
    final neutral = percent('neutral', balance?.neutralPercent ?? 0);
    final negative = percent('negative', balance?.negativePercent ?? 0);
    final unknown = percent('unknown', 0);
    final chartTotal = observations > 0 ? observations : storedTotal;
    double ratio(String key, int fallback) => chartTotal == 0 ? 0 : (observations > 0 ? counts[key]! : fallback) / chartTotal;
    final secondary = context.insightColor(const Color(0xFF64748B));

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: context.insightTheme.card,
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0))),
        boxShadow: [BoxShadow(color: context.insightColor(const Color(0xFF0F172A)).withValues(alpha: 0.035), blurRadius: 12.w, offset: Offset(0, 3.w))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FoodImpactSectionHeader(title: 'Food Impact So Far', subtitle: 'Based on your logged meals and how you felt afterward.'),
          Gap.h14,
          Row(
            children: [
              Expanded(
                flex: 5,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = math.min(constraints.maxWidth, 120.w);
                    return SizedBox(
                      width: size,
                      height: size,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: Size.square(size),
                            painter: _FoodImpactDonutPainter(
                              positiveRatio: ratio('positive', balance?.positivePercent ?? 0),
                              neutralRatio: ratio('neutral', balance?.neutralPercent ?? 0),
                              negativeRatio: ratio('negative', balance?.negativePercent ?? 0),
                              unknownRatio: ratio('unknown', 0),
                              positiveColor: _positive,
                              neutralColor: _neutral,
                              negativeColor: _negative,
                              unknownColor: _unknown,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$observations',
                                style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 22.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                              ),
                              Text(
                                'total\nobservations',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.sp, height: 1.15, color: secondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Gap.w12,
              Expanded(
                flex: 7,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _ImpactBalanceLegend(color: _positive, label: 'Positive Impact', value: positive, observations: counts['positive']!),
                        ),
                        Gap.w8,
                        Expanded(
                          child: _ImpactBalanceLegend(color: _neutral, label: 'Neutral Impact', value: neutral, observations: counts['neutral']!),
                        ),
                      ],
                    ),
                    Gap.h12,
                    Row(
                      children: [
                        Expanded(
                          child: _ImpactBalanceLegend(color: _negative, label: 'Negative Impact', value: negative, observations: counts['negative']!),
                        ),
                        Gap.w8,
                        Expanded(
                          child: _ImpactBalanceLegend(color: _unknown, label: 'Not Enough Data', value: unknown, observations: counts['unknown']!),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImpactBalanceLegend extends StatelessWidget {
  const _ImpactBalanceLegend({required this.color, required this.label, required this.value, required this.observations});

  final Color color;
  final String label;
  final int value;
  final int observations;

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
          Gap.w5,
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.5.sp, color: context.insightColor(const Color(0xFF64748B))),
            ),
          ),
        ],
      ),
      Padding(
        padding: EdgeInsets.only(left: 13.w, top: 2.w),
        child: Text(
          '$value%',
          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
        ),
      ),
      Padding(
        padding: EdgeInsets.only(left: 13.w),
        child: Text(
          '$observations observation${observations == 1 ? '' : 's'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.sp, color: context.insightColor(const Color(0xFF64748B))),
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
    required this.unknownRatio,
    required this.positiveColor,
    required this.neutralColor,
    required this.negativeColor,
    required this.unknownColor,
  });

  final double positiveRatio;
  final double neutralRatio;
  final double negativeRatio;
  final double unknownRatio;
  final Color positiveColor;
  final Color neutralColor;
  final Color negativeColor;
  final Color unknownColor;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.18;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    final total = positiveRatio + neutralRatio + negativeRatio + unknownRatio;
    if (total <= 0) {
      paint.color = unknownColor;
      canvas.drawArc(rect, 0, 2 * math.pi, false, paint);
      return;
    }

    var start = -math.pi / 2;
    void segment(double ratio, Color color) {
      if (ratio <= 0) return;
      paint.color = color;
      final sweep = 2 * math.pi * ratio / total;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }

    segment(positiveRatio, positiveColor);
    segment(neutralRatio, neutralColor);
    segment(negativeRatio, negativeColor);
    segment(unknownRatio, unknownColor);
  }

  @override
  bool shouldRepaint(covariant _FoodImpactDonutPainter old) =>
      old.positiveRatio != positiveRatio || old.neutralRatio != neutralRatio || old.negativeRatio != negativeRatio || old.unknownRatio != unknownRatio;
}
