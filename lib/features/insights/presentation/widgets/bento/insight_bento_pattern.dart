part of 'insight_bento_screens.dart';

/// Pattern and synergy presentation components.

class InsightBentoPattern extends StatelessWidget {
  const InsightBentoPattern({super.key, required this.pattern});
  final BodyPattern pattern;

  @override
  Widget build(BuildContext context) {
    final accent = _getAccent(pattern.type);

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16.w, 4.w, 16.w, 30.w),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // 1. Hero Mascot Card
          Gap.h10,
          _HeroMascotCard(pattern: pattern, accent: accent),
          Gap.h16,
          // 2. Meta Pills
          Row(
            children: [
              _MetaPill(label: pattern.timeframeDays > 0 ? '${pattern.frequency} matched logs · ${pattern.timeframeDays} days' : '${pattern.frequency} matched logs', color: accent, filled: false),
              Gap.w8,
              _MetaPill(label: pattern.evidenceLabel, color: accent, filled: true),
            ],
          ),
          Gap.h16,
          // 3. Metrics Grid
          Row(
            children: [
              _MetricCard(value: '${pattern.frequency}', label: 'MATCHED LOGS', color: accent),
              Gap.w10,
              _MetricCard(value: pattern.totalSimilarMeals > 0 ? '${pattern.totalSimilarMeals}' : '—', label: 'MEALS LOGGED', color: accent),
              Gap.w10,
              _MetricCard(value: pattern.typicalDelay?.trim().isNotEmpty == true ? pattern.typicalDelay! : 'Not recorded', label: 'ONSET TIMING', color: accent),
            ],
          ),
          Gap.h16,
          // 4. Biological Root
          _SectionCard(
            title: 'WHAT WE OBSERVED',
            color: accent,
            child: Text(
              pattern.description,
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 13.sp, color: PatternSurface.isDark(context) ? const Color(0xFFC3C9D4) : const Color(0xFF3A3F47), height: 1.55),
            ),
          ),
          if (pattern.involvedFoods.isNotEmpty) ...[
            Gap.h16,
            _SectionCard(
              title: 'FOODS IN THESE MEALS',
              color: accent,
              child: Wrap(
                spacing: 8.w,
                runSpacing: 8.w,
                children: [
                  for (final food in pattern.involvedFoods)
                    Chip(label: Text(food), visualDensity: VisualDensity.compact),
                ],
              ),
            ),
          ],
          Gap.h16,
          // 6. Recent Episodes
          if (pattern.occurrences.isNotEmpty)
            _SectionCard(
              title: 'RECENT EPISODES',
              color: accent,
              child: Column(
                children: [for (final o in pattern.occurrences.take(4)) _EpisodeRow(occurrence: o, color: accent)],
              ),
            ),
          Gap.h16,
          // 7. Common Factors
          if (pattern.commonFactors.isNotEmpty)
            _SectionCard(
              title: 'COMMON FACTORS',
              color: accent,
              child: Wrap(
                spacing: 6.w,
                runSpacing: 6.w,
                children: [
                  for (final f in pattern.commonFactors)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.w),
                      decoration: BoxDecoration(color: accent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(999)),
                      child: Text(
                        f.label,
                        style: TextStyle(
                          fontFamily: InsightBentoTheme.fontFamily,
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w600,
                          color: PatternSurface.isDark(context) ? accent : _getTextAccent(pattern.type),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Gap.h16,
          // 8. Recommendation
          _RecommendationCard(pattern: pattern, accent: accent),
          Gap.h14,
          // 9. Summary Text
          Center(
            child: Text(
              'Missing symptom follow-ups are treated as unknown, not symptom-free.',
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.5.sp, color: PatternSurface.isDark(context) ? const Color(0xFF8D96A5) : const Color(0xFF71767F)),
            ),
          ),
          Gap.h14,
          Center(
            child: Text(
              pattern.timeframeDays > 0 ? 'Based on your logs · last ${pattern.timeframeDays} days' : 'Based on your logged data',
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 10.5.sp, color: PatternSurface.isDark(context) ? const Color(0xFF6E7683) : const Color(0xFF9AA0A8)),
            ),
          ),
        ]),
      ),
    );
  }

  Color _getAccent(String type) => switch (type) {
    BodyPattern.typeBloating => const Color(0xFF8B5CF6),
    BodyPattern.typeEnergy => const Color(0xFFD97706),
    BodyPattern.typeHeadache => const Color(0xFFF08019),
    BodyPattern.typeDigestion => const Color(0xFF14A38F),
    BodyPattern.typeFullness => const Color(0xFFEFB008),
    BodyPattern.typeSleep => const Color(0xFF6B74E8),
    _ => const Color(0xFF8B5CF6),
  };

  Color _getTextAccent(String type) => switch (type) {
    BodyPattern.typeBloating => const Color(0xFF563999),
    BodyPattern.typeEnergy => const Color(0xFFB45309),
    BodyPattern.typeHeadache => const Color(0xFF954F10),
    BodyPattern.typeDigestion => const Color(0xFF0C6559),
    BodyPattern.typeFullness => const Color(0xFF946D05),
    BodyPattern.typeSleep => const Color(0xFF424890),
    _ => const Color(0xFF563999),
  };
}

