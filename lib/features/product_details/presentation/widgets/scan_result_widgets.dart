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
import 'package:gutgood/core/utils/extensions.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class BentoCard extends StatelessWidget {
  const BentoCard({super.key, required this.child, this.backgroundColor, this.padding, this.borderRadius, this.height, this.width, this.showShadow = true});
  final Widget child;
  final Color? backgroundColor;
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
        border: Border.all(color: scheme.border.withValues(alpha: 0.5)),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: scheme.textPrimary.withValues(alpha: 0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

class ScoreGauge extends StatelessWidget {
  const ScoreGauge({super.key, required this.score, required this.color});
  final int score;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final textColor = (color == const Color(0xFF181818)) ? Colors.white : AppPalette.black;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score.toDouble()),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutQuart,
      builder: (context, value, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final double size = constraints.maxWidth;

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
                        style: context.displaySm.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: (size * 0.28).clamp(32, 48).sp,
                          color: textColor,
                          height: 1.0,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        'GUT SCORE',
                        style: context.caption.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 7.sp,
                          letterSpacing: 1.5,
                          color: textColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
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
    final strokeWidth = 14.0;

    final bgPaint =
        Paint()
          ..color = (color == const Color(0xFF181818) ? Colors.white : AppPalette.black).withValues(alpha: 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    final progressPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    // Outer glow for the progress
    final glowPaint =
        Paint()
          ..color = color.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 4
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    // Full circle background
    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    if (score > 0) {
      // Draw progress arc starting from top (-90 degrees / -PI/2)
      const startAngle = -1.5708; // -90 degrees
      final sweepAngle = (score / 100) * 6.28319; // Full circle is 2*PI

      canvas.drawArc(Rect.fromCircle(center: center, radius: radius - strokeWidth / 2), startAngle, sweepAngle, false, glowPaint);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius - strokeWidth / 2), startAngle, sweepAngle, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) => oldDelegate.score != score;
}

class NutrientBarChart extends StatelessWidget {
  const NutrientBarChart({super.key, required this.nutrients});
  final Map<String, double> nutrients;
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [_buildBar('Sept', nutrients['protein'] ?? 0, const Color(0xFFC4B5FD)), Gap.w12, _buildBar('Nov', nutrients['fiber'] ?? 0, const Color(0xFFB4F1B4))]);
  Widget _buildBar(String label, double value, Color color) {
    final height = (value / 20).clamp(0.2, 1.0) * 80.h;
    return Column(mainAxisAlignment: MainAxisAlignment.end, children: [Text(label, style: TextStyle(color: Colors.white70, fontSize: 10.sp, fontWeight: FontWeight.w500)), Gap.h8, Container(width: 48.w, height: height, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)))]);
  }
}

class TimelineItem {
  final String title, subtitle;
  final Color color;
  TimelineItem({required this.title, required this.subtitle, required this.color});
}

class ImpactTimeline extends StatelessWidget {
  const ImpactTimeline({super.key, required this.items});
  final List<TimelineItem> items;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [for (int i = 0; i < items.length; i++) ...[_buildTimelineNode(items[i], i == items.length - 1)]]);
  Widget _buildTimelineNode(TimelineItem item, bool isLast) => IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Column(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: item.color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: item.color.withOpacity(0.3), blurRadius: 4)])), if (!isLast) Expanded(child: Container(width: 2, color: AppPalette.gray200))]), Gap.w16, Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.title.toUpperCase(), style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w900, color: AppPalette.black, letterSpacing: 0.5)), Gap.h4, Text(item.subtitle, style: TextStyle(fontSize: 10.sp, color: AppPalette.gray500, height: 1.4))])))]));
}

