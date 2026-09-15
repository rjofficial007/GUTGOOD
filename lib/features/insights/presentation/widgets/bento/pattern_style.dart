import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/insight_bento_theme.dart';

/// Brightness-aware surface resolver for the pattern-card language.
///
/// Light mode keeps the exact hexes from GUTGOOD_SCREENS.html; dark mode
/// derives the equivalent surfaces from the accent (a 14% accent wash over
/// the bento dark tile base) and swaps the ink/muted/foot text ramp so every
/// pattern-style card is readable on both themes without call-site changes.
abstract final class PatternSurface {
  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  static const Color _darkBase = Color(0xFF17181C); // bento dark tileBackground

  /// Card wash: the light pastel [lightTone], or accent blended over the dark base.
  static Color tone(BuildContext context, Color accent, Color lightTone) => isDark(context) ? Color.alphaBlend(accent.withValues(alpha: 0.14), _darkBase) : lightTone;

  static Color ink(BuildContext context) => isDark(context) ? const Color(0xFFF5F7FA) : const Color(0xFF181A2C);
  static Color muted(BuildContext context) => isDark(context) ? const Color(0xFFC3C9D4) : const Color(0xFF5C6070);
  static Color faint(BuildContext context) => isDark(context) ? const Color(0xFF8D96A5) : const Color(0xFF8A8E9E);
  static Color foot(BuildContext context) => isDark(context) ? const Color(0xFFC3C9D4) : const Color(0xFF33364A);

  /// The delta chip's translucent surface (white 72% in light, white 8% in dark).
  static Color chipBackground(BuildContext context) => isDark(context) ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.72);

  /// Elevated white card surface in light; the bento dark card base in dark.
  static Color card(BuildContext context) => isDark(context) ? const Color(0xFF121316) : Colors.white;

  /// The pattern-anatomy cards' soft elevated shadow (light only).
  static List<BoxShadow> softShadow(BuildContext context) =>
      isDark(context) ? const [] : [BoxShadow(color: const Color(0xFF141828).withValues(alpha: 0.07), blurRadius: 26.w, offset: Offset(0, 10.w))];

  /// Pattern-card drop shadow (light only — dark surfaces use the glow alone).
  static List<BoxShadow> shadow(BuildContext context) => isDark(context) ? const [] : [BoxShadow(color: const Color(0xFF5A4678).withValues(alpha: 0.07), blurRadius: 20.w, offset: Offset(0, 8.w))];
}

/// PatternCard-language building blocks (gallery redesign, GUTGOOD_SCREENS.html).
///
/// The score heroes across Insights (feed, learning, recap, synergy) and the
/// history cards all share one anatomy: a pastel tone wash, a 40px accent icon
/// tile with a w800 title, a filled status pill, a big w800 figure, a
/// data-driven chart slot, and a dot + chevron footer. [PatternHeroCard] is
/// that anatomy; [SeriesBars], [SlotSegs] and [SparkArea] are its charts.
///
/// Colors follow the same precedent as `PatternCard` in `pattern_grid.dart`:
/// callers pass concrete accent/tone hexes so the pattern language renders
/// identically on every screen.
class PatternHeroCard extends StatelessWidget {
  const PatternHeroCard({
    super.key,
    required this.accent,
    required this.tone,
    this.deep,
    this.icon,
    this.emoji,
    required this.title,
    this.sub,
    this.value,
    this.valueSuffix,
    this.valueColor,
    this.pill,
    this.chip,
    this.chipForeground,
    this.chipBorder,
    this.deltaSub,
    this.headline,
    this.description,
    this.chart,
    this.bottomWidget,
    this.footLeft,
    this.footRight,
    this.showChevron = true,
    this.onTap,
  });

  /// Accent color for the icon tile, pill, dot, chevron and chart.
  final Color accent;

  /// Deeper accent used for the delta chip text and the footer-right value.
  final Color? deep;

  /// Flat pastel wash behind the whole card (e.g. `#ECFDF5` for mint).
  final Color tone;

  /// Head-row icon. Exactly one of [icon] / [emoji] should be provided.
  final IconData? icon;
  final String? emoji;

  /// Head-row title (15px w800) and its muted one-line sub (e.g. "Last 7 Days").
  final String title;
  final String? sub;

  /// The big 44px w800 figure ("78") plus its muted suffix ("/100").
  /// When null, the hero renders [headline] + [description] instead — the
  /// synergy multiplier variant.
  final String? value;
  final String? valueSuffix;
  final Color? valueColor;

