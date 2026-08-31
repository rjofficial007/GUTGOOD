import 'dart:ui';

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
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class BentoCard extends StatelessWidget {
  const BentoCard({super.key, required this.child, this.backgroundColor, this.borderColor, this.padding, this.borderRadius, this.height, this.width, this.showShadow = true});
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final double? height;
  final double? width;
  final bool showShadow;
  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor ?? scheme.cardBackground,
        borderRadius: BorderRadius.circular(borderRadius ?? 20),
        border: Border.all(color: borderColor ?? scheme.borderSubtle),
        boxShadow: showShadow ? [BoxShadow(color: scheme.surfaceSubtle, blurRadius: 15, offset: const Offset(0, 5))] : null,
      ),
      child: child,
    );
  }
}

class ScoreGauge extends StatelessWidget {
  const ScoreGauge({super.key, required this.score, required this.color, this.label = 'GUT SCORE', this.fontSize});
  final int score;
  final Color color;
  final String label;
  final double? fontSize;
  @override
  Widget build(BuildContext context) {
    final textColor = (color == AppPalette.darkGrey) ? AppPalette.white : AppPalette.black;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score.toDouble()),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutQuart,
      builder: (context, value, _) => LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth;

          return SizedBox(
            height: size,
            width: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(size, size),
                  painter: _GaugePainter(score: value.toInt(), color: color),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${value.toInt()}',
                      style: context.displayHero.copyWith(fontSize: fontSize ?? (size * 0.28).clamp(32, 48).sp, color: textColor),
                    ),
                    Text(
                      label,
                      style: context.captionBold.copyWith(fontSize: (size * 0.08).clamp(6, 8).sp, color: textColor.withAlpha(127)),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.score, required this.color});
  final int score;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 14.0;

    final bgPaint = Paint()
      ..color = (color == AppPalette.darkGrey ? AppPalette.white : AppPalette.black).withAlpha(26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Outer glow for the progress
    final glowPaint = Paint()
      ..color = color.withAlpha(77)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 4
      ..strokeCap = StrokeCap.round;

    // Full circle background
    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    if (score > 0) {
      // Draw progress arc starting from top (-90 degrees / -PI/2)
      const startAngle = -1.5708; // -90 degrees
      final sweepAngle = (score / 100) * 6.28319; // Full circle is 2*PI

      canvas
        ..drawArc(Rect.fromCircle(center: center, radius: radius - strokeWidth / 2), startAngle, sweepAngle, false, glowPaint)
        ..drawArc(Rect.fromCircle(center: center, radius: radius - strokeWidth / 2), startAngle, sweepAngle, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) => oldDelegate.score != score;
}

class NutrientBarChart extends StatelessWidget {
  const NutrientBarChart({super.key, required this.nutrients});
  final Map<String, double> nutrients;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [_buildBar(context, 'Sept', nutrients['protein'] ?? 0, AppPalette.purplePastel), Gap.w12, _buildBar(context, 'Nov', nutrients['fiber'] ?? 0, AppPalette.greenPastel)],
  );
  Widget _buildBar(BuildContext context, String label, double value, Color color) {
    final height = (value / 20).clamp(0.2, 1.0) * 80.h;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(label, style: context.caption.copyWith(color: AppPalette.white70)),
        Gap.h8,
        Container(
          width: 48.w,
          height: height,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        ),
      ],
    );
  }
}

class TimelineItem {
  TimelineItem({required this.title, required this.subtitle, required this.color});
  final String title;
  final String subtitle;
  final Color color;
}

