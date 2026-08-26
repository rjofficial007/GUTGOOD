import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
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
            SliverPadding(
              padding: EdgeInsets.all(AppSizes.p20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _ProductImageHeroCard(scanData: _currentData, heroTag: widget.heroTag),
                  Gap.h24,
                  _ScoreHeroSection(scanData: _currentData),
                  Gap.h24,
                  _ImpactGrid(scanData: _currentData),
                  Gap.h24,
                  if (_currentData.impact.isNotEmpty) ...[
                    _NarrativeImpactCard(impact: _currentData.impact),
                    Gap.h24,
                  ],
                  if (_currentData.cycleInsight != null) ...[
                    _CycleInsightCard(insight: _currentData.cycleInsight!),
                    Gap.h24,
                  ],
                  if (_currentData.impacts.isNotEmpty) ...[
                    _BodyImpactsSection(impacts: _currentData.impacts),
                    Gap.h24,
                  ],
                  _NutrientSummaryCard(scanData: _currentData),
                  Gap.h24,
                  _SafetyAndAllergensCard(scanData: _currentData),
                  Gap.h24,
                  _IngredientBreakdownCard(scanData: _currentData),
                  if (_currentData.swaps.isNotEmpty) ...[
                    Gap.h24,
                    _BetterSwapsSection(swaps: _currentData.swaps),
                  ],
                  Gap.h24,
                  NutritionFactsSection(scanData: _currentData),
                  Gap.h24,
                  ProductMetadataSection(scanData: _currentData),
                  Gap.h40,
                ]),
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _buildSliverAppBar(BuildContext context, bool isSaved) {
    return GutSliverAppBar(
      title: 'PRODUCT ANALYSIS',
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
  }
}

class _ProductImageHeroCard extends StatelessWidget {
  const _ProductImageHeroCard({required this.scanData, this.heroTag});
  final ScanResult scanData;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final displayUrl = scanData.userImageUrl ?? scanData.imageUrl;

    if (displayUrl == null || displayUrl.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 200.h,
      decoration: BoxDecoration(
        color: scheme.elevatedSurface,
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(color: scheme.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32.r),
        child: Hero(
          tag: heroTag ?? 'product_${scanData.productName}',
          child: CachedNetworkImage(
            imageUrl: displayUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            placeholder: (context, url) => Center(child: CircularProgressIndicator(strokeWidth: 2, color: scheme.textPrimary)),
            errorWidget: (context, url, error) => Icon(AppIcons.image, size: 40, color: scheme.textMuted),
          ),
        ),
      ),
    );
  }
}