  /// Filled accent pill (uppercased): "THRIVING", "50% MAPPED", "3× RISK".
  final String? pill;

  /// Delta chip on the right of the value row ("↑ 5 pts").
  final String? chip;
  final Color? chipForeground;
  final Color? chipBorder;

  /// Small muted caption under the delta chip ("vs last week" in the gallery).
  final String? deltaSub;

  /// Large-title variant (synergy hero): 17.5px w800 headline + muted body.
  final String? headline;
  final String? description;

  /// Chart slot aligned in the score row (SeriesBars, SlotSegs, SparkArea…).
  final Widget? chart;

  /// Optional bottom widget slot below the score row (e.g. MiniFoodGrid).
  final Widget? bottomWidget;

  final String? footLeft;
  final String? footRight;
  final bool showChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final deep = this.deep ?? accent;
    final radius = 20.w;

    return Semantics(
      button: onTap != null,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: DecoratedBox(
            decoration: BoxDecoration(color: PatternSurface.tone(context, accent, tone), borderRadius: BorderRadius.circular(radius), boxShadow: PatternSurface.shadow(context)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _head(context),
                        if (value != null) ...[
                          Gap.h14,
                          _valueRow(context, deep),
                        ] else if (headline != null) ...[
                          Gap.h12,
                          Text(
                            headline!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: InsightBentoTheme.fontFamily,
                              fontSize: 17.5.sp,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                              letterSpacing: -0.35,
                              color: PatternSurface.ink(context),
                            ),
                          ),
                          if ((description ?? '').isNotEmpty) ...[
                            Gap.h6,
                            Text(
                              description!,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.5.sp, height: 1.45, color: PatternSurface.muted(context)),
                            ),
                          ],
                        ],
                        if (chart != null) ...[Gap.h14, chart!],
                        if (bottomWidget != null) ...[Gap.h12, bottomWidget!],
                        if (footLeft != null || footRight != null || (showChevron && onTap != null)) ...[Gap.h14, _footer(context, deep)],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _head(BuildContext context) => Row(
    children: [
      Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(12.w),
          boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.30), blurRadius: 14.w, offset: Offset(0, 6.w))],
        ),
        child: Center(
          child: emoji != null ? Text(emoji!, style: TextStyle(fontSize: 17.sp, height: 1)) : Icon(icon ?? AppIcons.activity, size: 20.w, color: Colors.white),
        ),
      ),
      Gap.w10,
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 15.sp, fontWeight: FontWeight.w800, letterSpacing: -0.2, color: PatternSurface.ink(context)),
            ),
            if (sub != null) ...[
              Gap.h2,
              Text(
                sub!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.sp, color: PatternSurface.muted(context)),
              ),
            ],
          ],
        ),
      ),
      if (pill != null && pill!.isNotEmpty) ...[
        Gap.w8,
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.w),
          decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(100)),
          child: Text(
            pill!.toUpperCase(),
            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: Colors.white),
          ),
        ),
      ],
    ],
  );

  Widget _valueRow(BuildContext context, Color deep) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            value!,
            maxLines: 1,
            style: TextStyle(
              fontFamily: InsightBentoTheme.fontFamily,
              fontSize: 40.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
              height: 1.0,
              fontFeatures: const [FontFeature.liningFigures(), FontFeature.tabularFigures()],
              color: valueColor ?? PatternSurface.ink(context),
            ),
          ),
          if (valueSuffix != null) ...[
            Gap.w4,
            Text(
              valueSuffix!,
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 13.sp, fontWeight: FontWeight.w600, color: PatternSurface.faint(context), height: 1.2),
            ),
          ],
        ],
      ),
      const Spacer(),
      if (chip != null) ...[
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.w),
              decoration: BoxDecoration(
                color: PatternSurface.chipBackground(context),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: chipBorder ?? accent.withValues(alpha: 0.3)),
              ),
              child: Text(
                chip!,
                style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w700, color: chipForeground ?? deep, height: 1.2),
              ),
            ),
            if (deltaSub != null) ...[
              Gap.h4,
              Text(
                deltaSub!,
                style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 10.5.sp, color: PatternSurface.muted(context)),
              ),
            ],
          ],
        ),
      ],
    ],
  );

  Widget _footer(BuildContext context, Color deep) => Row(
    children: [
      Container(
        width: 9.w,
        height: 9.w,
        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
      ),
      Gap.w8,
      Expanded(
        child: Text(
          footLeft ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w600, color: PatternSurface.foot(context)),
        ),
      ),
      if (footRight != null) ...[
        Gap.w8,
        Text(
          footRight!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: deep),
        ),
      ],
      if (showChevron && onTap != null) Icon(AppIcons.chevronRight, size: 15.w, color: accent),
    ],
  );
}

