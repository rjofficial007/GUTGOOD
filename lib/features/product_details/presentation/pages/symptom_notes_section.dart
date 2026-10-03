part of 'symptom_detail_screen.dart';

/// Symptom notes presentation component.

class _SymptomNotesSection extends StatelessWidget {
  const _SymptomNotesSection({required this.notes});
  final String notes;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;

    return Container(
      padding: EdgeInsets.all(BentoMetrics.padding.w),
      decoration: BoxDecoration(color: t.cardBackground, borderRadius: BorderRadius.circular(BentoMetrics.radius.w)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BentoCardHeader(title: 'REACTION MEMO', icon: AppIcons.fileText),
          Gap.h12,
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(color: t.border.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10.r)),
            child: Text(
              notes,
              style: TextStyle(
                fontFamily: InsightBentoTheme.fontFamily,
                fontSize: BentoMetrics.bodySize.sp,
                fontWeight: FontWeight.w500,
                height: 1.5,
                color: t.textPrimary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 🌟 Section 6: Symptom Provenance Details (matching ScanDetailsCard).
