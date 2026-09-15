import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/bento_widgets.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/pattern_style.dart';

class PatternGrid extends StatelessWidget {
  const PatternGrid({super.key, required this.patterns});
  final List<BodyPattern> patterns;

  @override
  Widget build(BuildContext context) {
    final gap = 12.w;
    // Split patterns into rows of 2, matching the BentoGrid's 2-column rhythm.
    // We avoid LayoutBuilder here because this grid often sits inside an
    // IntrinsicHeight (e.g. within a BentoTile), and LayoutBuilder cannot
    // answer intrinsic-dimension queries.
    final rows = <List<BodyPattern>>[];
    for (var i = 0; i < patterns.length; i += 2) {
      rows.add(patterns.sublist(i, math.min(i + 2, patterns.length)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: PatternCard(pattern: rows[i][0])),
                SizedBox(width: gap),
                Expanded(child: rows[i].length > 1 ? PatternCard(pattern: rows[i][1]) : const SizedBox.shrink()),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class PatternCard extends StatelessWidget {
  const PatternCard({super.key, required this.pattern});
  final BodyPattern pattern;

  @override
  Widget build(BuildContext context) {
    final accent = patternAccent(pattern.type);
    final tone = patternTone(pattern.type);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.patternDetail, extra: pattern),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(color: PatternSurface.tone(context, accent, tone), borderRadius: BorderRadius.circular(18.w), boxShadow: PatternSurface.shadow(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(10.w)),
                  child: Center(child: Icon(patternIcon(pattern.type), color: Colors.white, size: 16)),
                ),
                Gap.w8,
                Expanded(
                  child: Text(
                    patternName(pattern.type),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 13.sp, fontWeight: FontWeight.w800, color: PatternSurface.ink(context)),
                  ),
                ),
                Text(
                  '${pattern.frequency} logs',
                  style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: accent),
                ),
              ],
            ),
            Gap.h8,
            Text(
              pattern.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.sp, color: PatternSurface.muted(context), height: 1.4),
            ),
            Gap.h8,
            SizedBox(
              height: 50.w,
              child: MiniChart(pattern: pattern, color: accent),
            ),
            Gap.h8,
            Row(
              children: [
                Container(
                  width: 9.w,
                  height: 9.w,
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                ),
                Gap.w8,
                Text(
                  pattern.confidence,
                  style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w600, color: PatternSurface.foot(context)),
                ),
                const Spacer(),
                Icon(AppIcons.chevronRight, size: 15, color: accent),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Pattern identity helpers — shared by [PatternCard], the synergy drivers and
/// any other surface that renders a [BodyPattern] in the pattern language.
Color patternAccent(String type) => switch (type) {
  BodyPattern.typeBloating => const Color(0xFF8B5CF6),
  BodyPattern.typeEnergy => const Color(0xFF57B93B),
  BodyPattern.typeHeadache => const Color(0xFFF08019),
  BodyPattern.typeDigestion => const Color(0xFF14A38F),
  BodyPattern.typeFullness => const Color(0xFFEFB008),
  BodyPattern.typeSleep => const Color(0xFF6B74E8),
  _ => const Color(0xFF8B5CF6),
};

Color patternTone(String type) => switch (type) {
  BodyPattern.typeBloating => const Color(0xFFF5EEFC),
  BodyPattern.typeEnergy => const Color(0xFFF0F8EA),
  BodyPattern.typeHeadache => const Color(0xFFFDF1E7),
  BodyPattern.typeDigestion => const Color(0xFFE9F6F3),
  BodyPattern.typeFullness => const Color(0xFFFDF6E2),
  BodyPattern.typeSleep => const Color(0xFFEEF0FB),
  _ => const Color(0xFFF5EEFC),
};

IconData patternIcon(String type) => switch (type) {
  BodyPattern.typeBloating => AppIcons.wind,
  BodyPattern.typeEnergy => AppIcons.zap,
  BodyPattern.typeHeadache => AppIcons.brain,
  BodyPattern.typeDigestion => AppIcons.leaf,
  BodyPattern.typeFullness => AppIcons.chartPie,
  BodyPattern.typeSleep => AppIcons.moon,
  _ => AppIcons.sparkles,
};

String patternName(String type) => switch (type) {
  BodyPattern.typeBloating => 'Bloating',
  BodyPattern.typeEnergy => 'Energy',
  BodyPattern.typeHeadache => 'Headache',
  BodyPattern.typeDigestion => 'Digestion',
  BodyPattern.typeFullness => 'Fullness',
  BodyPattern.typeSleep => 'Sleep',
  _ => type.toUpperCase(),
};

/// Real chart data for a pattern's mini chart: the per-day episode counts over
/// the 7 days ending on the most recent dated occurrence. Returns an empty
/// list when fewer than 2 occurrences carry a parseable date, which makes the
/// painters fall back to their decorative shapes.
List<double> patternSeries(BodyPattern pattern) {
  final dates = <DateTime>[];
  for (final o in pattern.occurrences) {
    final d = DateTime.tryParse(o.date);
    if (d != null) dates.add(DateTime(d.year, d.month, d.day));
  }
  if (dates.length < 2) return const [];
  dates.sort();
  final end = dates.last;
  final start = end.subtract(const Duration(days: 6));
  final buckets = List<double>.filled(7, 0);
  for (final d in dates) {
    final idx = d.difference(start).inDays;
    if (idx >= 0 && idx < 7) buckets[idx] += 1;
  }
  return buckets;
}

class MiniChart extends StatelessWidget {
  const MiniChart({super.key, required this.pattern, required this.color});
  final BodyPattern pattern;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Real per-day episode counts when the pattern has dated occurrences;
    // otherwise the painters draw their decorative fallback shapes.
    final values = patternSeries(pattern);
    if (pattern.type == BodyPattern.typeEnergy || pattern.type == BodyPattern.typeDigestion || pattern.type == BodyPattern.typeSleep) {
      return CustomPaint(
        size: Size.infinite,
        painter: LinePainter(color: color, values: values),
      );
    }
    return CustomPaint(
      size: Size.infinite,
      painter: BarPainter(color: color, values: values),
    );
  }
}

