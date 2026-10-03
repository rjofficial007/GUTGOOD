import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/insight_theme.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_feed/insight_ui_kit.dart';


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
        cardBg: Color(0xFFFEFCE8),
        borderColor: Color(0xFFFEF08A),
        tagBg: Color(0xFFFEF3C7),
        tagFg: Color(0xFFB45309),
        accentColor: Color(0xFFD97706),
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
    final style = PatternCardStyle.forPattern(pattern);

    final firstOccWithImage = pattern.occurrences.firstWhere(
      (o) => o.imageUrl != null && o.imageUrl!.isNotEmpty,
      orElse: () => const PatternOccurrence(date: '', mealName: '', reaction: '', timeAfter: ''),
    );
    final foodName = pattern.involvedFoods.isNotEmpty ? pattern.involvedFoods.first : (pattern.trigger.isNotEmpty ? pattern.trigger : style.label);
    final imageUrl = InsightUiKit.foodImageUrl(foodName, imageUrl: firstOccWithImage.imageUrl);

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
    } else if (pattern.confidenceScore > 0) {
      confidencePct = (pattern.confidenceScore * 100).round();
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
          confidencePct = 72;
        } else if (lower == 'low') {
          confidencePct = 55;
        }
      }
    }

    // Dynamic Description String
    final descStr = pattern.description.trim();

    // Dynamic CTA Label
    final ctaText = confidencePct > 0 ? 'DEEP DIVE ($confidencePct%)' : 'VIEW DETAILS';

    final accentColor = style.accentColor;
    const cardBgColor = Color(0xFF0F1015);
    const cardGradient = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF23272F), Color(0xFF0F1015)]);

    return Container(
      height: 160.w,
      decoration: BoxDecoration(gradient: cardGradient, borderRadius: BorderRadius.circular(24.w)),
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
                  padding: EdgeInsets.fromLTRB(16.w, 14.w, 12.w, 14.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Texts & Tag Pill
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Domain Category Pill Tag
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.w),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(100.w),
                              border: Border.all(color: accentColor.withValues(alpha: 0.40), width: 0.8.w),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(style.icon, size: 10.w, color: accentColor),
                                Gap.w4,
                                Text(
                                  rawTypeLabel.toUpperCase(),
                                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w800, color: accentColor, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                          Gap.h6,

                          // Line 1: Bold Title
                          Text(
                            headlineTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 16.sp, fontWeight: FontWeight.w800, color: Colors.white, height: 1.15, letterSpacing: -0.3),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            Gap.h2,

                            // Line 2: Subtitle
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w600, color: accentColor, height: 1.2, letterSpacing: -0.1),
                            ),
                          ],
                          if (descStr.isNotEmpty) ...[
                            Gap.h4,

                            // Line 3: Description String
                            Text(
                              descStr,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w400, color: const Color(0xFF94A3B8), height: 1.25),
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
                            width: 28.w,
                            height: 28.w,
                            decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                            child: Center(
                              child: Icon(Icons.north_east_rounded, size: 14.w, color: Colors.white),
                            ),
                          ),
                          Gap.w8,
                          Text(
                            ctaText,
                            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w800, color: accentColor, letterSpacing: 0.3),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Right Side Image (Blended with black background)
              SizedBox(
                width: 130.w,
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
                            color: Colors.white.withValues(alpha: 0.05),
                            child: Center(
                              child: Icon(style.icon, color: accentColor.withValues(alpha: 0.5), size: 28.w),
                            ),
                          ),
                          errorWidget: (_, _, _) => Container(
                            color: Colors.white.withValues(alpha: 0.05),
                            child: Center(
                              child: Icon(style.icon, color: accentColor.withValues(alpha: 0.7), size: 28.w),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Soft Black Background Overlay
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [cardBgColor, cardBgColor.withValues(alpha: 0.2), cardBgColor.withValues(alpha: 0.0)],
                            stops: const [0.0, 0.5, 1.0],
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
