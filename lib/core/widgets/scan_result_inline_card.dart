import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/bottom_sheet_helper.dart';
import 'package:gutgood/core/utils/extensions.dart';
import 'package:gutgood/core/utils/image_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:provider/provider.dart';

class ScanResultInlineCard extends StatelessWidget {
  const ScanResultInlineCard({super.key, required this.scanData, required this.onViewFullReport});
  final ScanResult scanData;
  final VoidCallback onViewFullReport;

  void _showExplanation(BuildContext context) {
    BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: AppStrings.analysisDetail,
      padding: EdgeInsets.fromLTRB(AppSizes.p24, 0, AppSizes.p24, context.padding.bottom + AppSizes.p24),
      children: [
        Row(
          children: [Expanded(child: Text(AppStrings.gutGoodAnalysis, style: context.h2))],
        ),
        Gap.h10,
        _buildIngredientInfo(context),
        Gap.h16,
        Align(
          alignment: .topLeft,
          child: Text(AppStrings.keyBenefits, style: context.overline, textAlign: .start),
        ),
        Gap.h12,
        _InlineBenefitRow(icon: AppIcons.shieldCheck, title: AppStrings.gutProtection, description: scanData.impact),
        Gap.h16,
        _InlineBenefitRow(
          icon: AppIcons.leaf,
          title: AppStrings.cleanIngredients,
          description: 'We prioritize options without the ${scanData.ingredients.length} questionable ingredients found in your scan.',
        ),
        Gap.h16,
        const _InlineBenefitRow(icon: AppIcons.zap, title: AppStrings.bioAvailability, description: AppStrings.bioAvailabilityDesc),
        Gap.h32,
        GutButton(label: AppStrings.gotItThanks, onTap: () => context.pop()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ingredients = scanData.ingredients;
    final swaps = scanData.swaps;

    // 🟢 Fix: Ensure we don't try to load an empty string as a URL
    var userImg = scanData.userImageUrl;
    if (userImg != null && userImg.isEmpty) userImg = null;
    var prodImg = scanData.imageUrl;
    if (prodImg != null && prodImg.isEmpty) prodImg = null;

    final displayImgUrl = userImg ?? prodImg ?? getDynamicImageUrl(scanData.productName);

    final impactColor = scanData.impactType == ImpactType.positive
        ? context.appColorScheme.success
        : scanData.impactType == ImpactType.neutral
        ? context.appColorScheme.warning
        : context.appColorScheme.error;
    final impactBgColor = impactColor.withValues(alpha: 0.1);
    final impactIcon = scanData.impactType == ImpactType.positive
        ? AppIcons.checkCircle
        : scanData.impactType == ImpactType.neutral
        ? AppIcons.alertTriangle
        : AppIcons.alertCircle;

    return Container(
      margin: EdgeInsets.only(bottom: AppSizes.p16,right:  AppSizes.p16,left: AppSizes.p28),
      padding: EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: context.appColorScheme.aiResponseBackground,
        borderRadius: BorderRadius.circular(AppSizes.r24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80.0.w,
                height: 80.0.h,
                decoration: BoxDecoration(
                  color: context.appColorScheme.elevatedSurface,
                  borderRadius: BorderRadius.circular(AppSizes.r8),
                  image: DecorationImage(image: CachedNetworkImageProvider(displayImgUrl), fit: BoxFit.cover),
                ),
              ),
              Gap.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(scanData.productName, style: context.bodyBold, maxLines: 2, overflow: TextOverflow.ellipsis),
                    Gap.h6,
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.0.w, vertical: 2.0.h),
                      decoration: BoxDecoration(color: impactBgColor, borderRadius: BorderRadius.circular(AppSizes.r8)),
                      child: Text(
                        scanData.badge ?? 'Unknown',
                        style: context.caption.copyWith(color: impactColor, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Gap.h16,
          Text(AppStrings.contains, style: context.overline),
          Gap.h6,
          Wrap(spacing: 8.0.w, runSpacing: 8.0.h, children: ingredients.map((ing) => _ITag(ing.name, _getColor(context, ing.colorName))).toList()),
          Gap.h16,
          Text(AppStrings.likelyImpact, style: context.overline),
          Gap.h6,
          Container(
            padding: EdgeInsets.all(AppSizes.p12),
            decoration: BoxDecoration(color: impactBgColor, borderRadius: BorderRadius.circular(AppSizes.r10)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(impactIcon, color: impactColor, size: 18.0.w),
                Gap.w8,
                Expanded(
                  child: Text(scanData.impact, style: context.caption.copyWith(color: impactColor, height: 1.3)),
                ),
              ],
            ),
          ),
          Gap.h20,
          Divider(height: 1, color: context.appColorScheme.border),
          Gap.h16,

          _buildCycleInsight(context),

          if (swaps.isNotEmpty) ...[
            Row(
              children: [
                Icon(AppIcons.sparkles, size: 18.0.w, color: context.appColorScheme.textPrimary),
                Gap.w8,
                Text(AppStrings.swapThisInstead, style: context.overline.copyWith(color: context.appColorScheme.textPrimary)),
              ],
            ),
            Gap.h12,
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: swaps.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final swap = entry.value;

                  var calculatedTag = 'GOOD OPTIONS';
                  if (idx == 0) {
                    calculatedTag = 'BETTER CHOICE';
                  } else if (idx == 1) {
                    calculatedTag = 'GOOD FOR YOU';
                  }

                  return Padding(
                    padding: EdgeInsets.only(right: idx == swaps.length - 1 ? 0 : 12.0.w),
                    child: SwapCard(title: swap.title, subtitle: swap.subtitle, imageKeyword: swap.imageKeyword, imageUrl: swap.imageUrl, tag: calculatedTag, badge: idx == 0 ? '#1 PICK' : swap.badge),
                  );
                }).toList(),
              ),
            ),
            Gap.h20,

            InkWell(
              onTap: () => _showExplanation(context),
              borderRadius: BorderRadius.circular(AppSizes.r12),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12.0.h),
                decoration: BoxDecoration(
                  color: context.appColorScheme.cardBackground.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppSizes.r16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(AppStrings.whyBetter, style: context.bodyBold.copyWith(fontSize: 13.0.sp)),
                    Gap.w4,
                    Icon(AppIcons.chevronRight, size: 16.0.w, color: context.appColorScheme.textPrimary),
                  ],
                ),
              ),
            ),
          ],

          GutButton(label: AppStrings.viewFullReport, onTap: onViewFullReport),
        ],
      ),
    );
  }

  Widget _buildIngredientInfo(BuildContext context) =>
      Text('${AppStrings.comparingAnalysis}${scanData.productName}${AppStrings.withSwaps}', style: context.body.copyWith(color: context.appColorScheme.textMuted));

  Widget _buildCycleInsight(BuildContext context) {
    final profile = context.watch<ProfileNotifier>().profile;
    final cycleEnabled = profile?.cycleSyncEnabled ?? false;

    if (!cycleEnabled || scanData.cycleInsight == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        CycleInsightCard(insight: scanData.cycleInsight!),
        Gap.h20,
      ],
    );
  }

  Color _getColor(BuildContext context, String? colorName) {
    if (colorName == 'red') return context.appColorScheme.error;
    if (colorName == 'orange') return context.appColorScheme.warning;
    return context.appColorScheme.textMuted;
  }
}

class _InlineBenefitRow extends StatelessWidget {
  const _InlineBenefitRow({required this.icon, required this.title, required this.description});
  final IconData icon;
  final String title;
  final String description;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: EdgeInsets.all(AppSizes.p8),
        decoration: BoxDecoration(color: context.appColorScheme.elevatedSurface, borderRadius: BorderRadius.circular(AppSizes.r10)),
        child: Icon(icon, size: 20.0.w, color: context.appColorScheme.textPrimary),
      ),
      Gap.w16,
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: context.bodyBold.copyWith(fontSize: 15.0.sp)),
            Gap.h4,
            Text(description, style: context.caption.copyWith(height: 1.4)),
          ],
        ),
      ),
    ],
  );
}

class _ITag extends StatelessWidget {
  const _ITag(this.label, this.color);
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10.0.w, vertical: 6.0.h),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppSizes.r8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(AppIcons.x, color: color, size: 12.0.w),
        Gap.w6,
        Flexible(
          child: Text(
            label,
            style: context.caption.copyWith(color: context.appColorScheme.textPrimary, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}