class BarPainter extends CustomPainter {
  BarPainter({required this.color, this.values = const []});
  final Color color;

  /// Real series (per-day counts). Empty falls back to the decorative shape.
  final List<double> values;

  static const List<double> _fallback = [0.2, 0.5, 0.4, 0.7, 0.55, 0.9];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    if (values.length >= 2) {
      final data = values.length > 7 ? values.sublist(values.length - 7) : values;
      final n = data.length;
      final maxV = data.reduce(math.max);
      const gap = 6.0;
      final barW = (w - gap * (n - 1)) / n;
      for (var i = 0; i < n; i++) {
        final t = maxV <= 0 ? 0.5 : (0.2 + 0.8 * (data[i] / maxV)).clamp(0.0, 1.0);
        final rectH = h * t;
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(i * (barW + gap), h - rectH, barW, rectH), Radius.circular(math.min(5, barW / 2))),
          Paint()..color = color.withValues(alpha: n == 1 ? 1.0 : 0.45 + 0.55 * (i / (n - 1))),
        );
      }
      return;
    }

    final barW = (w - 30) / 6;
    for (var i = 0; i < 6; i++) {
      final rectH = h * _fallback[i];
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(i * (barW + 6), h - rectH, barW, rectH), const Radius.circular(5)), Paint()..color = color.withValues(alpha: 0.5 + (i * 0.08)));
    }
  }

  @override
  bool shouldRepaint(BarPainter old) => old.color != color || !listEquals(old.values, values);
}

class LinePainter extends CustomPainter {
  LinePainter({required this.color, this.values = const []});
  final Color color;

  /// Real series (per-day counts). Empty falls back to the decorative shape.
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    final List<Offset> points;
    if (values.length >= 2) {
      final data = values.length > 7 ? values.sublist(values.length - 7) : values;
      final n = data.length;
      final maxV = data.reduce(math.max);
      points = [for (var i = 0; i < n; i++) Offset(n == 1 ? 0 : w * i / (n - 1), h * (maxV <= 0 ? 0.5 : 0.85 - 0.7 * (data[i] / maxV)))];
    } else {
      points = [Offset(0, h * 0.7), Offset(w * 0.16, h * 0.4), Offset(w * 0.33, h * 0.6), Offset(w * 0.5, h * 0.2), Offset(w * 0.66, h * 0.4), Offset(w * 0.83, h * 0.1), Offset(w, h * 0.3)];
    }

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);

    final dotPaint = Paint()..color = color;
    for (final p in points) {
      canvas.drawCircle(p, 3.4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(LinePainter old) => old.color != color || !listEquals(old.values, values);
}