class ImpactTimeline extends StatelessWidget {
  const ImpactTimeline({super.key, required this.items});
  final List<TimelineItem> items;
  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < items.length; i++) ...[_buildTimelineNode(context, scheme, items[i], i == items.length - 1)],
      ],
    );
  }

  Widget _buildTimelineNode(BuildContext context, AppColorScheme scheme, TimelineItem item, bool isLast) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: item.color,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.cardBackground, width: 2),
                boxShadow: [BoxShadow(color: item.color.withAlpha(77), blurRadius: 4)],
              ),
            ),
            if (!isLast) Expanded(child: Container(width: 2, color: scheme.borderSubtle)),
          ],
        ),
        Gap.w16,
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title.toUpperCase(),
                  style: context.caption.copyWith(fontSize: 10.sp, fontWeight: FontWeight.w900, color: scheme.textPrimary, letterSpacing: 0.5),
                ),
                Gap.h2,
                Text(
                  item.subtitle,
                  style: context.caption.copyWith(fontSize: 10.sp, color: scheme.textSecondary, height: 1.3),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class BentoImageCard extends StatelessWidget {
  const BentoImageCard({super.key, required this.scanData, this.heroTag});
  final ScanResult scanData;
  final String? heroTag;
  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final displayImageUrl = scanData.userImageUrl ?? scanData.imageUrl;
    final scoreColor = scanData.score >= 70 ? AppPalette.greenPastel : (scanData.score >= 40 ? AppPalette.purplePastel : AppPalette.red);

    return BentoCard(
      padding: const EdgeInsets.all(12),
      height: 200.h,
      backgroundColor: scheme.cardBackground,
      child: Row(
        children: [
          // Left Panel: The "Wallet Card" aesthetic
          Container(
            width: 176.h, // Matched with card height (200.h - 24 padding)
            height: 176.h,
            decoration: BoxDecoration(color: scoreColor, borderRadius: BorderRadius.circular(16)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Text(AppStrings.gutGoodScore.toUpperCase(), style: context.captionTiny.copyWith(color: AppPalette.black.withAlpha(102))),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppPalette.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppPalette.black.withAlpha(26), blurRadius: 4)],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 5,
                    left: 10,
                    child: Text('${scanData.score}', style: context.displayHero.copyWith(color: AppPalette.black, letterSpacing: -5)),
                  ),
                ],
              ),
            ),
          ),
          Gap.w16,
          // Right Panel: Narrative & Identity
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (displayImageUrl != null && displayImageUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(height: 52, width: 52, imageUrl: displayImageUrl, fit: BoxFit.cover),
                  ),
                  Gap.h12,
                ],
                Text(scanData.brand.toUpperCase(), style: context.captionBold.copyWith(color: scheme.textSecondary)),
                Gap.h4,
                Text(
                  scanData.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.headingSm.copyWith(color: scheme.textPrimary, fontWeight: FontWeight.w900),
                ),
                Gap.h8,
                Text(
                  scanData.impact,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: context.captionBold.copyWith(color: scheme.textSecondary),
                ),
              ],
            ),
          ),
          Gap.w4,
        ],
      ),
    );
  }
}

class NutrientBalanceWrap extends StatelessWidget {
  const NutrientBalanceWrap({super.key, required this.balance});
  final Map<String, dynamic> balance;
  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: balance.entries.map((e) {
        final status = e.value.toString().toLowerCase();
        final color = switch (status) {
          'good' || 'high' => AppPalette.greenPastel,
          'moderate' => AppPalette.orange,
          'low' || 'poor' => AppPalette.red,
          _ => AppPalette.gray400,
        };
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(51)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              Gap.w6,
              Text(e.key.toUpperCase(), style: context.captionBold.copyWith(color: scheme.textPrimary)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class SaveButton extends StatelessWidget {
  const SaveButton({super.key, required this.isSaved, required this.isLoading, required this.onTap});
  final bool isSaved;
  final bool isLoading;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: isLoading ? null : onTap,
    child: Container(
      width: 44.0.w,
      height: 44.0.w,
      decoration: BoxDecoration(
        color: AppPalette.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: AppPalette.black.withAlpha(13), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: isLoading
          ? const Center(
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppPalette.black)),
            )
          : Icon(isSaved ? Icons.favorite : Icons.favorite_border, color: isSaved ? AppPalette.red : AppPalette.black, size: 20),
    ),
  );
}

class ProductImageHeader extends StatelessWidget {
  const ProductImageHeader({super.key, required this.scanData, this.heroTag, this.overlay});
  final ScanResult scanData;
  final String? heroTag;
  final Widget? overlay;
  @override
  Widget build(BuildContext context) {
    final displayImageUrl = scanData.userImageUrl ?? scanData.imageUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SheetSectionHeader(title: AppStrings.foodAnalysisLabel, color: AppPalette.transparent),
        Container(
          height: 420.h,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.appColorScheme.border.withAlpha(77)),
            boxShadow: [BoxShadow(color: context.appColorScheme.surfaceSubtle, blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned.fill(
                  child: displayImageUrl != null && displayImageUrl.isNotEmpty
                      ? Hero(
                          tag: heroTag ?? '${AppStrings.scanImageHero}${scanData.barcode ?? scanData.productName}',
                          child: CachedNetworkImage(
                            imageUrl: displayImageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: context.appColorScheme.borderSubtle,
                              highlightColor: context.appColorScheme.border.withAlpha(26),
                              child: Container(color: AppPalette.white),
                            ),
                            errorWidget: (_, _, _) => Container(
                              color: context.appColorScheme.elevatedSurface,
                              child: Icon(AppIcons.utensils, size: 48, color: context.appColorScheme.textMuted),
                            ),
                          ),
                        )
                      : Container(
                          color: context.appColorScheme.elevatedSurface,
                          child: Icon(AppIcons.utensils, size: 48, color: context.appColorScheme.textMuted),
                        ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppPalette.black.withAlpha(51), AppPalette.transparent, AppPalette.black.withAlpha(178)],
                        stops: const [0.0, 0.3, 1.0],
                      ),
                    ),
                  ),
                ),
                if (overlay != null) Positioned.fill(child: overlay!),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.borderRadius, this.padding, this.backgroundColor});
  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: borderRadius ?? BorderRadius.circular(24),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(color: backgroundColor ?? AppPalette.white.withAlpha(26), borderRadius: borderRadius ?? BorderRadius.circular(24)),
        child: child,
      ),
    ),
  );
}