class _HeroMascotCard extends StatelessWidget {
  const _HeroMascotCard({required this.pattern, required this.accent});
  final BodyPattern pattern;
  final Color accent;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 92.w,
        height: 92.w,
        decoration: BoxDecoration(color: PatternSurface.card(context), borderRadius: BorderRadius.circular(24.w), boxShadow: PatternSurface.softShadow(context)),
        child: Center(child: Icon(_getIcon(pattern.type), size: 48, color: accent)),
      ),
      Gap.w14,
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${pattern.type} pattern'.toUpperCase(),
              style: TextStyle(
                fontFamily: InsightBentoTheme.fontFamily,
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
                color: PatternSurface.isDark(context) ? accent : _getTextAccent(pattern.type),
              ),
            ),
            Gap.h4,
            Text(
              '${pattern.trigger} \u{2192} ${pattern.reaction}',
              style: TextStyle(
                fontFamily: InsightBentoTheme.fontFamily,
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: PatternSurface.isDark(context) ? const Color(0xFFF5F7FA) : const Color(0xFF1F2430),
                height: 1.22,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  IconData _getIcon(String type) => switch (type) {
    BodyPattern.typeBloating => AppIcons.wind,
    BodyPattern.typeEnergy => AppIcons.zap,
    BodyPattern.typeHeadache => AppIcons.brain,
    BodyPattern.typeDigestion => AppIcons.leaf,
    BodyPattern.typeFullness => AppIcons.chartPie,
    BodyPattern.typeSleep => AppIcons.moon,
    _ => AppIcons.sparkles,
  };

  Color _getTextAccent(String type) => switch (type) {
    BodyPattern.typeBloating => const Color(0xFF563999),
    BodyPattern.typeEnergy => const Color(0xFF367325),
    BodyPattern.typeHeadache => const Color(0xFF954F10),
    BodyPattern.typeDigestion => const Color(0xFF0C6559),
    BodyPattern.typeFullness => const Color(0xFF946D05),
    BodyPattern.typeSleep => const Color(0xFF424890),
    _ => const Color(0xFF563999),
  };
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label, required this.color, required this.filled});
  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.w),
    decoration: BoxDecoration(
      color: filled ? color : PatternSurface.chipBackground(context),
      borderRadius: BorderRadius.circular(999),
      border: filled ? null : Border.all(color: color.withValues(alpha: 0.5)),
    ),
    child: Text(
      label,
      style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.5.sp, fontWeight: filled ? FontWeight.w700 : FontWeight.w600, color: filled ? Colors.white : color),
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 12.w, horizontal: 6.w),
      decoration: BoxDecoration(color: PatternSurface.card(context), borderRadius: BorderRadius.circular(16.w), boxShadow: PatternSurface.softShadow(context)),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 16.sp, fontWeight: FontWeight.w800, color: color),
          ),
          Gap.h4,
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 9.5.sp, color: PatternSurface.isDark(context) ? const Color(0xFF8D96A5) : const Color(0xFF71767F), letterSpacing: 0.5),
          ),
        ],
      ),
    ),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.color, required this.child});
  final String title;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(16.w),
    decoration: BoxDecoration(color: PatternSurface.card(context), borderRadius: BorderRadius.circular(18.w), boxShadow: PatternSurface.softShadow(context)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4.w,
              height: 15.w,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
            ),
            Gap.w10,
            Text(
              title.toUpperCase(),
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: color),
            ),
          ],
        ),
        Gap.h10,
        child,
      ],
    ),
  );
}

class _EpisodeRow extends StatelessWidget {
  const _EpisodeRow({required this.occurrence, required this.color});
  final PatternOccurrence occurrence;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 8.w),
    child: Row(
      children: [
        SizedBox(
          width: 40.w,
          child: Text(
            _formatDate(occurrence.date),
            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w800, color: color),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                occurrence.mealName,
                style: TextStyle(
                  fontFamily: InsightBentoTheme.fontFamily,
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                  color: PatternSurface.isDark(context) ? const Color(0xFFF5F7FA) : const Color(0xFF1F2430),
                ),
              ),
              Text(
                '${occurrence.reaction} \u00b7 ${occurrence.timeAfter}',
                style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.sp, color: PatternSurface.isDark(context) ? const Color(0xFF8D96A5) : const Color(0xFF71767F)),
              ),
            ],
          ),
        ),
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ],
    ),
  );

  String _formatDate(String raw) {
    if (raw.isEmpty) return '???';
    try {
      final date = DateTime.parse(raw);
      return DateFormat('EEE').format(date);
    } catch (_) {
      return raw.length > 3 ? raw.substring(0, 3) : raw;
    }
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.pattern, required this.accent});
  final BodyPattern pattern;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(16.w),
    decoration: BoxDecoration(
      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [accent, accent.withValues(alpha: 0.8)]),
      borderRadius: BorderRadius.circular(18.w),
      boxShadow: [BoxShadow(color: const Color(0xFF141828).withValues(alpha: 0.07), blurRadius: 26.w, offset: Offset(0, 10.w))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECOMMENDATION',
          style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: Colors.white.withValues(alpha: 0.9)),
        ),
        Gap.h8,
        Text(
          pattern.recommendation?.trim().isNotEmpty == true ? pattern.recommendation! : 'No specific recommendation is available for this pattern yet.',
          style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 13.5.sp, color: Colors.white, height: 1.5),
        ),
      ],
    ),
  );
}