class BentoImageCard extends StatelessWidget {
  const BentoImageCard({super.key, required this.scanData, this.heroTag});
  final ScanResult scanData;
  final String? heroTag;
  @override
  Widget build(BuildContext context) {
    final displayImageUrl = scanData.userImageUrl ?? scanData.imageUrl;
    final Color scoreColor = scanData.score >= 70 ? const Color(0xFFB4F1B4) : (scanData.score >= 40 ? AppPalette.orange : AppPalette.red);

    return BentoCard(
      padding: const EdgeInsets.all(12),
      height: 220.h,
      backgroundColor: const Color(0xFF0D0D0D),
      child: Row(
        children: [
          // Left Panel: The "Wallet Card" aesthetic
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(color: scoreColor, borderRadius: BorderRadius.circular(20)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    if (displayImageUrl != null && displayImageUrl.isNotEmpty)
                      Positioned.fill(
                        child: Hero(
                          tag: heroTag ?? '${AppStrings.scanImageHero}${scanData.barcode ?? scanData.productName}',
                          child: Opacity(
                            opacity: 0.15,
                            child: CachedNetworkImage(imageUrl: displayImageUrl, fit: BoxFit.cover, color: Colors.black, colorBlendMode: BlendMode.saturation),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Text(
                        'ANALYSIS',
                        style: TextStyle(color: Colors.black.withOpacity(0.4), fontSize: 8.sp, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]),
                      ),
                    ),
                    Positioned(
                      bottom: -10,
                      left: 10,
                      child: Text(
                        '${scanData.score}',
                        style: TextStyle(color: Colors.black, fontSize: 84.sp, fontWeight: FontWeight.w900, letterSpacing: -6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Gap.w20,
          // Right Panel: Narrative & Identity
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  scanData.brand.toUpperCase(),
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9.sp, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                ),
                Gap.h8,
                Text(
                  scanData.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.bodyBold.copyWith(color: Colors.white, fontSize: 17.sp, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -0.5),
                ),
                Gap.h12,
                Text(
                  scanData.impact,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: context.caption.copyWith(color: Colors.white.withOpacity(0.5), fontSize: 10.sp, height: 1.4),
                ),
              ],
            ),
          ),
          Gap.w8,
        ],
      ),
    );
  }
}

class NutrientBalanceWrap extends StatelessWidget {
  const NutrientBalanceWrap({super.key, required this.balance});
  final Map<String, dynamic> balance;
  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, children: balance.entries.map((e) {
    final status = e.value.toString().toLowerCase();
    final Color color = switch (status) { 'good' || 'high' => const Color(0xFFB4F1B4), 'moderate' => AppPalette.orange, 'low' || 'poor' => AppPalette.red, _ => AppPalette.gray400 };
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))), child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), Gap.w6, Text(e.key.toUpperCase(), style: context.caption.copyWith(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 8.sp))]));
  }).toList());
}

