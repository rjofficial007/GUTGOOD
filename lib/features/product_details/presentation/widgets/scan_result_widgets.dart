import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/router/app_routes.dart';
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
                      style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: fontSize ?? (size * 0.28).clamp(24, 42).sp, fontWeight: FontWeight.w700, height: 0.9, color: textColor),
                    ),
                    Text(
                      label,
                      style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 8.sp, fontWeight: FontWeight.w700, color: textColor.withAlpha(127)),
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
    const strokeWidth = 8.0;

    final bgPaint = Paint()
      ..color = (color == AppPalette.darkGrey ? AppPalette.white : color).withValues(alpha: 0.15)
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
    final size = 104.w;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: t.cardBackground,
            borderRadius: BorderRadius.circular(BentoMetrics.radius.w * 0.75),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular((BentoMetrics.radius.w * 0.75) - 1.2),
            child: hasImage
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(
                      color: band.color.withValues(alpha: 0.08),
                      child: Center(
                        child: SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: CircularProgressIndicator(strokeWidth: 2, color: band.color),
                        ),
                      ),
                    ),
                    errorWidget: (_, _, _) => _fallbackTile(band.color, size),
                  )
                : _fallbackTile(band.color, size),
          ),
        ),
        Gap.w14,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (scanData.brand.isNotEmpty) ...[
                Text(
                  scanData.brand.toUpperCase(),
                  style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: (BentoMetrics.eyebrowSize * 0.95).sp, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: t.textSecondary),
                ),
                Gap.h6,
              ],
              Text(
                scanData.productName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: InsightBentoTheme.fontFamily,
                  fontSize: (BentoMetrics.titleWideSize * 1.05).sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: BentoMetrics.titleWideTracking,
                  height: 1.2,
                  color: t.textPrimary,
                ),
              ),
              Gap.h10,
              Wrap(
                spacing: 6.w,
                runSpacing: 6.h,
                children: [
                  if (scanData.nutriscore != null) _HeaderTag(label: _nutriLabel(scanData.nutriscore!), color: _nutriColor(scanData.nutriscore!)),
                  if (scanData.novaGroup != null) _HeaderTag(label: _novaLabel(scanData.novaGroup!), color: _novaColor(context, scanData.novaGroup!)),
                  if (scanData.isOrganic == true) _HeaderTag(label: 'Organic', color: t.positive, icon: AppIcons.leaf),
                  if (scanData.servingSize != null && scanData.servingSize!.isNotEmpty) _HeaderTag(label: _formatServingSize(scanData.servingSize!), color: t.textSecondary),
                  if (scanData.category != null && scanData.category!.isNotEmpty && scanData.category != 'food' && scanData.category != 'meal')
                    _HeaderTag(label: _formatCategory(scanData.category!), color: t.textSecondary),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _nutriLabel(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':
        return 'Great Nutrition';
      case 'B':
        return 'Good Nutrition';
      case 'C':
        return 'Okay Nutrition';
      case 'D':
        return 'Fair Nutrition';
      case 'E':
        return 'Poor Nutrition';
      default:
        return 'Nutri-Score $grade';
    }
  }

  String _novaLabel(String group) {
    switch (group) {
      case '1':
        return 'Unprocessed';
      case '2':
        return 'Lightly Processed';
      case '3':
        return 'Processed';
      case '4':
        return 'Ultra-Processed';
      default:
        return 'NOVA $group';
    }
  }

  String _formatServingSize(String serving) {
    final s = serving.trim();
    if (s.toLowerCase().contains('serving') && s.contains('(') && s.contains(')')) {
      final match = RegExp(r'\(([^)]+)\)').firstMatch(s);
      if (match != null) {
        return 'Serving: ${_capitalizeWords(match.group(1)!)}';
      }
    }
    if (RegExp(r'^\d+\s*g$', caseSensitive: false).hasMatch(s)) {
      return '${s.replaceAll(RegExp(r'\s+'), '').toLowerCase()} Serving';
    }
    return _capitalizeWords(s);
  }

  String _capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  String _formatCategory(String cat) {
    if (cat.isEmpty) return '';
    return cat[0].toUpperCase() + cat.substring(1).toLowerCase();
  }

  Color _nutriColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':
        return const Color(0xFF059669);
      case 'B':
        return const Color(0xFF10B981);
      case 'C':
        return const Color(0xFFF59E0B);
      case 'D':
        return const Color(0xFFEA580C);
      case 'E':
        return const Color(0xFFDC2626);
      default:
        return Colors.grey;
    }
  }

  Color _novaColor(BuildContext context, String group) {
    final t = context.bentoTheme;
    switch (group) {
      case '1':
        return t.positive;
      case '2':
        return const Color(0xFF0284C7);
      case '3':
        return AppPalette.orange;
      case '4':
        return t.negative;
      default:
        return Colors.grey;
    }
  }

  Widget _fallbackTile(Color color, double size) => Container(
    width: size,
    height: size,
    color: color.withValues(alpha: 0.1),
    child: Center(
      child: Icon(AppIcons.salad, color: color, size: (size * 0.36).sp),
    ),
  );
}

