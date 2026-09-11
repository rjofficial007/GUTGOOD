import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/image_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/widgets.dart';

class ScanResultInlineCard extends StatelessWidget {
  const ScanResultInlineCard({super.key, required this.scanData, this.onViewFullReport, this.isEmbedded = false});

  final ScanResult scanData;
  final VoidCallback? onViewFullReport;
  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;

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
}