class SaveButton extends StatelessWidget {
  const SaveButton({super.key, required this.isSaved, required this.isLoading, required this.onTap});
  final bool isSaved, isLoading;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: isLoading ? null : onTap, child: Container(width: 44.0.w, height: 44.0.w, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]), child: isLoading ? Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppPalette.black))) : Icon(isSaved ? Icons.favorite : Icons.favorite_border, color: isSaved ? AppPalette.red : AppPalette.black, size: 20)));
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
        const SheetSectionHeader(title: 'FOOD ANALYSIS', color: Colors.transparent),
        Container(
          height: 420.h,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: context.appColorScheme.textPrimary.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned.fill(
                  child:
                      displayImageUrl != null && displayImageUrl.isNotEmpty
                          ? Hero(
                            tag:
                                heroTag ??
                                '${AppStrings.scanImageHero}${scanData.barcode ?? scanData.productName}',
                            child: CachedNetworkImage(
                              imageUrl: displayImageUrl,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => Shimmer.fromColors(
                                    baseColor: context.appColorScheme.border.withOpacity(0.2),
                                    highlightColor: context.appColorScheme.border.withOpacity(0.1),
                                    child: Container(color: Colors.white),
                                  ),
                              errorWidget:
                                  (_, _, _) => Container(
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
                        colors: [Colors.black.withOpacity(0.2), Colors.transparent, Colors.black.withOpacity(0.7)],
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
  Widget build(BuildContext context) => ClipRRect(borderRadius: borderRadius ?? BorderRadius.circular(24), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), child: Container(padding: padding ?? const EdgeInsets.all(16), decoration: BoxDecoration(color: backgroundColor ?? Colors.white.withOpacity(0.1), borderRadius: borderRadius ?? BorderRadius.circular(24)), child: child)));
}

class ScanHeroSection extends StatelessWidget {
  const ScanHeroSection({super.key, required this.scanData, this.heroTag, this.isGlass = false});
  final ScanResult scanData;
  final String? heroTag;
  final bool isGlass;
  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final labelStyle = context.caption.copyWith(color: isGlass ? Colors.white.withOpacity(0.7) : scheme.textMuted, fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: 9.sp);
    final valueStyle = context.bodyBold.copyWith(color: isGlass ? Colors.white : scheme.textPrimary, fontSize: 24.sp, letterSpacing: -0.5, fontWeight: FontWeight.w900);
    return Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_MetricItem(label: 'NOVA-GROUP', value: scanData.novaGroup ?? '1', labelStyle: labelStyle, valueStyle: valueStyle), if (scanData.nutriscore != null) _MetricItem(label: 'NUTRI-SCORE', valueWidget: Text(scanData.nutriscore!, style: valueStyle.copyWith(color: isGlass ? Colors.white : (scanData.score >= 70 ? scheme.success : (scanData.score >= 40 ? scheme.warning : scheme.error)))), labelStyle: labelStyle), _MetricItem(label: 'GUT-SCORE', valueWidget: Text('${scanData.score}', style: valueStyle.copyWith(color: isGlass ? Colors.white : (scanData.score >= 70 ? scheme.success : (scanData.score >= 40 ? scheme.warning : scheme.error)))), labelStyle: labelStyle)]), if (scanData.allergens != null && scanData.allergens!.isNotEmpty) ...[Gap.h16, Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: isGlass ? Colors.white.withOpacity(0.15) : scheme.error.withOpacity(0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: isGlass ? Colors.white24 : scheme.error.withOpacity(0.2))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(AppIcons.alertTriangle, size: 14, color: isGlass ? Colors.white : scheme.error), Gap.w8, Text('CONTAINS: ${scanData.allergens!.toUpperCase()}', style: context.caption.copyWith(color: isGlass ? Colors.white : scheme.error, fontWeight: FontWeight.w900, fontSize: 10.sp, letterSpacing: 0.5))]))]]);
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
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [Text(label, style: labelStyle), Gap.h4, valueWidget ?? Text(value ?? '', style: valueStyle)]);
}

class ScanImpactSection extends StatelessWidget {
  const ScanImpactSection({super.key, required this.title, required this.icon, required this.iconColor, required this.items, this.servingInfo});
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<ScanImpactDetailItem> items;
  final String? servingInfo;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [SheetSectionHeader(title: title, color: Colors.transparent), if (servingInfo != null) ...[Text('Per serving ($servingInfo)', style: context.caption.copyWith(color: context.appColorScheme.textMuted)), Gap.h16], DashboardCard(child: Padding(padding: EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p8), child: Column(children: [for (int i = 0; i < items.length; i++) ...[items[i], if (i < items.length - 1) Divider(height: 1, color: context.appColorScheme.border.withOpacity(0.15))]])))]);
}

class ScanImpactDetailItem extends StatelessWidget {
  const ScanImpactDetailItem({super.key, required this.title, required this.subtitle, required this.icon, required this.value, required this.color, this.showCheck = false, this.isLast = false});
  final String title, subtitle, value;
  final IconData icon;
  final Color color;
  final bool showCheck, isLast;
  @override
  Widget build(BuildContext context) => Padding(padding: EdgeInsets.symmetric(vertical: AppSizes.p12), child: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.08), shape: BoxShape.circle), child: Icon(icon, color: color, size: 16)), Gap.w16, Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title.capitalize, style: context.bodyBold.copyWith(color: context.appColorScheme.textPrimary, fontSize: 14.sp)), if (subtitle.isNotEmpty) ...[Gap.h2, Text(subtitle, style: context.caption.copyWith(color: context.appColorScheme.textMuted, fontSize: 11.sp, height: 1.3))]])), Text(value, style: context.bodyBold.copyWith(color: context.appColorScheme.textPrimary, fontSize: 14.sp))]));
}

