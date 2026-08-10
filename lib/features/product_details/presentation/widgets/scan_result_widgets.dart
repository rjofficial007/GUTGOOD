import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:shimmer/shimmer.dart';

class ScanResultAppBar extends StatelessWidget {
  const ScanResultAppBar({super.key, required this.isSaved, required this.isLoading, required this.onSaveTap});

  final bool isSaved;
  final bool isLoading;
  final VoidCallback onSaveTap;

  @override
  Widget build(BuildContext context) => GutSliverAppBar(
    title: AppStrings.scanResult,
    leading: IconButton(
      icon: Icon(AppIcons.chevronLeft, color: context.appColorScheme.textPrimary),
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          // Fallback for cases where context.go() was used to reach this screen
          context.go(AppRoutes.history);
        }
      },
    ),
    actions: [
      SaveButton(isSaved: isSaved, isLoading: isLoading, onTap: onSaveTap),
      Gap.w16,
    ],
  );
}

class SaveButton extends StatelessWidget {
  const SaveButton({super.key, required this.isSaved, required this.isLoading, required this.onTap});
  final bool isSaved;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: isLoading ? null : onTap,
    child: isLoading
        ? SizedBox(
            width: AppSizes.icon24,
            height: AppSizes.icon24,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: context.appColorScheme.error),
          )
        : Icon(isSaved ? Icons.favorite : Icons.favorite_border, color: isSaved ? context.appColorScheme.error : context.appColorScheme.textMuted, size: AppSizes.icon24),
  );
}

class ProductHero extends StatelessWidget {
  const ProductHero({super.key, required this.scanData, this.heroTag});
  final ScanResult scanData;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    var userImg = scanData.userImageUrl;
    if (userImg != null && userImg.isEmpty) userImg = null;
    var prodImg = scanData.imageUrl;
    if (prodImg != null && prodImg.isEmpty) prodImg = null;

    final displayImageUrl = userImg ?? prodImg;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.appColorScheme.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.r24),
        border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: AppPalette.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSizes.p16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: AppSizes.w80,
              height: AppSizes.w80,
              decoration: BoxDecoration(color: AppPalette.gray50, borderRadius: BorderRadius.circular(AppSizes.r16)),
              child: displayImageUrl != null
                  ? Hero(
                      tag: heroTag ?? '${AppStrings.scanImageHero}${scanData.barcode ?? scanData.productName}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppSizes.r16),
                        child: CachedNetworkImage(
                          imageUrl: displayImageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: context.appColorScheme.border.withValues(alpha: 0.2),
                            highlightColor: context.appColorScheme.border.withValues(alpha: 0.1),
                            child: Container(color: AppPalette.white),
                          ),
                          errorWidget: (_, _, _) => Icon(AppIcons.package, size: AppSizes.icon32, color: context.appColorScheme.textMuted),
                        ),
                      ),
                    )
                  : Icon(AppIcons.package, size: AppSizes.icon32, color: context.appColorScheme.textMuted),
            ),
            Gap.w16,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scanData.productName,
                    style: context.bodyBold.copyWith(fontSize: AppSizes.s18, fontWeight: FontWeight.w800, height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    scanData.brand,
                    style: context.caption.copyWith(color: context.appColorScheme.textMuted, fontSize: AppSizes.s13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Gap.h12,
                  Wrap(
                    spacing: AppSizes.p8,
                    runSpacing: AppSizes.p8,
                    children: [
                      if (scanData.nutriscore != null) ClassificationBadge(label: AppStrings.nutriScore.toUpperCase(), value: scanData.nutriscore!.toUpperCase()),
                      if (scanData.novaGroup != null) ClassificationBadge(label: AppStrings.nova.toUpperCase(), value: scanData.novaGroup!),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClassificationBadge extends StatelessWidget {
  const ClassificationBadge({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    var badgeColor = context.appColorScheme.elevatedSurface;
    if (label == AppStrings.nova.toUpperCase()) {
      badgeColor = context.appColorScheme.elevatedSurface;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.p10, vertical: AppSizes.p4 / 1.3),
      decoration: BoxDecoration(
        color: context.appColorScheme.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.r8),
        border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: context.eyebrow.copyWith(fontSize: AppSizes.s9, letterSpacing: 0.5)),
          Gap.w8,
          Container(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.p6, vertical: AppSizes.p2),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(AppSizes.r4),
              border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.5)),
            ),
            child: Text(
              value,
              style: context.bodyBold.copyWith(fontSize: AppSizes.s11, color: context.appColorScheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class GutImpactChart extends StatelessWidget {
  const GutImpactChart({super.key, required this.score});
  final int score;

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      SizedBox(
        width: AppSizes.p64,
        height: AppSizes.p64,
        child: CircularProgressIndicator(value: 1.0, strokeWidth: 10.0.w, color: context.appColorScheme.border.withValues(alpha: 0.5)),
      ),
      SizedBox(
        width: AppSizes.p64,
        height: AppSizes.p64,
        child: CircularProgressIndicator(value: score / 100, strokeWidth: 10.0.w, strokeCap: StrokeCap.round, color: context.appColorScheme.textPrimary),
      ),
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            score.toString(),
            style: context.h1.copyWith(fontSize: AppSizes.s16, fontWeight: FontWeight.w900, color: context.appColorScheme.textPrimary),
          ),
          Text(
            AppStrings.pointsUnit.toUpperCase(),
            style: context.caption.copyWith(fontSize: AppSizes.s8, fontWeight: FontWeight.w800, color: context.appColorScheme.textMuted, letterSpacing: 1.0),
          ),
        ],
      ),
    ],
  );
}

