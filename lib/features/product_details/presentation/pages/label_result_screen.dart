import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/history/domain/repositories/history_repository.dart';
import 'package:gutgood/features/history/presentation/providers/saved_foods_provider.dart';
import 'package:provider/provider.dart';
import '../widgets/scan_result_widgets.dart';

class LabelResultScreen extends StatefulWidget {
  const LabelResultScreen({super.key, required this.scanData, this.heroTag});
  final ScanResult scanData;
  final String? heroTag;

  @override
  State<LabelResultScreen> createState() => _LabelResultScreenState();
}

class _LabelResultScreenState extends State<LabelResultScreen> {
  late ScanResult _currentData;
  bool _isLoading = false, _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _currentData = widget.scanData;
    AppLogger.info('LabelResultScreen: Init with data: ${_currentData.productName}');

    unawaited(sl<AnalyticsService>().logEvent(name: 'view_label_result', parameters: {'product_name': _currentData.productName}));

    if (_currentData.scanId != null) {
      final hasDetails = _currentData.ingredients.any((i) => i.impact.isNotEmpty || i.colorName != 'gray');
      if (!hasDetails) _refreshData();
    }
  }

  Future<void> _refreshData() async {
    if (_currentData.scanId == null) return;
    setState(() => _isRefreshing = true);
    try {
      final fullData = await sl<HistoryRepository>().getScanById(_currentData.scanId!);
      if (fullData != null && mounted) setState(() => _currentData = fullData);
    } catch (e) { AppLogger.error('LabelResultScreen: Hydration failed', error: e); }
    finally { if (mounted) setState(() => _isRefreshing = false); }
  }

  Future<void> _toggleSave() async {
    final provider = context.read<SavedFoodsProvider>();
    await provider.toggleSave(_currentData);
    sl<AppStateService>().notifyProfileUpdated();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    return Consumer<SavedFoodsProvider>(builder: (context, savedProvider, _) {
      final isSaved = savedProvider.isSaved(_currentData.productName, barcode: _currentData.barcode);

      return Scaffold(
        backgroundColor: scheme.cardBackground,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            GutSliverAppBar(
              title: 'LABEL ANALYSIS',
              centerTitle: true,
              actions: [
                Padding(
                  padding: EdgeInsets.only(right: 16.w),
                  child: SaveButton(
                    isSaved: isSaved,
                    isLoading: _isLoading,
                    onTap: () async {
                      setState(() => _isLoading = true);
                      try { await _toggleSave(); } finally { if (mounted) setState(() => _isLoading = false); }
                    },
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DashboardEntrance(delay: 50, child: BentoImageCard(scanData: _currentData, heroTag: widget.heroTag)),
                    if (_isRefreshing)
                      Padding(padding: const EdgeInsets.only(top: 32), child: Center(child: CircularProgressIndicator(color: scheme.textPrimary)))
                    else ...[
                      Gap.h12,
                      DashboardEntrance(delay: 100, child: DashboardMetricGrid(scanData: _currentData)),
                      Gap.h12,
                      DashboardEntrance(
                        delay: 150,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: ExpertSummaryCard(scanData: _currentData)),
                            Gap.w12,
                            Expanded(child: NutrientStatisticsCard(scanData: _currentData)),
                          ],
                        ),
                      ),
                      Gap.h12,
                      DashboardEntrance(
                        delay: 200,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: MealBalanceCard(scanData: _currentData)),
                            Gap.w12,
                            Expanded(child: ExpertStrategyCard(scanData: _currentData)),
                          ],
                        ),
                      ),
                      Gap.h24,
                      DashboardEntrance(delay: 250, child: _buildImpactSection(context)),
                      Gap.h24,
                      if (_currentData.ingredients.isNotEmpty)
                        DashboardEntrance(delay: 300, child: IngredientsSection(ingredients: _currentData.ingredients, scanData: _currentData)),
                      Gap.h24,
                      DashboardEntrance(delay: 350, child: AdditivesSection(scanData: _currentData)),
                      if (_currentData.allergens != null && _currentData.allergens!.isNotEmpty) ...[
                        Gap.h24,
                        DashboardEntrance(delay: 380, child: AllergensSection(allergens: _currentData.allergens!, servingSize: _currentData.servingSize)),
                      ],
                      Gap.h24,
                      DashboardEntrance(delay: 420, child: ProductMetadataSection(scanData: _currentData)),
                    ],
                    Gap.h40,
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildImpactSection(BuildContext context) {
    final items = <ScanImpactDetailItem>[];
    final scan = _currentData;
    final scheme = context.appColorScheme;

    for (final impact in scan.impacts) {
      var color = scheme.success;
      var icon = AppIcons.checkCircle;
      final level = impact.level.toLowerCase();
      if (level == 'high' || level == 'trigger' || level == 'negative') {
        color = scheme.error;
        icon = AppIcons.alertTriangle;
      } else if (level == 'moderate' || level == 'neutral') {
        color = scheme.warning;
        icon = AppIcons.alertCircle;
      }
      items.add(ScanImpactDetailItem(title: impact.title, subtitle: '', icon: icon, value: impact.level.toUpperCase(), color: color));
    }

    if (items.isEmpty) return const SizedBox.shrink();
    return ScanImpactSection(title: 'GUT HEALTH IMPACT', icon: AppIcons.activity, iconColor: scheme.textPrimary, servingInfo: scan.servingSize, items: items);
  }
}
