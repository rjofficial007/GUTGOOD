import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/utils/gut_score_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/insight_bento_theme.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/pattern_style.dart';

/// Style variants for displaying the Gut Score widget.
enum GutScoreCardStyle {
  /// Prominent gradient banner style matching the modern card reference.
  hero,

  /// Minimal pill/badge suitable for list headers, tiles, and inline summaries.
  compact,

  /// Radial gauge/meter style suitable for hero banners and cards.
  gauge,
}

/// A standalone, dedicated widget to display the user's Gut Score.
class GutScoreCard extends StatelessWidget {
  const GutScoreCard({
    super.key,
    required this.score,
    this.delta,
    this.series = const [],
    this.labels = const [],
    this.title,
    this.subtitle,
    this.footLeft,
    this.footRight,
    this.showChevron = true,
    this.showChart = true,
    this.style = GutScoreCardStyle.hero,
    this.onTap,
  });

  /// Creates a compact pill/badge version of the Gut Score.
  const factory GutScoreCard.compact({Key? key, required int score, int? delta, VoidCallback? onTap}) = _CompactGutScoreCard;

  /// Creates a gauge version of the Gut Score.
  const factory GutScoreCard.gauge({Key? key, required int score, VoidCallback? onTap}) = _GaugeGutScoreCard;

  /// The Gut Score value (0–100).
  final int score;

  /// Optional net point change (e.g., +5 or -3).
  final int? delta;

  /// Chronological score values for the 7-day trend chart.
  final List<double> series;

  /// Weekday or date labels corresponding to [series].
  final List<String> labels;

  /// Custom eyebrow or title text.
  final String? title;

  /// Custom subtitle text.
  final String? subtitle;

  /// Custom footer left text.
  final String? footLeft;

  /// Custom footer right text.
  final String? footRight;

  /// Whether to display the right chevron arrow on tap.
  final bool showChevron;

  /// Whether to display the 7-day bar chart on the right side of the card.
  final bool showChart;

  /// Card visual style variant.
  final GutScoreCardStyle style;

