import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/data/additive_concern_db.dart';
import 'package:gutgood/core/models/nova_group.dart';
import 'package:gutgood/core/models/route_arguments.dart';
import 'package:gutgood/core/models/scan_list_args.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/utils/gut_score_utils.dart';
import 'package:gutgood/core/utils/image_utils.dart';
import 'package:gutgood/core/utils/model_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/utils/yuka_score.dart';
import 'package:gutgood/core/widgets/bento_card.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/bento_widgets.dart' hide BentoCard;
import 'package:gutgood/features/product_details/presentation/utils/scan_result_utils.dart';
import 'package:intl/intl.dart';

class ScoreGauge extends StatelessWidget {
  const ScoreGauge({super.key, required this.score, required this.color, this.label = 'GUT SCORE', this.fontSize});
  final int score;
  final Color color;
  final String label;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final textColor = (color == AppPalette.darkGrey) ? AppPalette.white : t.textPrimary;

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
                      style: TextStyle(
                        fontFamily: InsightBentoTheme.fontFamily,
                        fontSize: fontSize ?? (size * 0.28).clamp(24, 42).sp,
                        fontWeight: FontWeight.w300,
                        letterSpacing: BentoMetrics.scoreTracking,
                        height: 0.9,
                        color: textColor,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: InsightBentoTheme.fontFamily,
                        fontSize: (size * 0.12).clamp(7, 9).sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: BentoMetrics.eyebrowTracking,
                        color: textColor.withAlpha(127),
                      ),
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

/// 🌟 Section 1: Food identity header (photo + brand + name + summary).
class ScanScoreHeader extends StatelessWidget {
  const ScanScoreHeader({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final imageUrl = scanData.userImageUrl ?? scanData.imageUrl;
    final band = GutScoreBand.fromScore(scanData.score);
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: hasImage ? CachedNetworkImage(imageUrl: imageUrl, width: 130.w, height: 130.w, fit: BoxFit.cover, errorWidget: (_, _, _) => _fallbackTile(band.color)) : _fallbackTile(band.color),
        ),
        Gap.w12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                scanData.brand.toUpperCase(),
                style: TextStyle(
                  fontFamily: InsightBentoTheme.fontFamily,
                  fontSize: BentoMetrics.eyebrowSize.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: BentoMetrics.eyebrowTracking,
                  color: t.textTertiary,
                  height: 1.2,
                ),
              ),
              Gap.h4,
              Text(
                scanData.productName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: InsightBentoTheme.fontFamily,
                  fontSize: BentoMetrics.titleWideSize.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: BentoMetrics.titleWideTracking,
                  height: 1.25,
                  color: t.textPrimary,
                ),
              ),
              if (scanData.impact.isNotEmpty) ...[
                Gap.h2,
                Text(
                  scanData.impact,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.bodySize.sp, fontWeight: FontWeight.w400, height: 1.4, color: t.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _fallbackTile(Color color) => Container(
    width: 76.w,
    height: 76.w,
    color: color.withAlpha(24),
    child: Icon(AppIcons.salad, color: color, size: 28.sp),
  );
}

/// 🌟 Section 2: Score gauge + band + personalized "here's why" + expandable breakdown.
class ScanScoreSection extends StatelessWidget {
  const ScanScoreSection({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final band = GutScoreBand.fromScore(scanData.score);

    final recomputed = YukaScore.evaluate(
      nutriscore: scanData.nutriscore,
      energyKcal: scanData.nutrients?.calories,
      fiberG: scanData.nutrients?.fiber,
      proteinG: scanData.nutrients?.proteins,
      sugarG: scanData.nutrients?.sugars,
      saltG: scanData.nutrients?.salt,
      saturatedFatG: scanData.nutrients?.saturatedFat,
      additiveConcerns: scanData.additiveConcerns,
    );

    final showBreakdown = recomputed.hasData;
    final factors = recomputed.factors;
    final explanation = recomputed.explanation.isNotEmpty ? recomputed.explanation : scanData.impact;

    return BentoCard(
      backgroundColor: band.color.withValues(alpha: 0.2),
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 104.w,
                child: ScoreGauge(score: scanData.score, color: band.color, fontSize: 24.sp),
              ),
              Gap.w16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      band.label,
                      style: TextStyle(
                        fontFamily: InsightBentoTheme.fontFamily,
                        fontSize: BentoMetrics.titleWideSize.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: BentoMetrics.titleWideTracking,
                        height: 1.25,
                        color: t.textPrimary,
                      ),
                    ),
                    Gap.h4,
                    Text(
                      explanation,
                      style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.bodySize.sp, fontWeight: FontWeight.w400, height: 1.4, color: t.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showBreakdown) ...[Gap.h12, _WhyScoreExpander(factors: factors)],
        ],
      ),
    );
  }
}