class ScanHeroSection extends StatelessWidget {
  const ScanHeroSection({super.key, required this.scanData, this.heroTag, this.isGlass = false});
  final ScanResult scanData;
  final String? heroTag;
  final bool isGlass;
  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final labelStyle = context.captionBold.copyWith(color: isGlass ? AppPalette.white.withAlpha(178) : scheme.textMuted);
    final valueStyle = context.bodyBold.copyWith(color: isGlass ? AppPalette.white : scheme.textPrimary, fontSize: 26.sp, letterSpacing: -1.0, fontWeight: FontWeight.w900, height: 1.0);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _MetricItem(label: 'NOVA-GROUP', value: scanData.novaGroup ?? '1', labelStyle: labelStyle, valueStyle: valueStyle),
            if (scanData.nutriscore != null)
              _MetricItem(
                label: 'NUTRI-SCORE',
                valueWidget: Text(
                  scanData.nutriscore!,
                  style: valueStyle.copyWith(color: isGlass ? AppPalette.white : (scanData.score >= 70 ? scheme.success : (scanData.score >= 40 ? const Color(0xFFC4B5FD) : scheme.error))),
                ),
                labelStyle: labelStyle,
              ),
            _MetricItem(
              label: 'IMPACT',
              value: scanData.impactType.name.toUpperCase(),
              labelStyle: labelStyle,
              valueStyle: valueStyle.copyWith(fontSize: 18.sp, letterSpacing: -0.5),
            ),
          ],
        ),
        if (scanData.allergens != null && scanData.allergens!.isNotEmpty) ...[
          Gap.h16,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isGlass ? AppPalette.white.withAlpha(38) : scheme.errorSubtle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isGlass ? AppPalette.white15 : scheme.error.withAlpha(51)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.alertTriangle, size: 14, color: isGlass ? AppPalette.white : scheme.error),
                Gap.w8,
                Text('${AppStrings.contains.toUpperCase()}: ${scanData.allergens!.toUpperCase()}', style: context.captionBold.copyWith(color: isGlass ? AppPalette.white : scheme.error)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({required this.label, this.value, this.valueWidget, required this.labelStyle, this.valueStyle});
  final String label;
  final String? value;
  final Widget? valueWidget;
  final TextStyle labelStyle;
  final TextStyle? valueStyle;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(label, style: labelStyle),
      Gap.h4,
      valueWidget ?? Text(value ?? '', style: valueStyle),
    ],
  );
}

class ScanImpactSection extends StatelessWidget {
  const ScanImpactSection({super.key, required this.title, required this.icon, required this.iconColor, required this.items, this.servingInfo});
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<TimelineItem> items;
  final String? servingInfo;
  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    return BentoCard(
      height: 240.h,
      padding: const EdgeInsets.all(20),
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
                    Text(title.toUpperCase(), style: context.captionBold.copyWith(color: scheme.textSecondary)),
                    if (servingInfo != null)
                      Text(
                        AppStrings.perServing(servingInfo!),
                        style: context.captionBold.copyWith(color: scheme.textMuted, fontSize: 10.sp),
                      ),
                  ],
                ),
              ),
              Icon(icon, color: scheme.textMuted, size: 14),
            ],
          ),
          Gap.h24,
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 24.sp, color: scheme.textMuted.withAlpha(77)),
                        Gap.h8,
                        Text('NO IMPACT DATA AVAILABLE', style: context.captionBold.copyWith(color: scheme.textMuted)),
                      ],
                    ),
                  )
                : _ScrollableBentoContent(child: ImpactTimeline(items: items)),
          ),
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
    final raw = scanData.rawData ?? {};
    final additives = scanData.additives ?? (raw['meal']?['additives'] ?? raw['scan']?['additives'] ?? raw['additives'] ?? '').toString();
    final addonList = additives.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final scheme = context.appColorScheme;

    final flagged = scanData.flaggedIngredients.isNotEmpty
        ? scanData.flaggedIngredients
        : ((raw['meal']?['flaggedIngredients'] ?? raw['scan']?['flaggedIngredients'] ?? raw['flaggedIngredients']) ?? []) as List;

    final items = <TimelineItem>[];
    for (final add in addonList) {
      items.add(TimelineItem(title: add, subtitle: 'Chemical Additive', color: scheme.warning));
    }
    for (final f in flagged) {
      final name = f is Map ? (f['name'] ?? '').toString() : f.toString();
      if (name.isNotEmpty) {
        items.add(TimelineItem(title: name, subtitle: 'Personal Sensitivity', color: scheme.error));
      }
    }

    return BentoCard(
      height: 240.h,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.whatToWatch.toUpperCase(), style: context.captionBold.copyWith(color: scheme.textSecondary)),
              Icon(AppIcons.alertTriangle, color: scheme.textMuted, size: 14),
            ],
          ),
          Gap.h24,
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppIcons.alertTriangle, size: 24.sp, color: scheme.textMuted.withAlpha(77)),
                        Gap.h8,
                        Text('NO CAUTIONS DETECTED', style: context.captionBold.copyWith(color: scheme.textMuted)),
                      ],
                    ),
                  )
                : _ScrollableBentoContent(child: ImpactTimeline(items: items)),
          ),
        ],
      ),
    );
  }
}

