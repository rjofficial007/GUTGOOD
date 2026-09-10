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
    final profile = context.watch<ProfileNotifier>().profile;
    final cycleEnabled = profile?.cycleSyncEnabled ?? false;

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
          // _buildAnalysisSection(context, ingredients),
          // _buildLikelyImpact(context),
          // if (cycleEnabled) _buildCycleInsight(context),
          FooterActionButton(label: AppStrings.viewFullReport, onTap: onViewFullReport, isEmbedded: isEmbedded),
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
                Text(scanData.brand, style: context.labelBold.copyWith(color: colorScheme.textMuted)),
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

  Widget _buildAnalysisSection(BuildContext context, List<Ingredient> ingredients) {
    if (ingredients.isEmpty) return const SizedBox.shrink();

    final colorScheme = context.appColorScheme;

    // 🚀 Professional Sorting: Red (Triggers) -> Orange (Caution) -> Low (Neutral)
    final sorted = List<Ingredient>.from(ingredients)
      ..sort((a, b) {
        int score(Ingredient i) => switch (i.colorName.toLowerCase()) {
          'red' => 2,
          'orange' => 1,
          _ => 0,
        };
        return score(b).compareTo(score(a));
      });

    return Padding(
      padding: EdgeInsets.fromLTRB(0, AppSizes.p10, 0, AppSizes.p20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.contains.toUpperCase(), style: context.eyebrow.copyWith(color: colorScheme.textMuted, fontSize: 10)),
              Text(AppStrings.itemsCount(ingredients.length), style: context.captionBold.copyWith(color: colorScheme.textMuted, fontSize: 10)),
            ],
          ),
          Gap.h12,
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: sorted.take(8).map((ing) => _IngredientPill(ingredient: ing)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLikelyImpact(BuildContext context) {
    if (scanData.impact.isEmpty) return const SizedBox.shrink();

    final colorScheme = context.appColorScheme;
    final isNegative = scanData.impactType == ImpactType.negative;
    final isPositive = scanData.impactType == ImpactType.positive;

    final baseColor = isNegative ? colorScheme.error : (isPositive ? colorScheme.success : colorScheme.warning);
    final bgColor = isNegative ? colorScheme.errorSubtle : (isPositive ? colorScheme.successSubtle : colorScheme.softWarning.withAlpha(50));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(AppSizes.p12),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(AppSizes.r12)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: baseColor.withAlpha(26), shape: BoxShape.circle),
                child: Icon(isNegative ? AppIcons.flame : AppIcons.sparkles, color: baseColor, size: 16.w),
              ),
              Gap.w10,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(AppStrings.likelyImpact.toUpperCase(), style: context.eyebrow.copyWith(color: baseColor, fontSize: 10)),
                    Gap.h4,
                    Text(
                      scanData.impact,
                      style: context.caption.copyWith(color: colorScheme.textPrimary, height: 1.4, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Gap.h20,
      ],
    );
  }

  Widget _buildCycleInsight(BuildContext context) {
    if (scanData.cycleInsight == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        CycleInsightCard(insight: scanData.cycleInsight!),
        Gap.h20,
      ],
    );
  }
}

class _IngredientPill extends StatelessWidget {
  const _IngredientPill({required this.ingredient});
  final Ingredient ingredient;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final impact = ingredient.colorName.toLowerCase();

    final (baseColor, bgColor, isNeutral) = switch (impact) {
      'red' => (colorScheme.error, colorScheme.errorSubtle, false),
      'orange' => (colorScheme.warning, colorScheme.softWarning.withAlpha(isDark ? 50 : 30), false),
      _ => (colorScheme.success, colorScheme.softSuccess.withAlpha(isDark ? 50 : 30), false),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.r8),
        border: Border.all(color: isNeutral ? colorScheme.borderSubtle : baseColor.withAlpha(isDark ? 80 : 40), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isNeutral) ...[
            Container(
              width: 5.w,
              height: 5.w,
              decoration: BoxDecoration(color: baseColor, shape: BoxShape.circle),
            ),
            Gap.w6,
          ],
          Text(
            ingredient.name.toUpperCase(),
            style: context.labelBold.copyWith(color: isNeutral ? colorScheme.textSecondary : (isDark ? baseColor : baseColor.withAlpha(230)), fontSize: 9.sp, letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }
}
