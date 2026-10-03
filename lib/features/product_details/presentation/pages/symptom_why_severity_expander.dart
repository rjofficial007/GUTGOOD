part of 'symptom_detail_screen.dart';

/// Symptom severity explanation component.

class _WhySeverityExpander extends StatefulWidget {
  const _WhySeverityExpander({required this.factors, required this.bandColor});
  final List<_SymptomFactor> factors;
  final Color bandColor;

  @override
  State<_WhySeverityExpander> createState() => _WhySeverityExpanderState();
}

class _WhySeverityExpanderState extends State<_WhySeverityExpander> {
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
                  'WHY THIS SEVERITY',
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
                ...widget.factors.map((f) => _SymptomFactorRow(factor: f)),
                Gap.h8,
                Divider(color: t.border.withValues(alpha: 0.4), height: 1),
                Gap.h8,
                Text(
                  'Severity is logged on a 1-10 scale based on physical discomfort and associated body signals.',
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