class AdditivesSection extends StatelessWidget {
  const AdditivesSection({super.key, required this.scanData});
  final ScanResult scanData;
  @override
  Widget build(BuildContext context) {
    final additives = scanData.additives ?? '';
    final count = additives.split(',').where((e) => e.trim().isNotEmpty).length;
    final scheme = context.appColorScheme;
    var riskColor = scheme.success;
    var riskLabel = 'CLEAN';
    if (count > 0) { riskColor = scheme.warning; riskLabel = count > 3 ? 'CAUTION' : 'MODERATE'; }
    if (count > 5 || scanData.novaGroup == '4') { riskColor = scheme.error; riskLabel = 'AVOID'; }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SheetSectionHeader(title: 'WHAT TO WATCH', color: Colors.transparent),
      DashboardCard(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p8),
          child: Column(
            children: [
              ScanImpactDetailItem(title: AppStrings.additivesLabel, subtitle: count > 0 ? 'Contains $count chemical additives' : 'No harmful additives detected', icon: AppIcons.flaskConical, value: count > 0 ? '$count TOTAL' : 'NONE', color: riskColor),
              if (scanData.flaggedIngredients.isNotEmpty) ...[
                Divider(height: 1, color: scheme.border.withOpacity(0.1)),
                ScanImpactDetailItem(title: 'Flagged Items', subtitle: '${scanData.flaggedIngredients.length} matches your sensitivities', icon: AppIcons.alertCircle, value: riskLabel, color: scheme.error),
              ]
            ],
          ),
        ),
      ),
    ]);
  }
}