class _WatchingCard extends StatelessWidget {
  const _WatchingCard({required this.title, required this.subtitle, required this.icon, required this.color});
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: scheme.elevatedSurface,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: scheme.border.withAlpha(77)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              shape: BoxShape.circle,
              border: Border.all(color: color.withAlpha(51)),
            ),
            child: Icon(icon, size: 16.w, color: color),
          ),
          Gap.w16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: context.bodyBold.copyWith(fontSize: 14.sp, height: 1.1, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: scheme.textPrimary),
                ),
                Text(
                  subtitle,
                  style: context.caption.copyWith(color: scheme.textMuted, fontSize: 10.5.sp, fontWeight: FontWeight.w600, height: 1.4),
                ),
              ],
            ),
          ),
          Icon(AppIcons.chevronRight, size: 16.w, color: scheme.textMuted),
          Gap.w4,
        ],
      ),
    );
  }
}

class PersonalizedInsightCard extends StatelessWidget {
  const PersonalizedInsightCard({super.key, required this.insight});
  final String insight;
  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return BentoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.personalizedInsightLabel.toUpperCase(), style: context.captionBold.copyWith(color: scheme.textSecondary)),
              Icon(AppIcons.sparkles, color: scheme.textMuted, size: 14),
            ],
          ),
          Gap.h24,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.aiDrivenFindings.toUpperCase(), style: context.labelBold.copyWith(color: scheme.textPrimary)),
              Gap.h12,
              Text(insight, style: context.label.copyWith(height: 1.5, color: scheme.textSecondary)),
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
    return BentoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.betterSwapsLabel.toUpperCase(), style: context.captionBold.copyWith(color: scheme.textSecondary)),
              Icon(AppIcons.refreshCw, color: scheme.textMuted, size: 14),
            ],
          ),
          Gap.h24,
          SizedBox(
            height: 240.0.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: swaps.length,
              itemBuilder: (context, i) => Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: SwapCard(
                  title: swaps[i].title,
                  subtitle: swaps[i].subtitle,
                  imageKeyword: swaps[i].imageKeyword,
                  imageUrl: swaps[i].imageUrl,
                  tag: swaps[i].tag,
                  badge: swaps[i].badge,
                  isBlackBadge: swaps[i].isBlackBadge,
                  width: 150.w,
                ),
              ),
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

    final items = ingredients.map((ing) {
      final color = ['red', 'orange'].contains(ing.colorName.toLowerCase()) ? (ing.colorName.toLowerCase() == 'red' ? scheme.error : scheme.warning) : scheme.success;

      return TimelineItem(title: ing.name, subtitle: ing.impact.isNotEmpty ? ing.impact : 'Verified component', color: color);
    }).toList();

    return BentoCard(
      height: 240.h,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.ingredientsLabel.toUpperCase(), style: context.captionBold.copyWith(color: scheme.textSecondary)),
              Icon(AppIcons.leaf, color: scheme.textMuted, size: 14),
            ],
          ),
          Gap.h24,
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppIcons.leaf, size: 24.sp, color: scheme.textMuted.withAlpha(77)),
                        Gap.h8,
                        Text('NO INGREDIENTS DATA', style: context.captionBold.copyWith(color: scheme.textMuted)),
                      ],
                    ),
                  )
                : _ScrollableBentoContent(child: ImpactTimeline(items: items)),
          ),
        ],
      ),
    );
  }
}

class NutritionFactsSection extends StatelessWidget {
  const NutritionFactsSection({super.key, required this.scanData});
  final ScanResult scanData;
  @override
  Widget build(BuildContext context) {
    final n = scanData.nutrients;
    final scheme = context.appColorScheme;

    final items = <TimelineItem>[];
    if (n != null) {
      void addItem(String label, num? value, String unit, Color color) {
        if (value != null && value != 0) {
          items.add(TimelineItem(title: label, subtitle: AppStrings.valueWithUnit(value, unit), color: color));
        }
      }

      addItem(AppStrings.calories, n.calories, 'kcal', AppPalette.blue);
      addItem(AppStrings.protein, n.proteins, 'g', scheme.success);
      addItem(AppStrings.totalFat, n.fat, 'g', scheme.warning);
      addItem(AppStrings.saturatedFat, n.saturatedFat, 'g', scheme.error);
      addItem(AppStrings.totalCarbohydrate, n.carbs, 'g', AppPalette.blue);
      addItem(AppStrings.sugars, n.sugars, 'g', scheme.error);
      addItem(AppStrings.fiber, n.fiber, 'g', scheme.success);
      addItem(AppStrings.salt, n.salt, 'mg', scheme.error);
    }

    return BentoCard(
      height: 240.h,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.nutritionAnalytics.toUpperCase(), style: context.captionBold.copyWith(color: scheme.textSecondary)),
              Icon(AppIcons.activity, color: scheme.textMuted, size: 14),
            ],
          ),
          Gap.h24,
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppIcons.activity, size: 24.sp, color: scheme.textMuted.withAlpha(77)),
                        Gap.h8,
                        Text('NO NUTRITION DATA', style: context.captionBold.copyWith(color: scheme.textMuted)),
                      ],
                    ),
                  )
                : _ScrollableBentoContent(child: ImpactTimeline(items: items)),
          ),
        ],
      ),
    );
  }
}

