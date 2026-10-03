part of 'scan_result_widgets.dart';

/// Scan details presentation component.

class ScanDetailsCard extends StatelessWidget {
  const ScanDetailsCard({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final date = DateFormat('MMM dd, yyyy • hh:mm a').format(scanData.createdAt);

    return Container(
      padding: EdgeInsets.all(BentoMetrics.padding.w),
      decoration: BoxDecoration(color: t.cardBackground, borderRadius: BorderRadius.circular(BentoMetrics.radius.w)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BentoCardHeader(title: 'SCAN DETAILS'),
          Gap.h12,
          _detailRow(context, AppStrings.analyzedOn, date, AppIcons.calendar),
          Gap.h8,
          _detailRow(context, AppStrings.servingSizeRow, scanData.servingSize ?? AppStrings.standardServing, AppIcons.utensils),
          Gap.h8,
          _detailRow(context, AppStrings.sourceRow, scanSourceLabel(scanData), AppIcons.database),
          Gap.h8,
          _detailRow(context, AppStrings.nutritionFactsLabel, scanData.nutritionEstimated ? 'Estimated' : 'Label data', AppIcons.fileText),
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

/// 🌟 Footer: gentle nudge into chat for follow-up questions.
