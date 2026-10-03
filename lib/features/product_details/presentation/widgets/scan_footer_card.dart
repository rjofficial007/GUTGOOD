part of 'scan_result_widgets.dart';

/// Scan footer presentation component.

class ScanFooterCard extends StatelessWidget {
  const ScanFooterCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    return InkWell(
      onTap: () => context.go(AppRoutes.chat),
      borderRadius: BorderRadius.circular(12),
      child: BentoCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 12,
        backgroundColor: t.mint.withAlpha(16),
        borderColor: t.mint.withAlpha(40),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: t.mint.withAlpha(26), shape: BoxShape.circle),
              child: Icon(AppIcons.leaf, size: 16.sp, color: t.mint),
            ),
            Gap.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.scanFooterTitle,
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.titleSize.sp, fontWeight: FontWeight.w700, color: t.mint),
                  ),
                  Gap.h2,
                  Text(
                    AppStrings.scanFooterBody,
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.footSize.sp, fontWeight: FontWeight.w400, color: t.textTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🌟 Cycle Insight Section
