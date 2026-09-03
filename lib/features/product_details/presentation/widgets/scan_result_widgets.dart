import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/ai_insight_details.dart';
import 'package:gutgood/core/models/nova_group.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/utils/gut_score_utils.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/image_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/super_card.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

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

class BentoCardHeader extends StatelessWidget {
  const BentoCardHeader({super.key, required this.title, this.icon, this.textColor, this.iconColor});
  final String title;
  final IconData? icon;
  final Color? textColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final color = textColor ?? scheme.textSecondary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(title.toUpperCase(), style: context.captionBold.copyWith(color: color, letterSpacing: 1.1)),
        ),
        if (icon != null) Icon(icon, color: iconColor ?? scheme.textMuted, size: 14),
      ],
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
                      style: context.displayHero.copyWith(fontSize: fontSize ?? (size * 0.28).clamp(24, 42).sp, color: textColor),
                    ),
                    Text(
                      label,
                      style: context.captionBold.copyWith(fontSize: (size * 0.12).clamp(7, 9).sp, color: textColor.withAlpha(127)),
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
    const strokeWidth = 10.0;

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

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    if (score > 0) {
      const startAngle = -1.5708;
      final sweepAngle = (score / 100) * 6.28319;

      canvas.drawArc(Rect.fromCircle(center: center, radius: radius - strokeWidth / 2), startAngle, sweepAngle, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) => oldDelegate.score != score;
}

/// 🌟 BentoImageCard with Wallet Panel Score Gauge & Photo/Narrative
class BentoImageCard extends StatelessWidget {
  const BentoImageCard({super.key, required this.scanData, this.heroTag});
  final ScanResult scanData;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayImageUrl = scanData.userImageUrl ?? scanData.imageUrl;

    // Premium Score Colors (Vibrant yet premium)
    final scoreColor = GutScoreBand.fromScore(scanData.score).color;

    // Adaptive Theme Colors
    final cardBg = isDark ? AppPalette.darkCard : scheme.cardBackground;
    final cardBorder = isDark ? AppPalette.white.withAlpha(20) : scheme.borderSubtle;
    final scoreTextColor = (scoreColor == AppPalette.green500 || scoreColor == AppPalette.orange) ? AppPalette.black : AppPalette.white;

    return BentoCard(
      padding: const EdgeInsets.all(12),
      height: 200.h,
      backgroundColor: cardBg,
      borderColor: cardBorder,
      child: Row(
        children: [
          // Left Panel: The "Wallet Card" aesthetic with Integrated Score Gauge
          Container(
            width: 176.h,
            height: double.infinity,
            decoration: BoxDecoration(
              color: scoreColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: scoreColor.withAlpha(isDark ? 40 : 60), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 🎨 Animated Gauge Indicator (White Shade for depth)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: scanData.score.toDouble()),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutQuart,
                    builder: (context, value, _) => SizedBox(
                      width: 120.h,
                      height: 120.h,
                      child: CustomPaint(
                        painter: _GaugePainter(score: value.toInt(), color: scoreTextColor.withAlpha(200)),
                      ),
                    ),
                  ),

                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: scoreTextColor.withAlpha(230),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppPalette.black.withAlpha(26), blurRadius: 4)],
                      ),
                    ),
                  ),
                  Text(
                    '${scanData.score}',
                    style: context.displayHero.copyWith(color: AppPalette.black, fontSize: 48.sp, letterSpacing: -2, fontWeight: FontWeight.w900),
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
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(height: 44.h, width: 44.h, imageUrl: displayImageUrl, fit: BoxFit.cover),
                  ),
                  Gap.h4,
                ],
                Text(
                  scanData.brand.toUpperCase(),
                  style: context.captionBold.copyWith(color: scheme.textSecondary, fontSize: 9.sp, letterSpacing: 1.1),
                ),
                Gap.h4,
                Text(
                  scanData.productName.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.bodyBold.copyWith(color: scheme.textPrimary, fontWeight: FontWeight.w900, fontSize: 16.sp, height: 1.1, letterSpacing: -0.4),
                ),
                Gap.h6,
                Text(
                  scanData.impact,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: context.caption.copyWith(color: scheme.textSecondary, height: 1.3, fontSize: 11.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 🌟 4 Core Metrics Row (Gut Impact, NOVA Group, Gut Barrier, Processing)
class CoreMetricsGrid extends StatelessWidget {
  const CoreMetricsGrid({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final nova = NovaGroup.fromGroup(scanData.novaGroup);
    final gutBand = GutScoreBand.fromScore(scanData.score);
    final gutBarrierVal = gutBand.label;
    final processingVal = nova?.label ?? 'Unprocessed';

    return BentoCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      borderRadius: 20,
      backgroundColor: isDark ? AppPalette.darkCard : scheme.cardBackground,
      borderColor: scheme.borderSubtle,
      child: Row(
        children: [
          _IndicatorCell(icon: AppIcons.activity, iconColor: scheme.success, title: '${scanData.score}/100', subtitle: 'Gut Impact'),
          _vDivider(scheme),
          _IndicatorCell(icon: AppIcons.sparkles, iconColor: AppPalette.purplePastel, title: 'NOVA', subtitle: 'Group ${nova?.group ?? scanData.novaGroup ?? '1'}'),
          _vDivider(scheme),
          _IndicatorCell(icon: AppIcons.shield, iconColor: AppPalette.orange, title: 'Gut Barrier', subtitle: gutBarrierVal),
          _vDivider(scheme),
          _IndicatorCell(icon: AppIcons.droplet, iconColor: AppPalette.blue, title: 'Processing', subtitle: processingVal),
        ],
      ),
    );
  }

  Widget _vDivider(AppColorScheme scheme) => Container(width: 1, height: 32.h, color: scheme.borderSubtle);
}

class _IndicatorCell extends StatelessWidget {
  const _IndicatorCell({required this.icon, required this.iconColor, required this.title, required this.subtitle});

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: iconColor.withAlpha(20), shape: BoxShape.circle),
            child: Icon(icon, size: 15.sp, color: iconColor),
          ),
          Gap.h6,
          Text(
            title,
            style: context.labelBold.copyWith(color: scheme.textPrimary, fontWeight: FontWeight.w900, fontSize: 11.sp),
            textAlign: TextAlign.center,
          ),
          Gap.h2,
          Text(
            subtitle,
            style: context.caption.copyWith(color: scheme.textMuted, fontSize: 8.5.sp, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// 🌟 Section 1: "What works for you"
class WhatWorksForYouSection extends StatelessWidget {
  const WhatWorksForYouSection({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final serving = scanData.servingSize ?? '1 serving';

    final positiveItems = <_FactorItem>[];
    final addedTitles = <String>{};

    void addPositive(_FactorItem item) {
      if (!addedTitles.contains(item.title.toLowerCase())) {
        addedTitles.add(item.title.toLowerCase());
        positiveItems.add(item);
      }
    }

    // 1. Check Organic or Clean tags
    final textContent = '${scanData.productName} ${scanData.impact} ${scanData.brand}'.toLowerCase();
    if (textContent.contains('organic') || textContent.contains('bio')) {
      addPositive(
        _FactorItem(
          icon: AppIcons.leaf,
          iconColor: scheme.success,
          title: 'Organic',
          subtitle: 'No synthetic herbicides or pesticides',
          trailingWidget: Icon(Icons.check_rounded, color: scheme.success, size: 18.sp),
        ),
      );
    }

    // 2. Check Nutrients (Protein, Fiber, Sat Fat, Sugar, Sodium, Calories)
    final n = scanData.nutrients;
    if (n != null) {
      if ((n.proteins ?? 0) >= 2.0) {
        addPositive(
          _FactorItem(
            icon: AppIcons.dumbbell,
            iconColor: scheme.success,
            title: 'Protein',
            subtitle: (n.proteins ?? 0) >= 8.0 ? 'High protein source' : 'Provides muscle-building protein',
            valueText: '${(n.proteins ?? 0).toInt()}g',
            badgeColor: scheme.success,
          ),
        );
      }
      if ((n.fiber ?? 0) >= 1.0) {
        addPositive(
          _FactorItem(
            icon: AppIcons.wheat,
            iconColor: scheme.success,
            title: 'Fiber',
            subtitle: (n.fiber ?? 0) >= 3.0 ? 'High dietary fiber' : 'Supports digestive motility',
            valueText: '${(n.fiber ?? 0).toStringAsFixed(1)}g',
            badgeColor: scheme.success,
          ),
        );
      }
      if ((n.saturatedFat ?? 0) <= 2.0) {
        addPositive(
          _FactorItem(
            icon: AppIcons.droplet,
            iconColor: scheme.success,
            title: 'Saturated Fat',
            subtitle: (n.saturatedFat ?? 0) == 0 ? 'No saturated fat' : 'Low saturated fat',
            valueText: '${(n.saturatedFat ?? 0).toInt()}g',
            badgeColor: scheme.success,
          ),
        );
      }
      if ((n.sugars ?? 0) <= 10.0) {
        addPositive(
          _FactorItem(
            icon: AppIcons.candy,
            iconColor: scheme.success,
            title: 'Sugar',
            subtitle: (n.sugars ?? 0) == 0 ? 'No sugar added' : 'Low in sugar',
            valueText: '${(n.sugars ?? 0).toInt()}g',
            badgeColor: scheme.success,
          ),
        );
      }
      if ((n.salt ?? 0) <= 1.5) {
        addPositive(
          _FactorItem(
            icon: AppIcons.scale,
            iconColor: scheme.success,
            title: 'Sodium',
            subtitle: (n.salt ?? 0) <= 0.1 ? 'No sodium' : 'Low sodium level',
            valueText: '${((n.salt ?? 0) * 400).toInt()}mg',
            badgeColor: scheme.success,
          ),
        );
      }
      if ((n.calories ?? 0) <= 250) {
        addPositive(
          _FactorItem(
            icon: AppIcons.flame,
            iconColor: scheme.success,
            title: 'Calories',
            subtitle: (n.calories ?? 0) <= 100 ? 'Low caloric density' : 'Moderate caloric impact',
            valueText: '${(n.calories ?? 0).toInt()} Cal',
            badgeColor: scheme.success,
          ),
        );
      }
    }

    // 3. Positive Green Ingredients
    for (final ing in scanData.ingredients) {
      if (['green', 'low', 'positive'].contains(ing.colorName.toLowerCase())) {
        addPositive(
          _FactorItem(
            icon: AppIcons.leaf,
            iconColor: scheme.success,
            title: ing.name,
            subtitle: ing.impact.isNotEmpty ? ing.impact : 'Beneficial gut food component',
            trailingWidget: Icon(Icons.check_rounded, color: scheme.success, size: 18.sp),
          ),
        );
      }
    }

    // 4. Positive AI Impacts
    for (final imp in scanData.impacts) {
      if (['positive', 'healing', 'good', 'low'].contains(imp.level.toLowerCase())) {
        addPositive(
          _FactorItem(
            icon: AppIcons.sparkles,
            iconColor: scheme.success,
            title: imp.title,
            subtitle: imp.level.isNotEmpty ? imp.level : 'Supports gut wellness',
            trailingWidget: Icon(Icons.check_rounded, color: scheme.success, size: 18.sp),
          ),
        );
      }
    }

    if (positiveItems.isEmpty) {
      positiveItems.add(
        _FactorItem(
          icon: AppIcons.leaf,
          iconColor: scheme.success,
          title: 'Clean Ingredients',
          subtitle: 'No major gut triggers detected',
          trailingWidget: Icon(Icons.check_rounded, color: scheme.success, size: 18.sp),
        ),
      );
    }

    return BentoCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      backgroundColor: isDark ? AppPalette.darkCard : scheme.cardBackground,
      borderColor: scheme.borderSubtle,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: scheme.success, size: 18.sp),
                  Gap.w8,
                  Text(
                    'What works for you',
                    style: context.title.copyWith(fontSize: 15.sp, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              Text(
                'Per serving ($serving)',
                style: context.caption.copyWith(color: scheme.textMuted, fontSize: 11.sp),
              ),
            ],
          ),
          Gap.h12,
          Divider(color: scheme.borderSubtle, height: 1),
          ...positiveItems.map((item) => _buildFactorRow(context, item)),
        ],
      ),
    );
  }

  Widget _buildFactorRow(BuildContext context, _FactorItem item) {
    final scheme = context.appColorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: item.iconColor.withAlpha(20), shape: BoxShape.circle),
            child: Icon(item.icon, size: 15.sp, color: item.iconColor),
          ),
          Gap.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: context.labelBold.copyWith(color: scheme.textPrimary, fontWeight: FontWeight.w800, fontSize: 12.5.sp),
                ),
                Text(
                  item.subtitle,
                  style: context.caption.copyWith(color: scheme.textMuted, fontSize: 10.5.sp),
                ),
              ],
            ),
          ),
          if (item.valueText != null) ...[
            Text(
              item.valueText!,
              style: context.captionBold.copyWith(color: scheme.textPrimary, fontSize: 11.5.sp, fontWeight: FontWeight.w700),
            ),
            Gap.w6,
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: item.badgeColor ?? scheme.success, shape: BoxShape.circle),
            ),
          ] else if (item.trailingWidget != null)
            item.trailingWidget!,
        ],
      ),
    );
  }
}

