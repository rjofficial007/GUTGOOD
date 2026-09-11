import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/bento_widgets.dart';

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
                Expanded(
                  child: rows[i].length > 1
                      ? PatternCard(pattern: rows[i][1])
                      : const SizedBox.shrink(),
                ),
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
    final accent = _getAccent(pattern.type);
    final tone = _getTone(pattern.type);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.patternDetail, extra: pattern),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: tone,
          borderRadius: BorderRadius.circular(18.w),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5A4678).withValues(alpha: 0.07),
              blurRadius: 20.w,
              offset: Offset(0, 8.w),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(10.w),
                  ),
                  child: Center(
                    child: Icon(_getIcon(pattern.type), color: Colors.white, size: 16),
                  ),
                ),
                Gap.w8,
                Expanded(
                  child: Text(
                    _getName(pattern.type),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: InsightBentoTheme.fontFamily,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF181A2C),
                    ),
                  ),
                ),
                Text(
                  '${pattern.frequency} logs',
                  style: TextStyle(
                    fontFamily: InsightBentoTheme.fontFamily,
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ],
            ),
            Gap.h8,
            Text(
              pattern.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: InsightBentoTheme.fontFamily,
                fontSize: 11.sp,
                color: const Color(0xFF5C6070),
                height: 1.4,
              ),
            ),
            Gap.h8,
            SizedBox(
              height: 36.w,
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
                  style: TextStyle(
                    fontFamily: InsightBentoTheme.fontFamily,
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF33364A),
                  ),
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

  Color _getAccent(String type) => switch (type) {
        BodyPattern.typeBloating => const Color(0xFF8B5CF6),
        BodyPattern.typeEnergy => const Color(0xFF57B93B),
        BodyPattern.typeHeadache => const Color(0xFFF08019),
        BodyPattern.typeDigestion => const Color(0xFF14A38F),
        BodyPattern.typeFullness => const Color(0xFFEFB008),
        BodyPattern.typeSleep => const Color(0xFF6B74E8),
        _ => const Color(0xFF8B5CF6),
      };

  Color _getTone(String type) => switch (type) {
        BodyPattern.typeBloating => const Color(0xFFF5EEFC),
        BodyPattern.typeEnergy => const Color(0xFFF0F8EA),
        BodyPattern.typeHeadache => const Color(0xFFFDF1E7),
        BodyPattern.typeDigestion => const Color(0xFFE9F6F3),
        BodyPattern.typeFullness => const Color(0xFFFDF6E2),
        BodyPattern.typeSleep => const Color(0xFFEEF0FB),
        _ => const Color(0xFFF5EEFC),
      };

  IconData _getIcon(String type) => switch (type) {
        BodyPattern.typeBloating => AppIcons.wind,
        BodyPattern.typeEnergy => AppIcons.zap,
        BodyPattern.typeHeadache => AppIcons.brain,
        BodyPattern.typeDigestion => AppIcons.leaf,
        BodyPattern.typeFullness => AppIcons.chartPie,
        BodyPattern.typeSleep => AppIcons.moon,
        _ => AppIcons.sparkles,
      };

  String _getName(String type) => switch (type) {
        BodyPattern.typeBloating => 'Bloating',
        BodyPattern.typeEnergy => 'Energy',
        BodyPattern.typeHeadache => 'Headache',
        BodyPattern.typeDigestion => 'Digestion',
        BodyPattern.typeFullness => 'Fullness',
        BodyPattern.typeSleep => 'Sleep',
        _ => type.toUpperCase(),
      };
}

class MiniChart extends StatelessWidget {
  const MiniChart({super.key, required this.pattern, required this.color});
  final BodyPattern pattern;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (pattern.type == BodyPattern.typeEnergy || pattern.type == BodyPattern.typeDigestion || pattern.type == BodyPattern.typeSleep) {
      return CustomPaint(
        size: Size.infinite,
        painter: LinePainter(color: color),
      );
    }
    return CustomPaint(
      size: Size.infinite,
      painter: BarPainter(color: color),
    );
  }
}

class BarPainter extends CustomPainter {
  BarPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final w = size.width;
    final h = size.height;
    final barW = (w - 30) / 6;
    final heights = [0.2, 0.5, 0.4, 0.7, 0.55, 0.9];
    for (var i = 0; i < 6; i++) {
      final rectH = h * heights[i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * (barW + 6), h - rectH, barW, rectH),
          const Radius.circular(5),
        ),
        paint..color = color.withValues(alpha: 0.5 + (i * 0.08)),
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter old) => false;
}

class LinePainter extends CustomPainter {
  LinePainter({required this.color});
  final Color color;

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
    final points = [
      Offset(0, h * 0.7),
      Offset(w * 0.16, h * 0.4),
      Offset(w * 0.33, h * 0.6),
      Offset(w * 0.5, h * 0.2),
      Offset(w * 0.66, h * 0.4),
      Offset(w * 0.83, h * 0.1),
      Offset(w, h * 0.3),
    ];

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
  bool shouldRepaint(CustomPainter old) => false;
}
