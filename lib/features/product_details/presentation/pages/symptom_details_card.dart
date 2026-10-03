part of 'symptom_detail_screen.dart';

/// Symptom details presentation component.

class _SymptomDetailsCard extends StatelessWidget {
  const _SymptomDetailsCard({required this.symptom});
  final SymptomLog symptom;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final date = DateFormatter.formatFull(symptom.eventTime);

    return Container(
      padding: EdgeInsets.all(BentoMetrics.padding.w),
      decoration: BoxDecoration(color: t.cardBackground, borderRadius: BorderRadius.circular(BentoMetrics.radius.w)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BentoCardHeader(title: 'LOG DETAILS', icon: AppIcons.info),
          Gap.h12,
          _detailRow(context, 'Recorded On', date, AppIcons.calendar),
          Gap.h8,
          _detailRow(context, 'Source', symptom.source?.toUpperCase() ?? AppStrings.chatSource, AppIcons.database),
          Gap.h8,
          _detailRow(context, 'Severity Level', '${symptom.severity ?? 0} / 10', AppIcons.activity),
          if (symptom.foodName != null && symptom.foodName!.isNotEmpty) ...[Gap.h8, _detailRow(context, 'Associated Food', symptom.foodName!, AppIcons.utensils)],
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value, IconData icon) {
    final t = context.bentoTheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(color: t.border.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8.r)),
      child: Row(
        children: [
          Icon(icon, size: 14.sp, color: t.textTertiary),
          Gap.w8,
          Text(
            label,
            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.footSize.sp, fontWeight: FontWeight.w500, color: t.textSecondary),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.footSize.sp, fontWeight: FontWeight.w700, color: t.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