class PersonalizedInsightCard extends StatelessWidget {
  const PersonalizedInsightCard({super.key, required this.insight});
  final String insight;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetSectionHeader(title: 'PERSONALIZED INSIGHT', color: Colors.transparent),
          DashboardCard(
            child: Padding(
              padding: EdgeInsets.all(AppSizes.p20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(AppIcons.sparkles, color: context.appColorScheme.textPrimary, size: 18),
                      Gap.w12,
                      Text(
                        'AI ANALYSIS',
                        style: context.bodyBold.copyWith(color: context.appColorScheme.textPrimary, fontSize: 13.sp),
                      ),
                    ],
                  ),
                  Gap.h12,
                  Text(
                    insight,
                    style: context.body.copyWith(fontSize: 13.sp, height: 1.5, color: context.appColorScheme.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}

class BetterSwapsCarousel extends StatelessWidget {
  const BetterSwapsCarousel({super.key, required this.swaps});
  final List<ProductSwap> swaps;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SheetSectionHeader(title: AppStrings.betterSwapsLabel, color: Colors.transparent), SizedBox(height: 100.0.h, child: ListView.builder(scrollDirection: Axis.horizontal, clipBehavior: Clip.none, itemCount: swaps.length, itemBuilder: (context, i) => _SwapCard(swap: swaps[i])))]);
}

class _SwapCard extends StatelessWidget {
  const _SwapCard({required this.swap});
  final ProductSwap swap;
  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Container(
      width: 240.0.w,
      margin: EdgeInsets.only(right: AppSizes.p16),
      padding: EdgeInsets.all(AppSizes.p12),
      decoration: BoxDecoration(
        color: scheme.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.r20),
        border: Border.all(color: scheme.border.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: scheme.textPrimary.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50.0.w,
            height: 70.0.h,
            decoration: BoxDecoration(color: scheme.elevatedSurface, borderRadius: BorderRadius.circular(AppSizes.r12)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.r12),
              child: swap.imageUrl != null && swap.imageUrl!.isNotEmpty ? CachedNetworkImage(imageUrl: swap.imageUrl!, fit: BoxFit.contain) : Icon(AppIcons.package, color: scheme.textMuted),
            ),
          ),
          Gap.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(swap.title, style: context.bodyBold.copyWith(fontSize: 12.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(swap.subtitle, style: context.caption.copyWith(color: scheme.textMuted, fontSize: 10.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
                Gap.h8,
                Row(
                  children: [
                    Icon(AppIcons.trendingUp, size: 10.sp, color: scheme.success),
                    Gap.w4,
                    Text(
                      'BETTER CHOICE',
                      style: context.eyebrow.copyWith(color: scheme.success, fontSize: 8.sp, letterSpacing: 0.5),
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
}

class IngredientsSection extends StatelessWidget {
  const IngredientsSection({super.key, required this.ingredients, required this.scanData});
  final List<Ingredient> ingredients;
  final ScanResult scanData;
  @override
  Widget build(BuildContext context) => DashboardCard(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.p20),
          child: RichText(
            text: TextSpan(
              children: [
                for (int i = 0; i < ingredients.length; i++) ...[
                  TextSpan(
                    text: ingredients[i].name.capitalize,
                    style: context.body.copyWith(
                      color: ['red', 'orange'].contains(ingredients[i].colorName.toLowerCase()) ? (ingredients[i].colorName.toLowerCase() == 'red' ? context.appColorScheme.error : context.appColorScheme.warning) : context.appColorScheme.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                  if (i < ingredients.length - 1) TextSpan(text: ', ', style: context.body.copyWith(color: context.appColorScheme.textMuted, fontSize: 14.sp)),
                ]
              ],
            ),
          ),
        ),
      );
}

class NutritionFactsSection extends StatelessWidget {
  const NutritionFactsSection({super.key, required this.scanData});
  final ScanResult scanData;
  @override
  Widget build(BuildContext context) {
    final n = scanData.nutrients;
    if (n == null) return const SizedBox.shrink();
    final scheme = context.appColorScheme;

    final List<Widget> items = [];
    void addItem(String label, num? value, String unit, IconData icon, {Color? color}) {
      if (value != null && value != 0) {
        final statusColor = color ?? scheme.textPrimary;
        items.add(Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: scheme.elevatedSurface,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: scheme.border.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                ),
                child: Icon(icon, size: 14.w, color: statusColor),
              ),
              Gap.w16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: context.bodyBold.copyWith(fontSize: 13.sp, height: 1.1)),
                    Text('$value $unit', style: context.caption.copyWith(color: scheme.textMuted, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Icon(AppIcons.chevronRight, size: 14.w, color: scheme.textMuted),
              Gap.w4,
            ],
          ),
        ));
      }
    }

    addItem(AppStrings.calories, n.calories, 'kcal', AppIcons.zap, color: AppPalette.blue);
    addItem(AppStrings.protein, n.proteins, 'g', AppIcons.dumbbell, color: scheme.success);
    addItem(AppStrings.totalFat, n.fat, 'g', AppIcons.droplet, color: scheme.warning);
    addItem(AppStrings.saturatedFat, n.saturatedFat, 'g', AppIcons.alertTriangle, color: scheme.error);
    addItem(AppStrings.totalCarbohydrate, n.carbs, 'g', AppIcons.wheat, color: AppPalette.blue);
    addItem(AppStrings.sugars, n.sugars, 'g', AppIcons.candy, color: scheme.error);
    addItem(AppStrings.fiber, n.fiber, 'g', AppIcons.leaf, color: scheme.success);
    addItem(AppStrings.salt, n.salt, 'mg', AppIcons.flaskConical, color: scheme.error);

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardCard(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(AppIcons.activity, size: 18.w, color: scheme.textPrimary),
                    Gap.w12,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NUTRITION ANALYTICS', style: context.bodyBold.copyWith(fontSize: 14.sp)),
                          Text('Scientific distribution', style: context.caption.copyWith(color: scheme.textMuted, fontSize: 10.sp)),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(color: scheme.textPrimary.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: Icon(AppIcons.trendingUp, size: 12.w, color: scheme.textPrimary),
                    ),
                  ],
                ),
                Gap.h20,
                ...items,
              ],
            ),
          ),
        ),
      ],
    );
  }
}