/// 🌟 Section 2: "What to watch" (Negative factors matching "What works for you" style)
class WhatToWatchSection extends StatelessWidget {
  const WhatToWatchSection({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final serving = scanData.servingSize ?? '1 serving';

    final negativeItems = <_FactorItem>[];

    // 1. Check negative nutrients (High Sugar, High Sodium, Saturated Fat, High Calories)
    final n = scanData.nutrients;
    if (n != null) {
      if ((n.sugars ?? 0) > 10) {
        negativeItems.add(
          _FactorItem(
            icon: AppIcons.candy,
            iconColor: scheme.error,
            title: 'High Sugar',
            subtitle: (n.sugars ?? 0) > 20 ? 'Too much sugar added' : 'High in sugar',
            valueText: '${(n.sugars ?? 0).toInt()}g',
            badgeColor: scheme.error,
            isUpArrow: true,
          ),
        );
      }
      if ((n.salt ?? 0) > 0.5) {
        negativeItems.add(
          _FactorItem(
            icon: AppIcons.scale,
            iconColor: scheme.error,
            title: 'Sodium',
            subtitle: (n.salt ?? 0) > 1.5 ? 'High sodium content' : 'Moderate sodium',
            valueText: '${((n.salt ?? 0) * 400).toInt()}mg',
            badgeColor: scheme.error,
            isUpArrow: true,
          ),
        );
      }
      if ((n.saturatedFat ?? 0) > 2) {
        negativeItems.add(
          _FactorItem(
            icon: AppIcons.droplet,
            iconColor: AppPalette.orange,
            title: 'Saturated Fat',
            subtitle: 'Pro-inflammatory fat level',
            valueText: '${(n.saturatedFat ?? 0).toInt()}g',
            badgeColor: AppPalette.orange,
            isUpArrow: true,
          ),
        );
      }
      if ((n.calories ?? 0) > 250) {
        negativeItems.add(
          _FactorItem(
            icon: AppIcons.flame,
            iconColor: AppPalette.orange,
            title: 'Calories',
            subtitle: 'High caloric density',
            valueText: '${(n.calories ?? 0).toInt()} Cal',
            badgeColor: AppPalette.orange,
            isUpArrow: true,
          ),
        );
      }
    }

    // 3. Check flagged ingredients / allergens
    if (scanData.allergens != null && scanData.allergens!.isNotEmpty) {
      negativeItems.add(_FactorItem(icon: Icons.warning_amber_rounded, iconColor: scheme.error, title: 'Allergens', subtitle: scanData.allergens!, badgeColor: scheme.error, isUpArrow: true));
    }

    for (final ing in scanData.ingredients) {
      if (['red', 'orange'].contains(ing.colorName.toLowerCase())) {
        negativeItems.add(
          _FactorItem(
            icon: AppIcons.leaf,
            iconColor: ing.colorName.toLowerCase() == 'red' ? scheme.error : AppPalette.orange,
            title: ing.name,
            subtitle: ing.impact.isNotEmpty ? ing.impact : 'Potential trigger ingredient',
            badgeColor: ing.colorName.toLowerCase() == 'red' ? scheme.error : AppPalette.orange,
            isUpArrow: true,
          ),
        );
      }
    }

    if (negativeItems.isEmpty) {
      negativeItems.add(
        _FactorItem(
          icon: Icons.shield_outlined,
          iconColor: scheme.success,
          title: 'No Major Triggers',
          subtitle: 'Low risk ingredient profile',
          trailingWidget: Icon(Icons.check_rounded, color: scheme.success, size: 18.sp),
        ),
      );
    }

    return BentoCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      backgroundColor: isDark ? scheme.error.withAlpha(12) : AppPalette.orangeLight,
      borderColor: scheme.warning.withAlpha(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppPalette.orange, size: 18.sp),
                  Gap.w8,
                  Text(
                    'What to watch',
                    style: context.title.copyWith(fontSize: 15.sp, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              Text(
                'Per serving ($serving)',
                style: context.caption.copyWith(color: scheme.textMuted, fontSize: 11.sp),
              ),
            ],
          ),
          Gap.h12,
          Divider(color: scheme.borderSubtle, height: 1),
          ...negativeItems.map((item) => _buildFactorRow(context, item)),
        ],
      ),
    );
  }

  Widget _buildFactorRow(BuildContext context, _FactorItem item) {
    final scheme = context.appColorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: item.iconColor.withAlpha(20), shape: BoxShape.circle),
            child: Icon(item.icon, size: 15.sp, color: item.iconColor),
          ),
          Gap.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: context.labelBold.copyWith(color: scheme.textPrimary, fontWeight: FontWeight.w800, fontSize: 12.5.sp),
                ),
                Text(
                  item.subtitle,
                  style: context.caption.copyWith(color: scheme.textMuted, fontSize: 10.5.sp),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (item.valueText != null) ...[
            Text(
              item.valueText!,
              style: context.captionBold.copyWith(color: scheme.textPrimary, fontSize: 11.5.sp, fontWeight: FontWeight.w700),
            ),
            Gap.w6,
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: item.badgeColor ?? AppPalette.orange, shape: BoxShape.circle),
            ),
            Gap.w4,
            Icon(item.isUpArrow ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: scheme.textMuted, size: 16.sp),
          ] else if (item.trailingWidget != null)
            item.trailingWidget!,
        ],
      ),
    );
  }
}