class _WhyScoreExpander extends StatefulWidget {
  const _WhyScoreExpander({required this.factors});
  final List<ScoreFactor> factors;

  @override
  State<_WhyScoreExpander> createState() => _WhyScoreExpanderState();
}

class _WhyScoreExpanderState extends State<_WhyScoreExpander> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppStrings.whyThisScore,
                style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.bodySize.sp, fontWeight: FontWeight.w600, height: 1.3, color: t.textSecondary),
              ),
              Icon(_open ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 18.sp, color: t.textTertiary),
            ],
          ),
        ),
        if (_open) ...[
          Gap.h8,
          Divider(color: t.border.withValues(alpha: 0.5), height: 1),
          ...widget.factors.map((f) => _ScoreFactorRow(factor: f)),
          Gap.h4,
          Text(
            AppStrings.scoreFootnote,
            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.footSize.sp, fontWeight: FontWeight.w400, color: t.textQuaternary, height: 1.2),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _ScoreFactorRow extends StatelessWidget {
  const _ScoreFactorRow({required this.factor});
  final ScoreFactor factor;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final color = factor.isPositive ? t.positive : t.negative;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Gap.w10,
          Expanded(
            child: Text(
              factor.label,
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.bodySize.sp, fontWeight: FontWeight.w600, color: t.textPrimary),
            ),
          ),
          Text(
            '${factor.isPositive ? '+' : ''}${factor.delta}',
            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.bodySize.sp, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

/// 🌟 Section 3: Quick-signal metric cards (Gut Impact, NOVA, Gut Barrier, Processing).
class ScanMetricsRow extends StatelessWidget {
  const ScanMetricsRow({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final nova = NovaGroup.fromGroup(scanData.novaGroup);
    return Row(
      children: [
        Expanded(
          child: _MetricCard(icon: AppIcons.heart, iconColor: _impactColor(context), value: _impactWord, label: AppStrings.gutImpact),
        ),
        Gap.w8,
        Expanded(
          child: _MetricCard(icon: AppIcons.sparkles, iconColor: nova?.color ?? AppPalette.orange, value: nova == null ? '–' : 'Group ${nova.group}', label: AppStrings.nova),
        ),
        Gap.w8,
        Expanded(
          child: _MetricCard(icon: AppIcons.shield, iconColor: AppPalette.orange, value: _barrierWord, label: AppStrings.gutBarrier),
        ),
        Gap.w8,
        Expanded(
          child: _MetricCard(icon: AppIcons.droplet, iconColor: AppPalette.blue, value: nova?.label ?? 'Unknown', label: AppStrings.processing),
        ),
      ],
    );
  }

  String get _impactWord {
    switch (scanData.impactType) {
      case ImpactType.positive:
        return 'Positive';
      case ImpactType.negative:
        return 'Negative';
      case ImpactType.neutral:
        return 'Moderate';
    }
  }

  Color _impactColor(BuildContext context) {
    final scheme = context.appColorScheme;
    switch (scanData.impactType) {
      case ImpactType.positive:
        return scheme.success;
      case ImpactType.negative:
        return scheme.error;
      case ImpactType.neutral:
        return AppPalette.orange;
    }
  }

  String get _barrierWord {
    final s = scanData.score;
    if (s >= 70) return 'Strong';
    if (s >= 50) return 'Steady';
    if (s >= 30) return 'Sensitive';
    return 'At risk';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.icon, required this.iconColor, required this.value, required this.label});
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    return BentoCard(
      backgroundColor: iconColor.withAlpha(22),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      borderRadius: 12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: iconColor.withAlpha(22), shape: BoxShape.circle),
            child: Icon(icon, size: 15.sp, color: iconColor),
          ),
          Gap.h6,
          Text(
            value,
            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.bodySize.sp, fontWeight: FontWeight.w700, color: t.textPrimary),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Gap.h2,
          Text(
            label.toUpperCase(),
            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.tagSize.sp, fontWeight: FontWeight.w700, letterSpacing: BentoMetrics.tagTracking, color: t.textTertiary),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ScanFactor {
  _ScanFactor({required this.icon, required this.iconColor, required this.title, required this.subtitle, this.valueText, this.badgeColor, this.trailing, this.onTap});

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? valueText;
  final Color? badgeColor;
  final Widget? trailing;
  final VoidCallback? onTap;
}

Widget _buildModernFactorCard(BuildContext context, _ScanFactor item, {required bool isPositive}) {
  final t = context.bentoTheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final bgColor = isPositive ? t.positive.withAlpha(isDark ? 30 : 12) : t.negative.withAlpha(isDark ? 30 : 12);
  final iconBgColor = isPositive ? t.positive.withAlpha(isDark ? 40 : 18) : t.negative.withAlpha(isDark ? 40 : 18);
  final iconColor = isPositive ? t.positive : t.negative;

  final content = Row(
    children: [
      Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
        child: Icon(item.icon, size: 18.sp, color: iconColor),
      ),
      Gap.w12,
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              maxLines: 1,
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.titleSize.sp, fontWeight: FontWeight.w600, color: t.textPrimary),
            ),
            const SizedBox(height: 1),
            Text(
              item.subtitle,
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.footSize.sp, fontWeight: FontWeight.w400, color: t.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      if (item.valueText != null)
        Text(
          item.valueText!,
          style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.tagSize.sp, fontWeight: FontWeight.w700, color: t.textPrimary),
        ),
      if (item.badgeColor != null) ...[
        Gap.w8,
        Container(
          width: 8.sp,
          height: 8.sp,
          decoration: BoxDecoration(color: item.badgeColor, shape: BoxShape.circle),
        ),
      ],
      if (item.onTap != null || item.trailing != null) ...[Gap.w8, item.trailing ?? Icon(AppIcons.chevronRight, size: 16.sp, color: (item.badgeColor ?? iconColor).withAlpha(150))],
    ],
  );

  return Container(
    margin: EdgeInsets.only(bottom: 8.h),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
          child: content,
        ),
      ),
    ),
  );
}

