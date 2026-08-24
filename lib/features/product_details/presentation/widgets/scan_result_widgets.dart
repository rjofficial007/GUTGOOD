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
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
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

class ScanHeroSection extends StatelessWidget {
  const ScanHeroSection({super.key, required this.scanData, this.heroTag});
  final ScanResult scanData;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final displayImageUrl = scanData.userImageUrl ?? scanData.imageUrl;
    final scoreColor = _getScoreColor(context, scanData.score);
    final bannerHeight = 80.0.h;
    final avatarSize = 80.0.w;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.appColorScheme.elevatedSurface,
        borderRadius: BorderRadius.circular(AppSizes.r28),
        border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          // Banner + Image Stack
          SizedBox(
            height: bannerHeight + (avatarSize / 2),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // Luxury Banner
                Container(
                  height: bannerHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [context.appColorScheme.textPrimary.withValues(alpha: 0.1), context.appColorScheme.textPrimary.withValues(alpha: 0.05)],
                    ),
                  ),
                ),
                // Product Image Avatar
                Positioned(
                  top: bannerHeight - (avatarSize / 2) - 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.appColorScheme.elevatedSurface,
                        border: Border.all(color: context.appColorScheme.cardBackground, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppPalette.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.4 : 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: displayImageUrl != null && displayImageUrl.isNotEmpty
                            ? Hero(
                                tag: heroTag ?? '${AppStrings.scanImageHero}${scanData.barcode ?? scanData.productName}',
                                child: CachedNetworkImage(
                                  imageUrl: displayImageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Shimmer.fromColors(
                                    baseColor: context.appColorScheme.elevatedSurface,
                                    highlightColor: context.appColorScheme.border,
                                    child: Container(color: AppPalette.white),
                                  ),
                                  errorWidget: (_, _, _) => Icon(AppIcons.droplet, size: avatarSize * 0.5, color: context.appColorScheme.textMuted),
                                ),
                              )
                            : Icon(AppIcons.droplet, size: avatarSize * 0.5, color: context.appColorScheme.textMuted),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Gap.h16,
          // Product Info
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.p20),
            child: Column(
              children: [
                if (scanData.category != null) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: AppSizes.p8, vertical: AppSizes.p2),
                    decoration: BoxDecoration(
                      border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(AppSizes.r4),
                    ),
                    child: Text(
                      scanData.category!.toUpperCase(),
                      style: context.eyebrow.copyWith(color: context.appColorScheme.textSecondary, fontSize: AppSizes.s8, letterSpacing: 2.0),
                    ),
                  ),
                  Gap.h8,
                ],
                Text(
                  scanData.productName,
                  textAlign: TextAlign.center,
                  style: context.headingLg.copyWith(color: context.appColorScheme.textPrimary, letterSpacing: 0.5, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Gap.h4,
                Text(
                  scanData.brand.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: context.caption.copyWith(color: context.appColorScheme.textMuted, letterSpacing: 1.0, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Gap.h24,
          // Nutrient Level Bubbles (Replacing Profile Weekly Bubbles)
          if (scanData.nutrientLevels != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.p20),
              child: _NutrientLevelBubbles(levels: scanData.nutrientLevels!),
            ),
          Gap.h32,
          // Stats Row with Linear Progress
          Padding(
            padding: EdgeInsets.only(left: AppSizes.p20, right: AppSizes.p20, bottom: AppSizes.p32),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Nova Group/Processing
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GROUP ${scanData.novaGroup ?? '1'}',
                            style: context.headingMd.copyWith(color: context.appColorScheme.textPrimary, fontWeight: FontWeight.w900),
                          ),
                          Text(
                            _getProcessingLabel(scanData.novaGroup).toUpperCase(),
                            style: context.eyebrow.copyWith(color: context.appColorScheme.textMuted, letterSpacing: 1.0, fontSize: 8.sp),
                          ),
                        ],
                      ),
                    ),
                    Gap.w32,
                    // Gut Score
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${scanData.score}',
                                  style: context.headingMd.copyWith(color: scoreColor, fontWeight: FontWeight.w900),
                                ),
                                TextSpan(
                                  text: '/100',
                                  style: context.caption.copyWith(color: context.appColorScheme.textMuted, fontSize: 10.sp),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'GUT IMPACT',
                            style: context.eyebrow.copyWith(color: context.appColorScheme.textMuted, letterSpacing: 1.0, fontSize: 8.sp),
                          ),
                        ],
                      ),
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

  Color _getScoreColor(BuildContext context, int score) {
    if (score >= 70) return context.appColorScheme.success;
    if (score >= 40) return context.appColorScheme.warning;
    return context.appColorScheme.error;
  }

  String _getProcessingLabel(String? nova) {
    final n = int.tryParse(nova ?? '');
    if (n == null) return AppStrings.notSpecified;
    if (n <= 2) return AppStrings.minimallyProcessed;
    return AppStrings.ultraProcessed;
  }
}

