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
import 'package:gutgood/core/utils/image_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:provider/provider.dart';

class ScanResultInlineCard extends StatelessWidget {
  const ScanResultInlineCard({super.key, required this.scanData, this.onViewFullReport, this.isEmbedded = false});

  final ScanResult scanData;
  final VoidCallback? onViewFullReport;
  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;
    final ingredients = scanData.ingredients;
    final swaps = scanData.swaps;

    final Map<String, dynamic> raw = scanData.rawData ?? {};
    final Map<String, dynamic> mealBlock = raw['meal'] is Map ? Map<String, dynamic>.from(raw['meal'] as Map) : {};
    final Map<String, dynamic> balance = mealBlock['balance'] is Map ? Map<String, dynamic>.from(mealBlock['balance'] as Map) : {};
    final List items = mealBlock['items'] is List ? mealBlock['items'] as List : [];

    final impactColor = scanData.impactType == ImpactType.positive
        ? colorScheme.success
        : scanData.impactType == ImpactType.neutral
        ? colorScheme.warning
        : colorScheme.error;

    return Container(
      margin: isEmbedded ? EdgeInsets.zero : EdgeInsets.only(bottom: AppSizes.p24, right: AppSizes.p16),
      decoration: isEmbedded
          ? null
          : BoxDecoration(
              color: colorScheme.cardBackground,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(4),
                topRight: Radius.circular(AppSizes.r32),
                bottomLeft: Radius.circular(AppSizes.r32),
                bottomRight: Radius.circular(AppSizes.r32),
              ),
              border: Border.all(color: colorScheme.border.withValues(alpha: 0.5)),
              boxShadow: [BoxShadow(color: colorScheme.textPrimary.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8))],
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, impactColor),
          _buildAnalysisSection(context, ingredients),
          _buildCycleInsight(context),
          if (swaps.isNotEmpty) _buildSwapsSection(context, swaps),
          FooterActionButton(
          label: AppStrings.viewFullReport,
          onTap: onViewFullReport,
          isEmbedded: isEmbedded,
        ),
        ],
      ),
    );
  }

  Widget _buildNutritionalBalance(BuildContext context, Map<String, dynamic> balance) {
    final scheme = context.appColorScheme;
    return Padding(
      padding: isEmbedded ? const EdgeInsets.only(bottom: 16) : const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: balance.entries.map((e) {
          final label = e.key.toUpperCase();
          final status = e.value.toString().toLowerCase();
          final Color color = switch (status) {
            'good' || 'high' => scheme.success,
            'moderate' => scheme.warning,
            _ => scheme.textMuted,
          };

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                Gap.w6,
                Text(
                  '$label: ${status.toUpperCase()}',
                  style: context.caption.copyWith(color: color, fontWeight: FontWeight.w900, fontSize: 8.sp, letterSpacing: 0.3),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildIdentifiedItems(BuildContext context, List items) {
    final scheme = context.appColorScheme;
    return Padding(
      padding: isEmbedded ? const EdgeInsets.only(bottom: 16) : const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('IDENTIFIED DISHES', style: context.eyebrow.copyWith(fontSize: 8.sp, letterSpacing: 1.0, color: scheme.textMuted)),
          Gap.h8,
          ...items.map((item) {
            final data = item is Map ? item : {};
            final name = data['name']?.toString() ?? 'Unknown';
            final observation = data['observation']?.toString() ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(AppIcons.check, size: 10.sp, color: scheme.success),
                  Gap.w8,
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: context.body.copyWith(fontSize: 11.5.sp, color: scheme.textPrimary),
                        children: [
                          TextSpan(text: name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (observation.isNotEmpty)
                            TextSpan(
                              text: ' • $observation',
                              style: TextStyle(color: scheme.textSecondary, fontSize: 10.5.sp),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color impactColor) {
    final colorScheme = context.appColorScheme;
    var userImg = scanData.userImageUrl;
    if (userImg != null && userImg.isEmpty) userImg = null;
    var prodImg = scanData.imageUrl;
    if (prodImg != null && prodImg.isEmpty) prodImg = null;

    final displayImgUrl = userImg ?? prodImg ?? getDynamicImageUrl(scanData.productName);

    return Padding(
      padding: isEmbedded ? const EdgeInsets.only(bottom: 16) : EdgeInsets.all(AppSizes.p20),
      child: Row(
        children: [
          Container(
            width: 50.0.w,
            height: 50.0.h,
            decoration: BoxDecoration(
              color: colorScheme.elevatedSurface,
              borderRadius: BorderRadius.circular(AppSizes.r12),
              image: DecorationImage(image: CachedNetworkImageProvider(displayImgUrl), fit: BoxFit.cover),
              border: isEmbedded ? Border.all(color: colorScheme.border.withValues(alpha: 0.3)) : null,
              boxShadow: isEmbedded ? null : [BoxShadow(color: colorScheme.textPrimary.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
          ),

          Gap.w10,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(scanData.productName.toUpperCase(), style: context.eyebrow.copyWith(color: colorScheme.textPrimary, fontSize: 10)),
                Text(
                  scanData.brand,
                  style: context.bodySm.copyWith(color: colorScheme.textMuted, fontSize: 12.sp),
                ),
                Gap.h4,
                Row(
                  children: [
                    RichText(
                      text: TextSpan(
                        style: context.eyebrow.copyWith(color: colorScheme.textMuted, fontSize: 9.sp, letterSpacing: 0.5),
                        children: [
                          TextSpan(text: '${AppStrings.gutGoodScore.toUpperCase()} '),
                          TextSpan(
                            text: scanData.score.toString(),
                            style: TextStyle(color: colorScheme.textPrimary, fontWeight: FontWeight.w900, fontSize: 11.sp),
                          ),
                        ],
                      ),
                    ),
                    if (scanData.nutriscore != null) ...[
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 8.w),
                        width: 1,
                        height: 8.h,
                        color: colorScheme.border,
                      ),
                      RichText(
                        text: TextSpan(
                          style: context.eyebrow.copyWith(color: colorScheme.textMuted, fontSize: 9.sp, letterSpacing: 0.5),
                          children: [
                            TextSpan(text: '${AppStrings.nutriScore.toUpperCase()} '),
                            TextSpan(
                              text: scanData.nutriscore,
                              style: TextStyle(color: colorScheme.textPrimary, fontWeight: FontWeight.w900, fontSize: 11.sp),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection(BuildContext context, List<Ingredient> ingredients) => Padding(
    padding: isEmbedded ? const EdgeInsets.only(bottom: 16) : EdgeInsets.all(AppSizes.p20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Gap.h10,
        if (ingredients.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.contains.toUpperCase(), style: context.eyebrow.copyWith(letterSpacing: 1.0, fontSize: 8.sp, color: context.appColorScheme.textMuted)),
              Text(
                '${ingredients.length} ITEMS',
                style: context.caption.copyWith(fontSize: 9.sp, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          Gap.h10,
          Column(
            children: ingredients
                .take(5)
                .map(
                  (ing) => Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: _RefinedTag(label: ing.name, impact: ing.colorName),
                  ),
                )
                .toList(),
          ),
          Gap.h12,
        ],
        Column(
          children: [
            _RefinedBenefitRow(icon: AppIcons.shieldCheck, title: AppStrings.gutProtection, description: scanData.impact, isLast: scanData.impacts.isEmpty),
            if (scanData.impacts.isNotEmpty)
              ...scanData.impacts.asMap().entries.map((entry) {
                final idx = entry.key;
                final imp = entry.value;
                final isLast = idx == scanData.impacts.length - 1;
                return _RefinedBenefitRow(
                  icon: AppIcons.salad,
                  title: imp.title == 'Impact' ? 'Key Finding' : imp.title,
                  description: imp.title == 'Impact' ? imp.title : imp.level,
                  descriptionOverride: imp.title,
                  isLast: isLast,
                );
              }),
          ],
        ),
      ],
    ),
  );

  Widget _buildSwapsSection(BuildContext context, List<ProductSwap> swaps) {
    final colorScheme = context.appColorScheme;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: isEmbedded ? 8 : 8),
      padding: isEmbedded ? const EdgeInsets.all(16) : EdgeInsets.all(AppSizes.p20),
      decoration: BoxDecoration(
        color: isEmbedded ? colorScheme.elevatedSurface.withValues(alpha: 0.5) : colorScheme.textPrimary.withValues(alpha: 0.03),
        borderRadius: isEmbedded ? BorderRadius.circular(AppSizes.r20) : BorderRadius.vertical(bottom: Radius.circular(AppSizes.r32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isEmbedded ? 6 : 8),
                decoration: BoxDecoration(color: colorScheme.textPrimary, borderRadius: BorderRadius.circular(isEmbedded ? AppSizes.r8 : AppSizes.r10)),
                child: Icon(AppIcons.salad, size: isEmbedded ? 14.sp : 18.w, color: colorScheme.cardBackground),
              ),
              Gap.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.swapItFeelBetter.toUpperCase(),
                      style: context.eyebrow.copyWith(color: colorScheme.textPrimary, fontWeight: FontWeight.w900, fontSize: isEmbedded ? 8.sp : 10.sp),
                    ),
                    Text(
                      AppStrings.easySwapsDesc,
                      style: context.caption.copyWith(color: colorScheme.textMuted, fontSize: isEmbedded ? 10.sp : 11.sp),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Gap.h16,
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: swaps.asMap().entries.map((entry) {
                final idx = entry.key;
                final swap = entry.value;
                return Padding(
                  padding: EdgeInsets.only(right: idx == swaps.length - 1 ? 0 : 12.0.w),
                  child: SwapCard(
                    title: swap.title,
                    subtitle: swap.subtitle,
                    imageKeyword: swap.imageKeyword,
                    imageUrl: swap.imageUrl,
                    tag: idx == 0 ? 'PRIME CHOICE' : 'VALID SWAP',
                    badge: idx == 0 ? 'TOP PICK' : null,
                    width: isEmbedded ? 130.w : 150.w,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCycleInsight(BuildContext context) {
    final profile = context.watch<ProfileNotifier>().profile;
    final cycleEnabled = profile?.cycleSyncEnabled ?? false;

    if (!cycleEnabled || scanData.cycleInsight == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.p20),
      child: Column(
        children: [
          CycleInsightCard(insight: scanData.cycleInsight!),
          Gap.h20,
        ],
      ),
    );
  }

  Widget _buildMealStrategy(BuildContext context) {
    final Map<String, dynamic> raw = scanData.rawData ?? {};
    final Map<String, dynamic> mealBlock = raw['meal'] is Map ? Map<String, dynamic>.from(raw['meal'] as Map) : {};

    final List workingWell = mealBlock['workingWell'] is List ? mealBlock['workingWell'] as List : [];
    final List missing = mealBlock['missingOrCouldAdd'] is List ? mealBlock['missingOrCouldAdd'] as List : [];
    final List sensitivities = mealBlock['sensitivityNotes'] is List ? mealBlock['sensitivityNotes'] as List : [];

    if (workingWell.isEmpty && missing.isEmpty && sensitivities.isEmpty) {
      return const SizedBox.shrink();
    }

    final scheme = context.appColorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: isEmbedded ? 16 : 8),
      padding: EdgeInsets.all(isEmbedded ? 12 : 16),
      decoration: BoxDecoration(
        color: scheme.textPrimary.withValues(alpha: isEmbedded ? 0.02 : 0.03),
        borderRadius: BorderRadius.circular(isEmbedded ? AppSizes.r16 : AppSizes.r24),
        border: isEmbedded ? null : Border.all(color: scheme.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (workingWell.isNotEmpty) ...[
            _StrategyLine(icon: AppIcons.checkCircle, color: scheme.success, title: 'Safe Bets', items: workingWell, isEmbedded: isEmbedded),
            if (missing.isNotEmpty || sensitivities.isNotEmpty) Gap.h12,
          ],
          if (missing.isNotEmpty) ...[
            _StrategyLine(icon: AppIcons.plusCircle, color: AppPalette.blue, title: 'Better with...', items: missing, isEmbedded: isEmbedded),
            if (sensitivities.isNotEmpty) Gap.h12,
          ],
          if (sensitivities.isNotEmpty) ...[
            _StrategyLine(icon: AppIcons.alertTriangle, color: scheme.warning, title: 'Watch out for', items: sensitivities, isEmbedded: isEmbedded),
          ],
        ],
      ),
    );
  }
}

class _StrategyLine extends StatelessWidget {
  const _StrategyLine({required this.icon, required this.color, required this.title, required this.items, this.isEmbedded = false});
  final IconData icon;
  final Color color;
  final String title;
  final List items;
  final bool isEmbedded;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: isEmbedded ? 12.sp : 14, color: color),
      Gap.w8,
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: context.caption.copyWith(fontWeight: FontWeight.w900, color: color, fontSize: isEmbedded ? 8.sp : 9.sp, letterSpacing: 0.5),
            ),
            Gap.h2,
            Text(
              items.join(' • '),
              style: context.body.copyWith(fontSize: isEmbedded ? 11.sp : 12.sp, color: context.appColorScheme.textPrimary, height: 1.3),
            ),
          ],
        ),
      ),
    ],
  );
}

class _RefinedTag extends StatelessWidget {
  const _RefinedTag({required this.label, required this.impact});
  final String label;
  final String? impact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;
    final isRisky = impact == 'red';
    final isCaution = impact == 'orange';

    final indicatorColor = isRisky ? colorScheme.error : (isCaution ? colorScheme.warning : colorScheme.success);

    return Row(
      children: [
        Container(
          width: 3.w,
          height: 14.h,
          decoration: BoxDecoration(color: indicatorColor, borderRadius: BorderRadius.circular(4)),
        ),
        Gap.w12,
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: context.caption.copyWith(color: colorScheme.textPrimary, fontSize: 11.sp, fontWeight: FontWeight.w800, letterSpacing: 0.3),
          ),
        ),
      ],
    );
  }
}

class _RefinedBenefitRow extends StatelessWidget {
  const _RefinedBenefitRow({required this.icon, required this.title, required this.description, this.descriptionOverride, this.isLast = false});
  final IconData icon;
  final String title;
  final String description;
  final String? descriptionOverride;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSizes.p16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16.w, color: colorScheme.textPrimary),
          Gap.w10,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (descriptionOverride != null ? 'Insight' : title).toUpperCase(),
                  style: context.eyebrow.copyWith(fontSize: 11.sp, color: colorScheme.textPrimary, fontWeight: FontWeight.w900),
                ),
                Gap.h2,
                Text(
                  descriptionOverride ?? description,
                  style: context.caption.copyWith(height: 1.4, fontSize: 12.sp, color: colorScheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
