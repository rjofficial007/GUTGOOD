import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/history/domain/repositories/history_repository.dart';
import 'package:gutgood/features/history/presentation/providers/saved_foods_provider.dart';
import '../widgets/scan_result_widgets.dart';
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
  static const Color bentoBlack = Color(0xFF181818), bentoMint = Color(0xFFB4F1B4), bentoPurple = Color(0xFFC4B5FD), bentoWhite = Colors.white;

  @override
  void initState() {
    super.initState();
    _currentData = widget.scanData;
    unawaited(sl<AnalyticsService>().logEvent(name: 'view_scan_result', parameters: {'product_name': _currentData.productName, 'score': _currentData.score}));
    if (_currentData.scanId != null && (_currentData.nutrients == null || _currentData.swaps.isEmpty)) _refreshData();
  }

  Future<void> _refreshData() async {
    if (_currentData.scanId == null) return;
    setState(() => _isRefreshing = true);
    try {
      final fullData = await sl<HistoryRepository>().getScanById(_currentData.scanId!);
      if (fullData != null && mounted) setState(() => _currentData = fullData);
    } catch (e) { AppLogger.error('ScanResultScreen: Hydration failed', error: e); }
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
                    DashboardEntrance(delay: 50, child: BentoImageCard(scanData: _currentData, heroTag: widget.heroTag)),
                    Gap.h12,
                    DashboardEntrance(delay: 200, child: _buildMetricGrid(context)),
                    Gap.h12,
                    DashboardEntrance(
                      delay: 100,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildNutrientStatistics(context)),
                          Gap.w12,
                          Expanded(child: _buildRecentAnalysisCard(context)),
                        ],
                      ),
                    ),
                    Gap.h12,
                    DashboardEntrance(
                      delay: 150,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildScoreGaugeCard(context)),
                          Gap.w12,
                          Expanded(child: _buildExpertStrategyCard(context)),
                        ],
                      ),
                    ),

                    if (_currentData.swaps.isNotEmpty) ...[
                      Gap.h24,
                      DashboardEntrance(delay: 250, child: BetterSwapsCarousel(swaps: _currentData.swaps)),
                    ],
                    if (_currentData.cycleInsight != null) ...[
                      Gap.h24,
                      DashboardEntrance(delay: 300, child: CycleInsightSection(insight: _currentData.cycleInsight!)),
                    ],
                    Gap.h24,
                    DashboardEntrance(delay: 350, child: NutritionFactsSection(scanData: _currentData)),
                    Gap.h24,
                    DashboardEntrance(delay: 400, child: ProductMetadataSection(scanData: _currentData)),
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

  Widget _buildNutrientStatistics(BuildContext context) {
    final protein = (_currentData.nutrients?.proteins ?? 0.0).toDouble(), fiber = (_currentData.nutrients?.fiber ?? 0.0).toDouble();
    return BentoCard(backgroundColor: bentoBlack, height: 200.h, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Nutrients', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10.sp, fontWeight: FontWeight.bold)), const Icon(Icons.keyboard_arrow_down, color: Colors.white60, size: 16)]), const Spacer(), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${(protein + fiber).toStringAsFixed(1)}g', style: context.displaySm.copyWith(color: Colors.white, fontSize: 32.sp, fontWeight: FontWeight.w900)), Row(children: [const Icon(Icons.arrow_upward, color: bentoMint, size: 12), Gap.w4, Text('Clean fuel', style: TextStyle(color: bentoMint, fontSize: 8.sp, fontWeight: FontWeight.bold))])])])]));
  }

  Widget _buildRecentAnalysisCard(BuildContext context) {
    final Map<String, dynamic> balance = (_currentData.rawData ?? {})['meal']?['balance'] ?? {};
    return BentoCard(backgroundColor: bentoWhite, height: 200.h, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Icon(AppIcons.utensils, size: 16, color: bentoBlack), Row(children: [CircleAvatar(radius: 8, backgroundColor: bentoMint.withOpacity(0.5)), Gap.w4, CircleAvatar(radius: 8, backgroundColor: bentoPurple.withOpacity(0.5))])]), Gap.h16, Text('Meal Balance', style: context.bodyBold.copyWith(fontSize: 12.sp, height: 1.1)), Gap.h12, Expanded(child: NutrientBalanceWrap(balance: balance))]));
  }

  Widget _buildScoreGaugeCard(BuildContext context) {
    final score = _currentData.score;
    final color = score >= 70 ? bentoMint : (score >= 40 ? AppPalette.orange : AppPalette.red);
    final String label = score >= 70 ? 'OPTIMAL' : (score >= 40 ? 'MODERATE' : 'CRITICAL');
    final String subtitle = score >= 70 ? 'High Gut-Fiber Balance' : (score >= 40 ? 'Moderate Glycemic Load' : 'High Inflammatory Risk');

    return BentoCard(
      backgroundColor: color,
      height: 240.h,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: context.caption.copyWith(color: bentoBlack, fontWeight: FontWeight.w900, fontSize: 8.sp, letterSpacing: 0.5),
              ),
              const Icon(AppIcons.salad, color: bentoBlack, size: 14),
            ],
          ),
          const Spacer(flex: 2),
          ScoreGauge(score: score, color: bentoBlack),
          const Spacer(flex: 3),
          Text(
            subtitle,
            textAlign: .center,
            style: context.caption.copyWith(color: bentoBlack.withOpacity(0.6), fontWeight: FontWeight.w800, fontSize: 8.5.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildExpertStrategyCard(BuildContext context) {
    final Map<String, dynamic> meal = (_currentData.rawData ?? {})['meal'] ?? {};
    final List workingWell = meal['workingWell'] ?? [], missing = meal['missingOrCouldAdd'] ?? [], sensitivities = meal['sensitivityNotes'] ?? [];
    final List<TimelineItem> items = [];
    if (workingWell.isNotEmpty) items.add(TimelineItem(title: 'Safe', subtitle: workingWell.first, color: bentoMint));
    if (missing.isNotEmpty) items.add(TimelineItem(title: 'Add', subtitle: missing.first, color: bentoPurple));
    if (sensitivities.isNotEmpty) items.add(TimelineItem(title: 'Avoid', subtitle: sensitivities.first, color: AppPalette.red));
    if (items.isEmpty) items.add(TimelineItem(title: 'Insight', subtitle: 'Gut healthy choice', color: bentoMint));
    return BentoCard(backgroundColor: bentoWhite, height: 240.h, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Expert Strategy', style: context.bodyBold.copyWith(fontSize: 12.sp)), const Icon(Icons.arrow_outward, color: bentoBlack, size: 14)]), Gap.h24, Expanded(child: ImpactTimeline(items: items))]));
  }

  Widget _buildMetricGrid(BuildContext context) => Row(children: [Expanded(child: _buildSmallMetric('Calories', '${_currentData.nutrients?.calories ?? 0}', 'KCAL', bentoWhite)), Gap.w12, Expanded(child: _buildSmallMetric('Additives', '${_currentData.additives?.split(',').where((e) => e.trim().isNotEmpty).length ?? 0}', 'DETECTED', bentoWhite)), Gap.w12, Expanded(child: _buildSmallMetric('NOVA', '${_currentData.novaGroup ?? 1}', 'GROUP', bentoMint)), Gap.w12, Expanded(child: _buildSmallMetric('Nutri', _currentData.nutriscore ?? 'A', 'SCORE', bentoPurple))]);

  Widget _buildSmallMetric(String label, String value, String unit, Color bgColor) => BentoCard(backgroundColor: bgColor, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16), borderRadius: 24, child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [Text(label.toUpperCase(), style: TextStyle(fontSize: 8.sp, fontWeight: FontWeight.w900, color: bentoBlack.withOpacity(0.5), letterSpacing: 0.5)), Gap.h8, Text(value, style: context.headingSm.copyWith(fontWeight: FontWeight.w900, fontSize: 18.sp)), Gap.h2, Text(unit, style: TextStyle(fontSize: 6.sp, fontWeight: FontWeight.w800, color: bentoBlack.withOpacity(0.4)))]));
}
