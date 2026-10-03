part of 'insights_feed.dart';

/// Food impact balance presentation components.

class _FoodImpactBalanceHeroCard extends StatelessWidget {
  const _FoodImpactBalanceHeroCard({this.balance, this.foodImpacts = const []});

  final FoodImpactBalance? balance;
  final List<FoodImpact> foodImpacts;

  @override
  Widget build(BuildContext context) {
    var pos = balance?.positivePercent ?? 0;
    var neu = balance?.neutralPercent ?? 0;
    var neg = balance?.negativePercent ?? 0;
    final periodLabel = balance?.periodLabel.trim().isNotEmpty == true ? balance!.periodLabel : 'Based on available logs';

    if (balance == null || (pos == 0 && neu == 0 && neg == 0)) {
      if (foodImpacts.isNotEmpty) {
        var posCount = 0;
        var negCount = 0;
        for (final f in foodImpacts) {
          if (f.impactType == 'positive') {
            posCount++;
          } else if (f.impactType == 'negative') {
            negCount++;
          }
        }
        final total = foodImpacts.length;
        if (total > 0) {
          pos = ((posCount / total) * 100).round();
          neg = ((negCount / total) * 100).round();
          neu = (100 - pos - neg).clamp(0, 100);
        }
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (pos == 0 && neu == 0 && neg == 0) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: context.insightTheme.card,
          borderRadius: BorderRadius.circular(20.w),
          border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(5.w),
                  decoration: BoxDecoration(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.20) : const Color(0xFFDCFCE7), shape: BoxShape.circle),
                  child: Icon(LucideIcons.leaf, size: 14.w, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)),
                ),
                Gap.w8,
                Text(
                  'Food Impact Balance',
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                ),
              ],
            ),
            Gap.h8,
            Text(
              'No food impact balance data yet. Keep logging your meals and symptoms to track your food impact ratios.',
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, color: context.insightColor(const Color(0xFF64748B)), height: 1.3),
            ),
          ],
        ),
      );
    }

    pos = pos.clamp(0, 100);
    neu = neu.clamp(0, 100);
    neg = neg.clamp(0, 100);
    final totalPercent = pos + neu + neg;
    if (totalPercent > 0 && totalPercent != 100) {
      pos = (pos * 100 / totalPercent).round();
      neg = (neg * 100 / totalPercent).round();
      neu = 100 - pos - neg;
    }
    final posRatio = pos / 100.0;
    final neuRatio = neu / 100.0;
    final negRatio = neg / 100.0;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: context.insightTheme.card,
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0)), width: 1.w),
        boxShadow: [BoxShadow(color: context.insightColor(const Color(0xFF0F172A)).withValues(alpha: 0.03), blurRadius: 8.w, offset: Offset(0, 2.w))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.20) : const Color(0xFFDCFCE7), shape: BoxShape.circle),
                child: Icon(LucideIcons.leaf, size: 14.w, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)),
              ),
              Gap.w8,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Food Impact Balance',
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 14.5.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                    ),
                    Text(
                      'Your food choices over the $periodLabel.',
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, color: context.insightColor(const Color(0xFF64748B))),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Gap.h12,

          // Row with Donut Chart + Legend
          Row(
            children: [
              // Donut Chart
              SizedBox(
                width: 86.w,
                height: 86.w,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: Size(86.w, 86.w),
                      painter: _FoodImpactDonutPainter(positiveRatio: posRatio, neutralRatio: neuRatio, negativeRatio: negRatio),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$pos%',
                          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 20.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A)), height: 1.0),
                        ),
                        Text(
                          'Positive',
                          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w700, color: context.insightColor(const Color(0xFF64748B))),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Legend items (Expanded)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LegendItem(color: const Color(0xFF22C55E), percent: '$pos%', label: 'Positive', sub: 'Helping your gut'),
                  Gap.h6,
                  _LegendItem(color: const Color(0xFFFBBF24), percent: '$neu%', label: 'Neutral', sub: 'Minimal impact'),
                  Gap.h6,
                  _LegendItem(color: const Color(0xFFF87171), percent: '$neg%', label: 'Negative', sub: 'May trigger symptoms'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.percent, required this.label, required this.sub});

  final Color color;
  final String percent;
  final String label;
  final String sub;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 7.w,
        height: 7.w,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      Gap.w4,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                percent,
                style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
              ),
              Gap.w3,
              Text(
                label,
                style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w700, color: context.insightColor(const Color(0xFF0F172A))),
              ),
            ],
          ),
          Text(
            sub,
            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.5.sp, color: context.insightColor(const Color(0xFF64748B))),
          ),
        ],
      ),
    ],
  );
}

// =============================================================================
// FOOD IMPACT TAB: 2. SIDE-BY-SIDE TOP HEALING & TOP TRIGGER FOOD CARDS
// =============================================================================