/// 🌟 Section 4: "What works for you" (positive factors).
class ScanWorkingSection extends StatelessWidget {
  const ScanWorkingSection({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final serving = scanData.servingSize ?? '1 serving';

    final positiveItems = <_ScanFactor>[];
    final addedTitles = <String>{};

    void addPositive(_ScanFactor item) {
      if (addedTitles.add(item.title.toLowerCase())) positiveItems.add(item);
    }

    // 1. Organic / clean tags
    final textContent = '${scanData.productName} ${scanData.impact} ${scanData.brand}'.toLowerCase();
    if (textContent.contains('organic') || textContent.contains('bio')) {
      addPositive(
        _ScanFactor(
          icon: AppIcons.leaf,
          iconColor: t.positive,
          title: 'Organic',
          subtitle: 'No synthetic herbicides or pesticides',
          trailing: Icon(Icons.check_rounded, color: t.positive, size: 18.sp),
        ),
      );
    }

    // 2. Favorable nutrients (per serving)
    final n = scanData.nutrients;
    if (n != null) {
      if ((n.proteins ?? 0) >= 2.0) {
        addPositive(
          _ScanFactor(
            icon: AppIcons.dumbbell,
            iconColor: t.positive,
            title: 'Protein',
            subtitle: (n.proteins ?? 0) >= 8.0 ? 'High protein source' : 'Provides muscle-building protein',
            valueText: '${(n.proteins ?? 0).toInt()}g',
            badgeColor: t.positive,
          ),
        );
      }
      if ((n.fiber ?? 0) >= 1.0) {
        addPositive(
          _ScanFactor(
            icon: AppIcons.wheat,
            iconColor: t.positive,
            title: 'Fiber',
            subtitle: (n.fiber ?? 0) >= 3.0 ? 'High dietary fiber' : 'Supports digestive motility',
            valueText: '${(n.fiber ?? 0).toStringAsFixed(1)}g',
            badgeColor: t.positive,
          ),
        );
      }
      if ((n.saturatedFat ?? 0) <= 2.0) {
        addPositive(
          _ScanFactor(
            icon: AppIcons.droplet,
            iconColor: t.positive,
            title: 'Saturated Fat',
            subtitle: (n.saturatedFat ?? 0) == 0 ? 'No saturated fat' : 'Low saturated fat',
            valueText: '${(n.saturatedFat ?? 0).toInt()}g',
            badgeColor: t.positive,
          ),
        );
      }
      if ((n.sugars ?? 0) <= 10.0) {
        addPositive(
          _ScanFactor(
            icon: AppIcons.candy,
            iconColor: t.positive,
            title: 'Sugar',
            subtitle: (n.sugars ?? 0) == 0 ? 'No sugar added' : 'Low in sugar',
            valueText: '${(n.sugars ?? 0).toInt()}g',
            badgeColor: t.positive,
          ),
        );
      }
      if ((n.salt ?? 0) <= 1.5) {
        addPositive(
          _ScanFactor(
            icon: AppIcons.scale,
            iconColor: t.positive,
            title: 'Sodium',
            subtitle: (n.salt ?? 0) <= 0.1 ? 'No sodium' : 'Low sodium level',
            valueText: '${((n.salt ?? 0) * 400).toInt()}mg',
            badgeColor: t.positive,
          ),
        );
      }
      if ((n.calories ?? 0) <= 250) {
        addPositive(
          _ScanFactor(
            icon: AppIcons.flame,
            iconColor: t.positive,
            title: 'Calories',
            subtitle: (n.calories ?? 0) <= 100 ? 'Low caloric density' : 'Moderate caloric impact',
            valueText: '${(n.calories ?? 0).toInt()} Cal',
            badgeColor: t.positive,
          ),
        );
      }
    }

    // 3. Positive green ingredients
    for (final ing in scanData.ingredients) {
      if (['green', 'low', 'positive'].contains(ing.colorName.toLowerCase())) {
        addPositive(
          _ScanFactor(
            icon: AppIcons.leaf,
            iconColor: t.positive,
            title: ing.name,
            subtitle: ing.impact.isNotEmpty ? ing.impact : 'Beneficial gut food component',
            trailing: Icon(Icons.check_rounded, color: t.positive, size: 18.sp),
          ),
        );
      }
    }

    // 4. Positive AI impacts
    for (final imp in scanData.impacts) {
      if (['positive', 'healing', 'good', 'low'].contains(imp.level.toLowerCase())) {
        addPositive(
          _ScanFactor(
            icon: AppIcons.sparkles,
            iconColor: t.positive,
            title: imp.title,
            subtitle: imp.level.isNotEmpty ? imp.level : 'Supports gut wellness',
            trailing: Icon(Icons.check_rounded, color: t.positive, size: 18.sp),
          ),
        );
      }
    }

    if (positiveItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: t.positive.withAlpha(20), shape: BoxShape.circle),
              child: Icon(Icons.check_circle_rounded, color: t.positive, size: 22.sp),
            ),
            Gap.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What\'s Working',
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.titleSize.sp, fontWeight: FontWeight.w700, color: t.textPrimary),
                  ),
                  Text(
                    AppStrings.perServing(serving),
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.footSize.sp, fontWeight: FontWeight.w400, color: t.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        Gap.h16,
        ...positiveItems.map((item) => _buildModernFactorCard(context, item, isPositive: true)),
      ],
    );
  }
}

