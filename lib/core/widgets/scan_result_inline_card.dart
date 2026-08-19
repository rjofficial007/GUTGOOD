import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/scan_result.dart';
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
    final ingredients = scanData.ingredients;
    final swaps = scanData.swaps;
    final colorScheme = context.appColorScheme;

    var userImg = scanData.userImageUrl;
    if (userImg != null && userImg.isEmpty) userImg = null;
    var prodImg = scanData.imageUrl;
    if (prodImg != null && prodImg.isEmpty) prodImg = null;

    final displayImgUrl = userImg ?? prodImg ?? getDynamicImageUrl(scanData.productName);

    final impactColor = scanData.impactType == ImpactType.positive
        ? colorScheme.success
        : scanData.impactType == ImpactType.neutral
        ? colorScheme.warning
        : colorScheme.error;
    final impactIcon = scanData.impactType == ImpactType.positive
        ? AppIcons.checkCircle
        : scanData.impactType == ImpactType.neutral
        ? AppIcons.alertTriangle
        : AppIcons.alertCircle;

    return Container(
      margin: isEmbedded ? EdgeInsets.zero : EdgeInsets.only(bottom: AppSizes.p24, right: AppSizes.p16),
      decoration: BoxDecoration(
        color: isEmbedded ? Colors.transparent : colorScheme.cardBackground,
        borderRadius: isEmbedded
            ? null
            : BorderRadius.only(topLeft: const Radius.circular(4), topRight: Radius.circular(AppSizes.r32), bottomLeft: Radius.circular(AppSizes.r32), bottomRight: Radius.circular(AppSizes.r32)),
        border: isEmbedded ? null : Border.all(color: colorScheme.border.withValues(alpha: 0.5)),
        boxShadow: isEmbedded ? null : [BoxShadow(color: colorScheme.textPrimary.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Padding(
            padding: isEmbedded ? EdgeInsets.zero : EdgeInsets.all(AppSizes.p20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 80.0.w,
                      height: 80.0.h,
                      decoration: BoxDecoration(
                        color: colorScheme.elevatedSurface,
                        borderRadius: BorderRadius.circular(AppSizes.r20),
                        image: DecorationImage(image: CachedNetworkImageProvider(displayImgUrl), fit: BoxFit.cover),
                      ),
                    ),
                    if (scanData.nutriscore != null) Positioned(bottom: 0, right: 0, child: _NutriScoreBadge(score: scanData.nutriscore!)),
                  ],
                ),
                Gap.w16,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(scanData.productName.toUpperCase(), style: context.title.copyWith(height: 1.1), maxLines: 2, overflow: TextOverflow.ellipsis),
                      Gap.h4,
                      Text(
                        scanData.brand,
                        style: context.eyebrow.copyWith(color: colorScheme.textMuted, fontSize: 10.sp),

                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Gap.h12,
                      Row(
                        spacing: 5,
                        children: [
                          _BlackBadge(label: scanData.badge?.toUpperCase() ?? 'ANALYZED', accentColor: impactColor),
                          _ScoreBadge(score: scanData.score, color: impactColor),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (!isEmbedded)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.p20),
              child: Divider(color: colorScheme.border.withValues(alpha: 0.3), height: 1),
            ),

          // Technical Analysis Section
          Padding(
            padding: isEmbedded ? EdgeInsets.symmetric(vertical: AppSizes.p20) : EdgeInsets.all(AppSizes.p20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ingredients.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppStrings.contains.toUpperCase(), style: context.eyebrow),
                      Text('${ingredients.length} ITEMS', style: context.caption.copyWith(fontSize: 8.sp)),
                    ],
                  ),
                  Gap.h12,
                  Wrap(
                    spacing: 6.0.w,
                    runSpacing: 6.0.h,
                    children: ingredients.take(8).map((ing) => _MinimalTag(label: ing.name, impact: ing.colorName)).toList(),
                  ),
                ],

                Gap.h24,
                Text(AppStrings.keyBenefits, style: context.eyebrow),
                Gap.h12,
                _InlineBenefitRow(icon: AppIcons.shieldCheck, title: AppStrings.gutProtection, description: scanData.impact),
                Gap.h16,
                _InlineBenefitRow(icon: AppIcons.leaf, title: AppStrings.cleanIngredients, description: 'Prioritizing options without the ${scanData.ingredients.length} identified ingredients.'),
                Gap.h16,
                const _InlineBenefitRow(icon: AppIcons.zap, title: AppStrings.bioAvailability, description: AppStrings.bioAvailabilityDesc),
              ],
            ),
          ),

          _buildCycleInsight(context),

          // Swaps
          if (swaps.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: isEmbedded ? EdgeInsets.zero : EdgeInsets.all(AppSizes.p20),
              decoration: BoxDecoration(
                color: isEmbedded ? Colors.transparent : colorScheme.textPrimary.withValues(alpha: 0.03),
                borderRadius: isEmbedded ? null : BorderRadius.vertical(bottom: Radius.circular(AppSizes.r32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(AppIcons.sparkles, size: 16.0.w, color: colorScheme.textPrimary),
                      Gap.w8,
                      Text(AppStrings.swapThisInstead.toUpperCase(), style: context.eyebrow.copyWith(color: colorScheme.textPrimary)),
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
                            width: 140.w,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Gap.h24,
                  SizedBox(
                    width: double.infinity,
                    child: GutButton(
                      label: AppStrings.viewFullReport.toUpperCase(),
                      onTap: onViewFullReport,
                      color: colorScheme.textPrimary,
                      textColor: colorScheme.cardBackground,
                      suffixIcon: AppIcons.arrowRight,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Padding(
              padding: isEmbedded ? EdgeInsets.only(bottom: AppSizes.p10) : EdgeInsets.all(AppSizes.p20),
              child: GutButton(
                label: AppStrings.viewFullReport.toUpperCase(),
                onTap: onViewFullReport,
                color: colorScheme.textPrimary,
                textColor: colorScheme.cardBackground,
                suffixIcon: AppIcons.arrowRight,
              ),
            ),
          ],
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

class _BlackBadge extends StatelessWidget {
  const _BlackBadge({required this.label, required this.accentColor});
  final String label;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: colorScheme.elevatedSurface,
        borderRadius: BorderRadius.circular(AppSizes.r8),
        border: Border.all(color: colorScheme.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.4), blurRadius: 4)],
            ),
          ),
          Gap.w8,
          Text(
            label,
            style: context.eyebrow.copyWith(fontSize: 8.sp, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: colorScheme.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score, required this.color});
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score.toDouble()),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutExpo,
      builder: (context, value, _) => Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: colorScheme.elevatedSurface,
          borderRadius: BorderRadius.circular(AppSizes.r8),
          border: Border.all(color: colorScheme.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4)],
              ),
            ),
            Gap.w8,
            Text(
              '${value.toInt()} SCORE',
              style: context.eyebrow.copyWith(fontSize: 8.sp, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: colorScheme.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _MinimalTag extends StatelessWidget {
  const _MinimalTag({required this.label, required this.impact});
  final String label;
  final String? impact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;
    final isRisky = impact == 'red';
    final isCaution = impact == 'orange';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: colorScheme.elevatedSurface,
        borderRadius: BorderRadius.circular(AppSizes.r8),
        border: Border.all(color: isRisky ? colorScheme.error.withValues(alpha: 0.3) : (isCaution ? colorScheme.warning.withValues(alpha: 0.3) : colorScheme.border)),
      ),
      child: Text(
        label.toUpperCase(),
        style: context.caption.copyWith(
          color: isRisky ? colorScheme.error : (isCaution ? colorScheme.warning : colorScheme.textPrimary),
          fontSize: 9.sp,
          fontWeight: isRisky || isCaution ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    );
  }
}

class _NutriScoreBadge extends StatelessWidget {
  const _NutriScoreBadge({required this.score});
  final String score;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;
    return Container(
      width: 24.w,
      height: 24.w,
      decoration: BoxDecoration(
        color: colorScheme.textPrimary,
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.cardBackground, width: 2),
      ),
      child: Center(
        child: Text(
          score,
          style: context.bodyBold.copyWith(color: colorScheme.cardBackground, fontSize: 12.sp, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _InlineBenefitRow extends StatelessWidget {
  const _InlineBenefitRow({required this.icon, required this.title, required this.description});
  final IconData icon;
  final String title;
  final String description;
  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(AppSizes.p6),
          decoration: BoxDecoration(color: colorScheme.textPrimary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(AppSizes.r8)),
          child: Icon(icon, size: 14.w, color: colorScheme.textPrimary),
        ),
        Gap.w12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: context.eyebrow.copyWith(fontSize: 12.sp, color: colorScheme.textPrimary),
              ),
              Gap.h2,
              Text(
                description,
                style: context.caption.copyWith(height: 1.3, fontSize: 12.sp, color: colorScheme.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
