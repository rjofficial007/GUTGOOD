import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/data/additive_concern_db.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/ai_insight_details.dart';
import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/nova_group.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/services/firestore/history_firestore_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/gut_score_utils.dart';
import 'package:gutgood/core/utils/image_utils.dart';
import 'package:gutgood/core/utils/model_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/super_card.dart';
import 'package:intl/intl.dart';

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

/// Args for the generic scan list detail screen (ingredients / allergens / additives).
enum ScanListKind { ingredients, allergens, additives }

class ScanListDetailArgs {
  const ScanListDetailArgs({required this.kind, required this.scan});
  final ScanListKind kind;
  final ScanResult scan;
}

/// Concern level → UI color.
Color additiveConcernColor(BuildContext context, AdditiveConcernLevel level) {
  final scheme = context.appColorScheme;
  switch (level) {
    case AdditiveConcernLevel.low:
      return scheme.success;
    case AdditiveConcernLevel.moderate:
      return AppPalette.orange;
    case AdditiveConcernLevel.higher:
      return scheme.error;
    case AdditiveConcernLevel.unknown:
      return scheme.textMuted;
  }
}

int _concernRank(AdditiveConcernLevel level) {
  switch (level) {
    case AdditiveConcernLevel.higher:
      return 3;
    case AdditiveConcernLevel.moderate:
      return 2;
    case AdditiveConcernLevel.low:
      return 1;
    case AdditiveConcernLevel.unknown:
      return 0;
  }
}

/// AI ingredient colorName → UI color.
Color ingredientSignalColor(BuildContext context, String colorName) {
  final scheme = context.appColorScheme;
  switch (colorName.toLowerCase()) {
    case 'green':
    case 'low':
    case 'positive':
      return scheme.success;
    case 'red':
      return scheme.error;
    case 'orange':
    case 'moderate':
    case 'yellow':
      return AppPalette.orange;
    default:
      return scheme.textMuted;
  }
}

/// Split a free-text allergen summary ('Milk, Soy', 'Contains: gluten') into items.
List<String> parseAllergenItems(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  final text = raw.trim().replaceAll(RegExp(r'^(contains|may contain)\s*:?\s*', caseSensitive: false), '');
  if (RegExp(r'^(none|no\s+allergens?|not\s+detected|n/?a)\b', caseSensitive: false).hasMatch(text)) return const [];
  var parts = text.split(RegExp(r'[,;•\n]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  if (parts.length == 1 && parts.first.contains(RegExp(r'\sand\s', caseSensitive: false))) {
    parts = parts.first.split(RegExp(r'\sand\s', caseSensitive: false)).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }
  return parts;
}

/// Human label for how this scan was captured.
String scanSourceLabel(ScanResult scan) {
  if (scan.barcode != null && scan.barcode!.isNotEmpty) return AppStrings.barcodeSource;
  final s = (scan.source ?? '').toLowerCase();
  if (s.contains('menu')) return AppStrings.menuSource;
  if (s.contains('label')) return AppStrings.labelSource;
  return AppStrings.photoSource;
}

/// Logs a swap to the journal as a snack. Shared by the swaps carousel + swap detail.
Future<void> logSwapToJournal(BuildContext context, ProductSwap swap) async {
  try {
    await sl<HistoryFirestoreService>().logMeal(MealLog(items: [swap.title], notes: swap.subtitle, mealType: 'snack', source: 'swap', createdAt: DateTime.now()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.swapLogged(swap.title)), behavior: SnackBarBehavior.floating));
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't log this swap — try again."), behavior: SnackBarBehavior.floating));
    }
  }
}