class _FactorItem {
  _FactorItem({required this.icon, required this.iconColor, required this.title, required this.subtitle, this.valueText, this.badgeColor, this.trailingWidget, this.isUpArrow = false});

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? valueText;
  final Color? badgeColor;
  final Widget? trailingWidget;
  final bool isUpArrow;
}

/// 🌟 Section 3: "What this means for you" (Styled exactly like CycleInsightSection)
class WhatThisMeansForYouCard extends StatelessWidget {
  const WhatThisMeansForYouCard({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final impactText = scanData.impact.isNotEmpty ? scanData.impact : 'Great option for hydration and gut health. The live cultures support digestion and your gut barrier.';

    return BentoCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 20,
      backgroundColor: isDark ? AppPalette.purple.withAlpha(26) : AppPalette.purplePastel,
      borderColor: AppPalette.purple.withAlpha(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BentoCardHeader(title: 'WHAT THIS MEANS FOR YOU', icon: AppIcons.sparkles, textColor: AppPalette.purple, iconColor: AppPalette.purple),
          Gap.h12,
          Text(
            impactText,
            style: context.bodySm.copyWith(color: isDark ? scheme.textSecondary : AppPalette.black.withAlpha(200), height: 1.5, fontWeight: FontWeight.w500, fontSize: 13.sp),
          ),
        ],
      ),
    );
  }
}