/// 🌟 Section 5: "What to watch" (negative factors + tappable additives/allergens).
class ScanWatchSection extends StatelessWidget {
  const ScanWatchSection({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final serving = scanData.servingSize ?? '1 serving';

    final negativeItems = <_ScanFactor>[];

    // 1. Unfavorable nutrients
    final n = scanData.nutrients;
    if (n != null) {
      if ((n.sugars ?? 0) > 10) {
        negativeItems.add(
          _ScanFactor(
            icon: AppIcons.candy,
            iconColor: t.negative,
            title: 'High Sugar',
            subtitle: (n.sugars ?? 0) > 20 ? 'Too much sugar added' : 'High in sugar',
            valueText: '${(n.sugars ?? 0).toInt()}g',
            badgeColor: t.negative,
          ),
        );
      }
      if ((n.salt ?? 0) > 0.5) {
        negativeItems.add(
          _ScanFactor(
            icon: AppIcons.scale,
            iconColor: t.negative,
            title: 'Sodium',
            subtitle: (n.salt ?? 0) > 1.5 ? 'High sodium content' : 'Moderate sodium',
            valueText: '${((n.salt ?? 0) * 400).toInt()}mg',
            badgeColor: t.negative,
          ),
        );
      }
      if ((n.saturatedFat ?? 0) > 2) {
        negativeItems.add(
          _ScanFactor(
            icon: AppIcons.droplet,
            iconColor: t.orange,
            title: 'Saturated Fat',
            subtitle: 'Pro-inflammatory fat level',
            valueText: '${(n.saturatedFat ?? 0).toInt()}g',
            badgeColor: t.orange,
          ),
        );
      }
      if ((n.calories ?? 0) > 250) {
        negativeItems.add(
          _ScanFactor(icon: AppIcons.flame, iconColor: t.orange, title: 'Calories', subtitle: 'High caloric density', valueText: '${(n.calories ?? 0).toInt()} Cal', badgeColor: t.orange),
        );
      }
    }

    // 2. Allergens (tappable → allergen detail)
    if (scanData.allergens != null && scanData.allergens!.isNotEmpty && parseAllergenItems(scanData.allergens).isNotEmpty) {
      negativeItems.add(
        _ScanFactor(
          icon: Icons.warning_amber_rounded,
          iconColor: t.negative,
          title: 'Allergens',
          subtitle: scanData.allergens!,
          onTap: () => context.push(
            AppRoutes.scanListDetail,
            extra: ScanListDetailArgs(kind: ScanListKind.allergens, scan: scanData),
          ),
        ),
      );
    }

    // 3. Flagged ingredients
    for (final ing in scanData.ingredients) {
      if (['red', 'orange'].contains(ing.colorName.toLowerCase())) {
        final color = ing.colorName.toLowerCase() == 'red' ? t.negative : t.orange;
        negativeItems.add(_ScanFactor(icon: AppIcons.leaf, iconColor: color, title: ing.name, subtitle: ing.impact.isNotEmpty ? ing.impact : 'Potential trigger ingredient', badgeColor: color));
      }
    }

    // 4. Moderate / higher-concern additives (tappable → additive detail)
    for (final concern in scanData.additiveConcerns) {
      if (concern.level == AdditiveConcernLevel.moderate || concern.level == AdditiveConcernLevel.higher) {
        negativeItems.add(
          _ScanFactor(
            icon: AppIcons.flaskConical,
            iconColor: concern.level == AdditiveConcernLevel.higher ? t.negative : t.orange,
            title: concern.displayTitle,
            subtitle: concern.whyFlagged.isNotEmpty ? '${concern.level.label} concern · ${concern.whyFlagged}' : '${concern.level.label} concern',
            onTap: () => context.push(AppRoutes.additiveDetail, extra: concern),
          ),
        );
      }
    }

    if (negativeItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: t.negative.withAlpha(20), shape: BoxShape.circle),
              child: Icon(Icons.warning_amber_rounded, color: t.negative, size: 22.sp),
            ),
            Gap.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What to Watch',
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.titleSize.sp, fontWeight: FontWeight.w700, color: t.textPrimary),
                  ),
                  Text(
                    AppStrings.perServing(serving),
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.footSize.sp, fontWeight: FontWeight.w400, color: t.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        Gap.h16,
        ...negativeItems.map((item) => _buildModernFactorCard(context, item, isPositive: false)),
      ],
    );
  }
}