class _ScoreHeroSection extends StatelessWidget {
  const _ScoreHeroSection({required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final score = scanData.score;
    
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: scheme.elevatedSurface,
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(color: scheme.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scanData.productName.toUpperCase(),
                      style: context.bodyBold.copyWith(fontSize: 13.sp, color: scheme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      scanData.brand.toUpperCase(),
                      style: context.caption.copyWith(fontSize: 10.sp, color: scheme.textMuted),
                    ),
                  ],
                ),
              ),
              if (scanData.badge != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppPalette.lime,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    scanData.badge!.toUpperCase(),
                    style: context.bodyBold.copyWith(fontSize: 8.sp, color: Colors.black),
                  ),
                ),
            ],
          ),
          Gap.h32,
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180.w,
                height: 120.w,
                child: CustomPaint(
                  painter: _GaugePainter(value: score / 100, color: scheme.textPrimary),
                ),
              ),
              Positioned(
                bottom: 15.w,
                child: Column(
                  children: [
                    Text(
                      "$score",
                      style: context.bodyBold.copyWith(fontSize: 40.sp, fontWeight: FontWeight.w900, height: 1, color: scheme.textPrimary),
                    ),
                    Text(
                      "Gut Score",
                      style: context.caption.copyWith(color: scheme.textMuted, fontSize: 10.sp),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Gap.h20,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (scanData.nutriscore != null) _MiniMeta(label: "Nutri-Score", value: scanData.nutriscore!),
              if (scanData.nutriscore != null && scanData.novaGroup != null) Gap.w12,
              if (scanData.novaGroup != null) _MiniMeta(label: "NOVA", value: "Group ${scanData.novaGroup}"),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMeta extends StatelessWidget {
  const _MiniMeta({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: scheme.aiResponseBackground,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: scheme.border),
      ),
      child: Row(
        children: [
          Text("$label:", style: context.caption.copyWith(fontSize: 9.sp, color: scheme.textMuted)),
          Gap.w4,
          Text(value.toUpperCase(), style: context.bodyBold.copyWith(fontSize: 10.sp, color: scheme.textPrimary)),
        ],
      ),
    );
  }
}

class _ImpactGrid extends StatelessWidget {
  const _ImpactGrid({required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    String? fiberValue;
    String? proteinValue;
    
    if (scanData.nutrients != null) {
      fiberValue = scanData.nutrients!.fiber != null ? "${scanData.nutrients!.fiber}g" : null;
      proteinValue = scanData.nutrients!.proteins != null ? "${scanData.nutrients!.proteins}g" : null;
    }

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: "PEAK VALUE",
            value: proteinValue != null ? "⚡ $proteinValue" : "---",
            subtitle: "Proteins",
            icon: AppIcons.zap,
            color: const Color(0xFF5D78FF),
            isDark: true,
          ),
        ),
        Gap.w20,
        Expanded(
          child: _StatCard(
            label: "GUT FIBER",
            value: fiberValue != null ? "🥗 $fiberValue" : "---",
            subtitle: "Total Fiber",
            icon: AppIcons.leaf,
            color: AppPalette.lime,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.subtitle, required this.icon, required this.color, this.isDark = false});
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5);

    return Container(
      padding: EdgeInsets.all(20.w),
      height: 150.h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(32.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.2) : Colors.white, shape: BoxShape.circle),
                child: Icon(icon, size: 16.w, color: isDark ? Colors.white : Colors.black),
              ),
              Row(
                children: [
                  Container(width: 4.w, height: 4.w, decoration: BoxDecoration(color: textColor, shape: BoxShape.circle)),
                  Gap.w4,
                  Container(width: 4.w, height: 4.w, decoration: BoxDecoration(color: textColor, shape: BoxShape.circle)),
                ],
              ),
            ],
          ),
          const Spacer(),
          Text(label, style: context.bodyBold.copyWith(fontSize: 10.sp, color: secondaryColor)),
          Text(value.toUpperCase(), style: context.bodyBold.copyWith(fontSize: 14.sp, color: textColor, height: 1.1), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(subtitle, style: context.caption.copyWith(fontSize: 9.sp, color: secondaryColor), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _NarrativeImpactCard extends StatelessWidget {
  const _NarrativeImpactCard({required this.impact});
  final String impact;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: scheme.elevatedSurface,
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(color: scheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.microscope, size: 18.w, color: scheme.textPrimary),
              Gap.w12,
              Text("GUTGOOD INSIGHT", style: context.bodyBold.copyWith(fontSize: 12.sp, letterSpacing: 0.5, color: scheme.textPrimary)),
            ],
          ),
          Gap.h16,
          Text(
            impact,
            style: context.bodySm.copyWith(color: scheme.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _BodyImpactsSection extends StatelessWidget {
  const _BodyImpactsSection({required this.impacts});
  final List<ImpactDetail> impacts;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: scheme.elevatedSurface,
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(color: scheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.brain, size: 18.w, color: scheme.textPrimary),
              Gap.w12,
              Text("KEY BODY IMPACTS", style: context.bodyBold.copyWith(fontSize: 12.sp, color: scheme.textPrimary)),
            ],
          ),
          Gap.h24,
          ...impacts.map((i) => Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Row(
              children: [
                Icon(AppIcons.checkCircle, size: 14.w, color: i.level.toLowerCase() == 'high' ? scheme.success : scheme.textMuted),
                Gap.w12,
                Expanded(
                  child: Text(
                    i.title,
                    style: context.bodySm.copyWith(color: scheme.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(color: scheme.aiResponseBackground, borderRadius: BorderRadius.circular(8.r)),
                  child: Text(i.level.toUpperCase(), style: context.bodyBold.copyWith(fontSize: 9.sp, color: scheme.textPrimary)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _CycleInsightCard extends StatelessWidget {
  const _CycleInsightCard({required this.insight});
  final CycleInsight insight;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: scheme.elevatedSurface,
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(color: scheme.lavender.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(color: AppPalette.purple.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.auto_awesome, size: 16.w, color: AppPalette.purple),
              ),
              Gap.w12,
              Text("${insight.phase.toUpperCase()} PHASE ADVICE", style: context.bodyBold.copyWith(fontSize: 12.sp, color: scheme.textPrimary)),
            ],
          ),
          Gap.h16,
          Text(insight.description, style: context.bodySm.copyWith(color: scheme.textSecondary, height: 1.4)),
        ],
      ),
    );
  }
}

class _NutrientSummaryCard extends StatelessWidget {
  const _NutrientSummaryCard({required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: scheme.elevatedSurface,
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(color: scheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.activity, size: 18.w, color: scheme.textPrimary),
              Gap.w12,
              Text("NUTRITION PROFILE", style: context.bodyBold.copyWith(fontSize: 12.sp, color: scheme.textPrimary)),
            ],
          ),
          Gap.h24,
          if (scanData.nutrientLevels != null) ...[
             _NutrientRow(label: "Sugars", level: scanData.nutrientLevels!.sugars),
             Gap.h12,
             _NutrientRow(label: "Saturated Fat", level: scanData.nutrientLevels!.saturatedFat),
             Gap.h12,
             _NutrientRow(label: "Salt", level: scanData.nutrientLevels!.salt),
          ],
        ],
      ),
    );
  }
}

