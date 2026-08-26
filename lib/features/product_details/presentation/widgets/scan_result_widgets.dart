import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/extensions.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class SaveButton extends StatelessWidget {
  const SaveButton({super.key, required this.isSaved, required this.isLoading, required this.onTap});
  final bool isSaved;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: isLoading ? null : onTap,
    child: Container(
      width: 40.0.w,
      height: 40.0.w,
      decoration: BoxDecoration(
        color: context.appColorScheme.elevatedSurface,
        shape: BoxShape.circle,
        border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.5)),
      ),
      child: isLoading
          ? Center(
              child: SizedBox(
                width: AppSizes.icon20,
                height: AppSizes.icon20,
                child: CircularProgressIndicator(strokeWidth: 2, color: context.appColorScheme.textPrimary),
              ),
            )
          : Icon(isSaved ? Icons.favorite : Icons.favorite_border, color: isSaved ? context.appColorScheme.error : context.appColorScheme.textPrimary, size: AppSizes.icon20),
    ),
  );
}

class ProductImageHeader extends StatelessWidget {
  const ProductImageHeader({super.key, required this.scanData, this.heroTag, this.overlay});
  final ScanResult scanData;
  final String? heroTag;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final displayImageUrl = scanData.userImageUrl ?? scanData.imageUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SheetSectionHeader(title: 'FOOD ANALYSIS', color: Colors.transparent),
        Container(
          height: 420.h,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.r32),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.r32),
            child: Stack(
              children: [
                // Background Image
                Positioned.fill(
                  child: displayImageUrl != null && displayImageUrl.isNotEmpty
                      ? Hero(
                          tag: heroTag ?? '${AppStrings.scanImageHero}${scanData.barcode ?? scanData.productName}',
                          child: CachedNetworkImage(
                            imageUrl: displayImageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: scheme.border.withValues(alpha: 0.2),
                              highlightColor: scheme.border.withValues(alpha: 0.1),
                              child: Container(color: Colors.white),
                            ),
                            errorWidget: (_, _, _) => Container(
                              color: scheme.elevatedSurface,
                              child: Icon(AppIcons.utensils, size: 48, color: scheme.textMuted),
                            ),
                          ),
                        )
                      : Container(
                          color: scheme.elevatedSurface,
                          child: Icon(AppIcons.utensils, size: 48, color: scheme.textMuted),
                        ),
                ),

                // Dark gradient for readability
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withValues(alpha: 0.2), Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                        stops: const [0.0, 0.3, 1.0],
                      ),
                    ),
                  ),
                ),

                // Overlay Content (Stats/AI)
                if (overlay != null) Positioned.fill(child: overlay!),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.borderRadius, this.padding, this.backgroundColor});
  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: borderRadius ?? BorderRadius.circular(24),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white.withValues(alpha: 0.1),
          borderRadius: borderRadius ?? BorderRadius.circular(24),
          // border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
        ),
        child: child,
      ),
    ),
  );
}

class ScanHeroSection extends StatelessWidget {
  const ScanHeroSection({super.key, required this.scanData, this.heroTag, this.isGlass = false});
  final ScanResult scanData;
  final String? heroTag;
  final bool isGlass;

  @override
  Widget build(BuildContext context) {
    final scoreColor = _getScoreColor(context, scanData.score);
    final scheme = context.appColorScheme;

    final labelStyle = context.caption.copyWith(color: isGlass ? Colors.white.withValues(alpha: 0.7) : scheme.textMuted, fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: 9.sp);

    final valueStyle = context.bodyBold.copyWith(color: isGlass ? Colors.white : scheme.textPrimary, fontSize: 24.sp, letterSpacing: -0.5, fontWeight: FontWeight.w900);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _MetricItem(label: 'NOVA-GROUP', value: scanData.novaGroup ?? '1', labelStyle: labelStyle, valueStyle: valueStyle),
        if (scanData.nutriscore != null)
          _MetricItem(
            label: 'NUTRI-SCORE',
            valueWidget: Text(scanData.nutriscore!, style: valueStyle.copyWith(color: isGlass ? Colors.white : scoreColor)),
            // valueWidget: _NutriScoreBadge(grade: scanData.nutriscore!, isGlass: isGlass),
            labelStyle: labelStyle,
          ),
        _MetricItem(
          label: 'GUT-SCORE',
          value: scanData.score.toString(),
          valueWidget: Text('${scanData.score}', style: valueStyle.copyWith(color: isGlass ? Colors.white : scoreColor)),
          labelStyle: labelStyle,
        ),
      ],
    );
  }

  Color _getScoreColor(BuildContext context, int score) {
    if (score >= 70) return context.appColorScheme.success;
    if (score >= 40) return context.appColorScheme.warning;
    return context.appColorScheme.error;
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({required this.label, this.value, this.valueWidget, required this.labelStyle, this.valueStyle});
  final String label;
  final String? value;
  final Widget? valueWidget;
  final TextStyle labelStyle;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(label, style: labelStyle),
      Gap.h4,
      valueWidget ?? Text(value ?? '', style: valueStyle),
    ],
  );
}

