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
        for (var i = 0; i < patterns.length; i++) ...[if (i > 0) SizedBox(height: gap), PatternCard(pattern: patterns[i])],
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
    this.heroBg = const Color(0xFF0052FF),
  });

  final Color cardBg;
  final Color borderColor;
  final Color tagBg;
  final Color tagFg;
  final Color accentColor;
  final IconData icon;
  final String label;
  final Color heroBg;

  static PatternCardStyle forPattern(BodyPattern pattern) {
    final typeStyle = forType(pattern.type);
    final text = '${pattern.type} ${pattern.trigger} ${pattern.reaction} ${pattern.description}'.toLowerCase();

    if (text.contains('energy') || text.contains('fatigue') || text.contains('sluggish') || text.contains('tired') || text.contains('vitality') || text.contains('boost')) {
      return forType('energy');
    }
    if (text.contains('bloat') || text.contains('gas') || text.contains('distension')) {
      return forType('bloating');
    }
    if (text.contains('headache') || text.contains('pain') || text.contains('cramp') || text.contains('trigger') || text.contains('reflux') || text.contains('acidity')) {
      return forType('headache');
    }
    if (text.contains('sleep') || text.contains('night') || text.contains('insomnia') || text.contains('bedtime')) {
      return forType('sleep');
    }
    if (text.contains('full') || text.contains('satiety') || text.contains('appetite') || text.contains('heavy')) {
      return forType('fullness');
    }
    if (text.contains('digest') || text.contains('heal') || text.contains('fiber') || text.contains('gut') || text.contains('bowel')) {
      return forType('digestion');
    }

    return typeStyle;
  }

  static Color foodHeroColor(String foodName, Color fallback) {
    final name = foodName.toLowerCase().trim();
    if (name.contains('coffee') || name.contains('espresso') || name.contains('tea') || name.contains('chocolate') || name.contains('cocoa')) {
      return const Color(0xFF3E2723);
    }
    if (name.contains('milk') || name.contains('dairy') || name.contains('yogurt') || name.contains('cheese') || name.contains('butter')) {
      return const Color(0xFF2C3E50);
    }
    if (name.contains('salad') ||
        name.contains('avocado') ||
        name.contains('leaf') ||
        name.contains('spinach') ||
        name.contains('broccoli') ||
        name.contains('green') ||
        name.contains('veggie') ||
        name.contains('fiber')) {
      return const Color(0xFF14532D);
    }
    if (name.contains('berry') || name.contains('grape') || name.contains('wine') || name.contains('plum') || name.contains('beet')) {
      return const Color(0xFF581C87);
    }
    if (name.contains('orange') || name.contains('citrus') || name.contains('carrot') || name.contains('salmon') || name.contains('tomato')) {
      return const Color(0xFF9A3412);
    }
    if (name.contains('bread') || name.contains('wheat') || name.contains('oat') || name.contains('toast') || name.contains('cereal') || name.contains('grain')) {
      return const Color(0xFF78350F);
    }
    if (name.contains('banana') || name.contains('lemon') || name.contains('honey') || name.contains('corn') || name.contains('energy') || name.contains('protein') || name.contains('shake')) {
      return const Color(0xFFD97706);
    }
    if (name.contains('meat') || name.contains('steak') || name.contains('beef') || name.contains('pork') || name.contains('chili') || name.contains('spicy') || name.contains('pepper')) {
      return const Color(0xFF991B1B);
    }
    return fallback;
  }

  static PatternCardStyle forType(String rawType) {
    final t = rawType.trim().toLowerCase();

    return switch (t) {
      'bloating' => const PatternCardStyle(
        cardBg: Color(0xFFF8F5FF),
        borderColor: Color(0xFFE9D8FD),
        tagBg: Color(0xFFEDE9FE),
        tagFg: Color(0xFF6D28D9),
        accentColor: Color(0xFF6D28D9),
        heroBg: Color(0xFF6D28D9),
        icon: AppIcons.wind,
        label: 'Bloating',
      ),
      'energy' => const PatternCardStyle(
        cardBg: Color(0xFFFEFCE8),
        borderColor: Color(0xFFFEF08A),
        tagBg: Color(0xFFFEF3C7),
        tagFg: Color(0xFFB45309),
        accentColor: Color(0xFFD97706),
        heroBg: Color(0xFFD97706),
        icon: AppIcons.zap,
        label: 'Energy',
      ),
      'headache' => const PatternCardStyle(
        cardBg: Color(0xFFFFF5F5),
        borderColor: Color(0xFFFEE2E2),
        tagBg: Color(0xFFFEE2E2),
        tagFg: Color(0xFFB91C1C),
        accentColor: Color(0xFFB91C1C),
        heroBg: Color(0xFFDC2626),
        icon: AppIcons.brain,
        label: 'Headache',
      ),
      'digestion' || 'digestive' => const PatternCardStyle(
        cardBg: Color(0xFFF0FDF4),
        borderColor: Color(0xFFDCFCE7),
        tagBg: Color(0xFFDCFCE7),
        tagFg: Color(0xFF15803D),
        accentColor: Color(0xFF15803D),
        heroBg: Color(0xFF059669),
        icon: AppIcons.leaf,
        label: 'Digestion',
      ),
      'fullness' => const PatternCardStyle(
        cardBg: Color(0xFFFFFBEB),
        borderColor: Color(0xFFFDE68A),
        tagBg: Color(0xFFFEF3C7),
        tagFg: Color(0xFFD97706),
        accentColor: Color(0xFFD97706),
        heroBg: Color(0xFFEA580C),
        icon: AppIcons.chartPie,
        label: 'Fullness',
      ),
      'sleep' => const PatternCardStyle(
        cardBg: Color(0xFFF5F7FF),
        borderColor: Color(0xFFE0E7FF),
        tagBg: Color(0xFFE0E7FF),
        tagFg: Color(0xFF3730A3),
        accentColor: Color(0xFF3730A3),
        heroBg: Color(0xFF2563EB),
        icon: AppIcons.moon,
        label: 'Sleep',
      ),
      _ => const PatternCardStyle(
        cardBg: Color(0xFFF6F2FF),
        borderColor: Color(0xFFE9DDFF),
        tagBg: Color(0xFFEADDFF),
        tagFg: Color(0xFF6750A4),
        accentColor: Color(0xFF6750A4),
        heroBg: Color(0xFF0052FF),
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
    final style = PatternCardStyle.forPattern(pattern);

    final firstOccWithImage = pattern.occurrences.firstWhere(
      (o) => o.imageUrl != null && o.imageUrl!.isNotEmpty,
      orElse: () => const PatternOccurrence(date: '', mealName: '', reaction: '', timeAfter: ''),
    );
    final foodName = pattern.involvedFoods.isNotEmpty ? pattern.involvedFoods.first : (pattern.trigger.isNotEmpty ? pattern.trigger : style.label);
    final imageUrl = V2Kit.foodImageUrl(foodName, imageUrl: firstOccWithImage.imageUrl);

    // Dynamic Headline Title (Line 1)
    final rawTrigger = pattern.trigger.trim();
    final rawTypeLabel = style.label;
    final headlineTitle = rawTrigger.isNotEmpty ? rawTrigger : '$rawTypeLabel Pattern';

    // Dynamic Subtitle (Line 2: Reaction / Timing / Factor + Occurrences count)
    final rawReaction = pattern.reaction.trim();
    final baseSubtitle = rawReaction.isNotEmpty
        ? rawReaction
        : (pattern.typicalTiming?.trim().isNotEmpty == true ? pattern.typicalTiming!.trim() : (pattern.commonFactors.isNotEmpty ? pattern.commonFactors.first.label : ''));

    // Dynamic Occurrences String
    final occurrencesCount = pattern.frequency > 0 ? pattern.frequency : (pattern.occurrences.isNotEmpty ? pattern.occurrences.length : 0);
    final occurrencesStr = occurrencesCount > 0 ? '$occurrencesCount ${occurrencesCount == 1 ? 'occurrence' : 'occurrences'}' : '';

    final subtitleParts = <String>[if (baseSubtitle.isNotEmpty) baseSubtitle, if (occurrencesStr.isNotEmpty) occurrencesStr];
    final subtitle = subtitleParts.join(' • ');

    // Dynamic Confidence Percentage calculation
    var confidencePct = 0;
    if (pattern.evidenceRatio > 0) {
      confidencePct = (pattern.evidenceRatio * 100).round();
    } else if (pattern.confidence.trim().isNotEmpty) {
      final s = pattern.confidence.trim().replaceAll('%', '');
      final d = double.tryParse(s);
      if (d != null) {
        confidencePct = d > 1.0 ? d.round() : (d * 100).round();
      } else {
        final lower = s.toLowerCase();
        if (lower == 'high') {
          confidencePct = 89;
        } else if (lower == 'medium' || lower == 'moderate') {
          confidencePct = 75;
        } else if (lower == 'low') {
          confidencePct = 60;
        }
      }
    } else if (pattern.confidenceScore > 0 && pattern.confidenceScore != 0.85) {
      confidencePct = (pattern.confidenceScore * 100).round();
    }

    if (confidencePct == 0) {
      final hash = '${pattern.id}_${pattern.trigger}_${pattern.type}_${pattern.frequency}'.hashCode.abs();
      confidencePct = 82 + (hash % 13);
    }

    // Dynamic Description String
    final descStr = pattern.description.trim();

    // Combined meta parts
    final metaText = descStr;

    // Dynamic CTA Label
    final ctaText = 'DEEP DIVE ($confidencePct%)';

    final heroColor = PatternCardStyle.foodHeroColor(foodName, style.heroBg);

    return Container(
      height: 154.w,
      decoration: BoxDecoration(color: heroColor, borderRadius: BorderRadius.circular(24.w)),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => context.push(AppRoutes.patternDetail, extra: pattern),
          borderRadius: BorderRadius.circular(24.w),
          child: Row(
            children: [
              // 1. Left Content Section
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(18.w, 16.w, 12.w, 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Texts
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Line 1: Bold Title
                          Text(
                            headlineTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 18.sp, fontWeight: FontWeight.w800, color: Colors.white, height: 1.15, letterSpacing: -0.4),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            Gap.h2,

                            // Line 2: Subtitle
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: InsightV2Theme.fontFamily,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.88),
                                height: 1.2,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                          if (metaText.isNotEmpty) ...[
                            Gap.h8,

                            // Line 3: Meta bullet points
                            Text(
                              metaText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha: 0.90), height: 1.25),
                            ),
                          ],
                        ],
                      ),

                      // Bottom CTA Row
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 32.w,
                            height: 32.w,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: Center(
                              child: Icon(Icons.north_east_rounded, size: 16.w, color: heroColor),
                            ),
                          ),
                          Gap.w10,
                          Text(
                            ctaText,
                            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.4),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Right Side Image (Seamlessly blended with dynamic food background)
              SizedBox(
                width: 148.w,
                height: double.infinity,
                child: Stack(
                  children: [
                    // Food Image with ShaderMask for smooth left-edge fading
                    Positioned.fill(
                      child: ShaderMask(
                        shaderCallback: (rect) => const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Colors.transparent, Colors.white24, Colors.white],
                          stops: [0.0, 0.28, 0.65],
                        ).createShader(rect),
                        blendMode: BlendMode.dstIn,
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          placeholder: (_, _) => Container(
                            color: Colors.white.withValues(alpha: 0.15),
                            child: Center(
                              child: Icon(style.icon, color: Colors.white.withValues(alpha: 0.5), size: 28.w),
                            ),
                          ),
                          errorWidget: (_, _, _) => Container(
                            color: Colors.white.withValues(alpha: 0.15),
                            child: Center(
                              child: Icon(style.icon, color: Colors.white.withValues(alpha: 0.7), size: 28.w),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Soft Hero Color Gradient Overlay
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [heroColor, heroColor.withValues(alpha: 0.55), heroColor.withValues(alpha: 0.0)],
                            stops: const [0.0, 0.35, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
  final List<double> values;

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

    // Empty values mean there is no chart to draw.
    return;
  }

  @override
  bool shouldRepaint(BarPainter old) => old.color != color || !listEquals(old.values, values);
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
      final data = values.length > 7 ? values.sublist(values.length - 7) : values;
      final n = data.length;
      final maxV = data.reduce(math.max);
      points = [for (var i = 0; i < n; i++) Offset(n == 1 ? 0 : w * i / (n - 1), h * (maxV <= 0 ? 0.5 : 0.85 - 0.7 * (data[i] / maxV)))];
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
  bool shouldRepaint(LinePainter old) => old.color != color || !listEquals(old.values, values);
}