class ScanSwapsSection extends StatelessWidget {
  const ScanSwapsSection({super.key, required this.swaps});
  final List<ProductSwap> swaps;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    if (swaps.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: t.orange.withAlpha(26), shape: BoxShape.circle),
              child: Icon(AppIcons.lightbulb, size: 22.sp, color: t.orange),
            ),
            Gap.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.betterSwapsLabel,
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.titleSize.sp, fontWeight: FontWeight.w700, color: t.textPrimary),
                  ),
                  Text(
                    'Simple swaps to make this meal even better.',
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.footSize.sp, fontWeight: FontWeight.w400, color: t.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        Gap.h16,
        SizedBox(
          height: 212.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: swaps.length,
            separatorBuilder: (_, _) => Gap.w10,
            itemBuilder: (context, i) => _SwapCard(swap: swaps[i]),
          ),
        ),
      ],
    );
  }
}

class _SwapCard extends StatelessWidget {
  const _SwapCard({required this.swap});
  final ProductSwap swap;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final imageUrl = (swap.imageUrl != null && swap.imageUrl!.isNotEmpty) ? swap.imageUrl! : getDynamicImageUrl(swap.imageKeyword.isNotEmpty ? swap.imageKeyword : swap.title);
    return InkWell(
      onTap: () => context.push(AppRoutes.swapDetail, extra: swap),
      borderRadius: BorderRadius.circular(12),
      child: BentoCard(
        width: 160.w,
        padding: const EdgeInsets.all(10),
        borderRadius: 12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(imageUrl: imageUrl, height: 82.h, width: double.infinity, fit: BoxFit.cover),
            ),
            Gap.h8,
            Text(
              swap.tag.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.tagSize.sp, fontWeight: FontWeight.w700, letterSpacing: BentoMetrics.tagTracking, color: t.positive),
            ),
            Gap.h2,
            Text(
              swap.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.bodySize.sp, fontWeight: FontWeight.w700, color: t.textPrimary),
            ),
            Text(
              swap.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.footSize.sp, fontWeight: FontWeight.w400, height: 1.3, color: t.textTertiary),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => logSwapToJournal(context, swap),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(color: t.positive.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(AppIcons.plus, size: 13.sp, color: t.positive),
                    Gap.w4,
                    Text(
                      AppStrings.addLabel,
                      style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.bodySize.sp, fontWeight: FontWeight.w700, color: t.positive),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🌟 Section 8: Additives (modern cards → additive detail; clean state when none).
class ScanAdditivesSection extends StatelessWidget {
  const ScanAdditivesSection({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final sorted = [...scanData.additiveConcerns]..sort((a, b) => additiveConcernRank(b.level).compareTo(additiveConcernRank(a.level)));
    final visible = sorted.take(3).toList();

    if (sorted.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: t.negative.withAlpha(20), shape: BoxShape.circle),
              child: Icon(AppIcons.flaskConical, size: 22.sp, color: t.negative),
            ),
            Gap.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${AppStrings.additivesLabel} (${scanData.additiveConcerns.length})',
                          style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.titleSize.sp, fontWeight: FontWeight.w700, color: t.textPrimary),
                        ),
                      ),
                      if (sorted.isNotEmpty)
                        InkWell(
                          onTap: () => context.push(
                            AppRoutes.additivesList,
                            extra: AdditiveListArgs(items: sorted, title: AppStrings.additivesLabel, subtitle: AppStrings.additivesSubtitle),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppStrings.seeAll,
                                style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.bodySize.sp, fontWeight: FontWeight.w700, color: t.textSecondary),
                              ),
                              Icon(AppIcons.chevronRight, size: 16.sp, color: t.textQuaternary),
                            ],
                          ),
                        ),
                    ],
                  ),
                  Text(
                    'Tap an additive to learn more about what it is and how it may impact you.',
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.footSize.sp, fontWeight: FontWeight.w400, color: t.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        Gap.h16,
        ...visible.map((concern) {
          final color = additiveConcernColor(context, concern.level);
          final isNeg = concern.level == AdditiveConcernLevel.moderate || concern.level == AdditiveConcernLevel.higher;
          return _buildModernFactorCard(
            context,
            _ScanFactor(
              icon: AppIcons.flaskConical,
              iconColor: color,
              title: concern.displayTitle,
              subtitle: concern.whyFlagged.isNotEmpty ? concern.whyFlagged : concern.whatItIs,
              badgeColor: color,
              onTap: () => context.push(AppRoutes.additiveDetail, extra: concern),
            ),
            isPositive: !isNeg,
          );
        }),
      ],
    );
  }
}