/// The hero's 7-day bar chart: one bar per point, alpha ramping .45 → 1.0
/// left to right, heights normalised between the series min and max, and an
/// optional FoilSpark-style ring dot on the peak bar.
class SeriesBars extends StatelessWidget {
  const SeriesBars({super.key, required this.values, required this.color, this.labels = const [], this.peak = false, this.height = 42});

  final List<double> values;
  final Color color;
  final List<String> labels;
  final bool peak;
  final double height;

  @override
  Widget build(BuildContext context) {
    // Ensure labels list is exactly 7 items long if labels were provided at all.
    final List<String> displayLabels;
    if (labels.isNotEmpty) {
      if (labels.length >= 7) {
        displayLabels = labels.sublist(labels.length - 7);
      } else {
        displayLabels = List.filled(7 - labels.length, '') + labels;
      }
    } else {
      displayLabels = const [];
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height.w,
          width: double.infinity,
          child: CustomPaint(
            painter: SeriesBarsPainter(values: values, color: color, peak: peak),
          ),
        ),
        if (displayLabels.isNotEmpty) ...[
          SizedBox(height: 6.w),
          Row(
            children: [
              for (final l in displayLabels)
                Expanded(
                  child: Text(
                    l,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: PatternSurface.muted(context)),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class SeriesBarsPainter extends CustomPainter {
  const SeriesBarsPainter({required this.values, required this.color, this.peak = false});

  final List<double> values;
  final Color color;
  final bool peak;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    const totalSlots = 7;
    final topPad = peak ? 8.0 : 2.0;
    final h = size.height - topPad;
    final cell = size.width / totalSlots;
    final barW = math.min(14.0, cell * 0.45);

    // Use only the last 7 values if more are provided.
    final data = values.length > totalSlots ? values.sublist(values.length - totalSlots) : values;
    final ghostCount = totalSlots - data.length;

    // Scale logic for actual data points.
    final lo = data.isEmpty ? 0.0 : data.reduce(math.min);
    final hi = data.isEmpty ? 0.0 : data.reduce(math.max);
    final range = hi - lo;
    double scale(double v) => range <= 0 ? 0.65 : (0.22 + 0.78 * ((v - lo) / range)).clamp(0.0, 1.0);

    var maxIdxInData = -1;
    if (data.isNotEmpty) {
      maxIdxInData = 0;
      for (var i = 1; i < data.length; i++) {
        if (data[i] > data[maxIdxInData]) maxIdxInData = i;
      }
    }

    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < totalSlots; i++) {
      final x = i * cell + (cell - barW) / 2;
      final trackRect = RRect.fromRectAndRadius(Rect.fromLTWH(x, topPad, barW, h), Radius.circular(barW / 2));

      // Draw background track capsule for every bar
      canvas.drawRRect(trackRect, trackPaint);

      final isGhost = i < ghostCount;
      final double rectH;

      if (isGhost) {
        rectH = 4.0;
        final ghostPaint = Paint()
          ..color = color.withValues(alpha: 0.12 + 0.08 * (i / (totalSlots - 1)))
          ..style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, topPad + h - rectH, barW, rectH), Radius.circular(barW / 2)), ghostPaint);
      } else {
        final dataIdx = i - ghostCount;
        rectH = math.max(h * scale(data[dataIdx]), 6.0);
        final barRect = Rect.fromLTWH(x, topPad + h - rectH, barW, rectH);

        final alpha = 0.55 + 0.45 * (i / (totalSlots - 1));
        final barPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: alpha * 0.7),
            ],
          ).createShader(barRect);

        canvas.drawRRect(RRect.fromRectAndRadius(barRect, Radius.circular(barW / 2)), barPaint);

        if (peak && data.length >= 2 && dataIdx == maxIdxInData) {
          final center = Offset(x + barW / 2, topPad + h - rectH);
          canvas
            ..drawCircle(center, 5.0, Paint()..color = color.withValues(alpha: 0.25))
            ..drawCircle(center, 3.5, Paint()..color = color)
            ..drawCircle(center, 1.6, Paint()..color = Colors.white);
        }
      }
    }
  }

  @override
  bool shouldRepaint(SeriesBarsPainter old) => !listEquals(old.values, values) || old.color != color || old.peak != peak;
}

