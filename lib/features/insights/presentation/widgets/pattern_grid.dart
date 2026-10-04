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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryText = isDark ? Colors.white.withValues(alpha: 0.72) : const Color(0xFF64748B);
    final surface = isDark ? const Color(0xFF17181C) : style.cardBg;
    final border = isDark ? style.accentColor.withValues(alpha: 0.34) : style.borderColor;

    final trigger = pattern.trigger.trim().isNotEmpty ? pattern.trigger.trim() : 'Logged meal';
    final reaction = pattern.reaction.trim().isNotEmpty ? pattern.reaction.trim() : '${style.label} response';
    String? occurrenceImage;
    for (final occurrence in pattern.occurrences) {
      if (occurrence.imageUrl != null && occurrence.imageUrl!.isNotEmpty) {
        occurrenceImage = occurrence.imageUrl;
        break;
      }
    }
    final foodName = pattern.involvedFoods.isNotEmpty ? pattern.involvedFoods.first : trigger;
    final foodImageUrl = InsightUiKit.foodImageUrl(foodName, imageUrl: occurrenceImage);
    final occurrenceCount = pattern.frequency > 0 ? pattern.frequency : pattern.occurrences.length;
    final observationText = occurrenceCount == 1 ? '1 observation' : '$occurrenceCount observations';
    final timeframeText = pattern.timeframeDays > 0 ? '${pattern.timeframeDays} days' : null;
    final confidencePct = _patternConfidencePercent(pattern);
    final evidenceText = confidencePct > 0
        ? '$confidencePct% match'
        : (pattern.confidence.trim().isNotEmpty ? pattern.confidence.trim() : 'Building evidence');
    final description = pattern.description.trim();

    return Semantics(
      button: true,
      label: '${style.label} pattern. $trigger may be linked to $reaction.',
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20.w),
          border: Border.all(color: border, width: 1.w),
          boxShadow: isDark ? const [] : [BoxShadow(color: style.accentColor.withValues(alpha: 0.08), blurRadius: 18.w, offset: Offset(0, 7.w))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => context.push(AppRoutes.patternDetail, extra: pattern),
            borderRadius: BorderRadius.circular(20.w),
            child: Padding(
              padding: EdgeInsets.all(14.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34.w,
                        height: 34.w,
                        decoration: BoxDecoration(color: style.accentColor, borderRadius: BorderRadius.circular(11.w)),
                        child: Icon(style.icon, size: 18.w, color: Colors.white),
                      ),
                      Gap.w10,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${style.label} pattern',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: primaryText),
                            ),
                            Gap.h2,
                            Text(
                              'Detected from your logs',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w500, color: secondaryText),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.w),
                        decoration: BoxDecoration(
                          color: style.accentColor.withValues(alpha: isDark ? 0.18 : 0.12),
                          borderRadius: BorderRadius.circular(100.w),
                          border: Border.all(color: style.accentColor.withValues(alpha: 0.28), width: 0.8.w),
                        ),
                        child: Text(
                          evidenceText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w800, color: style.accentColor),
                        ),
                      ),
                    ],
                  ),
                  Gap.h14,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _PatternIdentityNode(
                          label: 'TRIGGER',
                          value: trigger,
                          imageUrl: foodImageUrl,
                          icon: style.icon,
                          accentColor: style.accentColor,
                          primaryText: primaryText,
                          isDark: isDark,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 22.w),
                        child: Icon(Icons.arrow_forward_rounded, size: 16.w, color: secondaryText),
                      ),
                      Expanded(
                        child: _PatternIdentityNode(
                          label: 'RESPONSE',
                          value: reaction,
                          icon: style.icon,
                          accentColor: style.accentColor,
                          primaryText: primaryText,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    Gap.h10,
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w400, color: secondaryText, height: 1.3),
                    ),
                  ],
                  Gap.h12,
                  Row(
                    children: [
                      Icon(Icons.insights_outlined, size: 14.w, color: secondaryText),
                      Gap.w4,
                      Expanded(
                        child: Text(
                          timeframeText == null ? observationText : '$observationText • $timeframeText',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w700, color: secondaryText),
                        ),
                      ),
                      Gap.w8,
                      Text(
                        'View pattern',
                        style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w800, color: style.accentColor),
                      ),
                      Gap.w3,
                      Icon(Icons.arrow_forward_rounded, size: 14.w, color: style.accentColor),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PatternIdentityNode extends StatelessWidget {
  const _PatternIdentityNode({required this.label, required this.value, this.imageUrl, this.icon, required this.accentColor, required this.primaryText, required this.isDark});

  final String label;
  final String value;
  final String? imageUrl;
  final IconData? icon;
  final Color accentColor;
  final Color primaryText;
  final bool isDark;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.w),
    decoration: BoxDecoration(
      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(13.w),
      border: Border.all(color: accentColor.withValues(alpha: isDark ? 0.25 : 0.18)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.sp, fontWeight: FontWeight.w800, letterSpacing: 0.7, color: accentColor),
        ),
        Gap.h3,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _visual,
            Gap.w5,
            Expanded(child: _valueText()),
          ],
        ),
      ],
    ),
  );

  Widget get _visual {
    final size = 38.w;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(9.w),
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, _) => _PatternImageFallback(color: accentColor, icon: icon ?? Icons.restaurant_outlined, size: size),
          errorWidget: (_, _, _) => _PatternImageFallback(color: accentColor, icon: icon ?? Icons.restaurant_outlined, size: size),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: accentColor.withValues(alpha: isDark ? 0.18 : 0.12), borderRadius: BorderRadius.circular(9.w)),
      child: Icon(icon ?? Icons.auto_awesome_outlined, size: 19.w, color: accentColor),
    );
  }

  Widget _valueText() => Text(
    value,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w800, height: 1.18, color: primaryText),
  );
}

class _PatternImageFallback extends StatelessWidget {
  const _PatternImageFallback({required this.color, required this.icon, required this.size});

  final Color color;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    color: color.withValues(alpha: 0.12),
    child: Icon(icon, size: size * 0.5, color: color),
  );
}

int _patternConfidencePercent(BodyPattern pattern) {
  if (pattern.evidenceRatio > 0) return (pattern.evidenceRatio * 100).round();
  if (pattern.confidenceScore > 0) return (pattern.confidenceScore * 100).round();

  final raw = pattern.confidence.trim().replaceAll('%', '');
  final value = double.tryParse(raw);
  if (value != null) return value > 1 ? value.round() : (value * 100).round();

  return switch (raw.toLowerCase()) {
    'high' => 89,
    'medium' || 'moderate' => 72,
    'low' => 55,
    _ => 0,
  };
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