/// 🌟 Section 9a: Ingredients section (modern cards → ingredient list detail).
class ScanIngredientsSection extends StatelessWidget {
  const ScanIngredientsSection({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final ingredients = scanData.ingredients;
    final visible = ingredients.take(3).toList();
    final hasItems = ingredients.isNotEmpty;

    if (!hasItems) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: t.positive.withAlpha(20), shape: BoxShape.circle),
              child: Icon(AppIcons.leaf, size: 22.sp, color: t.positive),
            ),
            Gap.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppStrings.ingredientsTitle,
                          style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.titleSize.sp, fontWeight: FontWeight.w700, color: t.textPrimary),
                        ),
                      ),
                      if (hasItems)
                        InkWell(
                          onTap: () => context.push(
                            AppRoutes.scanListDetail,
                            extra: ScanListDetailArgs(kind: ScanListKind.ingredients, scan: scanData),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppStrings.seeAll,
                                style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.bodySize.sp, fontWeight: FontWeight.w700, color: t.textSecondary),
                              ),
                              Icon(AppIcons.chevronRight, size: 16.sp, color: t.textQuaternary),
                            ],
                          ),
                        ),
                    ],
                  ),
                  Text(
                    'Tap an ingredient to see details.',
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.footSize.sp, fontWeight: FontWeight.w400, color: t.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        Gap.h16,
        ...visible.map((ing) {
          final isPos = ['green', 'low', 'positive'].contains(ing.colorName.toLowerCase());
          final color = ingredientSignalColor(context, ing.colorName);
          return _buildModernFactorCard(
            context,
            _ScanFactor(
              icon: AppIcons.leaf,
              iconColor: color,
              title: ing.name,
              subtitle: ing.impact.isNotEmpty ? ing.impact : (isPos ? 'Beneficial gut food component' : 'Potential trigger ingredient'),
              badgeColor: color,
              onTap: () => context.push(
                AppRoutes.scanListDetail,
                extra: ScanListDetailArgs(kind: ScanListKind.ingredients, scan: scanData),
              ),
            ),
            isPositive: isPos,
          );
        }),
      ],
    );
  }
}

