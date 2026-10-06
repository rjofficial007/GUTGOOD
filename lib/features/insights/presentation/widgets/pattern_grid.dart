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
    required this.gradientColors,
    required this.highlightColor,
    required this.highlightForeground,
    required this.icon,
    required this.label,
  });

  final Color cardBg;
  final Color borderColor;
  final Color tagBg;
  final Color tagFg;
  final Color accentColor;
  final List<Color> gradientColors;
  final Color highlightColor;
  final Color highlightForeground;
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
        gradientColors: [Color(0xFF21152E), Color(0xFF45239B)],
        highlightColor: Color(0xFF6040F6),
        highlightForeground: Colors.white,
        icon: AppIcons.wind,
        label: 'Bloating',
      ),
      'energy' => const PatternCardStyle(
        cardBg: Color(0xFFFEFCE8),
        borderColor: Color(0xFFFEF08A),
        tagBg: Color(0xFFFEF3C7),
        tagFg: Color(0xFFB45309),
        accentColor: Color(0xFFD97706),
        gradientColors: [Color(0xFF202316), Color(0xFF3E4B20)],
        highlightColor: Color(0xFFA1F278),
        highlightForeground: Color(0xFF111111),
        icon: AppIcons.zap,
        label: 'Energy',
      ),
      'headache' => const PatternCardStyle(
        cardBg: Color(0xFFFFF5F5),
        borderColor: Color(0xFFFEE2E2),
        tagBg: Color(0xFFFEE2E2),
        tagFg: Color(0xFFB91C1C),
        accentColor: Color(0xFFB91C1C),
        gradientColors: [Color(0xFF261522), Color(0xFF56264F)],
        highlightColor: Color(0xFFE99CEF),
        highlightForeground: Color(0xFF111111),
        icon: AppIcons.brain,
        label: 'Headache',
      ),
      'digestion' || 'digestive' => const PatternCardStyle(
        cardBg: Color(0xFFF0FDF4),
        borderColor: Color(0xFFDCFCE7),
        tagBg: Color(0xFFDCFCE7),
        tagFg: Color(0xFF15803D),
        accentColor: Color(0xFF15803D),
        gradientColors: [Color(0xFF14261D), Color(0xFF234D35)],
        highlightColor: Color(0xFFA1F278),
        highlightForeground: Color(0xFF111111),
        icon: AppIcons.leaf,
        label: 'Digestion',
      ),
      'fullness' => const PatternCardStyle(
        cardBg: Color(0xFFFFFBEB),
        borderColor: Color(0xFFFDE68A),
        tagBg: Color(0xFFFEF3C7),
        tagFg: Color(0xFFD97706),
        accentColor: Color(0xFFD97706),
        gradientColors: [Color(0xFF29210F), Color(0xFF554313)],
        highlightColor: Color(0xFFE99CEF),
        highlightForeground: Color(0xFF111111),
        icon: AppIcons.chartPie,
        label: 'Fullness',
      ),
      'sleep' => const PatternCardStyle(
        cardBg: Color(0xFFF5F7FF),
        borderColor: Color(0xFFE0E7FF),
        tagBg: Color(0xFFE0E7FF),
        tagFg: Color(0xFF3730A3),
        accentColor: Color(0xFF3730A3),
        gradientColors: [Color(0xFF19152B), Color(0xFF373072)],
        highlightColor: Color(0xFF6040F6),
        highlightForeground: Colors.white,
        icon: AppIcons.moon,
        label: 'Sleep',
      ),
      _ => const PatternCardStyle(
        cardBg: Color(0xFFF6F2FF),
        borderColor: Color(0xFFE9DDFF),
        tagBg: Color(0xFFEADDFF),
        tagFg: Color(0xFF6750A4),
        accentColor: Color(0xFF6750A4),
        gradientColors: [Color(0xFF15151C), Color(0xFF3D3296)],
        highlightColor: Color(0xFFA1F278),
        highlightForeground: Color(0xFF111111),
        icon: AppIcons.sparkles,
        label: 'Pattern',
      ),
    };
  }
}

class PatternCard extends StatelessWidget {
  const PatternCard({super.key, required this.pattern, this.interactive = true});

  final BodyPattern pattern;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final style = PatternCardStyle.forPattern(pattern);
    final trigger = pattern.trigger.trim().isNotEmpty ? pattern.trigger.trim() : 'Logged meal';
    final reaction = pattern.reaction.trim().isNotEmpty ? pattern.reaction.trim() : '${style.label} response';
    final occurrenceCount = pattern.frequency > 0 ? pattern.frequency : pattern.occurrences.length;
    final observationText = occurrenceCount == 1 ? '1 observation' : '$occurrenceCount observations';
    final timeframeText = pattern.timeframeDays > 0 ? '${pattern.timeframeDays} days' : null;
    final description = pattern.description.trim();
    final metaText = timeframeText == null ? observationText : '$observationText • $timeframeText';
    final backgroundFoodName = pattern.involvedFoods.isNotEmpty ? pattern.involvedFoods.first : trigger;

    return Semantics(
      button: interactive,
      label: '${style.label} pattern. $trigger may be linked to $reaction.',
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: style.gradientColors),
          borderRadius: BorderRadius.circular(20.w),
          boxShadow: [BoxShadow(color: style.highlightColor.withValues(alpha: 0.2), blurRadius: 22.w, offset: Offset(0, 9.w))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: interactive ? () => context.push(AppRoutes.patternDetail, extra: pattern) : null,
            borderRadius: BorderRadius.circular(20.w),
            child: Stack(
              children: [
                Positioned.fill(
                  child: InsightUiKit.foodImage(
                    backgroundFoodName,
                    fit: BoxFit.cover,
                    placeholder: ColoredBox(color: style.gradientColors.first),
                    errorWidget: ColoredBox(color: style.gradientColors.first),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Colors.black.withValues(alpha: 0.68), Colors.black.withValues(alpha: 0.48), Colors.black.withValues(alpha: 0.24)],
                        stops: const [0, 0.58, 1],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 20.w, 16.w, 18.w),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 7,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(width: 20.w, height: 1.5.w, color: Colors.white.withValues(alpha: 0.82)),
                                Gap.w8,
                                Text(
                                  '${style.label.toUpperCase()} PATTERN',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.sp, fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.9), letterSpacing: 1.1),
                                ),
                              ],
                            ),
                            Gap.h12,
                            Text(
                              trigger,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 18.sp, fontWeight: FontWeight.w800, color: Colors.white, height: 1.12, letterSpacing: -0.35),
                            ),
                            Gap.h4,
                            Text(
                              'Followed by $reaction',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.86)),
                            ),
                            if (description.isNotEmpty) ...[
                              Gap.h6,
                              Text(
                                description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha: 0.78), height: 1.25),
                              ),
                            ],
                            Gap.h10,
                            Text(
                              metaText,
                              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.sp, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.86)),
                            ),
                            Gap.h12,
                            if (interactive) Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 36.w,
                                  height: 36.w,
                                  decoration: BoxDecoration(
                                    color: style.highlightColor,
                                    borderRadius: BorderRadius.circular(100.w),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(style.icon, size: 18.w, color: style.highlightForeground),
                                ),
                                Gap.w8,
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 9.w),
                                  decoration: BoxDecoration(color: style.highlightColor, borderRadius: BorderRadius.circular(100.w)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Explore pattern',
                                        style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w800, color: style.highlightForeground),
                                      ),
                                      Gap.w6,
                                      Icon(Icons.arrow_forward_rounded, size: 13.w, color: style.highlightForeground),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 174.w),
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
