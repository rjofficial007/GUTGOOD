import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/history/domain/repositories/history_repository.dart';
import 'package:gutgood/features/history/presentation/providers/saved_foods_provider.dart';
import 'package:gutgood/features/product_details/presentation/widgets/scan_result_widgets.dart';
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
  bool _isLoading = false, _isRefreshing = false;

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
    setState(() => _isRefreshing = true);
    try {
      final fullData = await sl<HistoryRepository>().getScanById(_currentData.scanId!);
      if (fullData != null && mounted) setState(() => _currentData = fullData);
    } catch (e) {
      AppLogger.error('ScanResultScreen: Hydration failed', error: e);
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
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
    return Consumer<SavedFoodsProvider>(
      builder: (context, savedProvider, _) {
        final isSaved = savedProvider.isSaved(_currentData.productName, barcode: _currentData.barcode);
        return Scaffold(
          backgroundColor: scheme.cardBackground,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              GutSliverAppBar(
                title: 'SCAN RESULT',
                centerTitle: true,
                actions: [
                  Padding(
                    padding: EdgeInsets.only(right: 16.w),
                    child: SaveButton(
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
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p16),
                  child: Column(
                    children: [
                      DashboardEntrance(
                        delay: 50,
                        child: BentoImageCard(scanData: _currentData, heroTag: widget.heroTag),
                      ),
                      Gap.h12,
                      DashboardEntrance(delay: 100, child: DashboardMetricGrid(scanData: _currentData)),
                      Gap.h12,
                      DashboardEntrance(delay: 150, child: ExpertSummaryCard(scanData: _currentData)),
                      Gap.h12,
                      DashboardEntrance(delay: 200, child: ExpertStrategyCard(scanData: _currentData)),
                      if (_currentData.swaps.isNotEmpty) ...[Gap.h12, DashboardEntrance(delay: 250, child: BetterSwapsCarousel(swaps: _currentData.swaps))],
                      if (_currentData.cycleInsight != null) ...[Gap.h12, DashboardEntrance(delay: 300, child: CycleInsightSection(insight: _currentData.cycleInsight!))],
                      Gap.h12,
                      DashboardEntrance(
                        delay: 320,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildImpactSection(context)),
                            Gap.w12,
                            Expanded(child: NutrientStatisticsCard(scanData: _currentData)),
                          ],
                        ),
                      ),
                      Gap.h12,
                      DashboardEntrance(
                        delay: 340,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: IngredientsSection(ingredients: _currentData.ingredients, scanData: _currentData),
                            ),
                            Gap.w12,
                            Expanded(child: NutritionFactsSection(scanData: _currentData)),
                          ],
                        ),
                      ),
                      Gap.h12,
                      DashboardEntrance(
                        delay: 360,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: AdditivesSection(scanData: _currentData)),
                            Gap.w12,
                            Expanded(child: ProductMetadataSection(scanData: _currentData)),
                          ],
                        ),
                      ),
                      Gap.h40,
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

  Widget _buildImpactSection(BuildContext context) {
    final scan = _currentData;
    final scheme = context.appColorScheme;
    final items = <TimelineItem>[];

    final raw = scan.rawData ?? {};
    final rawImpacts = ((raw['meal']?['impacts'] ?? raw['scan']?['impacts'] ?? raw['impacts']) ?? []) as List;

    // Explicit Impacts from AI
    final impactsToUse = scan.impacts.isNotEmpty
        ? scan.impacts
        : rawImpacts
              .map((e) {
                final data = e is Map ? e : {};
                return ImpactDetail(title: data['title']?.toString() ?? '', level: data['level']?.toString() ?? '', color: 'gray');
              })
              .where((e) => e.title.isNotEmpty)
              .toList();

    for (final impact in impactsToUse) {
      var color = scheme.success;
      final level = impact.level.toLowerCase();
      if (level == 'high' || level == 'trigger' || level == 'negative' || level == 'poor') {
        color = scheme.error;
      } else if (level == 'moderate' || level == 'neutral' || level == 'low') {
        color = scheme.warning;
      }
      items.add(TimelineItem(title: impact.title, subtitle: impact.level.toUpperCase(), color: color));
    }

    return ScanImpactSection(title: 'GUT HEALTH IMPACT', icon: AppIcons.activity, iconColor: scheme.textPrimary, servingInfo: scan.servingSize, items: items);
  }
}