/// 🌟 Section 9b: Allergens section (modern cards → allergen list detail).
class ScanAllergensSection extends StatelessWidget {
  const ScanAllergensSection({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final items = parseAllergenItems(scanData.allergens);
    final visible = items.take(3).toList();
    final hasItems = items.isNotEmpty;
    final color = hasItems ? t.negative : t.positive;

    if (!hasItems) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
              child: Icon(hasItems ? Icons.warning_amber_rounded : Icons.check_rounded, size: 22.sp, color: color),
            ),
            Gap.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppStrings.allergensLabel,
                          style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.titleSize.sp, fontWeight: FontWeight.w700, color: t.textPrimary),
                        ),
                      ),
                      if (hasItems)
                        InkWell(
                          onTap: () => context.push(
                            AppRoutes.scanListDetail,
                            extra: ScanListDetailArgs(kind: ScanListKind.allergens, scan: scanData),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppStrings.seeAll,
                                style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.bodySize.sp, fontWeight: FontWeight.w700, color: t.textSecondary),
                              ),
                              Icon(AppIcons.chevronRight, size: 16.sp, color: t.textQuaternary),
                            ],
                          ),
                        ),
                    ],
                  ),
                  Text(
                    hasItems ? 'Potential gut triggers detected.' : 'No allergens declared for this product.',
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.footSize.sp, fontWeight: FontWeight.w400, color: t.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        Gap.h16,
        ...visible.map(
          (name) => _buildModernFactorCard(
            context,
            _ScanFactor(
              icon: Icons.warning_amber_rounded,
              iconColor: t.negative,
              title: name,
              subtitle: 'Potential gut trigger detected',
              badgeColor: t.negative,
              onTap: () => context.push(
                AppRoutes.scanListDetail,
                extra: ScanListDetailArgs(kind: ScanListKind.allergens, scan: scanData),
              ),
            ),
            isPositive: false,
          ),
        ),
      ],
    );
  }
}