/// 🌟 Section 1: Food identity header (photo + brand + name + summary).
class ScanScoreHeader extends StatelessWidget {
  const ScanScoreHeader({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final imageUrl = scanData.userImageUrl ?? scanData.imageUrl;
    final band = GutScoreBand.fromScore(scanData.score);
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return BentoCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 20,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: hasImage ? CachedNetworkImage(imageUrl: imageUrl, width: 76.w, height: 76.w, fit: BoxFit.cover, errorWidget: (_, _, _) => _fallbackTile(band.color)) : _fallbackTile(band.color),
          ),
          Gap.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scanData.brand.toUpperCase(),
                  style: context.captionBold.copyWith(color: scheme.textMuted, fontSize: 10.sp, letterSpacing: 1.0),
                ),
                Gap.h4,
                Text(
                  scanData.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.title.copyWith(fontSize: 17.sp, fontWeight: FontWeight.w900, height: 1.15),
                ),
                if (scanData.impact.isNotEmpty) ...[
                  Gap.h6,
                  Text(
                    scanData.impact,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: context.caption.copyWith(color: scheme.textSecondary, fontSize: 12.sp, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
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
    final scheme = context.appColorScheme;
    final band = GutScoreBand.fromScore(scanData.score);
    final factors = ModelUtils.explainDeterministicScore(
      nutriscore: scanData.nutriscore,
      novaGroup: int.tryParse(scanData.novaGroup ?? ''),
      fiberG: scanData.nutrients?.fiber,
      proteinG: scanData.nutrients?.proteins,
      sugarG: scanData.nutrients?.sugars,
      saltG: scanData.nutrients?.salt,
      saturatedFatG: scanData.nutrients?.saturatedFat,
      additiveConcerns: scanData.additiveConcerns,
    );
    // Point breakdown only sums exactly on the deterministic (barcode) path,
    // so the expander is hidden for AI-scored photo scans.
    final showBreakdown = factors.isNotEmpty && scanData.barcode != null;
    final explanation = factors.isEmpty && scanData.impact.isNotEmpty ? scanData.impact : ModelUtils.scoreExplanationSentence(factors);

    return BentoCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 104.w,
                child: ScoreGauge(score: scanData.score, color: band.color, fontSize: 30.sp),
              ),
              Gap.w16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      band.label,
                      style: context.headingSm.copyWith(fontSize: 22.sp, fontWeight: FontWeight.w900),
                    ),
                    Gap.h4,
                    Text(
                      explanation,
                      style: context.caption.copyWith(color: scheme.textSecondary, fontSize: 12.5.sp, height: 1.45),
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
    final scheme = context.appColorScheme;
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
                style: context.captionBold.copyWith(color: scheme.textSecondary, fontSize: 12.sp),
              ),
              Icon(_open ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 18.sp, color: scheme.textMuted),
            ],
          ),
        ),
        if (_open) ...[
          Gap.h8,
          Divider(color: scheme.borderSubtle, height: 1),
          ...widget.factors.map((f) => _ScoreFactorRow(factor: f)),
          Gap.h4,
          Text(
            AppStrings.scoreFootnote,
            style: context.caption.copyWith(color: scheme.textMuted, fontSize: 10.5.sp),
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
    final scheme = context.appColorScheme;
    final color = factor.isPositive ? scheme.success : scheme.error;
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
              style: context.caption.copyWith(color: scheme.textPrimary, fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '${factor.isPositive ? '+' : ''}${factor.delta}',
            style: context.captionBold.copyWith(color: color, fontSize: 12.sp),
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
    final scheme = context.appColorScheme;
    return BentoCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      borderRadius: 16,
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
            style: context.labelBold.copyWith(color: scheme.textPrimary, fontWeight: FontWeight.w900, fontSize: 11.sp),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Gap.h2,
          Text(
            label,
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

Widget _buildScanFactorRow(BuildContext context, _ScanFactor item) {
  final scheme = context.appColorScheme;
  final row = Padding(
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
                maxLines: 2,
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
            decoration: BoxDecoration(color: item.badgeColor ?? scheme.success, shape: BoxShape.circle),
          ),
        ] else if (item.trailing != null)
          item.trailing!
        else if (item.onTap != null)
          Icon(AppIcons.chevronRight, size: 18.sp, color: scheme.textMuted),
      ],
    ),
  );
  if (item.onTap == null) return row;
  return InkWell(onTap: item.onTap, borderRadius: BorderRadius.circular(12), child: row);
}