/// 🌟 Cycle Insight Section
class CycleInsightSection extends StatelessWidget {
  const CycleInsightSection({super.key, required this.insight});
  final CycleInsight insight;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BentoCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 20,
      backgroundColor: isDark ? AppPalette.pink.withAlpha(26) : AppPalette.pinkLight,
      borderColor: AppPalette.pink.withAlpha(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BentoCardHeader(title: AppStrings.cycleInsightLabel, icon: AppIcons.sparkles, textColor: AppPalette.pink, iconColor: AppPalette.pink),
          Gap.h12,
          Text(
            insight.phase.toUpperCase(),
            style: context.headingSm.copyWith(color: AppPalette.pink, fontWeight: FontWeight.w900, letterSpacing: -0.5, fontSize: 16.sp),
          ),
          Gap.h8,
          Text(
            insight.description,
            style: context.bodySm.copyWith(color: isDark ? scheme.textSecondary : AppPalette.pink.withAlpha(204), height: 1.5, fontWeight: FontWeight.w500),
          ),
          if (insight.tags != null && insight.tags!.isNotEmpty) ...[
            Gap.h12,
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
    );
  }
}

class BentoFoodCard extends StatelessWidget {
  const BentoFoodCard({
    super.key,
    required this.foods,
    required this.title,
    required this.trend,
    required this.isPositive,
    required this.icon,
    this.score,
    this.highlight,
  });
  final List<dynamic> foods;
  final String title;
  final String? trend;
  final bool isPositive;
  final IconData icon;
  final int? score;
  final TopHighlight? highlight;