/// 🌟 Section 10: Scan details (provenance footer rows).
class ScanDetailsCard extends StatelessWidget {
  const ScanDetailsCard({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('MMM dd, yyyy • hh:mm a').format(scanData.createdAt);
    return BentoCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BentoCardHeader(title: 'SCAN DETAILS', icon: AppIcons.info),
          Gap.h10,
          _detailRow(context, AppStrings.analyzedOn, date),
          Gap.h8,
          _detailRow(context, AppStrings.servingSizeRow, scanData.servingSize ?? AppStrings.standardServing),
          Gap.h8,
          _detailRow(context, AppStrings.sourceRow, scanSourceLabel(scanData)),
          Gap.h8,
          _detailRow(context, AppStrings.nutritionFactsLabel, scanData.nutritionEstimated ? 'Estimated' : 'Label data'),
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    final t = context.bentoTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.footSize.sp, fontWeight: FontWeight.w400, color: t.textTertiary),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.footSize.sp, fontWeight: FontWeight.w700, color: t.textPrimary),
          ),
        ),
      ],
    );
  }
}

/// 🌟 Footer: gentle nudge into chat for follow-up questions.
class ScanFooterCard extends StatelessWidget {
  const ScanFooterCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    return InkWell(
      onTap: () => context.go(AppRoutes.chat),
      borderRadius: BorderRadius.circular(12),
      child: BentoCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 12,
        backgroundColor: t.mint.withAlpha(16),
        borderColor: t.mint.withAlpha(40),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: t.mint.withAlpha(26), shape: BoxShape.circle),
              child: Icon(AppIcons.leaf, size: 16.sp, color: t.mint),
            ),
            Gap.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.scanFooterTitle,
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.titleSize.sp, fontWeight: FontWeight.w700, color: t.mint),
                  ),
                  Gap.h2,
                  Text(
                    AppStrings.scanFooterBody,
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.footSize.sp, fontWeight: FontWeight.w400, color: t.textTertiary),
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

/// 🌟 Cycle Insight Section
class CycleInsightSection extends StatelessWidget {
  const CycleInsightSection({super.key, required this.insight});
  final CycleInsight insight;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BentoCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 16,
      backgroundColor: isDark ? t.purple.withAlpha(26) : AppPalette.pinkLight,
      borderColor: t.purple.withAlpha(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BentoCardHeader(title: AppStrings.cycleInsightLabel, icon: AppIcons.sparkles, textColor: t.purple, iconColor: t.purple),
          Gap.h12,
          Text(
            insight.phase.toUpperCase(),
            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.titleWideSize.sp, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: t.purple),
          ),
          Gap.h8,
          Text(
            insight.description,
            style: TextStyle(
              fontFamily: InsightBentoTheme.fontFamily,
              fontSize: BentoMetrics.bodySize.sp,
              fontWeight: FontWeight.w500,
              height: 1.5,
              color: isDark ? t.textSecondary : t.purple.withAlpha(204),
            ),
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
                        color: t.purple.withAlpha(38),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: t.purple.withAlpha(51)),
                      ),
                      child: Text(
                        tag.text,
                        style: TextStyle(
                          fontFamily: InsightBentoTheme.fontFamily,
                          fontSize: BentoMetrics.tagSize.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: BentoMetrics.tagTracking,
                          color: t.purple,
                        ),
                      ),
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
