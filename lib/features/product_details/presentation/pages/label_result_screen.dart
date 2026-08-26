import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/model_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/history/domain/repositories/history_repository.dart';
import 'package:gutgood/features/product_details/presentation/widgets/scan_result_widgets.dart';

class LabelResultScreen extends StatefulWidget {
  const LabelResultScreen({super.key, required this.scanData, this.heroTag});
  final ScanResult scanData;
  final String? heroTag;

  @override
  State<LabelResultScreen> createState() => _LabelResultScreenState();
}

class _LabelResultScreenState extends State<LabelResultScreen> {
  late ScanResult _currentData;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _currentData = widget.scanData;
    AppLogger.info('LabelResultScreen: Init with data: ${_currentData.productName}. Ingredients: ${_currentData.ingredients.length}');

    unawaited(sl<AnalyticsService>().logEvent(name: 'view_label_result', parameters: {'product_name': _currentData.productName}));

    if (_currentData.scanId != null) {
      // 🚀 Deep Hydration Check: Even if ingredients exist, check if we have detailed audit data
      // Labels from Chat might just have names, whereas DB has full Clinical Audit.
      final hasDetails = _currentData.ingredients.any((i) => i.impact.isNotEmpty || i.colorName != 'gray');

      if (!hasDetails) {
        AppLogger.info('LabelResultScreen: Data is partial/lite, triggering hydration for ID: ${_currentData.scanId}');
        _refreshData();
      }
    }
  }

  Future<void> _refreshData() async {
    if (_currentData.scanId == null) return;
    setState(() => _isRefreshing = true);

    try {
      final fullData = await sl<HistoryRepository>().getScanById(_currentData.scanId!);
      if (fullData != null && mounted) {
        AppLogger.info('LabelResultScreen: Hydration successful. Ingredients found: ${fullData.ingredients.length}');
        setState(() => _currentData = fullData);
      } else {
        AppLogger.warning('LabelResultScreen: Hydration returned null for ID: ${_currentData.scanId}');
      }
    } catch (e) {
      AppLogger.error('LabelResultScreen: Hydration failed', error: e);
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Widget _buildExpertSummary(BuildContext context) {
    final Map<String, dynamic> raw = _currentData.rawData ?? {};
    final Map<String, dynamic> contextBlock = raw.containsKey('rawData') && raw['rawData'] is Map ? Map<String, dynamic>.from(raw['rawData'] as Map) : raw;
    final Map<String, dynamic> scanBlock = contextBlock.containsKey('scan') && contextBlock['scan'] is Map ? Map<String, dynamic>.from(contextBlock['scan'] as Map) : {};
    final Map<String, dynamic> mealBlock = contextBlock.containsKey('meal') && contextBlock['meal'] is Map ? Map<String, dynamic>.from(contextBlock['meal'] as Map) : {};

    final String? summary = mealBlock['summary']?.toString() ?? scanBlock['summary']?.toString() ?? contextBlock['summary']?.toString();

    if (summary == null || summary.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SheetSectionHeader(title: 'EXPERT SUMMARY', color: Colors.transparent),
        Text(
          summary,
          style: context.body.copyWith(fontSize: 14.sp, height: 1.5, color: context.appColorScheme.textPrimary),
        ),
      ],
    );
  }

  Widget _buildImpactSection(BuildContext context) {
    final items = <ScanImpactDetailItem>[];
    final scan = _currentData;
    final scheme = context.appColorScheme;

    // 1. Nutrient Levels (High-level flags)
    if (scan.nutrientLevels != null) {
      final l = scan.nutrientLevels!;

      // Fiber/Protein - Positive flags
      if (scan.nutrients != null) {
        final n = scan.nutrients!;
        if (n.fiber != null && n.fiber! > 2) {
          items.add(ScanImpactDetailItem(title: 'High Fiber', subtitle: 'Supports gut motility', icon: AppIcons.salad, value: '${n.fiber}g', color: scheme.success));
        }
        if (n.proteins != null && n.proteins! > 5) {
          items.add(ScanImpactDetailItem(title: 'High Protein', subtitle: 'Essential for repair', icon: AppIcons.zap, value: '${n.proteins}g', color: scheme.success));
        }
      }

      // Sugar/Salt/Fat - Risk flags
      if (l.sugars.toLowerCase() == 'high') {
        items.add(ScanImpactDetailItem(title: 'High Sugar', subtitle: 'Potential inflammatory spike', icon: AppIcons.alertTriangle, value: 'CAUTION', color: scheme.error));
      }
      if (l.salt.toLowerCase() == 'high') {
        items.add(ScanImpactDetailItem(title: 'High Sodium', subtitle: 'Water retention risk', icon: AppIcons.alertTriangle, value: 'CAUTION', color: scheme.error));
      }
      if (l.saturatedFat.toLowerCase() == 'high') {
        items.add(ScanImpactDetailItem(title: 'High Sat Fat', subtitle: 'Check heart health goals', icon: AppIcons.alertTriangle, value: 'MODERATE', color: scheme.warning));
      }
    }

    // 2. Explicit Impacts from AI
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

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    // 🚀 Robust Extraction: Handle multiple nesting variations
    final Map<String, dynamic> raw = _currentData.rawData ?? {};
    final Map<String, dynamic> contextBlock = raw.containsKey('rawData') && raw['rawData'] is Map ? Map<String, dynamic>.from(raw['rawData'] as Map) : raw;
    final Map<String, dynamic> scanBlock = contextBlock.containsKey('scan') && contextBlock['scan'] is Map ? Map<String, dynamic>.from(contextBlock['scan'] as Map) : {};

    final ingredients = _currentData.ingredients.isNotEmpty ? _currentData.ingredients : ModelUtils.parseModelList<Ingredient>(scanBlock['ingredients'], Ingredient.fromMap);

    AppLogger.info('LabelResultScreen: Building UI. Product: ${_currentData.productName}, Ingredients: ${ingredients.length}');

    return Scaffold(
      backgroundColor: scheme.cardBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const GutSliverAppBar(title: AppStrings.ingredientsLabel, centerTitle: true),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.p24, vertical: AppSizes.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DashboardEntrance(delay: 50, child: _LabelHeader(scanData: _currentData)),
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
                                      const Icon(AppIcons.flaskConical, color: AppPalette.white, size: 16),
                                      Gap.w8,
                                      Text(
                                        'CLINICAL AUDIT',
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
                    DashboardEntrance(delay: 150, child: _buildExpertSummary(context)),
                    Gap.h32,
                    DashboardEntrance(delay: 175, child: _buildImpactSection(context)),
                    Gap.h32,
                    if (ingredients.isNotEmpty)
                      DashboardEntrance(
                        delay: 200,
                        child: _IngredientsAuditSection(ingredients: ingredients, scanData: _currentData),
                      ),
                    Gap.h32,
                    DashboardEntrance(delay: 250, child: AdditivesSection(scanData: _currentData)),
                    if (_currentData.allergens != null && _currentData.allergens!.isNotEmpty) ...[
                      Gap.h32,
                      DashboardEntrance(
                        delay: 280,
                        child: AllergensSection(allergens: _currentData.allergens!, servingSize: _currentData.servingSize),
                      ),
                    ],
                    DashboardEntrance(delay: 340, child: ProductMetadataSection(scanData: _currentData)),
                  ],
                  Gap.h20,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabelHeader extends StatelessWidget {
  const _LabelHeader({required this.scanData});
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
              decoration: BoxDecoration(color: AppPalette.blue, borderRadius: BorderRadius.circular(4)),
              child: Text(
                'INGREDIENT LABEL',
                style: context.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10.sp),
              ),
            ),
            Gap.w12,
            Text('SCIENTIFIC BREAKDOWN', style: context.eyebrow.copyWith(color: scheme.textMuted)),
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

class _IngredientsAuditSection extends StatelessWidget {
  const _IngredientsAuditSection({required this.ingredients, required this.scanData});
  final List<Ingredient> ingredients;
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SheetSectionHeader(title: 'INGREDIENT AUDIT', color: Colors.transparent),
      IngredientsSection(ingredients: ingredients, scanData: scanData),
    ],
  );
}
