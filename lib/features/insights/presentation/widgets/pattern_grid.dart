import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_theme.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/v2_kit.dart';

class PatternGrid extends StatelessWidget {
  const PatternGrid({super.key, required this.patterns});

  final List<BodyPattern> patterns;

  @override
  Widget build(BuildContext context) {
    final gap = 10.w;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < patterns.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          PatternCard(pattern: patterns[i]),
        ],
      ],
    );
  }
}

class PatternCardStyle {
  const PatternCardStyle({
    required this.cardBg,
    required this.borderColor,
    required this.tagBg,
    required this.tagFg,
    required this.accentColor,
    required this.icon,
    required this.label,
  });

  final Color cardBg;
  final Color borderColor;
  final Color tagBg;
  final Color tagFg;
  final Color accentColor;
  final IconData icon;
  final String label;

  static PatternCardStyle forType(String rawType) {
    final t = rawType.trim().toLowerCase();

    return switch (t) {
      'bloating' => const PatternCardStyle(
        cardBg: Color(0xFFF8F5FF),
        borderColor: Color(0xFFE9D8FD),
        tagBg: Color(0xFFEDE9FE),
        tagFg: Color(0xFF6D28D9),
        accentColor: Color(0xFF6D28D9),
        icon: AppIcons.wind,
        label: 'Bloating',
      ),
      'energy' => const PatternCardStyle(
        cardBg: Color(0xFFFFFDF0),
        borderColor: Color(0xFFFDE68A),
        tagBg: Color(0xFFFEF3C7),
        tagFg: Color(0xFFB45309),
        accentColor: Color(0xFFB45309),
        icon: AppIcons.zap,
        label: 'Energy',
      ),
      'headache' => const PatternCardStyle(
        cardBg: Color(0xFFFFF5F5),
        borderColor: Color(0xFFFEE2E2),
        tagBg: Color(0xFFFEE2E2),
        tagFg: Color(0xFFB91C1C),
        accentColor: Color(0xFFB91C1C),
        icon: AppIcons.brain,
        label: 'Headache',
      ),
      'digestion' || 'digestive' => const PatternCardStyle(
        cardBg: Color(0xFFF0FDF4),
        borderColor: Color(0xFFDCFCE7),
        tagBg: Color(0xFFDCFCE7),
        tagFg: Color(0xFF15803D),
        accentColor: Color(0xFF15803D),
        icon: AppIcons.leaf,
        label: 'Digestion',
      ),
      'fullness' => const PatternCardStyle(
        cardBg: Color(0xFFFFFBEB),
        borderColor: Color(0xFFFDE68A),
        tagBg: Color(0xFFFEF3C7),
        tagFg: Color(0xFFD97706),
        accentColor: Color(0xFFD97706),
        icon: AppIcons.chartPie,
        label: 'Fullness',
      ),
      'sleep' => const PatternCardStyle(
        cardBg: Color(0xFFF5F7FF),
        borderColor: Color(0xFFE0E7FF),
        tagBg: Color(0xFFE0E7FF),
        tagFg: Color(0xFF3730A3),
        accentColor: Color(0xFF3730A3),
        icon: AppIcons.moon,
        label: 'Sleep',
      ),
      _ => const PatternCardStyle(
        cardBg: Color(0xFFF6F2FF),
        borderColor: Color(0xFFE9DDFF),
        tagBg: Color(0xFFEADDFF),
        tagFg: Color(0xFF6750A4),
        accentColor: Color(0xFF6750A4),
        icon: AppIcons.sparkles,
        label: 'Pattern',
      ),
    };
  }
}

class PatternCard extends StatelessWidget {
  const PatternCard({super.key, required this.pattern});
  final BodyPattern pattern;