class _ScrollableBentoContent extends StatefulWidget {
  const _ScrollableBentoContent({required this.child});
  final Widget child;

  @override
  State<_ScrollableBentoContent> createState() => _ScrollableBentoContentState();
}

class _ScrollableBentoContentState extends State<_ScrollableBentoContent> {
  final ScrollController _controller = ScrollController();
  bool _canScroll = false;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_update);
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  void _update() {
    if (!_controller.hasClients) return;
    final max = _controller.position.maxScrollExtent;
    final val = _controller.offset;
    final can = max > 10;
    final prog = max > 0 ? (val / max).clamp(0.0, 1.0) : 0.0;
    if (can != _canScroll || (prog - _progress).abs() > 0.01) {
      setState(() {
        _canScroll = can;
        _progress = prog;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(controller: _controller, physics: const BouncingScrollPhysics(), child: widget.child),
        ),
        if (_canScroll) ...[Gap.w12, _VerticalDotIndicator(progress: _progress)],
      ],
    );
  }
}

class _VerticalDotIndicator extends StatelessWidget {
  const _VerticalDotIndicator({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        bool isActive = false;
        if (progress < 0.33) {
          isActive = index == 0;
        } else if (progress < 0.66) {
          isActive = index == 1;
        } else {
          isActive = index == 2;
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 4,
          height: isActive ? 12 : 4,
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(color: isActive ? scheme.textPrimary : scheme.textMuted.withAlpha(51), borderRadius: BorderRadius.circular(4)),
        );
      }),
    );
  }
}