class ScanImpactSection extends StatelessWidget {
  const ScanImpactSection({super.key, required this.title, required this.icon, required this.iconColor, required this.items, this.servingInfo});
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<ScanImpactDetailItem> items;
  final String? servingInfo;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SheetSectionHeader(title: title, color: Colors.transparent),
        if (servingInfo != null) ...[Text('Per serving ($servingInfo)', style: context.caption.copyWith(color: scheme.textMuted)), Gap.h16],
        Column(
          children: [
            for (int i = 0; i < items.length; i++) ...[items[i], if (i < items.length - 1) Divider(height: 1, color: scheme.border.withValues(alpha: 0.15))],
          ],
        ),
      ],
    );
  }
}

class ScanImpactDetailItem extends StatelessWidget {
  const ScanImpactDetailItem({super.key, required this.title, required this.subtitle, required this.icon, required this.value, required this.color, this.showCheck = false, this.isLast = false});

  final String title;
  final String subtitle;
  final IconData icon;
  final String value;
  final Color color;
  final bool showCheck;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSizes.p12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          Gap.w16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.capitalize,
                  style: context.bodyBold.copyWith(color: scheme.textPrimary, fontSize: 14.sp),
                ),
                if (subtitle.isNotEmpty) ...[
                  Gap.h2,
                  Text(
                    subtitle,
                    style: context.caption.copyWith(color: scheme.textMuted, fontSize: 11.sp, height: 1.3),
                  ),
                ],
              ],
            ),
          ),
          Text(
            value,
            style: context.bodyBold.copyWith(color: scheme.textPrimary, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }
}

class AdditivesSection extends StatelessWidget {
  const AdditivesSection({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final additives = scanData.additives ?? '';
    final count = additives.split(',').where((e) => e.trim().isNotEmpty).length;
    final scheme = context.appColorScheme;

    var riskColor = scheme.success;
    var riskLabel = 'CLEAN';

    if (count > 0) {
      riskColor = scheme.warning;
      riskLabel = count > 3 ? 'CAUTION' : 'MODERATE';
    }
    if (count > 5 || scanData.novaGroup == '4') {
      riskColor = scheme.error;
      riskLabel = 'AVOID';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SheetSectionHeader(title: 'WHAT TO WATCH', color: Colors.transparent),
        ScanImpactDetailItem(
          title: AppStrings.additivesLabel,
          subtitle: count > 0 ? 'Contains $count chemical additives' : 'No harmful additives detected',
          icon: AppIcons.flaskConical,
          value: count > 0 ? '$count TOTAL' : 'NONE',
          color: riskColor,
        ),
        if (scanData.flaggedIngredients.isNotEmpty) ...[
          Divider(height: 1, color: scheme.border.withValues(alpha: 0.1)),
          ScanImpactDetailItem(title: 'Flagged Items', subtitle: '${scanData.flaggedIngredients.length} matches your sensitivities', icon: AppIcons.alertCircle, value: riskLabel, color: scheme.error),
        ],
      ],
    );
  }
}

