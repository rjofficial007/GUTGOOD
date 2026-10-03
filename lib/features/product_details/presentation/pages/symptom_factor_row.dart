part of 'symptom_detail_screen.dart';

/// Symptom factor row component.

class _SymptomFactorRow extends StatelessWidget {
  const _SymptomFactorRow({required this.factor});
  final _SymptomFactor factor;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final isNeg = factor.isNegative;
    final color = isNeg ? t.negative : t.positive;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(isNeg ? Icons.remove_rounded : Icons.add_rounded, size: 10.sp, color: color),
          ),
          Gap.w10,
          Expanded(
            child: Text(
              factor.label,
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.bodySize.sp, fontWeight: FontWeight.w600, color: t.textPrimary),
            ),
          ),
          Text(
            factor.phrase,
            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.footSize.sp, fontWeight: FontWeight.w500, color: t.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// 🌟 Section 3: Quick-Signal Metric Cards Row (matching ScanMetricsRow).
