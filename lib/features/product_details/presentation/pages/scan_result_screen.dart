import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/history/domain/repositories/history_repository.dart';
import 'package:gutgood/features/history/presentation/providers/saved_foods_provider.dart';
import 'package:gutgood/features/product_details/presentation/widgets/scan_result_widgets.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:provider/provider.dart';

class ScanResultScreen extends StatefulWidget {
  const ScanResultScreen({super.key, required this.scanData, this.heroTag});
  final ScanResult scanData;
  final String? heroTag;

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  late ScanResult _currentData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentData = widget.scanData;
    unawaited(sl<AnalyticsService>().logEvent(name: 'view_scan_result', parameters: {'product_name': _currentData.productName, 'score': _currentData.score}));

    if (_currentData.scanId != null) {
      final hasDetails = _currentData.impacts.isNotEmpty || _currentData.nutrients != null || _currentData.swaps.isNotEmpty;
      if (!hasDetails) _refreshData();
    }
  }

  Future<void> _refreshData() async {
    if (_currentData.scanId == null) return;
    try {
      final fullData = await sl<HistoryRepository>().getScanById(_currentData.scanId!);
      if (fullData != null && mounted) setState(() => _currentData = fullData);
    } catch (e) {
      AppLogger.error('ScanResultScreen: Hydration failed', error: e);
    }
  }

  Future<void> _toggleSave() async {
    final provider = context.read<SavedFoodsProvider>();
    await provider.toggleSave(_currentData);
    sl<AppStateService>().notifyProfileUpdated();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileNotifier = context.watch<ProfileNotifier>();
    final cycleSyncEnabled = profileNotifier.profile?.cycleSyncEnabled ?? false;

    return Consumer<SavedFoodsProvider>(
      builder: (context, savedProvider, _) {
        final isSaved = savedProvider.isSaved(_currentData.productName, barcode: _currentData.barcode);
        return Scaffold(
          backgroundColor: isDark ? scheme.cardBackground : const Color(0xFFFCFCFD),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              GutSliverAppBar(
                title: 'Scan result',
                centerTitle: true,
                actions: [
                  SaveButton(
                    isSaved: isSaved,
                    isLoading: _isLoading,
                    onTap: () async {
                      setState(() => _isLoading = true);
                      try {
                        await _toggleSave();
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p16),
                  child: Column(
                    children: [
                      // 1. Food identity header (photo + brand + name + summary)
                      DashboardEntrance(delay: 50, child: ScanScoreHeader(scanData: _currentData)),
                      Gap.h12,

                      // 2. Score gauge + band + "here's why" + expandable breakdown
                      DashboardEntrance(delay: 100, child: ScanScoreSection(scanData: _currentData)),
                      Gap.h12,

                      // 3. Quick-signal metric cards (Gut Impact, NOVA, Gut Barrier, Processing)
                      DashboardEntrance(delay: 150, child: ScanMetricsRow(scanData: _currentData)),
                      Gap.h16,

                      // 4. What works for you (Positives)
                      DashboardEntrance(delay: 200, child: ScanWorkingSection(scanData: _currentData)),
                      Gap.h12,

                      // 5. What to watch (Negatives + tappable additives/allergens)
                      DashboardEntrance(delay: 250, child: ScanWatchSection(scanData: _currentData)),
                      Gap.h12,

                      // 6. What this means for you (hidden when the AI gave no narrative)
                      if (_currentData.impact.isNotEmpty) ...[DashboardEntrance(delay: 300, child: ScanTopInsightsCard(scanData: _currentData)), Gap.h12],

                      // 7. Cycle Insight (Hormonal Phase Advice if Enabled)
                      if (_currentData.cycleInsight != null && cycleSyncEnabled) ...[DashboardEntrance(delay: 320, child: CycleInsightSection(insight: _currentData.cycleInsight!)), Gap.h12],

                      // 8. Better Swaps (tappable cards + working "+ Add")
                      if (_currentData.swaps.isNotEmpty) ...[DashboardEntrance(delay: 340, child: ScanSwapsSection(swaps: _currentData.swaps)), Gap.h12],

                      // 9. Additives (tappable rows → additive detail)
                      DashboardEntrance(delay: 360, child: ScanAdditivesSection(scanData: _currentData)),
                      Gap.h12,

                      // 10. Ingredients section (modern cards → ingredient list)
                      DashboardEntrance(delay: 380, child: ScanIngredientsSection(scanData: _currentData)),
                      Gap.h12,

                      // 11. Allergens section (modern cards → allergen list)
                      DashboardEntrance(delay: 400, child: ScanAllergensSection(scanData: _currentData)),
                      Gap.h12,

                      // 12. Scan details (provenance footer)
                      DashboardEntrance(delay: 420, child: ScanDetailsCard(scanData: _currentData)),
                      Gap.h12,

                      // 13. Footer nudge into chat
                      const DashboardEntrance(delay: 440, child: ScanFooterCard()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