class PersonalizedInsightCard extends StatelessWidget {
  const PersonalizedInsightCard({super.key, required this.insight});
  final String insight;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSizes.p12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.sparkles, color: scheme.textPrimary, size: 18),
              Gap.w12,
              Text(
                'Personalized Insight',
                style: context.bodyBold.copyWith(color: scheme.textPrimary, fontSize: 15.sp),
              ),
            ],
          ),
          Gap.h8,
          Text(
            insight,
            style: context.body.copyWith(fontSize: 13.sp, height: 1.4, color: scheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class BetterSwapsCarousel extends StatelessWidget {
  const BetterSwapsCarousel({super.key, required this.swaps});
  final List<ProductSwap> swaps;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SheetSectionHeader(title: AppStrings.betterSwapsLabel, color: Colors.transparent),
      SizedBox(
        height: 100.0.h,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: swaps.length,
          itemBuilder: (context, i) => _SwapCard(swap: swaps[i]),
        ),
      ),
    ],
  );
}

class _SwapCard extends StatelessWidget {
  const _SwapCard({required this.swap});
  final ProductSwap swap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Container(
      width: 240.0.w,
      margin: EdgeInsets.only(right: AppSizes.p16),
      padding: EdgeInsets.all(AppSizes.p12),
      decoration: BoxDecoration(
        color: scheme.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.r20),
        border: Border.all(color: scheme.border.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 50.0.w,
            height: 70.0.h,
            decoration: BoxDecoration(color: scheme.elevatedSurface, borderRadius: BorderRadius.circular(AppSizes.r12)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.r12),
              child: swap.imageUrl != null && swap.imageUrl!.isNotEmpty ? CachedNetworkImage(imageUrl: swap.imageUrl!, fit: BoxFit.contain) : Icon(AppIcons.package, color: scheme.textMuted),
            ),
          ),
          Gap.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  swap.title,
                  style: context.bodyBold.copyWith(fontSize: 12.sp),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  swap.subtitle,
                  style: context.caption.copyWith(color: scheme.textMuted, fontSize: 10.sp),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Gap.h8,
                Row(
                  children: [
                    Icon(AppIcons.trendingUp, size: 10.sp, color: scheme.success),
                    Gap.w4,
                    Text(
                      'BETTER CHOICE',
                      style: context.eyebrow.copyWith(color: scheme.success, fontSize: 8.sp, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class IngredientsSection extends StatelessWidget {
  const IngredientsSection({super.key, required this.ingredients, required this.scanData});
  final List<Ingredient> ingredients;
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSizes.p8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full Composition / Paragraph Style
          RichText(
            text: TextSpan(
              children: [
                for (int i = 0; i < ingredients.length; i++) ...[
                  TextSpan(
                    text: ingredients[i].name.capitalize,
                    style: context.body.copyWith(
                      color: ['red', 'orange'].contains(ingredients[i].colorName.toLowerCase())
                          ? (ingredients[i].colorName.toLowerCase() == 'red' ? scheme.error : scheme.warning)
                          : scheme.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                  if (i < ingredients.length - 1)
                    TextSpan(
                      text: ', ',
                      style: context.body.copyWith(color: scheme.textMuted, fontSize: 14.sp),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NutritionFactsSection extends StatelessWidget {
  const NutritionFactsSection({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final n = scanData.nutrients;
    final scheme = context.appColorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SheetSectionHeader(title: AppStrings.nutritionFacts, color: Colors.transparent),
        if (n != null) ...[
          _NutrientRow(label: AppStrings.calories, value: '${n.calories ?? 0}', unit: 'kcal', color: scheme.textPrimary),
          _NutrientRow(label: AppStrings.protein, value: '${n.proteins ?? 0}', unit: 'g', color: scheme.success),
          _NutrientRow(label: AppStrings.totalFat, value: '${n.fat ?? 0}', unit: 'g', color: scheme.textPrimary),
          _NutrientRow(label: AppStrings.saturatedFat, value: '${n.saturatedFat ?? 0}', unit: 'g', color: scheme.textPrimary),
          _NutrientRow(label: AppStrings.totalCarbohydrate, value: '${n.carbs ?? 0}', unit: 'g', color: scheme.textPrimary),
          _NutrientRow(label: AppStrings.sugars, value: '${n.sugars ?? 0}', unit: 'g', color: scheme.textPrimary),
          _NutrientRow(label: AppStrings.fiber, value: '${n.fiber ?? 0}', unit: 'g', color: scheme.success),
          _NutrientRow(label: AppStrings.salt, value: '${n.salt ?? 0}', unit: 'mg', color: scheme.textPrimary, isLast: true),
        ],
      ],
    );
  }
}

class _NutrientRow extends StatelessWidget {
  const _NutrientRow({required this.label, required this.value, required this.unit, required this.color, this.isLast = false});
  final String label;
  final String value;
  final String unit;
  final Color color;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSizes.p10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: context.body.copyWith(color: scheme.textSecondary, fontSize: 13.sp),
          ),
          Text(
            '$value $unit',
            style: context.bodyBold.copyWith(color: scheme.textPrimary, fontSize: 13.sp),
          ),
        ],
      ),
    );
  }
}

class AllergensSection extends StatelessWidget {
  const AllergensSection({super.key, required this.allergens, this.servingSize});
  final String allergens;
  final String? servingSize;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final allergenList = allergens.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    if (allergenList.isEmpty) return const SizedBox.shrink();

    final items = allergenList
        .map((allergen) => ScanImpactDetailItem(title: allergen, subtitle: 'Potential inflammatory trigger', icon: AppIcons.alertTriangle, value: 'ALERT', color: scheme.error))
        .toList();

    return ScanImpactSection(title: 'Allergens detected', icon: AppIcons.alertTriangle, iconColor: scheme.error, servingInfo: servingSize, items: items);
  }
}

class MenuAnalysisSection extends StatelessWidget {
  const MenuAnalysisSection({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    // 🚀 Robust Extraction: Handle multiple nesting variations from different AI versions
    final Map<String, dynamic> raw = scanData.rawData ?? {};

    // Look inside a 'rawData' key if we have double-nesting
    final Map<String, dynamic> contextBlock = raw.containsKey('rawData') && raw['rawData'] is Map ? Map<String, dynamic>.from(raw['rawData'] as Map) : raw;

    final Map<String, dynamic> scanBlock = contextBlock.containsKey('scan') && contextBlock['scan'] is Map ? Map<String, dynamic>.from(contextBlock['scan'] as Map) : {};

    final Map<String, dynamic> menuBlock = contextBlock.containsKey('menu') && contextBlock['menu'] is Map
        ? Map<String, dynamic>.from(contextBlock['menu'] as Map)
        : (scanBlock.isNotEmpty ? scanBlock : contextBlock);

    final Map<String, dynamic> mealBlock = contextBlock.containsKey('meal') && contextBlock['meal'] is Map
        ? Map<String, dynamic>.from(contextBlock['meal'] as Map)
        : (scanBlock.isNotEmpty ? scanBlock : contextBlock);

    final restaurantName = menuBlock['restaurantName']?.toString() ?? scanBlock['restaurantName']?.toString() ?? contextBlock['restaurantName']?.toString() ?? scanData.productName;

    final List menuItems = menuBlock['menuItems'] is List
        ? menuBlock['menuItems'] as List
        : (scanBlock['menuItems'] is List
              ? scanBlock['menuItems'] as List
              : (mealBlock['items'] is List ? mealBlock['items'] as List : (contextBlock['menuItems'] is List ? contextBlock['menuItems'] as List : [])));

    final location = menuBlock['location'] ?? scanBlock['location'] ?? contextBlock['location'];
    final detectedText = menuBlock['detectedText'] ?? scanBlock['detectedText'] ?? contextBlock['detectedText'];

    // Meal Strategy details - prioritize 'meal' block, then fallback
    final List workingWell = mealBlock['workingWell'] is List
        ? mealBlock['workingWell'] as List
        : (scanBlock['workingWell'] is List ? scanBlock['workingWell'] as List : (contextBlock['workingWell'] is List ? contextBlock['workingWell'] as List : []));

    final List missing = mealBlock['missingOrCouldAdd'] is List
        ? mealBlock['missingOrCouldAdd'] as List
        : (scanBlock['missingOrCouldAdd'] is List ? scanBlock['missingOrCouldAdd'] as List : (contextBlock['missingOrCouldAdd'] is List ? contextBlock['missingOrCouldAdd'] as List : []));

    final List sensitivities = mealBlock['sensitivityNotes'] is List
        ? mealBlock['sensitivityNotes'] as List
        : (scanBlock['sensitivityNotes'] is List ? scanBlock['sensitivityNotes'] as List : (contextBlock['sensitivityNotes'] is List ? contextBlock['sensitivityNotes'] as List : []));

    final String? summary = mealBlock['summary']?.toString() ?? scanBlock['summary']?.toString() ?? contextBlock['summary']?.toString();

    if (menuItems.isEmpty && (detectedText == null || detectedText.toString().isEmpty) && summary == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (summary != null && summary.isNotEmpty) ...[
          const SheetSectionHeader(title: 'EXPERT SUMMARY', color: Colors.transparent),
          Text(
            summary,
            style: context.body.copyWith(fontSize: 14.sp, height: 1.5, color: context.appColorScheme.textPrimary),
          ),
          Gap.h32,
        ],
        if (workingWell.isNotEmpty || missing.isNotEmpty || sensitivities.isNotEmpty) ...[
          const SheetSectionHeader(title: 'DINING STRATEGY', color: Colors.transparent),
          _MenuStrategyCard(workingWell: workingWell, missing: missing, sensitivities: sensitivities),
          Gap.h32,
        ],
        const SheetSectionHeader(title: 'MENU RECOMMENDATIONS', color: Colors.transparent),
        if (restaurantName != null && restaurantName != 'Unknown') ...[
          Text(
            restaurantName.toUpperCase(),
            style: context.bodyBold.copyWith(color: context.appColorScheme.textPrimary, fontSize: 16.sp, letterSpacing: -0.5),
          ),
          if (location != null) ...[
            Gap.h4,
            Row(
              children: [
                Icon(AppIcons.mapPin, size: 12, color: context.appColorScheme.textMuted),
                Gap.w4,
                Text(location.toString(), style: context.caption.copyWith(color: context.appColorScheme.textMuted)),
              ],
            ),
          ],
          Gap.h20,
        ],
        if (menuItems.isNotEmpty) ...[
          for (int i = 0; i < menuItems.length; i++) ...[
            _MenuItemTile(item: menuItems[i] is Map<String, dynamic> ? menuItems[i] : {}),
            if (i < menuItems.length - 1) Divider(height: 32, color: context.appColorScheme.border.withValues(alpha: 0.1)),
          ],
        ] else if (detectedText != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.appColorScheme.elevatedSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.5)),
            ),
            child: Text(
              detectedText.toString(),
              style: context.body.copyWith(fontSize: 13.sp, color: context.appColorScheme.textSecondary),
            ),
          ),
        ],
      ],
    );
  }
}

class _MenuStrategyCard extends StatelessWidget {
  const _MenuStrategyCard({required this.workingWell, required this.missing, required this.sensitivities});
  final List workingWell;
  final List missing;
  final List sensitivities;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (workingWell.isNotEmpty) ...[
          _StrategyItem(title: 'Safe Bets', items: workingWell, icon: AppIcons.checkCircle, color: scheme.success),
          if (missing.isNotEmpty || sensitivities.isNotEmpty) Divider(height: 32, color: scheme.border.withValues(alpha: 0.1)),
        ],
        if (missing.isNotEmpty) ...[
          _StrategyItem(title: 'Better with...', items: missing, icon: AppIcons.plusCircle, color: AppPalette.blue),
          if (sensitivities.isNotEmpty) Divider(height: 32, color: scheme.border.withValues(alpha: 0.1)),
        ],
        if (sensitivities.isNotEmpty) ...[_StrategyItem(title: 'Watch out for', items: sensitivities, icon: AppIcons.alertTriangle, color: scheme.warning)],
      ],
    );
  }
}