class _HeaderTag extends StatelessWidget {
  const _HeaderTag({required this.label, required this.color, this.icon});
  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6.r),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 10.sp, color: color), Gap.w4],
        Text(
          label,
          style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: color),
        ),
      ],
    ),
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
      isOrganic: scanData.isOrganic,
    );

    final showBreakdown = recomputed.hasData;
    final factors = [...recomputed.factors];

    // Ensure the breakdown factors sum up to the actual displayed score
    final diff = scanData.score - recomputed.score;
    if (diff != 0 && showBreakdown) {
      factors.add(ScoreFactor(label: 'AI Personalization · ${diff > 0 ? '+' : ''}$diff pts', delta: diff, phrase: 'personal gut profile adjustment'));
    }

    // Use the backend AI narrative explanation if provided, otherwise clean up recomputed text.
    var explanation = scanData.impact.isNotEmpty ? scanData.impact : recomputed.explanation;
    if (explanation.startsWith('Score ')) {
      explanation = explanation.replaceFirst('Score ${recomputed.score} out of 100', 'Score ${scanData.score} out of 100');
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [band.color.withValues(alpha: 0.14), band.color.withValues(alpha: 0.05)]),
        borderRadius: BorderRadius.circular(BentoMetrics.radius.w),
        boxShadow: [BoxShadow(color: band.color.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      padding: EdgeInsets.all(BentoMetrics.padding.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 96.w,
                child: ScoreGauge(score: scanData.score, color: band.color, fontSize: 26.sp),
              ),
              Gap.w14,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(color: band.color, borderRadius: BorderRadius.circular(100.r)),
                          child: Text(
                            band.label,
                            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 9.sp, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Colors.white),
                          ),
                        ),
                        Gap.w6,
                        Text(
                          '${scanData.score}/100',
                          style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w800, color: band.color),
                        ),
                      ],
                    ),
                    Gap.h6,
                    Text(
                      explanation,
                      style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.bodySize.sp, fontWeight: FontWeight.w500, height: 1.4, color: t.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showBreakdown) ...[Gap.h14, _WhyScoreExpander(factors: factors, bandColor: band.color)],
        ],
      ),
    );
  }
}