/// 🌟 Section 4: "What works for you" (positive factors).
class ScanWorkingSection extends StatelessWidget {
  const ScanWorkingSection({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
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
          iconColor: scheme.success,
          title: 'Organic',
          subtitle: 'No synthetic herbicides or pesticides',
          trailing: Icon(Icons.check_rounded, color: scheme.success, size: 18.sp),
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
          _ScanFactor(
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
          _ScanFactor(
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
          _ScanFactor(
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
          _ScanFactor(
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
          _ScanFactor(
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

    // 3. Positive green ingredients
    for (final ing in scanData.ingredients) {
      if (['green', 'low', 'positive'].contains(ing.colorName.toLowerCase())) {
        addPositive(
          _ScanFactor(
            icon: AppIcons.leaf,
            iconColor: scheme.success,
            title: ing.name,
            subtitle: ing.impact.isNotEmpty ? ing.impact : 'Beneficial gut food component',
            trailing: Icon(Icons.check_rounded, color: scheme.success, size: 18.sp),
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
            iconColor: scheme.success,
            title: imp.title,
            subtitle: imp.level.isNotEmpty ? imp.level : 'Supports gut wellness',
            trailing: Icon(Icons.check_rounded, color: scheme.success, size: 18.sp),
          ),
        );
      }
    }

    if (positiveItems.isEmpty) {
      positiveItems.add(
        _ScanFactor(
          icon: AppIcons.leaf,
          iconColor: scheme.success,
          title: 'Clean Ingredients',
          subtitle: 'No major gut triggers detected',
          trailing: Icon(Icons.check_rounded, color: scheme.success, size: 18.sp),
        ),
      );
    }

    return BentoCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
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
                    AppStrings.clinicalAudit,
                    style: context.title.copyWith(fontSize: 15.sp, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              Text(
                AppStrings.perServing(serving),
                style: context.caption.copyWith(color: scheme.textMuted, fontSize: 11.sp),
              ),
            ],
          ),
          Gap.h12,
          Divider(color: scheme.borderSubtle, height: 1),
          ...positiveItems.map((item) => _buildScanFactorRow(context, item)),
        ],
      ),
    );
  }
}

/// 🌟 Section 5: "What to watch" (negative factors + tappable additives/allergens).
class ScanWatchSection extends StatelessWidget {
  const ScanWatchSection({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final serving = scanData.servingSize ?? '1 serving';

    final negativeItems = <_ScanFactor>[];

    // 1. Unfavorable nutrients
    final n = scanData.nutrients;
    if (n != null) {
      if ((n.sugars ?? 0) > 10) {
        negativeItems.add(
          _ScanFactor(
            icon: AppIcons.candy,
            iconColor: scheme.error,
            title: 'High Sugar',
            subtitle: (n.sugars ?? 0) > 20 ? 'Too much sugar added' : 'High in sugar',
            valueText: '${(n.sugars ?? 0).toInt()}g',
            badgeColor: scheme.error,
          ),
        );
      }
      if ((n.salt ?? 0) > 0.5) {
        negativeItems.add(
          _ScanFactor(
            icon: AppIcons.scale,
            iconColor: scheme.error,
            title: 'Sodium',
            subtitle: (n.salt ?? 0) > 1.5 ? 'High sodium content' : 'Moderate sodium',
            valueText: '${((n.salt ?? 0) * 400).toInt()}mg',
            badgeColor: scheme.error,
          ),
        );
      }
      if ((n.saturatedFat ?? 0) > 2) {
        negativeItems.add(
          _ScanFactor(
            icon: AppIcons.droplet,
            iconColor: AppPalette.orange,
            title: 'Saturated Fat',
            subtitle: 'Pro-inflammatory fat level',
            valueText: '${(n.saturatedFat ?? 0).toInt()}g',
            badgeColor: AppPalette.orange,
          ),
        );
      }
      if ((n.calories ?? 0) > 250) {
        negativeItems.add(
          _ScanFactor(
            icon: AppIcons.flame,
            iconColor: AppPalette.orange,
            title: 'Calories',
            subtitle: 'High caloric density',
            valueText: '${(n.calories ?? 0).toInt()} Cal',
            badgeColor: AppPalette.orange,
          ),
        );
      }
    }

    // 2. Allergens (tappable → allergen detail)
    if (scanData.allergens != null && scanData.allergens!.isNotEmpty && parseAllergenItems(scanData.allergens).isNotEmpty) {
      negativeItems.add(
        _ScanFactor(
          icon: Icons.warning_amber_rounded,
          iconColor: scheme.error,
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
        final color = ing.colorName.toLowerCase() == 'red' ? scheme.error : AppPalette.orange;
        negativeItems.add(_ScanFactor(icon: AppIcons.leaf, iconColor: color, title: ing.name, subtitle: ing.impact.isNotEmpty ? ing.impact : 'Potential trigger ingredient', badgeColor: color));
      }
    }

    // 4. Moderate / higher-concern additives (tappable → additive detail)
    for (final concern in scanData.additiveConcerns) {
      if (concern.level == AdditiveConcernLevel.moderate || concern.level == AdditiveConcernLevel.higher) {
        negativeItems.add(
          _ScanFactor(
            icon: AppIcons.flaskConical,
            iconColor: additiveConcernColor(context, concern.level),
            title: concern.displayTitle,
            subtitle: concern.whyFlagged.isNotEmpty ? '${concern.level.label} concern · ${concern.whyFlagged}' : '${concern.level.label} concern',
            onTap: () => context.push(AppRoutes.additiveDetail, extra: concern),
          ),
        );
      }
    }

    if (negativeItems.isEmpty) {
      negativeItems.add(
        _ScanFactor(
          icon: Icons.shield_outlined,
          iconColor: scheme.success,
          title: 'No Major Triggers',
          subtitle: 'Low risk ingredient profile',
          trailing: Icon(Icons.check_rounded, color: scheme.success, size: 18.sp),
        ),
      );
    }

    return BentoCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      backgroundColor: isDark ? scheme.error.withAlpha(12) : AppPalette.orangeLight.withAlpha(20),
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
                    AppStrings.whatToWatch,
                    style: context.title.copyWith(fontSize: 15.sp, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              Text(
                AppStrings.perServing(serving),
                style: context.caption.copyWith(color: scheme.textMuted, fontSize: 11.sp),
              ),
            ],
          ),
          Gap.h12,
          Divider(color: scheme.borderSubtle, height: 1),
          ...negativeItems.map((item) => _buildScanFactorRow(context, item)),
        ],
      ),
    );
  }
}