class MenuAnalysisSection extends StatelessWidget {
  const MenuAnalysisSection({super.key, required this.scanData});
  final ScanResult scanData;
  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> raw = scanData.rawData ?? {};
    final Map<String, dynamic> contextBlock = raw.containsKey('rawData') && raw['rawData'] is Map ? Map<String, dynamic>.from(raw['rawData'] as Map) : raw;
    final Map<String, dynamic> scanBlock = contextBlock.containsKey('scan') && contextBlock['scan'] is Map ? Map<String, dynamic>.from(contextBlock['scan'] as Map) : {};
    final Map<String, dynamic> menuBlock = contextBlock.containsKey('menu') && contextBlock['menu'] is Map ? Map<String, dynamic>.from(contextBlock['menu'] as Map) : (scanBlock.isNotEmpty ? scanBlock : contextBlock);
    final Map<String, dynamic> mealBlock = contextBlock.containsKey('meal') && contextBlock['meal'] is Map ? Map<String, dynamic>.from(contextBlock['meal'] as Map) : (scanBlock.isNotEmpty ? scanBlock : contextBlock);
    final restaurantName = menuBlock['restaurantName']?.toString() ?? scanBlock['restaurantName']?.toString() ?? contextBlock['restaurantName']?.toString() ?? scanData.productName;
    final List menuItems = menuBlock['menuItems'] is List ? menuBlock['menuItems'] as List : (scanBlock['menuItems'] is List ? scanBlock['menuItems'] as List : (mealBlock['items'] is List ? mealBlock['items'] as List : (contextBlock['menuItems'] is List ? contextBlock['menuItems'] as List : [])));
    final location = menuBlock['location'] ?? scanBlock['location'] ?? contextBlock['location'];
    final detectedText = menuBlock['detectedText'] ?? scanBlock['detectedText'] ?? contextBlock['detectedText'];
    final List workingWell = mealBlock['workingWell'] is List ? mealBlock['workingWell'] as List : (scanBlock['workingWell'] is List ? scanBlock['workingWell'] as List : (contextBlock['workingWell'] is List ? contextBlock['workingWell'] as List : []));
    final List missing = mealBlock['missingOrCouldAdd'] is List ? mealBlock['missingOrCouldAdd'] as List : (scanBlock['missingOrCouldAdd'] is List ? scanBlock['missingOrCouldAdd'] as List : (contextBlock['missingOrCouldAdd'] is List ? contextBlock['missingOrCouldAdd'] as List : []));
    final List sensitivities = mealBlock['sensitivityNotes'] is List ? mealBlock['sensitivityNotes'] as List : (scanBlock['sensitivityNotes'] is List ? scanBlock['sensitivityNotes'] as List : (contextBlock['sensitivityNotes'] is List ? contextBlock['sensitivityNotes'] as List : []));
    final Map<String, dynamic> balance = mealBlock['balance'] is Map ? Map<String, dynamic>.from(mealBlock['balance'] as Map) : {};
    final String? summary = mealBlock['summary']?.toString() ?? scanBlock['summary']?.toString() ?? contextBlock['summary']?.toString();

    if (menuItems.isEmpty && (detectedText == null || detectedText.toString().isEmpty) && summary == null && balance.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (summary != null && summary.isNotEmpty) ...[
          const SheetSectionHeader(title: 'EXPERT SUMMARY', color: Colors.transparent),
          DashboardCard(
            child: Padding(
              padding: EdgeInsets.all(AppSizes.p20),
              child: Text(summary, style: context.body.copyWith(fontSize: 14.sp, height: 1.5, color: context.appColorScheme.textPrimary)),
            ),
          ),
          Gap.h32,
        ],
        if (balance.isNotEmpty) ...[
          const SheetSectionHeader(title: 'MEAL BALANCE', color: Colors.transparent),
          DashboardCard(
            child: Padding(
              padding: EdgeInsets.all(AppSizes.p20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NUTRITIONAL EQUILIBRIUM FOR THIS CHOICE', style: context.caption.copyWith(color: context.appColorScheme.textMuted, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  Gap.h16,
                  NutrientBalanceWrap(balance: balance),
                ],
              ),
            ),
          ),
          Gap.h32,
        ],
        if (workingWell.isNotEmpty || missing.isNotEmpty || sensitivities.isNotEmpty) ...[
          const SheetSectionHeader(title: 'DINING STRATEGY', color: Colors.transparent),
          DashboardCard(
            child: Padding(
              padding: EdgeInsets.all(AppSizes.p20),
              child: _MenuStrategyCard(workingWell: workingWell, missing: missing, sensitivities: sensitivities),
            ),
          ),
          Gap.h32,
        ],
        const SheetSectionHeader(title: 'MENU RECOMMENDATIONS', color: Colors.transparent),
        if (restaurantName != null && restaurantName != 'Unknown') ...[
          Text(restaurantName.toUpperCase(), style: context.bodyBold.copyWith(color: context.appColorScheme.textPrimary, fontSize: 16.sp, letterSpacing: -0.5)),
          if (location != null) ...[
            Gap.h4,
            Row(children: [Icon(AppIcons.mapPin, size: 12, color: context.appColorScheme.textMuted), Gap.w4, Text(location.toString(), style: context.caption.copyWith(color: context.appColorScheme.textMuted))]),
          ],
          Gap.h20,
        ],
        if (menuItems.isNotEmpty) ...[
          for (int i = 0; i < menuItems.length; i++) ...[
            _MenuItemTile(item: menuItems[i] is Map<String, dynamic> ? menuItems[i] : {}),
            if (i < menuItems.length - 1) Divider(height: 32, color: context.appColorScheme.border.withOpacity(0.1)),
          ]
        ] else if (detectedText != null) ...[
          DashboardCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(detectedText.toString(), style: context.body.copyWith(fontSize: 13.sp, color: context.appColorScheme.textSecondary)),
            ),
          ),
        ]
      ],
    );
  }
}