class _StrategyItem extends StatelessWidget {
  const _StrategyItem({required this.title, required this.items, required this.icon, required this.color});
  final String title;
  final List items;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 14, color: color),
          Gap.w8,
          Text(
            title.toUpperCase(),
            style: context.caption.copyWith(fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5),
          ),
        ],
      ),
      Gap.h8,
      Text(
        items.join(' • '),
        style: context.body.copyWith(fontSize: 13.sp, color: context.appColorScheme.textPrimary, height: 1.4),
      ),
    ],
  );
}

class _MenuItemTile extends StatelessWidget {
  const _MenuItemTile({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final name = item['name'] ?? 'Unknown Item';
    final description = item['description'] ?? '';
    final impact = item['gutImpact'] ?? item['observation'] ?? '';
    final price = item['price'];
    final List ingredients = item['ingredients'] ?? [];
    final List tags = item['dietaryTags'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(name.toString().toUpperCase(), style: context.bodyBold.copyWith(letterSpacing: 0.5, fontSize: 14.sp)),
            ),
            if (price != null)
              Text(
                price.toString(),
                style: context.caption.copyWith(fontWeight: FontWeight.w900, color: scheme.textPrimary),
              ),
          ],
        ),
        if (description.isNotEmpty) ...[
          Gap.h8,
          Text(
            description.toString(),
            style: context.caption.copyWith(color: scheme.textSecondary, height: 1.4, fontSize: 12.sp),
          ),
        ],
        if (tags.isNotEmpty) ...[
          Gap.h12,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: scheme.textPrimary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      tag.toString().toUpperCase(),
                      style: context.caption.copyWith(fontSize: 9.sp, fontWeight: FontWeight.bold, color: scheme.textPrimary),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
        if (ingredients.isNotEmpty) ...[
          Gap.h12,
          Text(
            'Ingredients: ${ingredients.join(', ')}',
            style: context.caption.copyWith(color: scheme.textMuted, fontSize: 11.sp, fontStyle: FontStyle.italic),
          ),
        ],
        if (impact.isNotEmpty) ...[
          Gap.h12,
          Row(
            children: [
              Icon(AppIcons.salad, size: 14, color: scheme.success),
              Gap.w8,
              Expanded(
                child: Text(
                  impact.toString(),
                  style: context.caption.copyWith(color: scheme.success, fontWeight: FontWeight.bold, fontSize: 11.sp),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class CycleInsightSection extends StatelessWidget {
  const CycleInsightSection({super.key, required this.insight});
  final CycleInsight insight;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSizes.p12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AppIcons.sparkles, color: Colors.purple, size: 18),
              Gap.w12,
              Text(
                'Cycle Insight: ${insight.phase}',
                style: context.headingSm.copyWith(color: scheme.textPrimary, fontWeight: FontWeight.w900, fontSize: 18.sp),
              ),
            ],
          ),
          Gap.h12,
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppSizes.p16),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppSizes.r16),
              border: Border.all(color: Colors.purple.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.description, style: context.body.copyWith(color: scheme.textSecondary, height: 1.5)),
                if (insight.tags != null && insight.tags!.isNotEmpty) ...[
                  Gap.h12,
                  Wrap(
                    spacing: AppSizes.p8,
                    runSpacing: AppSizes.p8,
                    children: insight.tags!
                        .map(
                          (tag) => Container(
                            padding: EdgeInsets.symmetric(horizontal: AppSizes.p10, vertical: AppSizes.p4),
                            decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppSizes.r8)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  tag.text,
                                  style: context.caption.copyWith(color: Colors.purple, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProductMetadataSection extends StatelessWidget {
  const ProductMetadataSection({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final date = DateFormat('MMM dd, yyyy • hh:mm a').format(scanData.createdAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: scheme.border.withValues(alpha: 0.1)),
        Gap.h16,
        Text(
          'Product Information'.toUpperCase(),
          style: context.caption.copyWith(color: scheme.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
        Gap.h16,
        if (scanData.barcode != null) _MetadataRow(label: 'Barcode', value: scanData.barcode!),
        if (scanData.source != null) _MetadataRow(label: 'Source', value: scanData.source!.toUpperCase()),
        _MetadataRow(label: 'Analyzed On', value: date, isLast: true),
        Gap.h20,
      ],
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.label, required this.value, this.isLast = false});
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSizes.p8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: context.caption.copyWith(color: scheme.textMuted)),
          Text(
            value,
            style: context.caption.copyWith(color: scheme.textSecondary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