class MenuAnalysisSection extends StatelessWidget {
  const MenuAnalysisSection({super.key, required this.scanData});
  final ScanResult scanData;
  @override
  Widget build(BuildContext context) {
    final raw = scanData.rawData ?? {};
    final scheme = context.appColorScheme;

    List<dynamic> findList(String key) {
      if (raw[key] is List) return raw[key] as List;
      final blocks = ['menu', 'meal', 'scan', 'rawData'];
      for (final b in blocks) {
        if (raw[b] is Map && raw[b][key] is List) return raw[b][key] as List;
      }
      return [];
    }

    final menuItems = (findList('menuItems').isEmpty ? (findList('items').isEmpty ? findList('dishes') : findList('items')) : findList('menuItems'))
        .where((e) => e is Map && (e.containsKey('name') || e.containsKey('dish_name') || e.containsKey('item_name') || e.containsKey('dishName') || e.containsKey('title')))
        .toList();

    return BentoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.menuRecommendationsLabel.toUpperCase(), style: context.captionBold.copyWith(color: scheme.textSecondary)),
              Icon(AppIcons.utensils, color: scheme.textMuted, size: 14),
            ],
          ),
          Gap.h24,
          if (menuItems.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.utensils, size: 24.sp, color: scheme.textMuted.withAlpha(77)),
                    Gap.h8,
                    Text('NO RECOMMENDATIONS FOUND', style: context.captionBold.copyWith(color: scheme.textMuted)),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 200.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: menuItems.length,
                itemBuilder: (context, i) => _MenuItemCard(item: menuItems[i] is Map<String, dynamic> ? menuItems[i] : {}),
              ),
            ),
        ],
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({required this.item});
  final Map<String, dynamic> item;
  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final successColor = scheme.success;

    // 🚀 Robust Item Extraction
    final name = (item['name'] ?? item['dish_name'] ?? item['item_name'] ?? item['dishName'] ?? 'Unknown Item').toString();
    final description = (item['description'] ?? item['summary'] ?? item['about'] ?? item['desc'] ?? '').toString();
    final impact = (item['gutImpact'] ?? item['observation'] ?? item['impact'] ?? item['health_note'] ?? item['note'] ?? '').toString();
    final price = (item['price'] ?? item['cost'])?.toString();

    // 🖼️ Dynamic Image Generation via Utils
    var rawImageUrl = (item['imageUrl'] ?? item['image_url'] ?? item['image'])?.toString();
    if (rawImageUrl == 'null' || rawImageUrl == null || rawImageUrl.isEmpty) rawImageUrl = null;
    final displayImageUrl = rawImageUrl ?? getDynamicImageUrl(name);

    final rawIngredients = item['ingredients'] ?? item['components'] ?? [];
    final ingredients = rawIngredients is List ? rawIngredients : [];

    return Container(
      width: 260.w,
      margin: EdgeInsets.only(right: 16.w),
      decoration: BoxDecoration(
        color: scheme.cardBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: scheme.border.withAlpha(204)),
        boxShadow: [BoxShadow(color: scheme.surfaceSubtle, blurRadius: 20, offset: const Offset(0, 10))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Visual Element: Right-side Dynamic Image with Gradient Fade
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 140.w,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: displayImageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(color: scheme.surfaceSubtle),
                    errorWidget: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [scheme.cardBackground, scheme.cardBackground.withAlpha(204), AppPalette.transparent],
                        stops: const [0.0, 0.2, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Health Badge & Pricing
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: successColor.withAlpha(38), shape: BoxShape.circle),
                      child: Icon(AppIcons.leaf, size: 18, color: successColor),
                    ),
                    if (price != null && price != 'null' && price.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: scheme.textPrimary.withAlpha(26), borderRadius: BorderRadius.circular(100)),
                        child: Text(price, style: context.labelBold.copyWith(color: scheme.textPrimary)),
                      ),
                  ],
                ),
                Gap.h20,
                // Premium Typography: Dish Identity
                SizedBox(
                  width: 160.w,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.bodyBold.copyWith(color: scheme.textPrimary, fontSize: 16.sp, height: 1.1, letterSpacing: -0.4, fontWeight: FontWeight.w800),
                      ),
                      if (ingredients.isNotEmpty) ...[
                        Gap.h8,
                        Text(
                          'Ingredients: ${ingredients.join(", ")}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.captionBold.copyWith(color: scheme.textSecondary.withAlpha(153), fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ),
                Gap.h12,
                // Narrative Insight
                SizedBox(
                  width: 170.w,
                  child: Text(
                    impact.isNotEmpty ? impact : description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.body.copyWith(color: scheme.textSecondary, fontSize: 11.sp, height: 1.4),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CycleInsightSection extends StatelessWidget {
  const CycleInsightSection({super.key, required this.insight});
  final CycleInsight insight;
  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BentoCard(
      padding: const EdgeInsets.all(20),
      backgroundColor: isDark ? AppPalette.pink.withAlpha(26) : AppPalette.pinkLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.cycleInsightLabel.toUpperCase(), style: context.captionBold.copyWith(color: AppPalette.pink.withAlpha(178))),
              const Icon(AppIcons.sparkles, color: AppPalette.pink, size: 14),
            ],
          ),
          Gap.h24,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                insight.phase.toUpperCase(),
                style: context.headingSm.copyWith(color: AppPalette.pink, fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
              Gap.h12,
              Text(
                insight.description,
                style: context.bodySm.copyWith(color: isDark ? scheme.textSecondary : AppPalette.pink.withAlpha(204), height: 1.6, fontWeight: FontWeight.w500),
              ),
              if (insight.tags != null && insight.tags!.isNotEmpty) ...[
                Gap.h16,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: insight.tags!
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppPalette.pink.withAlpha(38),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppPalette.pink.withAlpha(51)),
                          ),
                          child: Text(tag.text, style: context.captionBold.copyWith(color: AppPalette.pink)),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class ProductMetadataSection extends StatelessWidget {
  const ProductMetadataSection({super.key, required this.scanData});
  final ScanResult scanData;
  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final date = DateFormat('MMM dd, yyyy • hh:mm a').format(scanData.createdAt);

    final items = <TimelineItem>[];
    if (scanData.barcode != null) items.add(TimelineItem(title: 'Barcode', subtitle: scanData.barcode!, color: scheme.textPrimary));
    if (scanData.source != null) items.add(TimelineItem(title: 'Source', subtitle: scanData.source!.toUpperCase(), color: scheme.textPrimary));
    items.add(TimelineItem(title: 'Analyzed On', subtitle: date, color: scheme.textPrimary));

    return BentoCard(
      height: 240.h,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.productMetadata.toUpperCase(), style: context.captionBold.copyWith(color: scheme.textSecondary)),
              Icon(AppIcons.info, color: scheme.textMuted, size: 14),
            ],
          ),
          Gap.h24,
          Expanded(
            child: _ScrollableBentoContent(child: ImpactTimeline(items: items)),
          ),
        ],
      ),
    );
  }
}

class ExpertSummaryCard extends StatelessWidget {
  const ExpertSummaryCard({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final raw = scanData.rawData ?? {};

    String? findString(String key) {
      if (raw[key] is String) return raw[key].toString();
      final blocks = ['meal', 'scan', 'rawData', 'analysis'];
      for (final b in blocks) {
        if (raw[b] is Map && raw[b][key] != null) return raw[b][key].toString();
      }
      return null;
    }

    final summaryStr = findString('summary') ?? scanData.impact;

    return BentoCard(
      padding: const EdgeInsets.all(20),
      backgroundColor: isDark ? AppPalette.purple.withAlpha(26) : AppPalette.purplePastel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.expertSummary, style: context.captionBold.copyWith(color: isDark ? AppPalette.purplePastel.withAlpha(153) : AppPalette.black.withAlpha(153))),
              Icon(AppIcons.sparkles, color: isDark ? AppPalette.purplePastel.withAlpha(102) : AppPalette.black.withAlpha(102), size: 14),
            ],
          ),
          Gap.h16,
          Text(
            summaryStr.isEmpty ? 'ANALYSIS IN PROGRESS...' : summaryStr,
            style: context.body.copyWith(color: isDark ? scheme.textPrimary : AppPalette.black, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic, height: 1.6, letterSpacing: -0.2),
          ),
        ],
      ),
    );
  }
}

