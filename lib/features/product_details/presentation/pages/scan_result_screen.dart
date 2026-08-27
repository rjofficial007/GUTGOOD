import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
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
  bool _isLoading = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _currentData = widget.scanData;
    unawaited(sl<AnalyticsService>().logEvent(name: 'view_scan_result', parameters: {'product_name': _currentData.productName, 'score': _currentData.score}));

    // 🚀 Professional Data Hydration: If we only have a "preview" (likely from chat persistence),
    // fetch the full document from Firestore to show complete details (nutrients, score, swaps).
    if (_currentData.scanId != null && (_currentData.nutrients == null || _currentData.swaps.isEmpty)) {
      _refreshData();
    }
  }

  Future<void> _refreshData() async {
    if (_currentData.scanId == null) return;
    setState(() => _isRefreshing = true);

    try {
      final fullData = await sl<HistoryRepository>().getScanById(_currentData.scanId!);
      if (fullData != null && mounted) {
        setState(() => _currentData = fullData);
      }
    } catch (e) {
      AppLogger.error('ScanResultScreen: Hydration failed', error: e);
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _toggleSave() async {
    final provider = context.read<SavedFoodsProvider>();
    await provider.toggleSave(_currentData);
    await sl<AnalyticsService>().logEvent(
      name: provider.isSaved(_currentData.productName, barcode: _currentData.barcode) ? 'food_saved' : 'food_unsaved',
      parameters: {'product_name': _currentData.productName},
    );
    sl<AppStateService>().notifyProfileUpdated();
  }

  @override
  Widget build(BuildContext context) => Consumer<SavedFoodsProvider>(
    builder: (context, savedProvider, _) {
      final isSaved = savedProvider.isSaved(_currentData.productName, barcode: _currentData.barcode);
      final scheme = context.appColorScheme;

      return Scaffold(
        backgroundColor: scheme.cardBackground,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(context, isSaved),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSizes.p24, vertical: AppSizes.p16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DashboardEntrance(delay: 50, child: _ProductHeader(scanData: _currentData)),
                    Gap.h32,
                    DashboardEntrance(
                      delay: 100,
                      child: ProductImageHeader(
                        scanData: _currentData,
                        heroTag: widget.heroTag,
                        overlay: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (_currentData.impact.isNotEmpty)
                              GlassCard(
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ScanHeroSection(scanData: _currentData, isGlass: true),
                                    Gap.h10,
                                    const Divider(color: Colors.white10),
                                    Gap.h10,
                                    Row(
                                      children: [
                                        const Icon(AppIcons.salad, color: AppPalette.white, size: 16),
                                        Gap.w8,
                                        Text(
                                          'GUTGOOD INSIGHT',
                                          style: context.eyebrow.copyWith(color: AppPalette.white, fontSize: 10.sp),
                                        ),
                                      ],
                                    ),
                                    Gap.h10,
                                    Text(
                                      _currentData.impact,
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.bodySm.copyWith(color: AppPalette.white, fontWeight: FontWeight.w500, height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    if (_isRefreshing)
                      Padding(
                        padding: const EdgeInsets.only(top: 32),
                        child: Center(child: CircularProgressIndicator(color: scheme.textPrimary)),
                      )
                    else ...[
                      Gap.h32,
                      DashboardEntrance(delay: 250, child: _buildWorksForYou(context)),
                      // 🚀 NEW: Detected Items Section for Meal Analyses
                      if (_currentData.rawData?['meal']?['items'] != null)
                        DashboardEntrance(delay: 275, child: _DetectedItemsSection(items: List<Map<String, dynamic>>.from(_currentData.rawData!['meal']['items']))),
                      Gap.h32,
                      DashboardEntrance(delay: 400, child: AdditivesSection(scanData: _currentData)),
                      if (_currentData.cycleInsight != null) ...[Gap.h32, DashboardEntrance(delay: 450, child: CycleInsightSection(insight: _currentData.cycleInsight!))],
                      if (_currentData.swaps.isNotEmpty) ...[Gap.h32, DashboardEntrance(delay: 500, child: BetterSwapsCarousel(swaps: _currentData.swaps))],
                      Gap.h32,
                      DashboardEntrance(delay: 550, child: NutritionFactsSection(scanData: _currentData)),
                      Gap.h32,
                      DashboardEntrance(delay: 600, child: ProductMetadataSection(scanData: _currentData)),
                    ],
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

  Widget _buildSliverAppBar(BuildContext context, bool isSaved) => GutSliverAppBar(
    title: 'SCAN RESULT',
    centerTitle: true,
    actions: [
      Padding(
        padding: EdgeInsets.only(right: AppSizes.p16),
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
  );

  Widget _buildWorksForYou(BuildContext context) {
    final items = <ScanImpactDetailItem>[];
    final scan = _currentData;
    final scheme = context.appColorScheme;

    if (scan.productName.toLowerCase().contains('organic')) {
      items.add(ScanImpactDetailItem(title: 'Organic', subtitle: 'No synthetic herbicides or pesticides', icon: AppIcons.leaf, value: 'CLEAN', color: scheme.success, showCheck: true));
    }

    if (scan.nutrients != null) {
      final n = scan.nutrients!;
      if (n.fiber != null && n.fiber! > 2) {
        items.add(ScanImpactDetailItem(title: AppStrings.fiber, subtitle: 'Great for gut motility', icon: AppIcons.salad, value: '${n.fiber}g', color: scheme.success));
      }
      if (n.proteins != null && n.proteins! > 5) {
        items.add(ScanImpactDetailItem(title: AppStrings.protein, subtitle: 'Essential amino acids', icon: AppIcons.zap, value: '${n.proteins}g', color: scheme.success));
      }
    }

    if (scan.nutrientLevels != null) {
      final l = scan.nutrientLevels!;
      if (l.sugars.toLowerCase() == 'low') {
        items.add(ScanImpactDetailItem(title: AppStrings.sugars, subtitle: 'No sugar added', icon: AppIcons.package, value: 'LOW', color: scheme.success));
      }
      if (l.saturatedFat.toLowerCase() == 'low') {
        items.add(ScanImpactDetailItem(title: AppStrings.saturatedFat, subtitle: 'No saturated fat', icon: AppIcons.droplet, value: 'LOW', color: scheme.success));
      }
      if (l.salt.toLowerCase() == 'low') {
        items.add(ScanImpactDetailItem(title: AppStrings.salt, subtitle: 'Low sodium content', icon: AppIcons.wheat, value: 'LOW', color: scheme.success));
      }
    }

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

    for (final ing in scan.ingredients.where((i) => i.colorName.toLowerCase() == 'green').take(2)) {
      items.add(ScanImpactDetailItem(title: ing.name, subtitle: ing.impact.isNotEmpty ? ing.impact : 'Clean ingredient', icon: AppIcons.leaf, value: 'CLEAN', color: scheme.success));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return ScanImpactSection(title: 'What works for you', icon: AppIcons.checkCircle, iconColor: scheme.success, servingInfo: scan.servingSize, items: items);
  }
}

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: scheme.textPrimary, borderRadius: BorderRadius.circular(4)),
              child: Text(
                scanData.brand.toUpperCase(),
                style: context.caption.copyWith(color: scheme.cardBackground, fontWeight: FontWeight.w900, fontSize: 10.sp),
              ),
            ),
            Gap.w12,
            Text('SCANNED PRODUCT', style: context.eyebrow.copyWith(color: scheme.textMuted)),
          ],
        ),
        Gap.h16,
        Text(
          scanData.productName.toUpperCase(),
          style: context.displaySm.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1.5, height: 1.0, color: scheme.textPrimary),
        ),
      ],
    );
  }
}

class _DetectedItemsSection extends StatelessWidget {
  const _DetectedItemsSection({required this.items});
  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Gap.h16,
        const SheetSectionHeader(title: 'WHAT I DETECTED', color: Colors.transparent),
        Gap.h16,
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
            final name = item['name']?.toString() ?? 'Unknown';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.elevatedSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.border.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.utensils, size: 14, color: scheme.textSecondary),
                  Gap.w10,
                  Text(
                    name.toUpperCase(),
                    style: context.bodyBold.copyWith(fontSize: 12.sp, color: scheme.textPrimary, letterSpacing: 0.5),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