/// 🌟 Section 6: "What this means for you" (hidden when the AI gave no narrative).
class ScanMeaningCard extends StatelessWidget {
  const ScanMeaningCard({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (scanData.impact.isEmpty) return const SizedBox.shrink();

    return BentoCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 20,
      backgroundColor: isDark ? AppPalette.purple.withAlpha(26) : AppPalette.purplePastel.withAlpha(26),
      borderColor: AppPalette.purple.withAlpha(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BentoCardHeader(title: 'WHAT THIS MEANS FOR YOU', icon: AppIcons.salad, textColor: AppPalette.purple, iconColor: AppPalette.purple),
          Gap.h12,
          Text(
            scanData.impact,
            style: context.bodySm.copyWith(color: isDark ? scheme.textSecondary : AppPalette.black.withAlpha(200), height: 1.5, fontWeight: FontWeight.w500, fontSize: 13.sp),
          ),
        ],
      ),
    );
  }
}

/// 🌟 Section 7: Better swaps (horizontal cards with working "+ Add" + detail tap).
class ScanSwapsSection extends StatelessWidget {
  const ScanSwapsSection({super.key, required this.swaps});
  final List<ProductSwap> swaps;

  @override
  Widget build(BuildContext context) {
    if (swaps.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            AppStrings.betterSwapsLabel,
            style: context.title.copyWith(fontSize: 15.sp, fontWeight: FontWeight.w900),
          ),
        ),
        Gap.h10,
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
    final scheme = context.appColorScheme;
    final imageUrl = (swap.imageUrl != null && swap.imageUrl!.isNotEmpty) ? swap.imageUrl! : getDynamicImageUrl(swap.imageKeyword.isNotEmpty ? swap.imageKeyword : swap.title);
    return InkWell(
      onTap: () => context.push(AppRoutes.swapDetail, extra: swap),
      borderRadius: BorderRadius.circular(16),
      child: BentoCard(
        width: 160.w,
        padding: const EdgeInsets.all(10),
        borderRadius: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(imageUrl: imageUrl, height: 82.h, width: double.infinity, fit: BoxFit.cover),
            ),
            Gap.h8,
            Text(
              swap.tag.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.captionBold.copyWith(color: scheme.success, fontSize: 9.sp, letterSpacing: 0.8),
            ),
            Gap.h2,
            Text(
              swap.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.labelBold.copyWith(fontSize: 12.5.sp, fontWeight: FontWeight.w800),
            ),
            Text(
              swap.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.caption.copyWith(color: scheme.textMuted, fontSize: 10.5.sp, height: 1.3),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => logSwapToJournal(context, swap),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(color: scheme.success.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(AppIcons.plus, size: 13.sp, color: scheme.success),
                    Gap.w4,
                    Text(
                      AppStrings.addLabel,
                      style: context.captionBold.copyWith(color: scheme.success, fontSize: 11.5.sp),
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

/// 🌟 Section 8: Additives (tappable rows → additive detail; clean state when none).
class ScanAdditivesSection extends StatelessWidget {
  const ScanAdditivesSection({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final sorted = [...scanData.additiveConcerns]..sort((a, b) => _concernRank(b.level).compareTo(_concernRank(a.level)));
    final visible = sorted.take(3).toList();

    return BentoCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.additivesLabel,
                style: context.title.copyWith(fontSize: 15.sp, fontWeight: FontWeight.w900),
              ),
              if (sorted.length > 3)
                InkWell(
                  onTap: () => context.push(
                    AppRoutes.scanListDetail,
                    extra: ScanListDetailArgs(kind: ScanListKind.additives, scan: scanData),
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      Text(
                        AppStrings.seeAll,
                        style: context.captionBold.copyWith(color: scheme.textSecondary, fontSize: 12.sp),
                      ),
                      Icon(AppIcons.chevronRight, size: 16.sp, color: scheme.textMuted),
                    ],
                  ),
                ),
            ],
          ),
          if (sorted.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(color: scheme.success.withAlpha(20), shape: BoxShape.circle),
                    child: Icon(Icons.check_rounded, size: 15.sp, color: scheme.success),
                  ),
                  Gap.w12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.noAdditivesDetected,
                          style: context.labelBold.copyWith(fontWeight: FontWeight.w800, fontSize: 12.5.sp),
                        ),
                        Text(
                          AppStrings.cleanLabelNote,
                          style: context.caption.copyWith(color: scheme.textMuted, fontSize: 10.5.sp),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            ...visible.map((concern) => _AdditiveRow(concern: concern)),
        ],
      ),
    );
  }
}