class _NutrientLevelBubbles extends StatelessWidget {
  const _NutrientLevelBubbles({required this.levels});
  final NutrientLevels levels;

  @override
  Widget build(BuildContext context) {
    final items = [
      (AppStrings.sugars, levels.sugars, AppIcons.package),
      (AppStrings.salt, levels.salt, AppIcons.wheat),
      (AppStrings.fatLabel, levels.fat, AppIcons.droplet),
      (AppStrings.satFatLabel, levels.saturatedFat, AppIcons.shield),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items.map((item) {
        final label = item.$1;
        final level = item.$2.toLowerCase();
        final icon = item.$3;

        Color color;
        if (level == 'low') {
          color = AppPalette.green;
        } else if (level == 'moderate') {
          color = AppPalette.orange;
        } else if (level == 'high') {
          color = AppPalette.red;
        } else {
          color = AppPalette.gray500;
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.1),
                border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
              ),
              child: Icon(icon, size: 14.w, color: color),
            ),
            Gap.h8,
            Text(
              label.toUpperCase(),
              style: context.caption.copyWith(fontSize: 8.sp, fontWeight: FontWeight.bold, color: context.appColorScheme.textMuted, letterSpacing: 0.5),
            ),
            Text(
              level == 'unknown' ? '—' : level.toUpperCase(),
              style: context.caption.copyWith(fontSize: 7.sp, color: color, fontWeight: FontWeight.w900),
            ),
          ],
        );
      }).toList(),
    );
  }
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

    return Container(
      margin: EdgeInsets.only(top: AppSizes.p16),
      padding: EdgeInsets.all(AppSizes.p20),
      decoration: BoxDecoration(
        color: scheme.elevatedSurface,
        borderRadius: BorderRadius.circular(AppSizes.r28),
        border: Border.all(color: scheme.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SOURCES',
                      style: context.eyebrow.copyWith(color: scheme.textSecondary.withValues(alpha: 0.6), letterSpacing: 1.2, fontSize: 9.sp),
                    ),
                    Text(title, style: context.bodyBold.copyWith(color: scheme.textPrimary, height: 1.1)),
                  ],
                ),
              ),
              if (servingInfo != null)
                Text(
                  'Per serving ($servingInfo)',
                  style: context.caption.copyWith(color: scheme.textMuted, fontSize: 8.5.sp),
                )
              else
                Icon(icon, color: iconColor, size: AppSizes.icon20),
            ],
          ),
          Gap.h24,
          Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[items[i], if (i < items.length - 1) Divider(height: 1, indent: 40.0.w, color: scheme.border.withValues(alpha: 0.3))],
            ],
          ),
        ],
      ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 12.sp),
                  Gap.w8,
                  Text(
                    title.toUpperCase(),
                    style: context.eyebrow.copyWith(fontSize: 9.sp, color: scheme.textSecondary, letterSpacing: 1.0),
                  ),
                ],
              ),
              Text(
                value,
                style: context.caption.copyWith(fontWeight: FontWeight.w900, fontFeatures: const [FontFeature.tabularFigures()], fontSize: 10.sp, color: scheme.textPrimary),
              ),
            ],
          ),
          if (subtitle.isNotEmpty) ...[
            Gap.h4,
            Padding(
              padding: EdgeInsets.only(left: 12.sp + AppSizes.p8),
              child: Text(
                subtitle,
                style: context.caption.copyWith(color: scheme.textMuted, fontSize: 8.5.sp),
              ),
            ),
          ],
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

    // Determine risk color and progress
    var riskColor = scheme.success;
    var progress = 0.1;
    var riskLabel = 'CLEAN';

    if (count > 0) {
      riskColor = scheme.warning;
      progress = (count / 10).clamp(0.1, 1.0);
      riskLabel = count > 3 ? 'CAUTION' : 'MODERATE';
    }
    if (count > 5 || scanData.novaGroup == '4') {
      riskColor = scheme.error;
      progress = (count / 10).clamp(0.5, 1.0);
      riskLabel = 'AVOID';
    }

    return Container(
      margin: EdgeInsets.only(top: AppSizes.p16),
      padding: EdgeInsets.all(AppSizes.p20),
      decoration: BoxDecoration(
        color: scheme.elevatedSurface,
        borderRadius: BorderRadius.circular(AppSizes.r28),
        border: Border.all(color: scheme.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TRIGGERS',
                      style: context.eyebrow.copyWith(color: scheme.textSecondary.withValues(alpha: 0.6), letterSpacing: 1.2, fontSize: 9.sp),
                    ),
                    Text('What to watch', style: context.bodyBold.copyWith(color: scheme.textPrimary, height: 1.1)),
                  ],
                ),
              ),
              if (scanData.servingSize != null)
                Text(
                  'Per serving (${scanData.servingSize})',
                  style: context.caption.copyWith(color: scheme.textMuted, fontSize: 8.5.sp),
                )
              else
                Icon(AppIcons.alertTriangle, color: scheme.warning, size: AppSizes.icon20),
            ],
          ),
          Gap.h24,
          ScanImpactDetailItem(
            title: AppStrings.additivesLabel,
            subtitle: count > 0 ? 'Contains $count chemical additives' : 'No harmful additives detected',
            icon: AppIcons.flaskConical,
            value: count > 0 ? '$count TOTAL' : 'NONE',
            color: riskColor,
          ),
          if (scanData.flaggedIngredients.isNotEmpty) ...[
            Divider(height: 1, color: scheme.border.withValues(alpha: 0.3)),
            ScanImpactDetailItem(
              title: 'FLAGGED ITEMS',
              subtitle: '${scanData.flaggedIngredients.length} ingredients matching your sensitivities',
              icon: AppIcons.alertCircle,
              value: riskLabel,
              color: scheme.error,
            ),
          ],
          if (count > 0) ...[
            Gap.h8,
            Row(children: [_buildRiskBadge(context, '1', 'Moderate risk', scheme.warning), Gap.w8, _buildRiskBadge(context, '2', 'Limited risk', scheme.warning.withValues(alpha: 0.7))]),
          ],
        ],
      ),
    );
  }

  Widget _buildRiskBadge(BuildContext context, String count, String label, Color color) => Container(
    padding: EdgeInsets.symmetric(horizontal: AppSizes.p8, vertical: AppSizes.p4),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppSizes.r12)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 8.0.w,
          backgroundColor: color,
          child: Text(
            count,
            style: context.caption.copyWith(color: AppPalette.white, fontSize: AppSizes.s9),
          ),
        ),
        Gap.w4,
        Text(
          label,
          style: context.caption.copyWith(color: color, fontSize: AppSizes.s10, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}

class PersonalizedInsightCard extends StatelessWidget {
  const PersonalizedInsightCard({super.key, required this.insight});
  final String insight;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    return Container(
      margin: EdgeInsets.only(top: AppSizes.p16),
      padding: EdgeInsets.all(AppSizes.p20),
      decoration: BoxDecoration(
        color: scheme.elevatedSurface,
        borderRadius: BorderRadius.circular(AppSizes.r28),
        border: Border.all(color: scheme.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'INSIGHTS',
                    style: context.eyebrow.copyWith(color: scheme.textSecondary.withValues(alpha: 0.6), letterSpacing: 1.2, fontSize: 9.sp),
                  ),
                  Text(AppStrings.personalizedImpactLabel, style: context.bodyBold.copyWith(color: scheme.textPrimary, height: 1.1)),
                ],
              ),
            ],
          ),
          Gap.h24,
          Row(
            children: [
              Expanded(
                child: Text(
                  insight,
                  style: context.body.copyWith(fontSize: AppSizes.s12, height: 1.4, color: scheme.textPrimary),
                ),
              ),
            ],
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
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Container(
      margin: EdgeInsets.only(top: AppSizes.p16),
      padding: EdgeInsets.all(AppSizes.p20),
      decoration: BoxDecoration(
        color: scheme.elevatedSurface,
        borderRadius: BorderRadius.circular(AppSizes.r28),
        border: Border.all(color: scheme.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SWAPS',
                    style: context.eyebrow.copyWith(color: scheme.textSecondary.withValues(alpha: 0.6), letterSpacing: 1.2, fontSize: 9.sp),
                  ),
                  Text(AppStrings.betterSwapsLabel, style: context.bodyBold.copyWith(color: scheme.textPrimary, height: 1.1)),
                ],
              ),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: scheme.textPrimary, borderRadius: BorderRadius.circular(100)),
                  child: Text(
                    AppStrings.seeAll.toUpperCase(),
                    style: context.caption.copyWith(color: scheme.cardBackground, fontWeight: FontWeight.w900, fontSize: 8.5.sp, letterSpacing: 1),
                  ),
                ),
              ),
            ],
          ),
          Gap.h24,
          SizedBox(
            height: 100.0.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: swaps.length,
              itemBuilder: (context, i) => _SwapCard(swap: swaps[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwapCard extends StatelessWidget {
  const _SwapCard({required this.swap});
  final ProductSwap swap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Container(
      width: 200.0.w,
      margin: EdgeInsets.only(right: AppSizes.p12),
      padding: EdgeInsets.all(AppSizes.p10),
      decoration: BoxDecoration(
        color: scheme.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.r16),
        border: Border.all(color: scheme.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40.0.w,
            height: 60.0.h,
            decoration: BoxDecoration(color: scheme.elevatedSurface, borderRadius: BorderRadius.circular(AppSizes.r8)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.r8),
              child: swap.imageUrl != null && swap.imageUrl!.isNotEmpty ? CachedNetworkImage(imageUrl: swap.imageUrl!, fit: BoxFit.contain) : Icon(AppIcons.droplet, color: scheme.info),
            ),
          ),
          Gap.w10,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  swap.title,
                  style: context.bodyBold.copyWith(fontSize: AppSizes.s11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  swap.subtitle,
                  style: context.caption.copyWith(color: scheme.textMuted, fontSize: AppSizes.s9),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Gap.h4,
                Container(
                  padding: EdgeInsets.symmetric(horizontal: AppSizes.p6, vertical: AppSizes.p2),
                  decoration: BoxDecoration(color: scheme.softSuccess, borderRadius: BorderRadius.circular(AppSizes.r6)),
                  child: Text(
                    'Better choice ↑',
                    style: context.caption.copyWith(color: scheme.success, fontSize: AppSizes.s9, fontWeight: FontWeight.bold),
                  ),
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

    return Container(
      margin: EdgeInsets.only(top: AppSizes.p16),
      padding: EdgeInsets.all(AppSizes.p20),
      decoration: BoxDecoration(
        color: scheme.elevatedSurface,
        borderRadius: BorderRadius.circular(AppSizes.r28),
        border: Border.all(color: scheme.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COMPOSITION',
                      style: context.eyebrow.copyWith(color: scheme.textSecondary.withValues(alpha: 0.6), letterSpacing: 1.2, fontSize: 9.sp),
                    ),
                    Text(AppStrings.ingredientsLabel, style: context.bodyBold.copyWith(color: scheme.textPrimary, height: 1.1)),
                  ],
                ),
              ),
              Icon(AppIcons.clipboardList, color: scheme.textPrimary, size: AppSizes.icon20),
            ],
          ),
          Gap.h24,
          ...ingredients.map((ing) {
            final isWarning = ['red', 'orange'].contains(ing.colorName.toLowerCase());
            final color = isWarning ? (ing.colorName.toLowerCase() == 'red' ? scheme.error : scheme.warning) : scheme.success;

            return Padding(
              padding: EdgeInsets.only(bottom: AppSizes.p12),
              child: _IngredientRow(name: ing.name, impact: ing.colorName, color: color),
            );
          }),
        ],
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.name, required this.impact, required this.color});
  final String name;
  final String impact;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 6.0.w,
                height: 6.0.w,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              Gap.w12,
              Expanded(
                child: Text(
                  name,
                  style: context.bodyBold.copyWith(color: scheme.textPrimary, fontSize: 11.sp),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Text(
          impact.toUpperCase(),
          style: context.eyebrow.copyWith(fontSize: 8.sp, color: color, letterSpacing: 0.5),
        ),
      ],
    );
  }
}