class CycleImpactDashboardSection extends StatelessWidget {
  const CycleImpactDashboardSection({super.key, required this.insight});
  final CycleInsight insight;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(AppSizes.p24),
    decoration: BoxDecoration(
      color: context.appColorScheme.textPrimary,
      borderRadius: BorderRadius.circular(AppSizes.r28),
      boxShadow: [BoxShadow(color: AppPalette.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.phase, style: context.eyebrow.copyWith(color: context.appColorScheme.cardBackground.withValues(alpha: 0.8), letterSpacing: 2.0)),
                  Text(
                    insight.phase.toUpperCase(),
                    style: context.bodyBold.copyWith(color: context.appColorScheme.cardBackground, fontWeight: FontWeight.w900, height: 1.1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        Gap.h24,
        Text(
          insight.description,
          style: context.body.copyWith(color: context.appColorScheme.cardBackground.withValues(alpha: 0.9), fontSize: AppSizes.s15, height: 1.4, fontWeight: FontWeight.w500),
        ),
        Gap.h16,
        Row(
          children: [
            Icon(AppIcons.trendingUp, color: context.appColorScheme.cardBackground, size: AppSizes.icon14),
            Gap.w8,
            Text(
              AppStrings.highMetabolicImpact,
              style: context.caption.copyWith(color: context.appColorScheme.cardBackground, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    ),
  );
}

class NutrientVisualization extends StatelessWidget {
  const NutrientVisualization({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const GutProgressBar(ratio: 0.7),
      Gap.h12,
      Text(
        AppStrings.optimalProfileIdentified,
        style: context.caption.copyWith(fontSize: AppSizes.s10, color: context.appColorScheme.textMuted),
      ),
    ],
  );
}

class SwapVisualization extends StatelessWidget {
  const SwapVisualization({super.key});

  @override
  Widget build(BuildContext context) => const DashboardIconVisualization(icon: AppIcons.arrowRightLeft);
}

String getIngredientImpactLabel(String colorName) {
  switch (colorName.toLowerCase()) {
    case 'red':
      return AppStrings.labelAvoid;
    case 'orange':
      return AppStrings.labelLimit;
    default:
      return AppStrings.labelClean;
  }
}
