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
import 'package:gutgood/core/utils/image_utils.dart';
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
  const ScoreGauge({super.key, required this.score, required this.color, this.label = 'GUT SCORE', this.fontSize});
  final int score;
  final Color color;
  final String label;
  final double? fontSize;
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
                          fontSize: fontSize ?? (size * 0.28).clamp(32, 48).sp,
                          color: textColor,
                          height: 1.0,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        label,
                        style: context.caption.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: (size * 0.08).clamp(6, 8).sp,
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
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < items.length; i++) ...[_buildTimelineNode(context, scheme, items[i], i == items.length - 1)]
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
                    boxShadow: [BoxShadow(color: item.color.withValues(alpha: 0.3), blurRadius: 4)],
                  ),
                ),
                if (!isLast) Expanded(child: Container(width: 2, color: scheme.border.withValues(alpha: 0.5))),
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
    final Color scoreColor = scanData.score >= 70 ? const Color(0xFFB4F1B4) : (scanData.score >= 40 ? const Color(0xFFC4B5FD) : AppPalette.red);

    return BentoCard(
      padding: const EdgeInsets.all(12),
      height: 200.h,
      backgroundColor: scheme.cardBackground,
      child: Row(
        children: [
          // Left Panel: The "Wallet Card" aesthetic
          AspectRatio(
            aspectRatio: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(color: scoreColor, borderRadius: BorderRadius.circular(16)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [

                    Positioned(
                      top: 12,
                      left: 12,
                      child: Text(
                        'ANALYSIS',
                        style: TextStyle(color: Colors.black.withValues(alpha: 0.4), fontSize: 7.sp, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)]),
                      ),
                    ),
                    Positioned(
                      bottom: -10,
                      left: 8,
                      child: Text(
                        '${scanData.score}',
                        style: TextStyle(color: Colors.black, fontSize: 72.sp, fontWeight: FontWeight.w900, letterSpacing: -5),
                      ),
                    ),
                  ],
                ),
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
                Text(
                  scanData.brand.toUpperCase(),
                  style: TextStyle(color: scheme.textSecondary, fontSize: 8.5.sp, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                ),
                Gap.h4,
                Text(
                  scanData.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.bodyBold.copyWith(
                    color: scheme.textPrimary,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    letterSpacing: -0.8,
                  ),
                ),
                Gap.h8,
                Text(
                  scanData.impact,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: context.caption.copyWith(
                    color: scheme.textSecondary,
                    fontSize: 10.5.sp,
                    height: 1.4,
                    letterSpacing: -0.1,
                  ),
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
        final Color color = switch (status) {
          'good' || 'high' => const Color(0xFFB4F1B4),
          'moderate' => AppPalette.orange,
          'low' || 'poor' => AppPalette.red,
          _ => AppPalette.gray400
        };
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              Gap.w6,
              Text(
                e.key.toUpperCase(),
                style: context.caption.copyWith(color: scheme.textPrimary, fontWeight: FontWeight.w900, fontSize: 8.sp, letterSpacing: 0.5),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
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
    final scheme = context.appColorScheme;
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
    final labelStyle = context.caption.copyWith(color: isGlass ? Colors.white.withOpacity(0.7) : scheme.textMuted, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 8.5.sp);
    final valueStyle = context.bodyBold.copyWith(color: isGlass ? Colors.white : scheme.textPrimary, fontSize: 26.sp, letterSpacing: -1.0, fontWeight: FontWeight.w900, height: 1.0);
    return Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_MetricItem(label: 'NOVA-GROUP', value: scanData.novaGroup ?? '1', labelStyle: labelStyle, valueStyle: valueStyle), if (scanData.nutriscore != null) _MetricItem(label: 'NUTRI-SCORE', valueWidget: Text(scanData.nutriscore!, style: valueStyle.copyWith(color: isGlass ? Colors.white : (scanData.score >= 70 ? scheme.success : (scanData.score >= 40 ? const Color(0xFFC4B5FD) : scheme.error)))), labelStyle: labelStyle), _MetricItem(label: 'IMPACT', value: scanData.impactType.name.toUpperCase(), labelStyle: labelStyle, valueStyle: valueStyle.copyWith(fontSize: 18.sp, letterSpacing: -0.5))]), if (scanData.allergens != null && scanData.allergens!.isNotEmpty) ...[Gap.h16, Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: isGlass ? Colors.white.withOpacity(0.15) : scheme.error.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: isGlass ? Colors.white24 : scheme.error.withOpacity(0.2))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(AppIcons.alertTriangle, size: 14, color: isGlass ? Colors.white : scheme.error), Gap.w8, Text('CONTAINS: ${scanData.allergens!.toUpperCase()}', style: context.caption.copyWith(color: isGlass ? Colors.white : scheme.error, fontWeight: FontWeight.w900, fontSize: 10.sp, letterSpacing: 1.0))]))]]);
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
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

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
                    Icon(icon, size: 18.w, color: scheme.textPrimary),
                    Gap.w12,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: context.bodyBold.copyWith(fontSize: 14.sp)),
                          if (servingInfo != null)
                            Text('Per serving ($servingInfo)', style: context.caption.copyWith(color: scheme.textMuted, fontSize: 10.sp)),
                        ],
                      ),
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