class _WhyScoreExpander extends StatefulWidget {
  const _WhyScoreExpander({required this.factors, required this.bandColor});
  final List<ScoreFactor> factors;
  final Color bandColor;

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
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(color: widget.bandColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10.r)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(AppIcons.chartPie, size: 14.sp, color: widget.bandColor),
                Gap.w6,
                Text(
                  AppStrings.whyThisScore,
                  style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.bodySize.sp, fontWeight: FontWeight.w700, height: 1.2, color: t.textPrimary),
                ),
                Gap.w4,
                AnimatedRotation(
                  turns: _open ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down_rounded, size: 20.sp, color: t.textSecondary),
                ),
              ],
            ),
          ),
        ),
        if (_open) ...[
          Gap.h10,
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(color: t.cardBackground, borderRadius: BorderRadius.circular(12.r)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...widget.factors.map((f) => _ScoreFactorRow(factor: f)),
                Gap.h8,
                Divider(color: t.border.withValues(alpha: 0.4), height: 1),
                Gap.h8,
                Text(
                  AppStrings.scoreFootnote,
                  style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.footSize.sp, fontWeight: FontWeight.w400, color: t.textQuaternary, height: 1.3),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
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
    final isPos = factor.isPositive;
    final color = isPos ? t.positive : t.negative;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(isPos ? Icons.add_rounded : Icons.remove_rounded, size: 10.sp, color: color),
          ),
          Gap.w10,
          Expanded(
            child: Text(
              factor.label,
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.bodySize.sp, fontWeight: FontWeight.w600, color: t.textPrimary),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6.r)),
            child: Text(
              '${isPos ? '+' : ''}${factor.delta}',
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w800, color: color),
            ),
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
          child: _MetricCard(icon: _impactIcon, color: _impactColor(context), value: _impactWord, label: 'Impact'),
        ),
        Gap.w6,
        Expanded(
          child: _MetricCard(icon: AppIcons.sparkles, color: _novaColor(context, nova), value: _novaWord(nova), label: nova == null ? 'Nova' : 'Nova ${nova.group}'),
        ),
        Gap.w6,
        Expanded(
          child: _MetricCard(icon: AppIcons.shield, color: _barrierColor(context), value: _barrierWord, label: 'Barrier'),
        ),
        Gap.w6,
        Expanded(
          child: _MetricCard(icon: AppIcons.droplet, color: _processingColor(context, nova), value: _processingWord(nova), label: 'Food Type'),
        ),
      ],
    );
  }

  IconData get _impactIcon {
    switch (scanData.impactType) {
      case ImpactType.positive:
        return AppIcons.heart;
      case ImpactType.negative:
        return AppIcons.alertCircle;
      case ImpactType.neutral:
        return AppIcons.sparkles;
    }
  }

  String get _impactWord {
    switch (scanData.impactType) {
      case ImpactType.positive:
        return 'Gut Friendly';
      case ImpactType.negative:
        return 'Gut Heavy';
      case ImpactType.neutral:
        return 'Moderate';
    }
  }

  String _novaWord(NovaGroup? nova) {
    if (nova == null) return '–';
    switch (nova.group) {
      case 1:
        return 'Unprocessed';
      case 2:
        return 'Lightly Processed';
      case 3:
        return 'Processed';
      case 4:
        return 'Ultra-Processed';
      default:
        return nova.label;
    }
  }

  Color _impactColor(BuildContext context) {
    final t = context.bentoTheme;
    switch (scanData.impactType) {
      case ImpactType.positive:
        return t.positive;
      case ImpactType.negative:
        return t.negative;
      case ImpactType.neutral:
        return AppPalette.orange;
    }
  }

  Color _novaColor(BuildContext context, NovaGroup? nova) {
    final t = context.bentoTheme;
    if (nova == null) return AppPalette.orange;
    switch (nova.group) {
      case 1:
        return t.positive;
      case 2:
        return const Color(0xFF0284C7);
      case 3:
        return AppPalette.orange;
      case 4:
        return t.negative;
      default:
        return AppPalette.orange;
    }
  }

  String get _barrierWord {
    final s = scanData.score;
    if (s >= 70) return 'Gut Support';
    if (s >= 50) return 'Steady';
    if (s >= 30) return 'Sensitive';
    return 'At risk';
  }

  Color _barrierColor(BuildContext context) {
    final t = context.bentoTheme;
    final s = scanData.score;
    if (s >= 70) return t.positive;
    if (s >= 50) return const Color(0xFF2563EB);
    if (s >= 30) return AppPalette.orange;
    return t.negative;
  }

  String _processingWord(NovaGroup? nova) {
    if (nova == null) return 'Unknown';
    switch (nova.group) {
      case 1:
        return 'Whole Food';
      case 2:
        return 'Some Processing';
      case 3:
        return 'Processed';
      case 4:
        return 'Heavy Processing';
      default:
        return nova.label;
    }
  }

  Color _processingColor(BuildContext context, NovaGroup? nova) {
    final t = context.bentoTheme;
    if (nova == null) return t.textTertiary;
    switch (nova.group) {
      case 1:
        return t.positive;
      case 2:
        return const Color(0xFF0284C7);
      case 3:
        return const Color(0xFF7C3AED);
      case 4:
        return const Color(0xFFE11D48);
      default:
        return t.textTertiary;
    }
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.icon, required this.color, required this.value, required this.label});

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNumber = RegExp(r'^\d+$').hasMatch(value);
    final fontSize = isNumber ? 16.sp : 10.5.sp;

    final bgStart = color.withValues(alpha: isDark ? 0.22 : 0.12);
    final bgEnd = color.withValues(alpha: isDark ? 0.12 : 0.04);

    return Container(
      height: 100.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [bgStart, bgEnd]),
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.12 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.28 : 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18.sp, color: color),
          ),
          Gap.h2,
          SizedBox(
            height: 28.h,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Text(
                value,
                style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: fontSize, fontWeight: FontWeight.w900, height: 1.1, color: color),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Gap.h2,
          Text(
            label,
            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: t.textSecondary),
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

  final accentColor = item.badgeColor ?? item.iconColor;
  final cardShade = accentColor.withValues(alpha: isDark ? 0.16 : 0.08);
  final iconBgColor = accentColor.withValues(alpha: isDark ? 0.28 : 0.16);
  final valueBgColor = accentColor.withValues(alpha: isDark ? 0.25 : 0.14);

  final content = Row(
    children: [
      Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
        child: Icon(item.icon, size: 16.sp, color: accentColor),
      ),
      Gap.w12,
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w700, color: t.textPrimary, height: 1.2),
            ),
            Gap.h2,
            Text(
              item.subtitle,
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w400, color: t.textSecondary, height: 1.3),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      if (item.valueText != null) ...[
        Gap.w8,
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(color: valueBgColor, borderRadius: BorderRadius.circular(8.r)),
          child: Text(
            item.valueText!,
            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w800, color: accentColor),
          ),
        ),
      ],
      if (item.onTap != null || item.trailing != null) ...[
        Gap.w8,
        item.trailing ??
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isDark ? 0.22 : 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(AppIcons.chevronRight, size: 14.sp, color: accentColor),
            ),
      ],
    ],
  );

  return Container(
    margin: EdgeInsets.only(bottom: 8.h),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
          decoration: BoxDecoration(color: cardShade, borderRadius: BorderRadius.circular(14.r)),
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

  static bool hasData(ScanResult scanData) {
    final textContent = '${scanData.productName} ${scanData.impact} ${scanData.brand}'.toLowerCase();
    if (scanData.isOrganic == true || textContent.contains('organic') || textContent.contains('bio')) return true;
    final n = scanData.nutrients;
    if (n != null) {
      if ((n.proteins ?? 0) >= 2.0 || (n.fiber ?? 0) >= 1.0 || (n.saturatedFat ?? 0) <= 2.0 || (n.sugars ?? 0) <= 10.0 || (n.salt ?? 0) <= 1.5 || (n.calories ?? 0) <= 250) {
        return true;
      }
    }
    if (scanData.ingredients.any((ing) => ['green', 'low', 'positive'].contains(ing.colorName.toLowerCase()))) return true;
    if (scanData.impacts.any((imp) => ['positive', 'healing', 'good', 'low'].contains(imp.level.toLowerCase()))) return true;
    return false;
  }

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
    if (scanData.isOrganic == true || textContent.contains('organic') || textContent.contains('bio')) {
      addPositive(
        _ScanFactor(icon: AppIcons.leaf, iconColor: t.positive, title: 'Organic Certified', subtitle: '+10 Gut Score bonus · Certified organic ingredients', valueText: '+10', badgeColor: t.positive),
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

  static bool hasData(ScanResult scanData) {
    final n = scanData.nutrients;
    if (n != null) {
      if ((n.sugars ?? 0) > 10 || (n.salt ?? 0) > 0.5 || (n.saturatedFat ?? 0) > 2 || (n.calories ?? 0) > 250) {
        return true;
      }
    }
    if (scanData.allergens != null && scanData.allergens!.isNotEmpty && parseAllergenItems(scanData.allergens).isNotEmpty) return true;
    if (scanData.ingredients.any((ing) => ['red', 'orange', 'yellow'].contains(ing.colorName.toLowerCase()))) return true;
    if (scanData.additiveConcerns.any((c) => c.level == AdditiveConcernLevel.moderate || c.level == AdditiveConcernLevel.higher)) return true;
    return false;
  }

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
      if (['red', 'orange', 'yellow'].contains(ing.colorName.toLowerCase())) {
        final color = ing.colorName.toLowerCase() == 'red' ? t.negative : t.orange;
        negativeItems.add(
          _ScanFactor(icon: AppIcons.leaf, iconColor: color, title: ing.name, subtitle: ing.impact.isNotEmpty ? ing.impact : 'Potential trigger or moderate ingredient', badgeColor: color),
        );
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
          height: 186.h,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageUrl = (swap.imageUrl != null && swap.imageUrl!.isNotEmpty) ? swap.imageUrl! : getDynamicImageUrl(swap.imageKeyword.isNotEmpty ? swap.imageKeyword : swap.title);
    final cardShade = t.positive.withValues(alpha: isDark ? 0.16 : 0.08);

    return InkWell(
      onTap: () => context.push(AppRoutes.swapDetail, extra: swap),
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        width: 164.w,
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(color: cardShade, borderRadius: BorderRadius.circular(14.r)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: 84.h,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => Container(
                  height: 84.h,
                  color: t.positive.withValues(alpha: 0.12),
                  child: Center(
                    child: Icon(AppIcons.salad, color: t.positive, size: 24.sp),
                  ),
                ),
              ),
            ),
            Gap.h8,
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: t.positive.withValues(alpha: isDark ? 0.25 : 0.14),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                swap.tag,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w900, letterSpacing: 0.6, color: t.positive),
              ),
            ),
            Gap.h4,
            Text(
              swap.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: t.textPrimary),
            ),
            Gap.h2,
            Expanded(
              child: Text(
                swap.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w400, height: 1.2, color: t.textSecondary),
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
    final t = context.bentoTheme;
    final date = DateFormat('MMM dd, yyyy • hh:mm a').format(scanData.createdAt);

    return Container(
      padding: EdgeInsets.all(BentoMetrics.padding.w),
      decoration: BoxDecoration(color: t.cardBackground, borderRadius: BorderRadius.circular(BentoMetrics.radius.w)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BentoCardHeader(title: 'SCAN DETAILS'),
          Gap.h12,
          _detailRow(context, AppStrings.analyzedOn, date, AppIcons.calendar),
          Gap.h8,
          _detailRow(context, AppStrings.servingSizeRow, scanData.servingSize ?? AppStrings.standardServing, AppIcons.utensils),
          Gap.h8,
          _detailRow(context, AppStrings.sourceRow, scanSourceLabel(scanData), AppIcons.database),
          Gap.h8,
          _detailRow(context, AppStrings.nutritionFactsLabel, scanData.nutritionEstimated ? 'Estimated' : 'Label data', AppIcons.fileText),
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value, IconData icon) {
    final t = context.bentoTheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(color: t.border.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8.r)),
      child: Row(
        children: [
          Icon(icon, size: 14.sp, color: t.textTertiary),
          Gap.w8,
          Text(
            label,
            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.footSize.sp, fontWeight: FontWeight.w500, color: t.textSecondary),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.footSize.sp, fontWeight: FontWeight.w700, color: t.textPrimary),
            ),
          ),
        ],
      ),
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
    final palette = t.bento(BentoTone.pink);

    return Container(
      padding: EdgeInsets.all(BentoMetrics.padding.w),
      decoration: BoxDecoration(gradient: palette.gradient, borderRadius: BorderRadius.circular(BentoMetrics.radius.w)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BentoCardHeader(title: AppStrings.cycleInsightLabel, icon: AppIcons.sparkles, textColor: palette.tagForeground, iconColor: palette.tagForeground),
          Gap.h12,
          Text(
            insight.phase.toUpperCase(),
            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 16.sp, fontWeight: FontWeight.w900, letterSpacing: -0.4, color: t.textPrimary),
          ),
          Gap.h6,
          Text(
            insight.description,
            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.bodySize.sp, fontWeight: FontWeight.w500, height: 1.5, color: t.textSecondary),
          ),
          if (insight.tags != null && insight.tags!.isNotEmpty) ...[
            Gap.h12,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: insight.tags!
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: palette.tagBackground, borderRadius: BorderRadius.circular(100)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getIcon(tag.icon), size: 10.sp, color: palette.tagForeground),
                          Gap.w6,
                          Text(
                            tag.text.toUpperCase(),
                            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 9.sp, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: palette.tagForeground),
                          ),
                        ],
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

  IconData _getIcon(String icon) {
    switch (icon.toLowerCase()) {
      case 'zap':
        return AppIcons.zap;
      case 'leaf':
        return AppIcons.leaf;
      case 'sparkles':
      case 'sparkle':
        return AppIcons.sparkles;
      case 'activity':
        return AppIcons.activity;
      default:
        return AppIcons.sparkles;
    }
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
