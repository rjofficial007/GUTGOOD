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
    final clampedScore = score.clamp(0, 100);
    final d = delta;
    final positive = d != null && d > 0;
    final shownSeries = series.length > 7 ? series.sublist(series.length - 7) : series;
    final shownLabels = labels.length > 7 ? labels.sublist(labels.length - 7) : labels;

    final band = GutScoreBand.fromScore(clampedScore);

    // Identical rich purple gradient colors used in DeepDiscoveryCard
    const gradientColors = [Colors.black, Colors.black];

    final effectiveTitle = title ?? AppStrings.bentoScoreEyebrow;
    final radius = 20.w; // Matching DeepDiscoveryCard radius

    return Semantics(
      button: onTap != null,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: const LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: gradientColors),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(18.w, 16.w, 16.w, 16.w), // Padding matched to DeepDiscoveryCard
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Left Column: Eyebrow, Large Bold Title/Score, Dark Pill Button
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Typography matched exactly to DeepDiscoveryCard subtitle/eyebrow text
                                Text(
                                  effectiveTitle.toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: InsightBentoTheme.fontFamily,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.85),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                Gap.h6,
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    // Typography matched exactly to DeepDiscoveryCard main bold white headline style attributes
                                    Text(
                                      '$clampedScore',
                                      style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 28.sp, fontWeight: FontWeight.w800, height: 1.20, letterSpacing: -0.4, color: Colors.white),
                                    ),
                                    Text(
                                      '/100',
                                      style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.70)),
                                    ),
                                  ],
                                ),
                                Gap.h14,

                                // Bottom Left Pill CTA Button matching DeepDiscoveryCard layout completely
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      d != null && d != 0 ? '${positive ? '↑ +' : '↓ '}$d pts this week' : band.label,
                                      style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: Colors.white),
                                    ),
                                    if (showChevron) ...[Gap.w4, Icon(Icons.arrow_forward_rounded, size: 14.w, color: Colors.white)],
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Right Column: Translucent 7-Day Bar Chart Overlay
                          if (showChart && shownSeries.isNotEmpty) ...[Gap.w16, CompactSeriesBars(values: shownSeries, color: Colors.white, labels: shownLabels, height: 52)],
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

  @override
  Widget build(BuildContext context) {
    final List<String> displayLabels;
    if (labels.isNotEmpty) {
      if (labels.length >= 7) {
        displayLabels = labels.sublist(labels.length - 7);
      } else {
        displayLabels = List.filled(7 - labels.length, '') + labels;
      }
    } else {
      displayLabels = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    }

    const totalSlots = 7;
    final data = values.length > totalSlots ? values.sublist(values.length - totalSlots) : values;
    final ghostCount = totalSlots - data.length;

    var maxIdxInData = -1;
    if (data.isNotEmpty) {
      maxIdxInData = 0;
      for (var i = 1; i < data.length; i++) {
        if (data[i] >= data[maxIdxInData]) maxIdxInData = i;
      }
    }
    final maxIdxInSlots = maxIdxInData != -1 ? maxIdxInData + ghostCount : -1;

    final chartWidth = 110.w;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height.w,
          width: chartWidth,
          child: CustomPaint(
            painter: _CompactBarsPainter(values: values, color: color),
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
                      fontWeight: i == maxIdxInSlots ? FontWeight.w900 : FontWeight.w700,
                      color: i == maxIdxInSlots ? Colors.white : Colors.white.withValues(alpha: 0.65),
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
  const _CompactBarsPainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    const totalSlots = 7;
    const topPad = 2.0;
    final h = size.height - topPad;
    final cell = size.width / totalSlots;
    final barW = math.min(6.0, cell * 0.42);

    final data = values.length > totalSlots ? values.sublist(values.length - totalSlots) : values;
    final ghostCount = totalSlots - data.length;

    final lo = data.isEmpty ? 0.0 : data.reduce(math.min);
    final hi = data.isEmpty ? 0.0 : data.reduce(math.max);
    final range = hi - lo;
    double scale(double v) => range <= 0 ? 0.60 : (0.25 + 0.75 * ((v - lo) / range)).clamp(0.0, 1.0);

    var maxIdxInData = -1;
    if (data.isNotEmpty) {
      maxIdxInData = 0;
      for (var i = 1; i < data.length; i++) {
        if (data[i] >= data[maxIdxInData]) maxIdxInData = i;
      }
    }

    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < totalSlots; i++) {
      final x = i * cell + (cell - barW) / 2;
      final trackRRect = RRect.fromRectAndRadius(Rect.fromLTWH(x, topPad, barW, h), Radius.circular(barW / 2));

      // Track capsule
      canvas.drawRRect(trackRRect, trackPaint);

      final isGhost = i < ghostCount;
      if (!isGhost) {
        final dataIdx = i - ghostCount;
        final rectH = math.max(h * scale(data[dataIdx]), 6.0);
        final barRect = Rect.fromLTWH(x, topPad + h - rectH, barW, rectH);
        final barRRect = RRect.fromRectAndRadius(barRect, Radius.circular(barW / 2));

        final isMax = dataIdx == maxIdxInData;
        final barPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isMax ? const [Colors.white, Color(0xFFC084FC)] : [Colors.white.withValues(alpha: 0.85), Colors.white.withValues(alpha: 0.35)],
          ).createShader(barRect)
          ..style = PaintingStyle.fill;

        canvas.drawRRect(barRRect, barPaint);

        // Highlight the peak day with a subtle glowing accent stroke
        if (isMax) {
          final glowPaint = Paint()
            ..color = Colors.white.withValues(alpha: 0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5;
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 1.5, topPad + h - rectH - 1.5, barW + 3, rectH + 3), Radius.circular((barW + 3) / 2)), glowPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_CompactBarsPainter old) => !listEquals(old.values, values) || old.color != color;
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