  @override
  Widget build(BuildContext context) {
    final items = foods.map((f) {
      if (f is HealingFood || f is TriggerFood) {
        final dynamic food = f;
        return SuperCyclerItemData(name: food.name, effect: food.effect, imageUrl: food.imageUrl);
      } else if (f is FoodImpact) {
        return SuperCyclerItemData(name: f.food, effect: f.effect, imageUrl: f.imageUrl);
      } else if (f is ProductSwap) {
        return SuperCyclerItemData(name: f.title, effect: f.subtitle, imageUrl: f.imageUrl ?? getDynamicImageUrl(f.imageKeyword.isNotEmpty ? f.imageKeyword : f.title));
      } else if (f is RecapHighlight) {
        return SuperCyclerItemData(name: f.text, effect: '');
      }
      return SuperCyclerItemData(name: 'Unknown', effect: '');
    }).toList();

    if (title.toUpperCase() == 'HEALING' || title.toUpperCase() == 'TRIGGERS' || title.toUpperCase() == 'RECENT LOGS') {
      final displayScore = score ?? (isPositive ? 75 : 25);
      Color statusColor = isPositive ? const Color(0xFF27F15B) : const Color(0xFFE9579A);
      
      if (title.toUpperCase() == 'RECENT LOGS') {
        statusColor = const Color(0xFF0759E8); // Premium Blue for History
      }

      return DashboardEntrance(
        delay: 200,
        child: SuperFoodGaugeCard(
          title: title,
          label: highlight?.timeframe.toUpperCase() ?? (title.toUpperCase() == 'RECENT LOGS' ? 'HISTORY' : (isPositive ? 'POSITIVE PATTERNS' : 'NEGATIVE PATTERNS')),
          score: displayScore,
          statusColor: statusColor,
          foods: items,
        ),
      );
    }

    return DashboardEntrance(
      delay: 200,
      child: SuperFoodCyclerCard(
        items: items,
        title: title,
        trend: trend,
        isPositive: isPositive,
        icon: icon,
      ),
    );
  }

