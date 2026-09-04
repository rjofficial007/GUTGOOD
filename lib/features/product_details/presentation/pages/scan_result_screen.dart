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
    final profileNotifier = context.watch<ProfileNotifier>();
    final cycleSyncEnabled = profileNotifier.profile?.cycleSyncEnabled ?? false;

    return Consumer<SavedFoodsProvider>(
      builder: (context, savedProvider, _) {
        final isSaved = savedProvider.isSaved(_currentData.productName, barcode: _currentData.barcode);
        return Scaffold(
          backgroundColor: scheme.cardBackground,
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
                      // 1. Bento Image Card Hero Header
                      DashboardEntrance(
                        delay: 50,
                        child: BentoImageCard(scanData: _currentData, heroTag: widget.heroTag),
                      ),
                      Gap.h12,

                      // 2. 4 Core Key Indicators Bar (Gut Impact, NOVA, Gut Barrier, Processing)
                      DashboardEntrance(delay: 100, child: CoreMetricsGrid(scanData: _currentData)),
                      Gap.h12,

                      // 3. What works for you (Positives)
                      DashboardEntrance(delay: 150, child: WhatWorksForYouSection(scanData: _currentData)),
                      Gap.h12,

                      // 4. What to watch (Negatives & Additives Risk)
                      DashboardEntrance(delay: 200, child: WhatToWatchSection(scanData: _currentData)),
                      Gap.h12,

                      // 5. What this means for you (Synthesis Card with Persona Avatar)
                      DashboardEntrance(delay: 250, child: WhatThisMeansForYouCard(scanData: _currentData)),
                      Gap.h12,

                      // 6. Cycle Insight (Hormonal Phase Advice if Enabled)
                      if (_currentData.cycleInsight != null && cycleSyncEnabled) ...[DashboardEntrance(delay: 280, child: CycleInsightSection(insight: _currentData.cycleInsight!)), Gap.h12],

                      // 7. Better Swaps Carousel
                      if (_currentData.swaps.isNotEmpty) ...[DashboardEntrance(delay: 320, child: BetterSwapsCarousel(swaps: _currentData.swaps)), Gap.h12],

                      // 8. Product Metadata Footer
                      DashboardEntrance(delay: 360, child: ProductMetadataSection(scanData: _currentData)),
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