class NutrientStatisticsCard extends StatelessWidget {
  const NutrientStatisticsCard({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final protein = (scanData.nutrients?.proteins ?? 0.0).toDouble();
    final fiber = (scanData.nutrients?.fiber ?? 0.0).toDouble();

    return BentoCard(
      height: 240.h,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.nutrientStatsLabel, style: context.captionBold.copyWith(color: scheme.textSecondary)),
              Icon(AppIcons.activity, color: scheme.textSecondary, size: 14),
            ],
          ),
          const Spacer(),
          if (protein == 0 && fiber == 0)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.activity, size: 24.sp, color: scheme.textMuted.withAlpha(77)),
                  Gap.h8,
                  Text('STATS NOT AVAILABLE', style: context.captionBold.copyWith(color: scheme.textMuted)),
                ],
              ),
            )
          else ...[
            Text(
              '${(protein + fiber).toStringAsFixed(1)}g',
              style: context.displayHero.copyWith(color: scheme.textPrimary, fontSize: 32.sp),
            ),
            Gap.h6,
            const Spacer(),
            NutrientBarChart(nutrients: {'protein': protein, 'fiber': fiber}),
          ],
          const Spacer(),
        ],
      ),
    );
  }
}

class MealBalanceCard extends StatelessWidget {
  const MealBalanceCard({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final raw = scanData.rawData ?? {};
    var balance = <String, dynamic>{};

    Map<String, dynamic> findMap(String key) {
      if (raw[key] is Map) return Map<String, dynamic>.from(raw[key] as Map);
      final blocks = ['menu', 'meal', 'scan', 'rawData', 'analysis', 'nutrients'];
      for (final b in blocks) {
        if (raw[b] is Map && (raw[b] as Map).containsKey(key) && raw[b][key] is Map) {
          return Map<String, dynamic>.from(raw[b][key] as Map);
        }
      }
      return <String, dynamic>{};
    }

    balance = findMap('balance').isEmpty ? findMap('nutritionalBalance') : findMap('balance');
    if (balance.isEmpty) balance = findMap('macroBalance');

    if (balance.isEmpty) {
      void search(Map<String, dynamic> m) {
        if (balance.isNotEmpty) return;
        if (m.containsKey('balance') && m['balance'] is Map) {
          balance = Map<String, dynamic>.from(m['balance'] as Map);
          return;
        }
        for (final v in m.values) {
          if (v is Map) search(Map<String, dynamic>.from(v));
          if (balance.isNotEmpty) return;
        }
      }

      search(raw);
    }

    if (balance.isEmpty) return const SizedBox.shrink();

    final items = balance.entries.map((e) {
      final status = e.value.toString().toUpperCase();
      final color = switch (status.toLowerCase()) {
        'good' || 'high' => AppPalette.greenPastel,
        'moderate' => AppPalette.orange,
        'low' || 'poor' => AppPalette.red,
        _ => AppPalette.gray400,
      };
      return TimelineItem(title: e.key, subtitle: status, color: color);
    }).toList();

    return BentoCard(
      height: 240.h,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.mealBalanceLabel, style: context.captionBold.copyWith(color: scheme.textSecondary)),
          Gap.h24,
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppIcons.utensils, size: 24.sp, color: scheme.textMuted.withAlpha(77)),
                        Gap.h8,
                        Text('BALANCE DATA NOT AVAILABLE', style: context.captionBold.copyWith(color: scheme.textMuted)),
                      ],
                    ),
                  )
                : _ScrollableBentoContent(child: ImpactTimeline(items: items)),
          ),
        ],
      ),
    );
  }
}