  String _getFoodName(dynamic f) {
    if (f is HealingFood || f is TriggerFood) return f.name;
    if (f is FoodImpact) return f.food;
    if (f is ProductSwap) return f.title;
    return 'Unknown';
  }
}

class BentoActivityCard extends StatelessWidget {
  const BentoActivityCard({super.key, required this.impacts, this.score});
  final List<FoodImpact> impacts;
  final int? score;

  @override
  Widget build(BuildContext context) => BentoFoodCard(
    foods: impacts,
    title: 'RECENT LOGS',
    trend: null,
    isPositive: true, 
    icon: AppIcons.history,
    score: score,
  );
}

/// 🌟 Better Swaps Card in BentoFoodCard Style
class BetterSwapsCarousel extends StatelessWidget {
  const BetterSwapsCarousel({super.key, required this.swaps});
  final List<ProductSwap> swaps;

  @override
  Widget build(BuildContext context) {
    if (swaps.isEmpty) return const SizedBox.shrink();

    return BentoFoodCard(title: 'BETTER SWAPS', trend: 'Healthier Choice', isPositive: true, icon: AppIcons.refreshCw, foods: swaps);
  }
}

/// 🌟 Save Button
class SaveButton extends StatelessWidget {
  const SaveButton({super.key, required this.isSaved, required this.isLoading, required this.onTap});
  final bool isSaved;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: isLoading ? null : onTap,
    child: Container(
      margin: EdgeInsets.only(right: 10.w),
      width: 40.w,
      height: 40.w,
      child: isLoading
          ? const Center(
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppPalette.black)),
            )
          : Icon(isSaved ? Icons.favorite : Icons.favorite_border, color: isSaved ? AppPalette.red : AppPalette.black, size: 20),
    ),
  );
}

/// 🌟 Legacy ExpertStrategyCard for compatibility
class ExpertStrategyCard extends StatelessWidget {
  const ExpertStrategyCard({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) => WhatWorksForYouSection(scanData: scanData);
}

/// 🌟 Legacy AdditivesSection for compatibility
class AdditivesSection extends StatelessWidget {
  const AdditivesSection({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) => WhatToWatchSection(scanData: scanData);
}

/// 🌟 Legacy MealBalanceCard for compatibility
class MealBalanceCard extends StatelessWidget {
  const MealBalanceCard({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}




/// 🌟 Metadata Section
class ProductMetadataSection extends StatelessWidget {
  const ProductMetadataSection({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final date = DateFormat('MMM dd, yyyy • hh:mm a').format(scanData.createdAt);

    return BentoCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BentoCardHeader(title: AppStrings.productMetadata, icon: AppIcons.info),
          Gap.h10,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Analyzed On', style: context.caption.copyWith(color: scheme.textMuted)),
              Text(date, style: context.captionBold.copyWith(color: scheme.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}
