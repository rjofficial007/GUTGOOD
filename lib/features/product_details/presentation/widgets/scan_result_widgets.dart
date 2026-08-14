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
      icon: Icon(AppIcons.arrowLeft, color: context.appColorScheme.textPrimary),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = context.appColorScheme;
    final textColor = scheme.textPrimary;
    final invertedColor = scheme.cardBackground;
    final borderColor = scheme.border.withValues(alpha: 0.5);

    var userImg = scanData.userImageUrl;
    if (userImg != null && userImg.isEmpty) userImg = null;
    var prodImg = scanData.imageUrl;
    if (prodImg != null && prodImg.isEmpty) prodImg = null;
    final displayImageUrl = userImg ?? prodImg;

    return Container(
      decoration: BoxDecoration(
        color: scheme.elevatedSurface,
        borderRadius: BorderRadius.circular(AppSizes.r32),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(5),
      child: Column(
        children: [
          // Header Section
          Container(
            constraints: const BoxConstraints(minHeight: 120),
            decoration: BoxDecoration(
              color: scheme.border.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: borderColor),
            ),
            padding: const EdgeInsets.fromLTRB(20, 18, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            scanData.productName,
                            style: context.headingMd.copyWith(color: textColor, fontWeight: FontWeight.w900, letterSpacing: -1.0, height: 1.1, fontFeatures: const [FontFeature.tabularFigures()]),
                          ),
                          Gap.h8,
                          Text(
                            scanData.brand.toUpperCase(),
                            style: context.eyebrow.copyWith(color: textColor.withValues(alpha: 0.6), fontWeight: FontWeight.w900, letterSpacing: 1.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(color: textColor, borderRadius: BorderRadius.circular(14)),
                      child: displayImageUrl != null
                          ? Hero(
                              tag: heroTag ?? '${AppStrings.scanImageHero}${scanData.barcode ?? scanData.productName}',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: CachedNetworkImage(
                                  imageUrl: displayImageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Shimmer.fromColors(
                                    baseColor: scheme.border.withValues(alpha: 0.2),
                                    highlightColor: scheme.border.withValues(alpha: 0.1),
                                    child: Container(color: AppPalette.white),
                                  ),
                                  errorWidget: (_, _, _) => Icon(AppIcons.package, size: 22, color: invertedColor),
                                ),
                              ),
                            )
                          : Icon(AppIcons.package, size: 22, color: invertedColor),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Gut Impact Summary Row (New Integrated Style)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: _ProductHeroRow(
              title: '${scanData.score} ${AppStrings.pointsUnit.toUpperCase()}',
              subtitle: AppStrings.gutImpact,
              isDone: true,
              textColor: textColor,
              borderColor: borderColor,
              icon: AppIcons.activity,
            ),
          ),

          if (scanData.nutriscore != null)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: _ProductHeroRow(title: AppStrings.nutriScore, subtitle: 'Grade ${scanData.nutriscore!.toUpperCase()}', isDone: true, textColor: textColor, borderColor: borderColor),
            ),
          if (scanData.novaGroup != null)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: _ProductHeroRow(title: AppStrings.nova, subtitle: 'Processing Group ${scanData.novaGroup}', isDone: true, textColor: textColor, borderColor: borderColor),
            ),

          // Individual Impact Details
          ...scanData.impacts.map(
            (e) => Padding(
              padding: const EdgeInsets.only(top: 5),
              child: _ProductHeroRow(
                title: e.title,
                subtitle: e.level,
                isDone: ['good', 'positive', 'healing', 'high', 'neutral'].contains(e.level.toLowerCase()),
                textColor: textColor,
                borderColor: borderColor,
                icon: ['good', 'positive', 'healing', 'high', 'neutral'].contains(e.level.toLowerCase()) ? AppIcons.check : AppIcons.alertCircle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductHeroRow extends StatelessWidget {
  const _ProductHeroRow({required this.title, this.subtitle, this.isDone = false, required this.textColor, required this.borderColor, this.icon});

  final String title;
  final String? subtitle;
  final bool isDone;
  final Color textColor;
  final Color borderColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    // Smart Radius Heuristic: If it has a subtitle or very long title, it's likely 2+ lines.
    final isLong = (subtitle?.length ?? 0) > 40 || title.length > 30;
    final radius = isLong ? 24.0 : 50.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.appColorScheme.elevatedSurface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: textColor,
              border: Border.all(color: textColor, width: 1.5),
            ),
            child: Icon(icon ?? AppIcons.check, size: 14, color: context.appColorScheme.cardBackground),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: context.bodySm.copyWith(fontWeight: FontWeight.w600, color: textColor),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: context.caption.copyWith(color: textColor.withValues(alpha: 0.5), fontSize: 11.sp),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(AppIcons.chevronRight, size: 20, color: textColor.withValues(alpha: 0.3)),
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