  @override
  Widget build(BuildContext context) {
    final v2 = context.v2Theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = PatternCardStyle.forType(pattern.type);
    final foodName = pattern.involvedFoods.isNotEmpty
        ? pattern.involvedFoods.first
        : pattern.trigger;
    final imageUrl = V2Kit.foodImageUrl(foodName);

    final trigger = pattern.trigger.trim();
    final reaction = pattern.reaction.trim();
    final title = (trigger.isNotEmpty || reaction.isNotEmpty)
        ? ((trigger.isNotEmpty && reaction.isNotEmpty)
              ? '$trigger → $reaction'
              : (trigger.isNotEmpty ? trigger : reaction))
        : style.label;

    return Container(
      height: 124.w,
      decoration: BoxDecoration(
        color: isDark ? v2.card : style.cardBg,
        borderRadius: BorderRadius.circular(18.w),
        border: Border.all(
          color: isDark ? v2.border : style.borderColor,
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? v2.textPrimary : style.accentColor).withValues(
              alpha: 0.05,
            ),
            blurRadius: 8.w,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => context.push(AppRoutes.patternDetail, extra: pattern),
          borderRadius: BorderRadius.circular(18.w),
          child: Stack(
            children: [
              // 1. Left Content Area
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                right: 120.w,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12.w, 10.w, 6.w, 10.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Tag Pill
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 3.w,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark ? v2.cardSubtle : style.tagBg,
                                  borderRadius: BorderRadius.circular(14.w),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      style.icon,
                                      size: 10.w,
                                      color: isDark
                                          ? v2.textPrimary
                                          : style.tagFg,
                                    ),
                                    Gap.w3,
                                    Text(
                                      style.label,
                                      style: TextStyle(
                                        fontFamily: InsightV2Theme.fontFamily,
                                        fontSize: 9.5.sp,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? v2.textPrimary
                                            : style.tagFg,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Gap.w6,
                              Text(
                                pattern.frequency > 0 ? '${pattern.frequency} logs' : 'Frequency unavailable',
                                style: TextStyle(
                                  fontFamily: InsightV2Theme.fontFamily,
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? v2.textSecondary
                                      : style.accentColor,
                                ),
                              ),
                            ],
                          ),
                          Gap.h4,

                          // Title
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: InsightV2Theme.fontFamily,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                              color: v2.textPrimary,
                              height: 1.15,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Gap.h2,

                          // Subtitle / Description
                          Text(
                            pattern.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: InsightV2Theme.fontFamily,
                              fontSize: 9.5.sp,
                              fontWeight: FontWeight.w500,
                              color: v2.textSecondary,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),

                      // Dark Pill View Button
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 11.w,
                          vertical: 4.5.w,
                        ),
                        decoration: BoxDecoration(
                          color: style.accentColor,
                          borderRadius: BorderRadius.circular(16.w),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View Pattern',
                              style: TextStyle(
                                fontFamily: InsightV2Theme.fontFamily,
                                fontSize: 9.5.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Gap.w3,
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 10.w,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Right Angled Food Photo
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 115.w,
                child: ClipPath(
                  clipper: const _RightAngledClipper(),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    placeholder: (_, _) =>
                        Container(color: isDark ? v2.cardSubtle : style.tagBg),
                    errorWidget: (_, _, _) => Container(
                      color: isDark ? v2.cardSubtle : style.tagBg,
                      child: Icon(
                        style.icon,
                        color: isDark ? v2.textSecondary : style.tagFg,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RightAngledClipper extends CustomClipper<Path> {
  const _RightAngledClipper();

  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width * 0.18, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Pattern identity helpers — shared by [PatternCard] and other pattern surfaces.
Color patternAccent(String type) => PatternCardStyle.forType(type).accentColor;
Color patternTone(String type) => PatternCardStyle.forType(type).cardBg;
IconData patternIcon(String type) => PatternCardStyle.forType(type).icon;
String patternName(String type) => PatternCardStyle.forType(type).label;

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
    final values = patternSeries(pattern);
    if (pattern.type == BodyPattern.typeEnergy ||
        pattern.type == BodyPattern.typeDigestion ||
        pattern.type == BodyPattern.typeSleep) {
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
  final List<double> values;


  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    if (values.length >= 2) {
      final data = values.length > 7
          ? values.sublist(values.length - 7)
          : values;
      final n = data.length;
      final maxV = data.reduce(math.max);
      const gap = 6.0;
      final barW = (w - gap * (n - 1)) / n;
      for (var i = 0; i < n; i++) {
        final t = maxV <= 0
            ? 0.5
            : (0.2 + 0.8 * (data[i] / maxV)).clamp(0.0, 1.0);
        final rectH = h * t;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(i * (barW + gap), h - rectH, barW, rectH),
            Radius.circular(math.min(5, barW / 2)),
          ),
          Paint()
            ..color = color.withValues(
              alpha: n == 1 ? 1.0 : 0.45 + 0.55 * (i / (n - 1)),
            ),
        );
      }
      return;
    }

    // Empty values mean there is no chart to draw.
    return;
  }

  @override
  bool shouldRepaint(BarPainter old) =>
      old.color != color || !listEquals(old.values, values);
}

class LinePainter extends CustomPainter {
  LinePainter({required this.color, this.values = const []});
  final Color color;
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
      final data = values.length > 7
          ? values.sublist(values.length - 7)
          : values;
      final n = data.length;
      final maxV = data.reduce(math.max);
      points = [
        for (var i = 0; i < n; i++)
          Offset(
            n == 1 ? 0 : w * i / (n - 1),
            h * (maxV <= 0 ? 0.5 : 0.85 - 0.7 * (data[i] / maxV)),
          ),
      ];
    } else {
      return;
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
  bool shouldRepaint(LinePainter old) =>
      old.color != color || !listEquals(old.values, values);
}