  /// Optional tap callback.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case GutScoreCardStyle.compact:
        return _CompactGutScoreCard(score: score, delta: delta, onTap: onTap);
      case GutScoreCardStyle.gauge:
        return _GaugeGutScoreCard(score: score, onTap: onTap);
      case GutScoreCardStyle.hero:
        return Padding(padding: const EdgeInsets.only(top: 10), child: _buildHeroCard(context));
    }
  }

  Widget _buildHeroCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final clampedScore = score.clamp(0, 100);
    final d = delta;
    final positive = d != null && d > 0;
    final shownSeries = series.length > 7 ? series.sublist(series.length - 7) : series;
    final shownLabels = labels.length > 7 ? labels.sublist(labels.length - 7) : labels;

    final effectiveTitle = title ?? AppStrings.bentoScoreEyebrow;
    final radius = 20.w;

    final cardBg = isDark ? Colors.black : Colors.white;
    final cardBorder = isDark ? Border.all(color: const Color(0xFF1E293B)) : Border.all(color: const Color(0xFFE2E8F0));
    final cardShadow = isDark
        ? [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4))]
        : [BoxShadow(color: const Color(0xFF17171B).withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 4))];

    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final scoreValueColor = isDark ? Colors.white.withValues(alpha: 0.70) : const Color(0xFF64748B);
    final subtitleColor = isDark ? Colors.white.withValues(alpha: 0.80) : const Color(0xFF475569);
    final ctaTextColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Semantics(
      button: onTap != null,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(radius), border: cardBorder, boxShadow: cardShadow),
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(18.w, 16.w, 16.w, 16.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Left Column: Headline Title, Score Subtitle, Body Description, Circular CTA Button
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 1. Title (e.g. "YOUR GUT SCORE", "GUTGOOD SCORE", "WEEKLY AVERAGE")
                                Text(
                                  effectiveTitle.toUpperCase(),
                                  style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: titleColor, letterSpacing: -0.2, height: 1.15),
                                ),
                                Gap.h2,

                                // 2. Subtitle Value (e.g. "52/100")
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '$clampedScore',
                                      style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 22.sp, fontWeight: FontWeight.w400, color: scoreValueColor, letterSpacing: -0.3),
                                    ),
                                    Text(
                                      '/100',
                                      style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w400, color: scoreValueColor),
                                    ),
                                  ],
                                ),
                                if (subtitle != null && subtitle!.isNotEmpty) ...[
                                  Gap.h6,

                                  // 3. Body Description
                                  Text(
                                    subtitle!,
                                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w400, color: subtitleColor, height: 1.3),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                if (showChevron) ...[
                                  Gap.h12,

                                  // 4. Bottom CTA Row (Circular Dark Button + Uppercase Bold Label)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 24.w,
                                        height: 24.w,
                                        decoration: BoxDecoration(color: isDark ? Colors.white : const Color(0xFF0F172A), shape: BoxShape.circle),
                                        child: Center(
                                          child: Icon(Icons.north_east_rounded, size: 12.w, color: isDark ? const Color(0xFF0F172A) : Colors.white),
                                        ),
                                      ),
                                      Gap.w8,
                                      Text(() {
                                        if (shownSeries.isNotEmpty) {
                                          final nonZeroIndices = <int>[];
                                          for (var i = 0; i < shownSeries.length; i++) {
                                            if (shownSeries[i] > 0) {
                                              nonZeroIndices.add(i);
                                            }
                                          }
                                          if (nonZeroIndices.length >= 2) {
                                            final currentIndex = nonZeroIndices.last;
                                            final previousIndex = nonZeroIndices[nonZeroIndices.length - 2];
                                            final currentVal = shownSeries[currentIndex];
                                            final prevVal = shownSeries[previousIndex];
                                            final diff = (currentVal - prevVal).round();
                                            if (diff > 0) return '↑ +$diff vs yesterday';
                                            if (diff < 0) return '↓ $diff vs yesterday';
                                            return 'No change vs yesterday';
                                          }
                                        }
                                        if (d != null && d != 0 && shownSeries.length <= 1) {
                                          return '${positive ? '↑ +' : '↓ '}$d pts';
                                        }
                                        return 'Great start today!';
                                      }(), style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w800, letterSpacing: 0.2, color: ctaTextColor)),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Right Column: 7-Day Bar Chart
                          if (showChart && shownSeries.isNotEmpty) ...[
                            Gap.w16,
                            CompactSeriesBars(values: shownSeries, color: isDark ? Colors.white : const Color(0xFF0F172A), labels: shownLabels, height: 52),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Thin, compact 7-day capsule bar chart designed for gradient banners.
class CompactSeriesBars extends StatelessWidget {
  const CompactSeriesBars({super.key, required this.values, required this.color, this.labels = const [], this.height = 52});

  final List<double> values;
  final Color color;
  final List<String> labels;
  final double height;

  static List<double> padSlots(List<double> values) {
    const totalSlots = 7;
    if (values.isEmpty) {
      return List.filled(totalSlots, 0.0);
    }

    // If values is ALREADY a 7-day calendar week series (Sun..Sat), return as-is
    if (values.length >= totalSlots) {
      return values.sublist(values.length - totalSlots);
    }

    final todayIndex = DateTime.now().weekday % 7; // 0 = Sun, 1 = Mon ... 6 = Sat
    final data = List<double>.filled(totalSlots, 0.0);

    // If a single score is provided as fallback, put it at today's index
    if (values.length == 1) {
      data[todayIndex] = values.first;
      return data;
    }

    // If K items are provided (ending today), map back from todayIndex
    final lastIdx = values.length - 1;
    for (var i = 0; i < values.length; i++) {
      final daysAgo = lastIdx - i;
      var slot = (todayIndex - daysAgo) % totalSlots;
      if (slot < 0) slot += totalSlots;
      data[slot] = values[i];
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayLabels = labels.length >= 7 ? labels.sublist(labels.length - 7) : const ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    final data = padSlots(values);

    final todayIndex = DateTime.now().weekday % 7;
    var activeIdx = -1;
    if (data[todayIndex] > 0) {
      activeIdx = todayIndex;
    } else {
      for (var i = 0; i < data.length; i++) {
        if (data[i] > 0 && (activeIdx < 0 || data[i] >= data[activeIdx])) {
          activeIdx = i;
        }
      }
    }

    final chartWidth = 110.w;
    final activeLabelColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final inactiveLabelColor = isDark ? Colors.white.withValues(alpha: 0.65) : const Color(0xFF94A3B8);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height.w,
          width: chartWidth,
          child: CustomPaint(
            painter: _CompactBarsPainter(values: values, color: color, isDark: isDark),
          ),
        ),
        SizedBox(height: 6.w),
        SizedBox(
          width: chartWidth,
          child: Row(
            children: [
              for (var i = 0; i < displayLabels.length; i++)
                Expanded(
                  child: Text(
                    displayLabels[i].isNotEmpty ? displayLabels[i][0].toUpperCase() : '',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: InsightBentoTheme.fontFamily,
                      fontSize: 9.sp,
                      fontWeight: i == activeIdx ? FontWeight.w900 : FontWeight.w700,
                      color: i == activeIdx ? activeLabelColor : inactiveLabelColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactBarsPainter extends CustomPainter {
  const _CompactBarsPainter({required this.values, required this.color, required this.isDark});

  final List<double> values;
  final Color color;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    const totalSlots = 7;
    const topPad = 2.0;
    final h = size.height - topPad;
    final cell = size.width / totalSlots;
    final barW = math.min(6.0, cell * 0.42);

    final data = CompactSeriesBars.padSlots(values);

    double scale(double v) {
      if (v <= 0) return 0.0;
      return (v / 100.0).clamp(0.15, 1.0);
    }

    final todayIndex = DateTime.now().weekday % 7;
    var activeIdx = -1;
    if (data[todayIndex] > 0) {
      activeIdx = todayIndex;
    } else {
      for (var i = 0; i < data.length; i++) {
        if (data[i] > 0 && (activeIdx < 0 || data[i] >= data[activeIdx])) {
          activeIdx = i;
        }
      }
    }

    final trackPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFF1F5F9)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < totalSlots; i++) {
      final x = i * cell + (cell - barW) / 2;
      final trackRRect = RRect.fromRectAndRadius(Rect.fromLTWH(x, topPad, barW, h), Radius.circular(barW / 2));

      // Track capsule always present so empty days still show the day slot.
      canvas.drawRRect(trackRRect, trackPaint);

      final value = data[i];
      if (value <= 0) continue; // no score that day → empty track only

      final rectH = math.max(h * scale(value), 6.0);
      final barRect = Rect.fromLTWH(x, topPad + h - rectH, barW, rectH);
      final barRRect = RRect.fromRectAndRadius(barRect, Radius.circular(barW / 2));

      final isMax = i == activeIdx;

      final activeGradient = isDark ? const [Color(0xFFFFFFFF), Color(0xFFD9FF30)] : const [Color(0xFF84CC16), Color(0xFF4D7C0F)];

      final inactiveGradient = isDark
          ? [const Color(0xFFD9FF30).withValues(alpha: 0.85), const Color(0xFF84CC16).withValues(alpha: 0.40)]
          : [const Color(0xFF84CC16).withValues(alpha: 0.75), const Color(0xFF65A30D).withValues(alpha: 0.35)];

      final barPaint = Paint()
        ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: isMax ? activeGradient : inactiveGradient).createShader(barRect)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(barRRect, barPaint);

      if (isMax) {
        final glowColor = isDark ? const Color(0xFFD9FF30).withValues(alpha: 0.6) : const Color(0xFF65A30D).withValues(alpha: 0.5);
        final glowPaint = Paint()
          ..color = glowColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 1.5, topPad + h - rectH - 1.5, barW + 3, rectH + 3), Radius.circular((barW + 3) / 2)), glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_CompactBarsPainter old) => !listEquals(old.values, values) || old.color != color || old.isDark != isDark;
}

class _CompactGutScoreCard extends GutScoreCard {
  const _CompactGutScoreCard({super.key, required super.score, super.delta, super.onTap}) : super(style: GutScoreCardStyle.compact);

  @override
  Widget build(BuildContext context) {
    final clampedScore = score.clamp(0, 100);
    final band = GutScoreBand.fromScore(clampedScore);
    final color = band.color;
    final d = delta;

    return Semantics(
      button: onTap != null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.w),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12.w),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                Gap.w8,
                Text(
                  '$clampedScore',
                  style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 16.sp, fontWeight: FontWeight.w800, color: PatternSurface.ink(context)),
                ),
                Text(
                  '/100',
                  style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w600, color: PatternSurface.faint(context)),
                ),
                Gap.w8,
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.w),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6.w)),
                  child: Text(
                    band.label.toUpperCase(),
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 9.sp, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
                if (d != null) ...[
                  Gap.w6,
                  Text(
                    '${d > 0 ? '↑' : '↓'}${d.abs()}',
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w700, color: d > 0 ? const Color(0xFF10B981) : const Color(0xFFF87171)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugeGutScoreCard extends GutScoreCard {
  const _GaugeGutScoreCard({super.key, required super.score, super.onTap}) : super(style: GutScoreCardStyle.gauge);

  @override
  Widget build(BuildContext context) {
    final clampedScore = score.clamp(0, 100);
    final band = GutScoreBand.fromScore(clampedScore);
    final color = band.color;
    final progress = clampedScore / 100.0;

    return Semantics(
      button: onTap != null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.w),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: PatternSurface.card(context),
              borderRadius: BorderRadius.circular(20.w),
              boxShadow: PatternSurface.softShadow(context),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 80.w,
                  height: 80.w,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 7.w,
                          strokeCap: StrokeCap.round,
                          backgroundColor: color.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$clampedScore',
                            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 24.sp, fontWeight: FontWeight.w800, color: PatternSurface.ink(context)),
                          ),
                          Text(
                            'SCORE',
                            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 8.sp, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: PatternSurface.faint(context)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Gap.h8,
                Text(
                  band.label,
                  style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 13.sp, fontWeight: FontWeight.w700, color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