class ScanImpactDetailItem extends StatelessWidget {
  const ScanImpactDetailItem({super.key, required this.title, required this.subtitle, required this.icon, required this.value, required this.color, this.showCheck = false, this.isLast = false});
  final String title, subtitle, value;
  final IconData icon;
  final Color color;
  final bool showCheck, isLast;
  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: scheme.elevatedSurface,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: scheme.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, size: 16.w, color: color),
          ),
          Gap.w16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.capitalize, style: context.bodyBold.copyWith(fontSize: 14.sp, height: 1.1, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: scheme.textPrimary)),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: context.caption.copyWith(color: scheme.textMuted, fontSize: 10.5.sp, fontWeight: FontWeight.w600, height: 1.4)),
              ],
            ),
          ),
          Text(value, style: context.caption.copyWith(color: color,  fontWeight: FontWeight.w900, letterSpacing: -0.6)),
          Gap.w4,
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
    final Map<String, dynamic> raw = scanData.rawData ?? {};
    final String additives = scanData.additives ?? (raw['meal']?['additives'] ?? raw['scan']?['additives'] ?? raw['additives'] ?? '').toString();
    final addonList = additives.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final scheme = context.appColorScheme;

    final List flagged = scanData.flaggedIngredients.isNotEmpty 
        ? scanData.flaggedIngredients 
        : ((raw['meal']?['flaggedIngredients'] ?? raw['scan']?['flaggedIngredients'] ?? raw['flaggedIngredients']) ?? []) as List;

    if (addonList.isEmpty && flagged.isEmpty) return const SizedBox.shrink();

    final List<Widget> items = [];
    for (final add in addonList) {
      items.add(_WatchingCard(title: add, subtitle: 'Chemical Additive', icon: AppIcons.flaskConical, color: scheme.warning));
    }
    for (final f in flagged) {
      final String name = f is Map ? (f['name'] ?? '').toString() : f.toString();
      if (name.isNotEmpty) {
        items.add(_WatchingCard(title: name, subtitle: 'Personal Sensitivity', icon: AppIcons.alertCircle, color: scheme.error));
      }
    }

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
                    Icon(AppIcons.alertTriangle, size: 18.w, color: scheme.textPrimary),
                    Gap.w12,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('WHAT TO WATCH', style: context.bodyBold.copyWith(fontSize: 14.sp)),
                          Text('Potential risk factors detected', style: context.caption.copyWith(color: scheme.textMuted, fontSize: 10.sp)),
                        ],
                      ),
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