class ExpertStrategyCard extends StatelessWidget {
  const ExpertStrategyCard({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final raw = scanData.rawData ?? {};

    // Attempt Label-style Clinical Audit first
    final items = <TimelineItem>[];
    if (scanData.nutrientLevels != null) {
      final l = scanData.nutrientLevels!;
      if (l.sugars.toLowerCase() == 'high') items.add(TimelineItem(title: 'Sugar', subtitle: 'Inflammatory spike', color: scheme.error));
      if (l.salt.toLowerCase() == 'high') items.add(TimelineItem(title: 'Sodium', subtitle: 'Water retention', color: scheme.error));
    }
    for (final impact in scanData.impacts.take(2)) {
      var color = AppPalette.greenPastel;
      final level = impact.level.toLowerCase();
      if (level == 'high' || level == 'trigger' || level == 'negative') {
        color = AppPalette.red;
      } else if (level == 'moderate' || level == 'neutral')
        color = AppPalette.orange;
      items.add(TimelineItem(title: impact.title, subtitle: impact.level, color: color));
    }

    // Fallback to Meal Strategy logic if items empty
    if (items.isEmpty) {
      final Map<String, dynamic> meal = raw['meal'] ?? raw['scan'] ?? raw;
      final strategies = meal['workingWell'] is List ? meal['workingWell'] as List : [];
      if (strategies.isNotEmpty) {
        items.addAll(strategies.take(3).map((s) => TimelineItem(title: 'Safe', subtitle: s.toString(), color: AppPalette.greenPastel)));
      }
    }

    return BentoCard(
      height: 240.h,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.clinicalAudit, style: context.captionBold.copyWith(color: scheme.textSecondary)),
              Icon(Icons.arrow_outward, color: scheme.textMuted, size: 14),
            ],
          ),
          Gap.h24,
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_outward, size: 24.sp, color: scheme.textMuted.withAlpha(77)),
                        Gap.h8,
                        Text('STRATEGY NOT AVAILABLE', style: context.captionBold.copyWith(color: scheme.textMuted)),
                      ],
                    ),
                  )
                : _ScrollableBentoContent(child: ImpactTimeline(items: items)),
          ),
        ],
      ),
    );
  }
}

class DashboardMetricGrid extends StatelessWidget {
  const DashboardMetricGrid({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final raw = scanData.rawData ?? {};
    final isMenu = scanData.detailRoute == '/menu-result';

    final metric1 = isMenu
        ? _MetricData('Dishes', '${((raw['menu'] ?? raw)['menuItems'] ?? (raw['menu'] ?? raw)['items'] ?? []).length}', 'DETECTED')
        : _MetricData('Calories', '${scanData.nutrients?.calories ?? 0}', 'KCAL');

    final metric2 = isMenu ? _MetricData('Venue', 'CAFE', 'TYPE') : _MetricData('Safety', '${scanData.score}%', 'SCORE');

    final metric3 = isMenu
        ? _MetricData('Allergens', '${scanData.allergens?.split(',').where((e) => e.trim().isNotEmpty).length ?? 0}', 'TOTAL')
        : _MetricData('Additives', '${scanData.additives?.split(',').where((e) => e.trim().isNotEmpty).length ?? 0}', 'DETECTED');

    final metric4 = _MetricData('Nova', '${scanData.novaGroup ?? 1}', 'GROUP');

    return Row(
      children: [
        Expanded(child: _SmallMetricCard(data: metric1)),
        Gap.w12,
        Expanded(child: _SmallMetricCard(data: metric2)),
        Gap.w12,
        Expanded(child: _SmallMetricCard(data: metric3)),
        Gap.w12,
        Expanded(child: _SmallMetricCard(data: metric4)),
      ],
    );
  }
}

class _MetricData {
  _MetricData(this.label, this.value, this.unit);
  final String label;
  final String value;
  final String unit;
}

class _SmallMetricCard extends StatelessWidget {
  const _SmallMetricCard({required this.data});
  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return BentoCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(data.label.toUpperCase(), style: context.captionBold.copyWith(color: scheme.textSecondary)),
          Gap.h8,
          Text(
            data.value,
            style: context.headingSm.copyWith(fontWeight: FontWeight.w900, color: scheme.textPrimary),
          ),
          Gap.h2,
          Text(data.unit, style: context.captionMicro.copyWith(color: scheme.textMuted)),
        ],
      ),
    );
  }
}

class AllergensSection extends StatelessWidget {
  const AllergensSection({super.key, required this.allergens, this.servingSize});
  final String allergens;
  final String? servingSize;
  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final allergenList = allergens.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    final items = <TimelineItem>[];
    for (final allergen in allergenList) {
      items.add(TimelineItem(title: allergen.toUpperCase(), subtitle: AppStrings.inflammatoryTrigger, color: scheme.error));
    }

    return BentoCard(
      height: 240.h,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.safetyAuditLabel.toUpperCase(), style: context.captionBold.copyWith(color: scheme.textSecondary)),
                  if (servingSize != null)
                    Text(
                      AppStrings.analyzedPer(servingSize!),
                      style: context.captionBold.copyWith(color: scheme.textMuted, fontSize: 10.sp),
                    ),
                ],
              ),
              // Icon(AppIcons.alertTriangle, color: scheme.textMuted, size: 14),
            ],
          ),
          Gap.h24,
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppIcons.alertTriangle, size: 24.sp, color: scheme.textMuted.withAlpha(77)),
                        Gap.h8,
                        Text('NO COMMON ALLERGENS', style: context.captionBold.copyWith(color: scheme.textMuted)),
                      ],
                    ),
                  )
                : _ScrollableBentoContent(child: ImpactTimeline(items: items)),
          ),
        ],
      ),
    );
  }
}
