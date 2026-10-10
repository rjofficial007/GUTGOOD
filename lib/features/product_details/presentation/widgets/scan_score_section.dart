part of 'scan_result_widgets.dart';

/// Score explanation and factor presentation components.

class ScanScoreSection extends StatelessWidget {
  const ScanScoreSection({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final band = GutScoreBand.fromScore(scanData.score);

    final recomputed = YukaScore.evaluate(
      nutriscore: scanData.nutriscore,
      nutriscoreScore: scanData.nutriscoreScore,
      energyKcal: scanData.nutrients?.calories,
      fiberG: scanData.nutrients?.fiber,
      proteinG: scanData.nutrients?.proteins,
      sugarG: scanData.nutrients?.sugars,
      saltG: scanData.nutrients?.salt,
      saturatedFatG: scanData.nutrients?.saturatedFat,
      additiveConcerns: scanData.additiveConcerns,
      isOrganic: scanData.isOrganic,
      novaGroup: int.tryParse(scanData.novaGroup ?? ''),
      isBeverage: YukaScore.isBeverageCategory(scanData.category),
      isWater: YukaScore.isPlainWater(
        productName: scanData.productName,
        category: scanData.category,
        energyKcal: scanData.nutrients?.calories,
        sugarG: scanData.nutrients?.sugars,
      ),
    );

    final showBreakdown = recomputed.hasData;
    final factors = [...recomputed.factors];

    // Ensure the breakdown factors sum up to the actual displayed score
    final diff = scanData.score - recomputed.score;
    if (diff != 0 && showBreakdown) {
      factors.add(ScoreFactor(label: 'Difference from current calculation · ${diff > 0 ? '+' : ''}$diff pts', delta: diff, phrase: 'recorded score differs from the current calculation'));
    }

    // Use the backend AI narrative explanation if provided, otherwise clean up recomputed text.
    var explanation = scanData.impact.isNotEmpty ? scanData.impact : recomputed.explanation;
    if (explanation.startsWith('Score ')) {
      explanation = explanation.replaceFirst('Score ${recomputed.score} out of 100', 'Score ${scanData.score} out of 100');
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [band.color.withValues(alpha: 0.14), band.color.withValues(alpha: 0.05)]),
        borderRadius: BorderRadius.circular(BentoMetrics.radius.w),
        boxShadow: [BoxShadow(color: band.color.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      padding: EdgeInsets.all(BentoMetrics.padding.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 96.w,
                child: ScoreGauge(score: scanData.score, color: band.color, fontSize: 26.sp),
              ),
              Gap.w14,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(color: band.color, borderRadius: BorderRadius.circular(100.r)),
                          child: Text(
                            band.label,
                            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 9.sp, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Colors.white),
                          ),
                        ),
                        Gap.w6,
                        Text(
                          '${scanData.score}/100',
                          style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w800, color: band.color),
                        ),
                      ],
                    ),
                    Gap.h6,
                    Text(
                      explanation,
                      style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.bodySize.sp, fontWeight: FontWeight.w500, height: 1.4, color: t.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showBreakdown) ...[Gap.h14, _WhyScoreExpander(factors: factors, bandColor: band.color)],
        ],
      ),
    );
  }
}

class _WhyScoreExpander extends StatefulWidget {
  const _WhyScoreExpander({required this.factors, required this.bandColor});
  final List<ScoreFactor> factors;
  final Color bandColor;

  @override
  State<_WhyScoreExpander> createState() => _WhyScoreExpanderState();
}

class _WhyScoreExpanderState extends State<_WhyScoreExpander> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(color: widget.bandColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10.r)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(AppIcons.chartPie, size: 14.sp, color: widget.bandColor),
                Gap.w6,
                Text(
                  AppStrings.whyThisScore,
                  style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.bodySize.sp, fontWeight: FontWeight.w700, height: 1.2, color: t.textPrimary),
                ),
                Gap.w4,
                AnimatedRotation(
                  turns: _open ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down_rounded, size: 20.sp, color: t.textSecondary),
                ),
              ],
            ),
          ),
        ),
        if (_open) ...[
          Gap.h10,
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(color: t.cardBackground, borderRadius: BorderRadius.circular(12.r)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...widget.factors.map((f) => _ScoreFactorRow(factor: f)),
                Gap.h8,
                Divider(color: t.border.withValues(alpha: 0.4), height: 1),
                Gap.h8,
                Text(
                  AppStrings.scoreFootnote,
                  style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.footSize.sp, fontWeight: FontWeight.w400, color: t.textQuaternary, height: 1.3),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ScoreFactorRow extends StatelessWidget {
  const _ScoreFactorRow({required this.factor});
  final ScoreFactor factor;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final isPos = factor.isPositive;
    final color = isPos ? t.positive : t.negative;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(isPos ? Icons.add_rounded : Icons.remove_rounded, size: 10.sp, color: color),
          ),
          Gap.w10,
          Expanded(
            child: Text(
              factor.label,
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.bodySize.sp, fontWeight: FontWeight.w600, color: t.textPrimary),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6.r)),
            child: Text(
              '${isPos ? '+' : ''}${factor.delta}',
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w800, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// 🌟 Section 3: Quick-signal metric cards (Gut Impact, NOVA, Gut Barrier, Processing).