class _WatchingCard extends StatelessWidget {
  const _WatchingCard({required this.title, required this.subtitle, required this.icon, required this.color});
  final String title, subtitle;
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
        border: Border.all(color: scheme.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, size: 16.w, color: color),
          ),
          Gap.w16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.toUpperCase(), style: context.bodyBold.copyWith(fontSize: 14.sp, height: 1.1, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: scheme.textPrimary)),
                Text(subtitle, style: context.caption.copyWith(color: scheme.textMuted, fontSize: 10.5.sp, fontWeight: FontWeight.w600, height: 1.4)),
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
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    final List<Widget> items = [];
    for (final ing in ingredients) {
      final Color color = ['red', 'orange'].contains(ing.colorName.toLowerCase())
          ? (ing.colorName.toLowerCase() == 'red' ? scheme.error : scheme.warning)
          : scheme.success;

      items.add(Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: scheme.elevatedSurface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: scheme.border.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Icon(AppIcons.leaf, size: 16.w, color: color),
            ),
            Gap.w16,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ing.name.capitalize, style: context.bodyBold.copyWith(fontSize: 14.sp, height: 1.1, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: scheme.textPrimary)),
                  Text(ing.impact.isNotEmpty ? ing.impact : 'Scientific component', style: context.caption.copyWith(color: scheme.textMuted, fontSize: 10.5.sp, fontWeight: FontWeight.w600, height: 1.4)),
                ],
              ),
            ),
            Icon(AppIcons.chevronRight, size: 16.w, color: scheme.textMuted),
            Gap.w4,
          ],
        ),
      ));
    }

    return DashboardCard(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(AppIcons.flaskConical, size: 18.w, color: scheme.textPrimary),
                Gap.w12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CLINICAL AUDIT', style: context.bodyBold.copyWith(fontSize: 14.sp)),
                      Text('${ingredients.length} items verified', style: context.caption.copyWith(color: scheme.textMuted, fontSize: 10.sp)),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(color: scheme.textPrimary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(AppIcons.shieldCheck, size: 12.w, color: scheme.textPrimary),
                ),
              ],
            ),
            Gap.h20,
            ...items,
          ],
        ),
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
    if (n == null) return const SizedBox.shrink();
    final scheme = context.appColorScheme;

    final List<Widget> items = [];
    void addItem(String label, num? value, String unit, IconData icon, {Color? color}) {
      if (value != null && value != 0) {
        final statusColor = color ?? scheme.textPrimary;
        items.add(Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: scheme.elevatedSurface,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: scheme.border.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                ),
                child: Icon(icon, size: 16.w, color: statusColor),
              ),
              Gap.w16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: context.bodyBold.copyWith(fontSize: 14.sp, height: 1.1, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: scheme.textPrimary)),
                    Text('$value $unit', style: context.caption.copyWith(color: scheme.textMuted, fontSize: 10.5.sp, fontWeight: FontWeight.w600, height: 1.4)),
                  ],
                ),
              ),
              Icon(AppIcons.chevronRight, size: 16.w, color: scheme.textMuted),
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

    final findList = (String key) {
      if (raw[key] is List) return raw[key] as List;
      final blocks = ['menu', 'meal', 'scan', 'rawData'];
      for (final b in blocks) {
        if (raw[b] is Map && raw[b][key] is List) return raw[b][key] as List;
      }
      return [];
    };

    final List menuItems = (findList('menuItems').isEmpty 
        ? (findList('items').isEmpty ? findList('dishes') : findList('items'))
        : findList('menuItems'))
        .where((e) => e is Map && (e.containsKey('name') || e.containsKey('dish_name') || e.containsKey('item_name') || e.containsKey('dishName') || e.containsKey('title'))).toList();

    if (menuItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SheetSectionHeader(title: 'MENU RECOMMENDATIONS', color: Colors.transparent),
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
    String? rawImageUrl = (item['imageUrl'] ?? item['image_url'] ?? item['image'])?.toString();
    if (rawImageUrl == 'null' || rawImageUrl == null || rawImageUrl.isEmpty) rawImageUrl = null;
    final displayImageUrl = rawImageUrl ?? getDynamicImageUrl(name);

    final rawIngredients = item['ingredients'] ?? item['components'] ?? [];
    final List ingredients = rawIngredients is List ? rawIngredients : [];

    return Container(
      width: 260.w,
      margin: EdgeInsets.only(right: 16.w),
      decoration: BoxDecoration(
        color: scheme.cardBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: scheme.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: scheme.textPrimary.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
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
                    placeholder: (_, __) => Container(color: scheme.textPrimary.withValues(alpha: 0.05)),
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          scheme.cardBackground,
                          scheme.cardBackground.withValues(alpha: 0.8),
                          Colors.transparent,
                        ],
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
                      decoration: BoxDecoration(
                        color: successColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(AppIcons.leaf, size: 18, color: successColor),
                    ),
                    if (price != null && price != 'null' && price.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: scheme.textPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          price,
                          style: context.caption.copyWith(color: scheme.textPrimary, fontWeight: FontWeight.w900, fontSize: 11.sp),
                        ),
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
                        style: context.bodyBold.copyWith(
                          color: scheme.textPrimary,
                          fontSize: 16.sp,
                          height: 1.1,
                          letterSpacing: -0.4,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (ingredients.isNotEmpty) ...[
                        Gap.h8,
                        Text(
                          'Ingredients: ${ingredients.join(", ")}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.caption.copyWith(color: scheme.textSecondary.withValues(alpha: 0.6), fontSize: 9.sp, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ),
                Gap.h12,
                // Narrative Insight
                SizedBox(
                  width: 160.w,
                  child: Text(
                    impact.isNotEmpty ? impact : description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: context.body.copyWith(
                      color: scheme.textSecondary,
                      fontSize: 11.sp,
                      height: 1.4,
                    ),
                  ),
                ),
                const Spacer(),
                // Professional CTA Footer
                Row(
                  children: [
                    Text(
                      'Explore Science',
                      style: context.caption.copyWith(
                        color: successColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 10.sp,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Gap.w6,
                    Icon(AppIcons.arrowRight, size: 12, color: successColor),
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
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: scheme.elevatedSurface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: scheme.border.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: scheme.textPrimary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(color: scheme.border.withValues(alpha: 0.5)),
              ),
              child: Icon(icon, size: 16.w, color: scheme.textPrimary),
            ),
            Gap.w16,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: context.bodyBold.copyWith(fontSize: 14.sp, height: 1.1, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: scheme.textPrimary)),
                  Text(value, style: context.caption.copyWith(color: scheme.textMuted, fontSize: 10.5.sp, fontWeight: FontWeight.w600, height: 1.4)),
                ],
              ),
            ),
            Icon(AppIcons.chevronRight, size: 16.w, color: scheme.textMuted),
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

class ExpertSummaryCard extends StatelessWidget {
  const ExpertSummaryCard({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final Map<String, dynamic> raw = scanData.rawData ?? {};

    final findString = (String key) {
      if (raw[key] is String) return raw[key].toString();
      final blocks = ['meal', 'scan', 'rawData', 'analysis'];
      for (final b in blocks) {
        if (raw[b] is Map && raw[b][key] != null) return raw[b][key].toString();
      }
      return null;
    };

    final String? summaryStr = findString('summary') ?? scanData.impact;
    if (summaryStr == null || summaryStr.isEmpty) return const SizedBox.shrink();

    return BentoCard(
      height: 240.h,
      padding: const EdgeInsets.all(20),
      backgroundColor: const Color(0xFFC4B5FD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('EXPERT SUMMARY', style: context.caption.copyWith(color: Colors.black.withOpacity(0.6), fontWeight: FontWeight.w900, fontSize: 9.sp, letterSpacing: 1.2)),
              Icon(AppIcons.sparkles, color: Colors.black.withOpacity(0.4), size: 14),
            ],
          ),
          const Spacer(),
          Text(
            summaryStr,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: context.body.copyWith(fontSize: 13.5.sp, height: 1.5, color: Colors.black, fontWeight: FontWeight.w500, letterSpacing: -0.2),
          ),
          const Spacer(),

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

    if (protein == 0 && fiber == 0) return const SizedBox.shrink();

    return BentoCard(
      height: 240.h,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('NUTRIENT STATS', style: context.caption.copyWith(color: scheme.textSecondary, fontWeight: FontWeight.w900, fontSize: 9.sp, letterSpacing: 1.2)),
              Icon(AppIcons.activity, color: scheme.textSecondary, size: 14),
            ],
          ),
          const Spacer(),
          Text('${(protein + fiber).toStringAsFixed(1)}g', style: context.displaySm.copyWith(color: scheme.textPrimary, fontSize: 32.sp, fontWeight: FontWeight.w900, letterSpacing: -1.5, height: 1.0)),
          Gap.h6,
          const Spacer(),
          NutrientBarChart(nutrients: {'protein': protein, 'fiber': fiber}),
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
    final Map<String, dynamic> raw = scanData.rawData ?? {};
    Map<String, dynamic> balance = {};

    final findMap = (String key) {
      if (raw[key] is Map) return Map<String, dynamic>.from(raw[key] as Map);
      final blocks = ['menu', 'meal', 'scan', 'rawData', 'analysis', 'nutrients'];
      for (final b in blocks) {
        if (raw[b] is Map && (raw[b] as Map).containsKey(key) && raw[b][key] is Map) {
          return Map<String, dynamic>.from(raw[b][key] as Map);
        }
      }
      return <String, dynamic>{};
    };

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
          if (v is Map) search(Map<String, dynamic>.from(v as Map));
          if (balance.isNotEmpty) return;
        }
      }
      search(raw);
    }

    if (balance.isEmpty) return const SizedBox.shrink();

    final items = balance.entries.map((e) {
      final status = e.value.toString().toUpperCase();
      final Color color = switch (status.toLowerCase()) {
        'good' || 'high' => const Color(0xFFB4F1B4),
        'moderate' => AppPalette.orange,
        'low' || 'poor' => AppPalette.red,
        _ => AppPalette.gray400
      };
      return TimelineItem(title: e.key, subtitle: status, color: color);
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
              Text('MEAL BALANCE', style: context.caption.copyWith(color: scheme.textSecondary, fontWeight: FontWeight.w900, fontSize: 9.sp, letterSpacing: 1.2)),
              Row(
                children: [
                  CircleAvatar(radius: 6, backgroundColor: const Color(0xFFB4F1B4).withValues(alpha: 0.5)),
                  Gap.w4,
                  CircleAvatar(radius: 6, backgroundColor: const Color(0xFFC4B5FD).withValues(alpha: 0.5)),
                ],
              )
            ],
          ),
          Gap.h24,
          Expanded(child: ImpactTimeline(items: items)),
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
    final Map<String, dynamic> raw = scanData.rawData ?? {};
    
    // Attempt Label-style Clinical Audit first
    final items = <TimelineItem>[];
    if (scanData.nutrientLevels != null) {
      final l = scanData.nutrientLevels!;
      if (l.sugars.toLowerCase() == 'high') items.add(TimelineItem(title: 'Sugar', subtitle: 'Inflammatory spike', color: scheme.error));
      if (l.salt.toLowerCase() == 'high') items.add(TimelineItem(title: 'Sodium', subtitle: 'Water retention', color: scheme.error));
    }
    for (final impact in scanData.impacts.take(2)) {
      var color = const Color(0xFFB4F1B4);
      final level = impact.level.toLowerCase();
      if (level == 'high' || level == 'trigger' || level == 'negative') color = AppPalette.red;
      else if (level == 'moderate' || level == 'neutral') color = AppPalette.orange;
      items.add(TimelineItem(title: impact.title, subtitle: impact.level, color: color));
    }

    // Fallback to Meal Strategy logic if items empty
    if (items.isEmpty) {
      final Map<String, dynamic> meal = raw['meal'] ?? raw['scan'] ?? raw;
      final List strategies = meal['workingWell'] is List ? meal['workingWell'] as List : [];
      if (strategies.isNotEmpty) {
        items.addAll(strategies.take(3).map((s) => TimelineItem(title: 'Safe', subtitle: s.toString(), color: const Color(0xFFB4F1B4))));
      }
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return BentoCard(
      height: 240.h,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('CLINICAL AUDIT', style: context.caption.copyWith(color: scheme.textSecondary, fontWeight: FontWeight.w900, fontSize: 9.sp, letterSpacing: 1.2)),
              Icon(Icons.arrow_outward, color: scheme.textMuted, size: 14),
            ],
          ),
          Gap.h24,
          Expanded(child: ImpactTimeline(items: items)),
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
    final scheme = context.appColorScheme;
    final Map<String, dynamic> raw = scanData.rawData ?? {};
    final isMenu = scanData.detailRoute == '/menu-result';
    
    final metric1 = isMenu 
        ? _MetricData('Dishes', '${((raw['menu'] ?? raw)['items'] ?? []).length}', 'DETECTED')
        : _MetricData('Calories', '${scanData.nutrients?.calories ?? 0}', 'KCAL');
    
    final metric2 = _MetricData('Safety', '${scanData.score}%', 'SCORE');
    
    final metric3 = isMenu 
        ? _MetricData('Allergens', '${scanData.allergens?.split(',').length ?? 0}', 'TOTAL')
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
  final String label, value, unit;
  _MetricData(this.label, this.value, this.unit);
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
          Text(data.label.toUpperCase(), style: TextStyle(fontSize: 8.sp, fontWeight: FontWeight.w900, color: scheme.textSecondary, letterSpacing: 0.5)),
          Gap.h8,
          Text(data.value, style: context.headingSm.copyWith(fontWeight: FontWeight.w900, fontSize: 18.sp, color: scheme.textPrimary)),
          Gap.h2,
          Text(data.unit, style: TextStyle(fontSize: 6.sp, fontWeight: FontWeight.w800, color: scheme.textMuted)),
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
    if (allergenList.isEmpty) return const SizedBox.shrink();

    final List<Widget> items = [];
    for (final allergen in allergenList) {
      items.add(Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: scheme.elevatedSurface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: scheme.error.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(color: scheme.error.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(AppIcons.alertTriangle, size: 16.w, color: scheme.error),
            ),
            Gap.w16,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(allergen.toUpperCase(), style: context.bodyBold.copyWith(fontSize: 14.sp, color: scheme.error, letterSpacing: -0.4, fontWeight: FontWeight.w800, height: 1.1)),
                  Text('Inflammatory trigger', style: context.caption.copyWith(color: scheme.textMuted, fontSize: 10.5.sp, fontWeight: FontWeight.w600, height: 1.4)),
                ],
              ),
            ),
            Text('ALERT', style: context.caption.copyWith(color: scheme.error, fontWeight: FontWeight.w900, fontSize: 8.sp, letterSpacing: 1.0)),
            Gap.w8,
          ],
        ),
      ));
    }

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
                    Icon(AppIcons.alertTriangle, size: 18.w, color: scheme.error),
                    Gap.w12,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SAFETY AUDIT', style: context.bodyBold.copyWith(fontSize: 14.sp, color: scheme.error)),
                          if (servingSize != null) Text('Analyzed per $servingSize', style: context.caption.copyWith(color: scheme.textMuted, fontSize: 10.sp)),
                        ],
                      ),
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
