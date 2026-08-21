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
          _buildFooterAction(context),
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
      padding: isEmbedded ? EdgeInsets.zero : EdgeInsets.all(AppSizes.p20),
      child: Row(
        children: [
          Container(
            width: 50.0.w,
            height: 50.0.h,
            padding: EdgeInsets.all(AppSizes.p10),
            decoration: BoxDecoration(
              color: colorScheme.elevatedSurface,
              borderRadius: BorderRadius.circular(AppSizes.r12),
              image: DecorationImage(image: CachedNetworkImageProvider(displayImgUrl), fit: BoxFit.cover),
              boxShadow: [BoxShadow(color: colorScheme.textPrimary.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
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
    padding: isEmbedded ? EdgeInsets.symmetric(vertical: AppSizes.p20) : EdgeInsets.all(AppSizes.p20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ingredients.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.contains.toUpperCase(), style: context.eyebrow.copyWith(letterSpacing: 1.2)),
              Text(
                '${ingredients.length} ITEMS',
                style: context.caption.copyWith(fontSize: 10.sp, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          Gap.h12,
          Column(
            children: ingredients
                .take(5)
                .map(
                  (ing) => Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: _RefinedTag(label: ing.name, impact: ing.colorName),
                  ),
                )
                .toList(),
          ),
          Gap.h12,
        ],
        Column(
          children: [
            _RefinedBenefitRow(icon: AppIcons.shieldCheck, title: AppStrings.gutProtection, description: scanData.impact, isLast: false),
            _RefinedBenefitRow(
              icon: AppIcons.leaf,
              title: AppStrings.cleanIngredients,
              description: 'Prioritizing options without the ${scanData.ingredients.length} identified ingredients.',
              isLast: false,
            ),
            const _RefinedBenefitRow(icon: AppIcons.zap, title: AppStrings.bioAvailability, description: AppStrings.bioAvailabilityDesc, isLast: true),
          ],
        ),
      ],
    ),
  );

  Widget _buildSwapsSection(BuildContext context, List<ProductSwap> swaps) {
    final colorScheme = context.appColorScheme;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: AppSizes.p8),
      padding: isEmbedded ? EdgeInsets.symmetric(vertical: AppSizes.p20) : EdgeInsets.all(AppSizes.p20),
      decoration: BoxDecoration(
        color: isEmbedded ? colorScheme.textPrimary.withValues(alpha: 0.03) : colorScheme.textPrimary.withValues(alpha: 0.03),
        borderRadius: isEmbedded ? BorderRadius.circular(AppSizes.r24) : BorderRadius.vertical(bottom: Radius.circular(AppSizes.r32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSizes.p8),
                decoration: BoxDecoration(color: colorScheme.textPrimary, borderRadius: BorderRadius.circular(AppSizes.r10)),
                child: Icon(AppIcons.salad, size: 18.w, color: colorScheme.cardBackground),
              ),
              Gap.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.swapItFeelBetter.toUpperCase(),
                      style: context.eyebrow.copyWith(color: colorScheme.textPrimary, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      AppStrings.easySwapsDesc,
                      style: context.caption.copyWith(color: colorScheme.textMuted, fontSize: 11.sp),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Gap.h20,
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
                    width: 150.w,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterAction(BuildContext context) {
    if (onViewFullReport == null) return const SizedBox.shrink();
    final colorScheme = context.appColorScheme;

    return Padding(
      padding: EdgeInsets.all(isEmbedded ? 0 : AppSizes.p20),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onViewFullReport,
              borderRadius: BorderRadius.circular(AppSizes.r24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.r24),
                  border: Border.all(color: colorScheme.border, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(AppIcons.arrowRight, size: 12, color: colorScheme.textPrimary),
                    Gap.w8,
                    Text(
                      AppStrings.viewFullReport.toUpperCase(),
                      style: context.eyebrow.copyWith(color: colorScheme.textPrimary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                    ),
                  ],
                ),
              ),
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
            style: context.caption.copyWith(color: colorScheme.textPrimary, fontSize: 11.sp, fontWeight: FontWeight.w800, letterSpacing: 0.3),
          ),
        ),
      ],
    );
  }
}

class _RefinedBenefitRow extends StatelessWidget {
  const _RefinedBenefitRow({required this.icon, required this.title, required this.description, this.isLast = false});
  final IconData icon;
  final String title;
  final String description;
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
                  title.toUpperCase(),
                  style: context.eyebrow.copyWith(fontSize: 11.sp, color: colorScheme.textPrimary, fontWeight: FontWeight.w900),
                ),
                Gap.h2,
                Text(
                  description,
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