class NutritionFactsSection extends StatelessWidget {
  const NutritionFactsSection({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final n = scanData.nutrients;

    return Container(
      margin: EdgeInsets.only(top: AppSizes.p16),
      padding: EdgeInsets.all(AppSizes.p20),
      decoration: BoxDecoration(
        color: scheme.elevatedSurface,
        borderRadius: BorderRadius.circular(AppSizes.r28),
        border: Border.all(color: scheme.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'METRICS',
                    style: context.eyebrow.copyWith(color: scheme.textSecondary.withValues(alpha: 0.6), letterSpacing: 1.2, fontSize: 9.sp),
                  ),
                  Text(AppStrings.nutritionFacts, style: context.bodyBold.copyWith(color: scheme.textPrimary, height: 1.1)),
                ],
              ),
              Icon(AppIcons.clipboardList, color: scheme.textPrimary, size: AppSizes.icon20),
            ],
          ),
          Gap.h24,
          if (n != null) ...[
            _NutrientRow(label: AppStrings.calories, value: '${n.calories ?? 0}', unit: 'kcal', color: scheme.textPrimary),
            Gap.h12,
            _NutrientRow(label: AppStrings.protein, value: '${n.proteins ?? 0}', unit: 'g', color: scheme.success),
            Gap.h12,
            _NutrientRow(label: AppStrings.totalFat, value: '${n.fat ?? 0}', unit: 'g', color: scheme.textPrimary),
            Gap.h12,
            _NutrientRow(label: AppStrings.saturatedFat, value: '${n.saturatedFat ?? 0}', unit: 'g', color: scheme.textPrimary),
            Gap.h12,
            _NutrientRow(label: AppStrings.totalCarbohydrate, value: '${n.carbs ?? 0}', unit: 'g', color: scheme.textPrimary),
            Gap.h12,
            _NutrientRow(label: AppStrings.sugars, value: '${n.sugars ?? 0}', unit: 'g', color: scheme.textPrimary),
            Gap.h12,
            _NutrientRow(label: AppStrings.fiber, value: '${n.fiber ?? 0}', unit: 'g', color: scheme.success),
            Gap.h12,
            _NutrientRow(label: AppStrings.salt, value: '${n.salt ?? 0}', unit: 'mg', color: scheme.textPrimary),
          ],
        ],
      ),
    );
  }
}

class _NutrientRow extends StatelessWidget {
  const _NutrientRow({required this.label, required this.value, required this.unit, required this.color});
  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label.toUpperCase(),
              style: context.eyebrow.copyWith(fontSize: 8.sp, color: scheme.textSecondary, letterSpacing: 0.5),
            ),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: context.caption.copyWith(fontWeight: FontWeight.w900, color: scheme.textPrimary, fontSize: 10.sp),
                  ),
                  TextSpan(
                    text: ' $unit',
                    style: context.caption.copyWith(color: scheme.textMuted, fontSize: 8.sp),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
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
        style: TextStyle(fontSize: AppSizes.s10, color: AppPalette.gray500),
      ),
    ],
  );
}

class SwapVisualization extends StatelessWidget {
  const SwapVisualization({super.key});

  @override
  Widget build(BuildContext context) => const DashboardIconVisualization(icon: AppIcons.arrowRightLeft);
}