class _MenuStrategyCard extends StatelessWidget {
  const _MenuStrategyCard({required this.workingWell, required this.missing, required this.sensitivities});
  final List workingWell, missing, sensitivities;
  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (workingWell.isNotEmpty) ...[_StrategyItem(title: 'Safe Bets', items: workingWell, icon: AppIcons.checkCircle, color: scheme.success), if (missing.isNotEmpty || sensitivities.isNotEmpty) Divider(height: 32, color: scheme.border.withOpacity(0.1))], if (missing.isNotEmpty) ...[_StrategyItem(title: 'Better with...', items: missing, icon: AppIcons.plusCircle, color: AppPalette.blue), if (sensitivities.isNotEmpty) Divider(height: 32, color: scheme.border.withOpacity(0.1))], if (sensitivities.isNotEmpty) ...[_StrategyItem(title: 'Watch out for', items: sensitivities, icon: AppIcons.alertTriangle, color: scheme.warning)]]);
  }
}

class _StrategyItem extends StatelessWidget {
  const _StrategyItem({required this.title, required this.items, required this.icon, required this.color});
  final String title;
  final List items;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, size: 14, color: color), Gap.w8, Text(title.toUpperCase(), style: context.caption.copyWith(fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5))]), Gap.h8, Text(items.join(' • '), style: context.body.copyWith(fontSize: 13.sp, color: context.appColorScheme.textPrimary, height: 1.4))]);
}

class _MenuItemTile extends StatelessWidget {
  const _MenuItemTile({required this.item});
  final Map<String, dynamic> item;
  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final name = item['name'] ?? 'Unknown Item';
    final description = item['description'] ?? '';
    final impact = item['gutImpact'] ?? item['observation'] ?? '';
    final price = item['price'];
    final List ingredients = item['ingredients'] ?? [];
    final List tags = item['dietaryTags'] ?? [];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(name.toString().toUpperCase(), style: context.bodyBold.copyWith(letterSpacing: 0.5, fontSize: 14.sp))), if (price != null) Text(price.toString(), style: context.caption.copyWith(fontWeight: FontWeight.w900, color: scheme.textPrimary))]), if (description.isNotEmpty) ...[Gap.h8, Text(description.toString(), style: context.caption.copyWith(color: scheme.textSecondary, height: 1.4, fontSize: 12.sp))], if (tags.isNotEmpty) ...[Gap.h12, Wrap(spacing: 8, runSpacing: 8, children: tags.map((tag) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: scheme.textPrimary.withOpacity(0.05), borderRadius: BorderRadius.circular(8)), child: Text(tag.toString().toUpperCase(), style: context.caption.copyWith(fontSize: 9.sp, fontWeight: FontWeight.bold, color: scheme.textPrimary)))).toList())], if (ingredients.isNotEmpty) ...[Gap.h12, Text('Ingredients: ${ingredients.join(', ')}', style: context.caption.copyWith(color: scheme.textMuted, fontSize: 11.sp, fontStyle: FontStyle.italic))], if (impact.isNotEmpty) ...[Gap.h12, Row(children: [Icon(AppIcons.salad, size: 14, color: scheme.success), Gap.w8, Expanded(child: Text(impact.toString(), style: context.caption.copyWith(color: scheme.success, fontWeight: FontWeight.bold, fontSize: 11.sp)))])], Gap.h12]);
  }
}

