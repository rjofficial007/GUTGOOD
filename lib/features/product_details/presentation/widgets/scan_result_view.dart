import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/features/product_details/presentation/widgets/scan_result_widgets.dart';

class ScanResultView extends StatelessWidget {
  const ScanResultView({super.key, required this.scanData, required this.cycleSyncEnabled});

  final ScanResult scanData;
  final bool cycleSyncEnabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p16),
      child: Column(
        children: [
          // 1. Food identity header (photo + brand + name + summary)
          DashboardEntrance(delay: 50, child: ScanScoreHeader(scanData: scanData)),
          Gap.h20,

          // 2. Score gauge + band + "here's why" + expandable breakdown
          DashboardEntrance(delay: 100, child: ScanScoreSection(scanData: scanData)),
          Gap.h20,

          // 3. Quick-signal metric cards (Gut Impact, NOVA, Gut Barrier, Processing)
          DashboardEntrance(delay: 150, child: ScanMetricsRow(scanData: scanData)),
          Gap.h20,

          // 4. What works for you (Positives)
          DashboardEntrance(delay: 200, child: ScanWorkingSection(scanData: scanData)),
          Gap.h20,

          // 5. What to watch (Negatives + tappable additives/allergens)
          DashboardEntrance(delay: 250, child: ScanWatchSection(scanData: scanData)),
          Gap.h20,

          // 6. What this means for you (hidden when the AI gave no narrative)
          if (scanData.impact.isNotEmpty) ...[DashboardEntrance(delay: 300, child: ScanTopInsightsCard(scanData: scanData)), Gap.h20],

          // 7. Cycle Insight (Hormonal Phase Advice if Enabled)
          if (scanData.cycleInsight != null && cycleSyncEnabled) ...[DashboardEntrance(delay: 320, child: CycleInsightSection(insight: scanData.cycleInsight!)), Gap.h20],

          // 8. Better Swaps (tappable cards + working "+ Add")
          if (scanData.swaps.isNotEmpty) ...[DashboardEntrance(delay: 340, child: ScanSwapsSection(swaps: scanData.swaps)), Gap.h20],

          // 9. Additives (tappable rows → additive detail)
          DashboardEntrance(delay: 360, child: ScanAdditivesSection(scanData: scanData)),
          Gap.h20,

          // 10. Ingredients section (modern cards → ingredient list)
          DashboardEntrance(delay: 380, child: ScanIngredientsSection(scanData: scanData)),
          Gap.h20,

          // 11. Allergens section (modern cards → allergen list)
          DashboardEntrance(delay: 400, child: ScanAllergensSection(scanData: scanData)),
          Gap.h20,

          // 12. Scan details (provenance footer)
          DashboardEntrance(delay: 420, child: ScanDetailsCard(scanData: scanData)),
          Gap.h20,

          // 13. Footer nudge into chat
          const DashboardEntrance(delay: 440, child: ScanFooterCard()),
        ],
      ),
    );
  }
}
