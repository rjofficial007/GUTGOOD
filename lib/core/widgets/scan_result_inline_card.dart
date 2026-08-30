import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
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
              border: Border.all(color: colorScheme.borderSubtle),
              boxShadow: [BoxShadow(color: colorScheme.surfaceSubtle, blurRadius: 20, offset: const Offset(0, 8))],
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
              border: isEmbedded ? Border.all(color: colorScheme.border.withAlpha(77)) : null,
              boxShadow: isEmbedded ? null : [BoxShadow(color: colorScheme.surfaceSubtle, blurRadius: 10, offset: const Offset(0, 4))],
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
                  style: context.labelBold.copyWith(color: colorScheme.textMuted),
                ),
                Gap.h4,
                Row(
                  children: [
                    RichText(
                      text: TextSpan(
                        style: context.captionBold.copyWith(color: colorScheme.textMuted),
                        children: [
                          TextSpan(text: '${AppStrings.gutGoodScore.toUpperCase()} '),
                          TextSpan(
                            text: scanData.score.toString(),
                            style: context.labelBold.copyWith(color: colorScheme.textPrimary),
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
                          style: context.captionBold.copyWith(color: colorScheme.textMuted),
                          children: [
                            TextSpan(text: '${AppStrings.nutriScore.toUpperCase()} '),
                            TextSpan(
                              text: scanData.nutriscore,
                              style: context.labelBold.copyWith(color: colorScheme.textPrimary),
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
              Text(AppStrings.contains.toUpperCase(), style: context.captionBold.copyWith(color: context.appColorScheme.textMuted)),
              Text(
                AppStrings.itemsCount(ingredients.length),
                style: context.captionBold,
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
        color: isEmbedded ? colorScheme.elevatedSurface.withAlpha(127) : colorScheme.surfaceSubtle,
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
                      style: context.captionBold.copyWith(color: colorScheme.textPrimary),
                    ),
                    Text(
                      AppStrings.easySwapsDesc,
                      style: context.caption.copyWith(color: colorScheme.textMuted),
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
            style: context.labelBold.copyWith(color: colorScheme.textPrimary),
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
                  (descriptionOverride != null ? AppStrings.insightLabel : title).toUpperCase(),
                  style: context.labelBold.copyWith(color: colorScheme.textPrimary),
                ),
                Gap.h2,
                Text(
                  descriptionOverride ?? description,
                  style: context.label.copyWith(color: colorScheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