class CycleInsightSection extends StatelessWidget {
  const CycleInsightSection({super.key, required this.insight});
  final CycleInsight insight;
  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SheetSectionHeader(title: 'CYCLE INSIGHT', color: Colors.transparent),
        DashboardCard(
          child: Padding(
            padding: EdgeInsets.all(AppSizes.p20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(AppIcons.sparkles, color: Colors.purple, size: 18),
                    Gap.w12,
                    Text(
                      insight.phase.toUpperCase(),
                      style: context.headingSm.copyWith(color: scheme.textPrimary, fontWeight: FontWeight.w900, fontSize: 18.sp),
                    ),
                  ],
                ),
                Gap.h12,
                Text(
                  insight.description,
                  style: context.body.copyWith(color: scheme.textSecondary, height: 1.5, fontSize: 13.sp),
                ),
                if (insight.tags != null && insight.tags!.isNotEmpty) ...[
                  Gap.h12,
                  Wrap(
                    spacing: AppSizes.p8,
                    runSpacing: AppSizes.p8,
                    children:
                        insight.tags!
                            .map(
                              (tag) => Container(
                                padding: EdgeInsets.symmetric(horizontal: AppSizes.p10, vertical: AppSizes.p4),
                                decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(AppSizes.r8)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [Text(tag.text, style: context.caption.copyWith(color: Colors.purple, fontWeight: FontWeight.bold))],
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
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

    final List<Widget> items = [];
    void addItem(String label, String value, IconData icon) {
      items.add(Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: scheme.elevatedSurface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: scheme.border.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: scheme.textPrimary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(color: scheme.border.withValues(alpha: 0.5)),
              ),
              child: Icon(icon, size: 14.w, color: scheme.textPrimary),
            ),
            Gap.w16,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: context.bodyBold.copyWith(fontSize: 13.sp, height: 1.1)),
                  Text(value, style: context.caption.copyWith(color: scheme.textMuted, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Icon(AppIcons.chevronRight, size: 14.w, color: scheme.textMuted),
            Gap.w4,
          ],
        ),
      ));
    }

    if (scanData.barcode != null) addItem('Barcode', scanData.barcode!, AppIcons.barcode);
    if (scanData.source != null) addItem('Source', scanData.source!.toUpperCase(), AppIcons.database);
    addItem('Analyzed On', date, AppIcons.clock);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardCard(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(AppIcons.info, size: 18.w, color: scheme.textPrimary),
                    Gap.w12,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PRODUCT METADATA', style: context.bodyBold.copyWith(fontSize: 14.sp)),
                          Text('Technical verification', style: context.caption.copyWith(color: scheme.textMuted, fontSize: 10.sp)),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(color: scheme.textPrimary.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: Icon(AppIcons.checkCircle, size: 12.w, color: scheme.textPrimary),
                    ),
                  ],
                ),
                Gap.h20,
                ...items,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.label, required this.value, this.isLast = false});
  final String label, value;
  final bool isLast;
  @override
  Widget build(BuildContext context) => Padding(padding: EdgeInsets.only(bottom: isLast ? 0 : AppSizes.p8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: context.caption.copyWith(color: context.appColorScheme.textMuted)), Text(value, style: context.caption.copyWith(color: context.appColorScheme.textSecondary, fontWeight: FontWeight.bold))]));
}

class AllergensSection extends StatelessWidget {
  const AllergensSection({super.key, required this.allergens, this.servingSize});
  final String allergens;
  final String? servingSize;
  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final allergenList = allergens.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (allergenList.isEmpty) return const SizedBox.shrink();
    final items = allergenList.map((allergen) => ScanImpactDetailItem(title: allergen, subtitle: 'Potential inflammatory trigger', icon: AppIcons.alertTriangle, value: 'ALERT', color: scheme.error)).toList();
    return ScanImpactSection(title: 'Allergens detected', icon: AppIcons.alertTriangle, iconColor: scheme.error, servingInfo: servingSize, items: items);
  }
}