class _AdditiveRow extends StatelessWidget {
  const _AdditiveRow({required this.concern});
  final AdditiveConcern concern;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final color = additiveConcernColor(context, concern.level);
    final subtitle = concern.whyFlagged.isNotEmpty ? concern.whyFlagged : concern.whatItIs;
    return InkWell(
      onTap: () => context.push(AppRoutes.additiveDetail, extra: concern),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            Gap.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    concern.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.labelBold.copyWith(fontWeight: FontWeight.w800, fontSize: 12.5.sp),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.caption.copyWith(color: scheme.textMuted, fontSize: 10.5.sp),
                  ),
                ],
              ),
            ),
            Gap.w8,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withAlpha(22), borderRadius: BorderRadius.circular(6)),
              child: Text(
                concern.level.label,
                style: context.captionBold.copyWith(color: color, fontSize: 10.sp),
              ),
            ),
            Gap.w4,
            Icon(AppIcons.chevronRight, size: 18.sp, color: scheme.textMuted),
          ],
        ),
      ),
    );
  }
}

/// 🌟 Section 9a: Ingredients card (tappable → ingredient list detail).
class ScanIngredientsCard extends StatelessWidget {
  const ScanIngredientsCard({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final hasItems = scanData.ingredients.isNotEmpty;
    final preview = hasItems ? scanData.ingredients.take(4).map((e) => e.name).join(', ') : 'No ingredient data';
    return InkWell(
      onTap: hasItems
          ? () => context.push(
              AppRoutes.scanListDetail,
              extra: ScanListDetailArgs(kind: ScanListKind.ingredients, scan: scanData),
            )
          : null,
      borderRadius: BorderRadius.circular(20),
      child: BentoCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: scheme.success.withAlpha(20), shape: BoxShape.circle),
              child: Icon(AppIcons.wheat, size: 16.sp, color: scheme.success),
            ),
            Gap.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasItems ? '${AppStrings.ingredientsTitle} (${scanData.ingredients.length})' : AppStrings.ingredientsTitle,
                    style: context.labelBold.copyWith(fontWeight: FontWeight.w800, fontSize: 13.sp),
                  ),
                  Gap.h2,
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.caption.copyWith(color: scheme.textMuted, fontSize: 11.sp),
                  ),
                ],
              ),
            ),
            if (hasItems) Icon(AppIcons.chevronRight, size: 18.sp, color: scheme.textMuted),
          ],
        ),
      ),
    );
  }
}