/// The learning hero's progress chart: [total] uniform rounded slots, the
/// first [filled] of them lit with an alpha ramp, the rest ghosted at 12%.
class SlotSegs extends StatelessWidget {
  const SlotSegs({super.key, required this.filled, required this.total, required this.color, this.height = 22});

  final int filled;
  final int total;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height.w,
    width: double.infinity,
    child: CustomPaint(
      painter: SlotSegsPainter(filled: filled, total: total, color: color, ghostAlpha: PatternSurface.isDark(context) ? 0.18 : 0.10),
    ),
  );
}

class SlotSegsPainter extends CustomPainter {
  const SlotSegsPainter({required this.filled, required this.total, required this.color, this.ghostAlpha = 0.10});

  final int filled;
  final int total;
  final Color color;
  final double ghostAlpha;

  @override
  void paint(Canvas canvas, Size size) {
    final n = total.clamp(1, 12);
    final k = filled.clamp(0, n);
    if (size.width <= 0 || size.height <= 0) return;
    const gap = 5.0;
    final slotW = (size.width - gap * (n - 1)) / n;
    if (slotW <= 0) return;
    final r = Radius.circular(size.height / 2);

    for (var i = 0; i < n; i++) {
      final rect = Rect.fromLTWH(i * (slotW + gap), 0, slotW, size.height);
      final rrect = RRect.fromRectAndRadius(rect, r);

      canvas.drawRRect(rrect, Paint()..color = color.withValues(alpha: ghostAlpha));

      if (i < k) {
        final alpha = k <= 1 ? 1.0 : (0.60 + 0.40 * (i / (k - 1)));
        final fillPaint = Paint()
          ..shader = LinearGradient(
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: alpha * 0.85),
            ],
          ).createShader(rect);

        canvas.drawRRect(rrect, fillPaint);
      }
    }
  }

  @override
  bool shouldRepaint(SlotSegsPainter old) => old.filled != filled || old.total != total || old.color != color || old.ghostAlpha != ghostAlpha;
}

/// A filled sparkline over real values (stroke 2.5, cubic curve, area fade, peak halo dot).
class SparkArea extends StatelessWidget {
  const SparkArea({super.key, required this.values, required this.color, this.height = 36});

  final List<double> values;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height.w,
    width: double.infinity,
    child: CustomPaint(
      painter: SparkAreaPainter(values: values, color: color),
    ),
  );
}

class SparkAreaPainter extends CustomPainter {
  const SparkAreaPainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.width <= 0 || size.height <= 0) return;
    final w = size.width;
    final h = size.height;
    const padX = 4.0;
    const padY = 6.0;

    final lo = values.reduce(math.min);
    final hi = values.reduce(math.max);
    final range = hi - lo;

    Offset at(int i) {
      final x = padX + (w - padX * 2) * i / (values.length - 1);
      final t = range <= 0 ? 0.5 : (values[i] - lo) / range;
      return Offset(x, padY + (1 - t) * (h - padY * 2));
    }

    final path = Path();
    final points = [for (var i = 0; i < values.length; i++) at(i)];
    path.moveTo(points.first.dx, points.first.dy);

    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final control1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final control2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      path.cubicTo(control1.dx, control1.dy, control2.dx, control2.dy, p1.dx, p1.dy);
    }

    final areaPath = Path.from(path)
      ..lineTo(points.last.dx, h)
      ..lineTo(points.first.dx, h)
      ..close();

    canvas
      ..drawPath(
        areaPath,
        Paint()
          ..style = PaintingStyle.fill
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
          ).createShader(Rect.fromLTWH(0, 0, w, h)),
      )
      ..drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

    var maxIdx = 0;
    for (var i = 1; i < values.length; i++) {
      if (values[i] > values[maxIdx]) maxIdx = i;
    }
    final p = points[maxIdx];

    canvas
      ..drawCircle(p, 5.0, Paint()..color = color.withValues(alpha: 0.25))
      ..drawCircle(p, 3.5, Paint()..color = color)
      ..drawCircle(p, 1.6, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(SparkAreaPainter old) => !listEquals(old.values, values) || old.color != color;
}