class _NutrientRow extends StatelessWidget {
  const _NutrientRow({required this.label, required this.level});
  final String label;
  final String level;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isLow = level.toLowerCase() == 'low';
    final isHigh = level.toLowerCase() == 'high';
    final color = isLow ? AppPalette.green : (isHigh ? AppPalette.red : AppPalette.orange);
    
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: scheme.aiResponseBackground,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: scheme.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Text(label, style: context.bodyBold.copyWith(fontSize: 12.sp, color: scheme.textPrimary)),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(100)),
            child: Text(level.toUpperCase(), style: context.bodyBold.copyWith(fontSize: 10.sp, color: color)),
          ),
        ],
      ),
    );
  }
}

class _SafetyAndAllergensCard extends StatelessWidget {
  const _SafetyAndAllergensCard({required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final hasAllergens = scanData.allergens != null && scanData.allergens!.isNotEmpty;
    final hasFlagged = scanData.flaggedIngredients.isNotEmpty;
    final hasAdditives = scanData.additives != null && scanData.additives!.isNotEmpty;

    if (!hasAllergens && !hasFlagged && !hasAdditives) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: scheme.elevatedSurface,
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(color: scheme.error.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.alertTriangle, size: 18.w, color: scheme.error),
              Gap.w12,
              Text("SAFETY ANALYSIS", style: context.bodyBold.copyWith(fontSize: 12.sp, color: scheme.textPrimary)),
            ],
          ),
          if (hasAllergens) ...[
            Gap.h20,
            _SafetyRow(label: "ALLERGENS", value: scanData.allergens!, color: scheme.error),
          ],
          if (hasAdditives) ...[
            Gap.h12,
            _SafetyRow(label: "ADDITIVES", value: scanData.additives!, color: scheme.warning),
          ],
          if (hasFlagged) ...[
            Gap.h20,
            Text("FLAGGED INGREDIENTS", style: context.caption.copyWith(fontWeight: FontWeight.bold, fontSize: 10.sp, color: scheme.textMuted)),
            Gap.h12,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: scanData.flaggedIngredients.map((f) => Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(color: scheme.error.withOpacity(0.1), borderRadius: BorderRadius.circular(100)),
                child: Text(f.toUpperCase(), style: context.bodyBold.copyWith(fontSize: 9.sp, color: scheme.error)),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SafetyRow extends StatelessWidget {
  const _SafetyRow({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.caption.copyWith(fontWeight: FontWeight.bold, fontSize: 10.sp, color: color)),
        Gap.h4,
        Text(value, style: context.bodySm.copyWith(color: scheme.textPrimary, height: 1.3)),
      ],
    );
  }
}

class _IngredientBreakdownCard extends StatelessWidget {
  const _IngredientBreakdownCard({required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    if (scanData.ingredients.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: scheme.elevatedSurface,
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(color: scheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.utensils, size: 18.w, color: scheme.textPrimary),
              Gap.w12,
              Text("INGREDIENTS", style: context.bodyBold.copyWith(fontSize: 12.sp, color: scheme.textPrimary)),
              const Spacer(),
              Text("${scanData.ingredients.length} Total", style: context.caption.copyWith(fontSize: 10.sp, color: scheme.textMuted)),
            ],
          ),
          Gap.h24,
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: scanData.ingredients.map((ing) => Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: scheme.aiResponseBackground,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: scheme.border),
              ),
              child: Text(ing.name.toUpperCase(), style: context.bodyBold.copyWith(fontSize: 9.sp, color: scheme.textPrimary)),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _BetterSwapsSection extends StatelessWidget {
  const _BetterSwapsSection({required this.swaps});
  final List<ProductSwap> swaps;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(32.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(color: AppPalette.lime.withOpacity(0.2), shape: BoxShape.circle),
                child: Icon(AppIcons.refreshCw, size: 16.w, color: AppPalette.lime),
              ),
              Gap.w12,
              Text("BETTER SWAPS", style: context.bodyBold.copyWith(color: Colors.white, fontSize: 13.sp, letterSpacing: 0.5)),
            ],
          ),
          Gap.h24,
          BetterSwapsCarousel(swaps: swaps),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.value, required this.color});
  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 10.w);
    final radius = size.width / 2;

    final bgPaint = Paint()..color = AppPalette.gray200..style = PaintingStyle.stroke..strokeWidth = 1.5;
    final progressPaint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.5;

    for (var i = 0; i <= 60; i++) {
      final angle = math.pi + (i / 60) * math.pi;
      final isMajor = i % 10 == 0;
      final tickLen = isMajor ? 10.0 : 5.0;
      canvas.drawLine(
        Offset(center.dx + (radius - tickLen) * math.cos(angle), center.dy + (radius - tickLen) * math.sin(angle)),
        Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle)),
        bgPaint,
      );
    }

    final activeTicks = (value * 60).toInt();
    for (var i = 0; i <= activeTicks; i++) {
      final angle = math.pi + (i / 60) * math.pi;
      final isMajor = i % 10 == 0;
      final tickLen = isMajor ? 14.0 : 8.0;
      canvas.drawLine(
        Offset(center.dx + (radius - tickLen) * math.cos(angle), center.dy + (radius - tickLen) * math.sin(angle)),
        Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle)),
        progressPaint,
      );
    }

    final needlePaint = Paint()..color = color.withOpacity(0.2)..style = PaintingStyle.stroke..strokeWidth = 1.0;
    final indicatorAngle = math.pi + value * math.pi;
    final dotPos = Offset(center.dx + radius * math.cos(indicatorAngle), center.dy + radius * math.sin(indicatorAngle));
    canvas.drawLine(center, dotPos, needlePaint);
    canvas.drawCircle(dotPos, 4, Paint()..color = color);
    canvas.drawCircle(dotPos, 2, Paint()..color = Colors.white);
    canvas.drawCircle(center, 4, Paint()..color = AppPalette.gray100);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