/// 🌟 Section 9b: Allergens card (tappable → allergen list detail).
class ScanAllergensCard extends StatelessWidget {
  const ScanAllergensCard({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final items = parseAllergenItems(scanData.allergens);
    final hasItems = items.isNotEmpty;
    final color = hasItems ? scheme.error : scheme.success;
    return InkWell(
      onTap: hasItems
          ? () => context.push(
              AppRoutes.scanListDetail,
              extra: ScanListDetailArgs(kind: ScanListKind.allergens, scan: scanData),
            )
          : null,
      borderRadius: BorderRadius.circular(20),
      child: BentoCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
              child: Icon(hasItems ? Icons.warning_amber_rounded : Icons.check_rounded, size: 16.sp, color: color),
            ),
            Gap.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.allergensLabel,
                    style: context.labelBold.copyWith(fontWeight: FontWeight.w800, fontSize: 13.sp),
                  ),
                  Gap.h2,
                  Text(
                    hasItems ? items.join(', ') : 'None declared',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.caption.copyWith(color: scheme.textMuted, fontSize: 11.sp),
                  ),
                ],
              ),
            ),
            if (hasItems) Icon(AppIcons.chevronRight, size: 18.sp, color: scheme.textMuted),
          ],
        ),
      ),
    );
  }
}

/// 🌟 Section 10: Scan details (provenance footer rows).
class ScanDetailsCard extends StatelessWidget {
  const ScanDetailsCard({super.key, required this.scanData});
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
    final scheme = context.appColorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: context.caption.copyWith(color: scheme.textMuted)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: context.captionBold.copyWith(color: scheme.textPrimary),
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
    final scheme = context.appColorScheme;
    return InkWell(
      onTap: () => context.go(AppRoutes.chat),
      borderRadius: BorderRadius.circular(20),
      child: BentoCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        backgroundColor: AppPalette.purple.withAlpha(16),
        borderColor: AppPalette.purple.withAlpha(40),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppPalette.purple.withAlpha(26), shape: BoxShape.circle),
              child: Icon(AppIcons.sparkles, size: 16.sp, color: AppPalette.purple),
            ),
            Gap.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.scanFooterTitle,
                    style: context.labelBold.copyWith(fontWeight: FontWeight.w800, fontSize: 13.sp),
                  ),
                  Gap.h2,
                  Text(
                    AppStrings.scanFooterBody,
                    style: context.caption.copyWith(color: scheme.textMuted, fontSize: 11.sp),
                  ),
                ],
              ),
            ),
            Icon(AppIcons.chevronRight, size: 18.sp, color: scheme.textMuted),
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
  const BentoFoodCard({super.key, required this.foods, required this.title, required this.trend, required this.isPositive, required this.icon, this.score, this.highlight});
  final List<dynamic> foods;
  final String title;
  final String? trend;
  final bool isPositive;
  final IconData icon;
  final int? score;
  final TopHighlight? highlight;

  @override
  Widget build(BuildContext context) {
    if (title.toUpperCase() == 'RECENT LOGS') {
      debugPrint('--- BentoFoodCard: RECENT LOGS DATA DEBUG ---');
      debugPrint('Foods list length: ${foods.length}');
      for (var i = 0; i < foods.length; i++) {
        debugPrint('Item $i type: ${foods[i].runtimeType}');
        if (foods[i] is FoodImpact) {
          final fi = foods[i] as FoodImpact;
          debugPrint('  FoodImpact: ${fi.food}, ImageUrl: ${fi.imageUrl}');
        }
      }
      debugPrint('----------------------------------------------');
    }

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

    if (title.toUpperCase() == 'HEALING' || title.toUpperCase() == 'TRIGGERS' || title.toUpperCase() == 'RECENT LOGS' || title.toUpperCase() == 'BETTER SWAPS') {
      final displayScore = score ?? (isPositive ? 85 : 25);
      Color statusColor = isPositive ? const Color(0xFF27F15B) : const Color(0xFFE9579A);

      if (title.toUpperCase() == 'RECENT LOGS') {
        statusColor = const Color(0xFF0759E8); // Premium Blue for History
      }

      return DashboardEntrance(
        delay: 200,
        child: SuperFoodGaugeCard(
          title: title,
          label:
              highlight?.timeframe.toUpperCase() ??
              (title.toUpperCase() == 'RECENT LOGS' ? 'HISTORY' : (title.toUpperCase() == 'BETTER SWAPS' ? 'RECOMMENDED' : (isPositive ? 'POSITIVE PATTERNS' : 'NEGATIVE PATTERNS'))),
          score: displayScore,
          statusColor: statusColor,
          foods: items,
        ),
      );
    }

    return DashboardEntrance(
      delay: 200,
      child: SuperFoodCyclerCard(items: items, title: title, trend: trend, isPositive: isPositive, icon: icon),
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
  Widget build(BuildContext context) => BentoFoodCard(foods: impacts, title: 'RECENT LOGS', trend: null, isPositive: true, icon: AppIcons.history, score: score);
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
