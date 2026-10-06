part of 'pattern_detail_screen.dart';

/// Pattern detail sections and evidence presentation.

extension PatternDetailSections on PatternDetailScreen {
  /// 1. Reuse the same hero card shown in the Patterns tab, without navigation.
  Widget _buildHeroCard() => PatternCard(pattern: pattern, interactive: false);

  /// 2. "What We Observed" Card
  Widget _buildWhatWeObservedCard(BuildContext context) {
    final theme = context.insightTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = PatternCardStyle.forType(pattern.type);
    final text = pattern.trigger.isNotEmpty && pattern.typicalDelay?.trim().isNotEmpty == true
        ? 'Repeated log history shows that eating ${pattern.trigger} is associated with a ${pattern.type.toLowerCase()} reaction within ${pattern.typicalDelay}.'
        : pattern.trigger.isNotEmpty
        ? 'Your logs show ${pattern.trigger} alongside a ${pattern.type.toLowerCase()} reaction.'
        : pattern.timeframeDays > 0
        ? 'Logged evidence indicates a recurring ${pattern.type.toLowerCase()} pattern over the last ${pattern.timeframeDays} days.'
        : 'Logged evidence indicates a recurring ${pattern.type.toLowerCase()} pattern.';

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? theme.card : Colors.white,
        borderRadius: BorderRadius.circular(18.w),
        border: Border.all(color: isDark ? theme.border : const Color(0xFFE2E8F0), width: 1.w),
        boxShadow: [BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.15) : const Color(0xFF17171B).withValues(alpha: 0.03), blurRadius: 6.w, offset: Offset(0, 2.w))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(color: isDark ? theme.cardSubtle : context.insightColor(style.tagBg), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(style.icon, size: 16.w, color: isDark ? theme.textPrimary : context.insightColor(style.tagFg)),
          ),
          Gap.w10,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What We Observed',
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: theme.textPrimary),
                ),
                Gap.h3,
                Text(
                  text,
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w500, color: theme.textSecondary, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3. "The Evidence" Metric Dashboard Card
  Widget _buildTheEvidenceCard(BuildContext context, {required int evidenceRatio, required int frequency, required int symptomLogs, required int normalLogs}) {
    final theme = context.insightTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = PatternCardStyle.forType(pattern.type);

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? theme.card : Colors.white,
        borderRadius: BorderRadius.circular(18.w),
        border: Border.all(color: isDark ? theme.border : const Color(0xFFE2E8F0), width: 1.w),
        boxShadow: [BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.15) : const Color(0xFF17171B).withValues(alpha: 0.03), blurRadius: 6.w, offset: Offset(0, 2.w))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(color: isDark ? theme.cardSubtle : context.insightColor(style.tagBg), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(LucideIcons.barChart2, size: 14.w, color: isDark ? theme.textPrimary : context.insightColor(style.tagFg)),
              ),
              Gap.w8,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'The Evidence',
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: theme.textPrimary),
                    ),
                    Text(
                      pattern.timeframeDays > 0 ? 'Based on your last ${pattern.timeframeDays} days of data.' : 'Based on your available logged data.',
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, color: theme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Gap.h12,
          Row(
            children: [
              _buildMetricTile(
                context,
                title: '$evidenceRatio%',
                label: 'Evidence Ratio',
                icon: LucideIcons.pieChart,
                color: isDark ? theme.purple : style.accentColor,
                bg: isDark ? theme.cardSubtle : style.tagBg,
              ),
              Gap.w6,
              _buildMetricTile(
                context,
                title: '${frequency}x',
                label: 'Times Logged',
                icon: LucideIcons.history,
                color: isDark ? theme.purple : style.accentColor,
                bg: isDark ? theme.cardSubtle : style.tagBg,
              ),
              Gap.w6,
              _buildMetricTile(
                context,
                title: '$symptomLogs',
                label: 'Symptom Logs',
                icon: LucideIcons.thumbsDown,
                color: isDark ? theme.error : const Color(0xFFDC2626),
                bg: isDark ? theme.errorSoft : const Color(0xFFFEF2F2),
              ),
              Gap.w6,
              _buildMetricTile(
                context,
                title: '$normalLogs',
                label: 'Normal Logs',
                icon: LucideIcons.thumbsUp,
                color: isDark ? theme.success : const Color(0xFF15803D),
                bg: isDark ? theme.successSoft : const Color(0xFFF0FDF4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(BuildContext context, {required String title, required String label, required IconData icon, required Color color, required Color bg}) {
    final theme = context.insightTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final resolvedBg = isDark ? theme.cardSubtle : context.insightColor(bg);
    final resolvedColor = isDark ? color : context.insightColor(color);

    return Expanded(
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: resolvedBg,
          borderRadius: BorderRadius.circular(12.w),
          border: Border.all(color: isDark ? theme.border : resolvedColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(color: isDark ? resolvedColor.withValues(alpha: 0.18) : resolvedColor.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: Icon(icon, size: 10.w, color: resolvedColor),
                ),
              ],
            ),
            Gap.h6,
            Text(
              title,
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: theme.textPrimary),
            ),
            Gap.h2,
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w600, color: theme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  /// 4. "Involved Foods" Horizontal Grid (Harvests from involvedFoods, trigger, and occurrences)
  Widget _buildInvolvedFoodsSection(BuildContext context) {
    final theme = context.insightTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final foods = <String>[];
    final seen = <String>{};

    for (final f in pattern.involvedFoods) {
      final key = f.trim().toLowerCase();
      if (key.isNotEmpty && seen.add(key)) foods.add(f.trim());
    }

    if (pattern.trigger.trim().isNotEmpty) {
      final key = pattern.trigger.trim().toLowerCase();
      if (seen.add(key)) foods.add(pattern.trigger.trim());
    }

    for (final occ in pattern.occurrences) {
      final key = occ.mealName.trim().toLowerCase();
      if (key.isNotEmpty && seen.add(key)) foods.add(occ.mealName.trim());
    }

    if (foods.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(color: isDark ? const Color(0xFFB45309).withValues(alpha: 0.20) : const Color(0xFFFEF3C7), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(LucideIcons.utensils, size: 14.w, color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309)),
            ),
            Gap.w8,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Involved Foods',
                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: theme.textPrimary),
                  ),
                  Text(
                    'Foods frequently associated with this pattern.',
                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, color: theme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        Gap.h8,

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (final food in foods) ...[_InvolvedFoodTile(foodName: food), Gap.w8],
            ],
          ),
        ),
      ],
    );
  }

  /// 5. Occurrences Timeline & Common Factors Card
  Widget _buildOccurrencesTimelineCard(BuildContext context) {
    final theme = context.insightTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = PatternCardStyle.forType(pattern.type);

    if (pattern.commonFactors.isEmpty && pattern.occurrences.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(color: isDark ? style.accentColor.withValues(alpha: 0.20) : style.accentColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(LucideIcons.history, size: 12.w, color: isDark ? theme.textPrimary : style.accentColor),
            ),
            Gap.w8,
            Text(
              'Occurrences & Factors',
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: theme.textPrimary),
            ),
          ],
        ),
        Gap.h10,

        // Common Factors Card (if available)
        if (pattern.commonFactors.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: theme.card,
              borderRadius: BorderRadius.circular(18.w),
              border: Border.all(color: theme.border, width: 1.w),
              boxShadow: [BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.15) : const Color(0xFF0F172A).withValues(alpha: 0.03), blurRadius: 8.w, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Associated Factors',
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w700, color: theme.textSecondary),
                ),
                Gap.h8,
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.w,
                  children: [
                    for (final factor in pattern.commonFactors)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.w),
                        decoration: BoxDecoration(
                          color: isDark ? theme.cardSubtle : style.tagBg.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(100.w),
                          border: Border.all(color: isDark ? theme.border : style.tagFg.withValues(alpha: 0.15), width: 0.7.w),
                        ),
                        child: Text(
                          '${_patternFactorGlyph(factor.icon)} ${factor.label}',
                          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w600, color: isDark ? theme.textPrimary : style.tagFg, height: 1.1),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Gap.h10,
        ],

        // Recent Occurrences List (Separate Item Cards using OccurrenceTile)
        if (pattern.occurrences.isNotEmpty) ...[
          for (final occ in pattern.occurrences.take(4)) ...[OccurrenceTile(occurrence: occ, pattern: pattern), Gap.h10],
        ],
      ],
    );
  }

  /// 6. Split Grid Section ("Your Next Steps" & "Supporting Evidence")
  Widget _buildSplitGridSection(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Column: Your Next Steps
        Expanded(child: _buildYourNextStepsCard(context)),
        Gap.w10,

        // Right Column: Supporting Evidence
        Expanded(child: _buildSupportingEvidenceCard(context)),
      ],
    ),
  );

  Widget _buildYourNextStepsCard(BuildContext context) {
    final theme = context.insightTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = PatternCardStyle.forType(pattern.type);
    final recText = (pattern.recommendation?.isNotEmpty == true) ? pattern.recommendation! : 'Log your meals and symptoms consistently to track this trend.';

    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF102319) : const Color(0xFFF4FAF5),
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.28) : const Color(0xFFDCFCE7), width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 24.w,
                    height: 24.w,
                    decoration: BoxDecoration(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.20) : context.insightColor(style.tagBg), shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Icon(style.icon, size: 12.w, color: isDark ? const Color(0xFF4ADE80) : context.insightColor(style.tagFg)),
                  ),
                  Gap.w6,
                  Expanded(
                    child: Text(
                      'Your Next Steps',
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: theme.textPrimary),
                    ),
                  ),
                ],
              ),
              Gap.h3,
              Text(
                'Recommended actions for this pattern:',
                style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, color: theme.textSecondary, height: 1.2),
              ),
              Gap.h10,

              InsightNextStepCheckRow(
                title: 'Recommendation',
                subtitle: recText,
                accentColor: isDark ? const Color(0xFF22C55E) : const Color(0xFF16A34A),
                titleColor: theme.textPrimary,
                subtitleColor: theme.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupportingEvidenceCard(BuildContext context) {
    final theme = context.insightTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    AIInsight? latestInsight;
    try {
      latestInsight = context.read<InsightsNotifier>().latestInsight;
    } on ProviderNotFoundException {
      latestInsight = null;
    }

    final mealsCount = latestInsight?.evidence?.sampleSizes.meals ?? pattern.totalSimilarMeals;
    final symptomsCount = latestInsight?.evidence?.sampleSizes.symptoms ?? pattern.occurrences.length;
    final scansCount = latestInsight?.evidence?.sampleSizes.scans ?? 0;

    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111C2E) : const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.28) : const Color(0xFFE2E8F0), width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24.w,
                height: 24.w,
                decoration: BoxDecoration(color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.20) : const Color(0xFFDBEAFE), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(LucideIcons.fileText, size: 12.w, color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8)),
              ),
              Gap.w4,
              Expanded(
                child: Text(
                  'Supporting Evidence',
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: theme.textPrimary),
                ),
              ),
            ],
          ),
          Gap.h2,
          Text(
            'Based on your logged data.',
            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, color: theme.textSecondary),
          ),
          Gap.h10,

          InsightEvidenceMetricRow(
            icon: LucideIcons.utensils,
            title: 'Meals',
            subtitle: 'Similar meals analyzed',
            value: '$mealsCount',
            iconBackground: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.20) : const Color(0xFFDBEAFE),
            iconColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8),
            titleColor: theme.textPrimary,
            subtitleColor: theme.textSecondary,
            valueColor: theme.textPrimary,
          ),
          Gap.h8,

          InsightEvidenceMetricRow(
            icon: LucideIcons.clipboardList,
            title: 'Symptoms',
            subtitle: 'Pattern occurrences',
            value: '$symptomsCount',
            iconBackground: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.20) : const Color(0xFFDBEAFE),
            iconColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8),
            titleColor: theme.textPrimary,
            subtitleColor: theme.textSecondary,
            valueColor: theme.textPrimary,
          ),
          Gap.h8,

          InsightEvidenceMetricRow(
            icon: LucideIcons.fileText,
            title: 'Scans',
            subtitle: 'Total scans',
            value: '$scansCount',
            iconBackground: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.20) : const Color(0xFFDBEAFE),
            iconColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8),
            titleColor: theme.textPrimary,
            subtitleColor: theme.textSecondary,
            valueColor: theme.textPrimary,
          ),
        ],
      ),
    );
  }
}
