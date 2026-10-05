part of 'smart_insight_detail_screen.dart';

/// Smart insight detail sections and evidence presentation.

extension SmartInsightDetailSections on SmartInsightDetailScreen {
  /// 2. "What We Observed" Card
  Widget _buildWhatWeObservedCard(BuildContext context, {required bool isEarlyObservation}) {
    final theme = context.insightTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = PatternCardStyle.forType(insight.domain ?? insight.type);
    final observationAccent = isEarlyObservation ? theme.warning : style.accentColor;
    final observationSurface = isEarlyObservation ? theme.warningSoft : context.insightColor(style.cardBg);
    final text = (insight.observation != null && insight.observation!.isNotEmpty)
        ? insight.observation!
        : (insight.description.isNotEmpty ? insight.description : 'No observation details are available for this insight.');

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isEarlyObservation ? observationSurface : (isDark ? theme.card : Colors.white),
        borderRadius: BorderRadius.circular(18.w),
        border: Border.all(color: isEarlyObservation ? observationAccent.withValues(alpha: 0.24) : (isDark ? theme.border : const Color(0xFFE2E8F0)), width: 1.w),
        boxShadow: [BoxShadow(color: observationAccent.withValues(alpha: 0.06), blurRadius: 12.w, offset: Offset(0, 4.w))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: observationAccent.withValues(alpha: isDark ? 0.18 : 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(isEarlyObservation ? LucideIcons.info : style.icon, size: 16.w, color: observationAccent),
          ),
          Gap.w10,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'What We Observed',
                        style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: theme.textPrimary),
                      ),
                    ),
                    if (isEarlyObservation) const InsightBadge('REPORTED', tone: InsightTone.warning, withDot: false, size: 8),
                  ],
                ),
                Gap.h4,
                Text(
                  text,
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w500, color: theme.textSecondary, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3. "The Evidence" Metric Dashboard Card
  Widget _buildTheEvidenceCard(BuildContext context, {required int? evidenceRatio, required int? frequency, required int? symptomLogs, required int? normalLogs, required bool isEarlyObservation}) {
    final theme = context.insightTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = PatternCardStyle.forType(insight.domain ?? insight.type);

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
                      isEarlyObservation ? 'One reported observation — comparison data is not available yet.' : 'Based on your logged historical data.',
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, color: theme.textSecondary, height: 1.25),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Gap.h12,
          if (isEarlyObservation) ...[
            Container(
              padding: EdgeInsets.all(11.w),
              decoration: BoxDecoration(
                color: isDark ? theme.warningSoft : const Color(0xFFFFF8E8),
                borderRadius: BorderRadius.circular(14.w),
                border: Border.all(color: isDark ? theme.warning.withValues(alpha: 0.24) : const Color(0xFFF5D99A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28.w,
                    height: 28.w,
                    decoration: BoxDecoration(color: isDark ? theme.warning.withValues(alpha: 0.16) : const Color(0xFFFFEDC2), shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Icon(LucideIcons.history, size: 14.w, color: isDark ? theme.warning : const Color(0xFF9A5B00)),
                  ),
                  Gap.w8,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          frequency == null ? 'One observation recorded' : '$frequency observation${frequency == 1 ? '' : 's'} recorded',
                          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w800, color: theme.textPrimary),
                        ),
                        Gap.h3,
                        Text(
                          'Keep logging to see whether this repeats. A comparison is not available yet.',
                          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, color: theme.textSecondary, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else
            Row(
              children: [
                _buildMetricTile(
                  context,
                  title: evidenceRatio == null ? '—' : '$evidenceRatio%',
                  label: 'Evidence Ratio',
                  icon: LucideIcons.pieChart,
                  color: isDark ? theme.purple : style.accentColor,
                  bg: isDark ? theme.cardSubtle : style.tagBg,
                ),
                Gap.w6,
                _buildMetricTile(
                  context,
                  title: frequency == null ? '—' : '$frequency×',
                  label: 'Times Logged',
                  icon: LucideIcons.history,
                  color: isDark ? theme.purple : style.accentColor,
                  bg: isDark ? theme.cardSubtle : style.tagBg,
                ),
                Gap.w6,
                _buildMetricTile(
                  context,
                  title: symptomLogs == null ? '—' : '$symptomLogs',
                  label: 'Symptom Logs',
                  icon: LucideIcons.thumbsDown,
                  color: isDark ? theme.error : const Color(0xFFDC2626),
                  bg: isDark ? theme.errorSoft : const Color(0xFFFEF2F2),
                ),
                Gap.w6,
                _buildMetricTile(
                  context,
                  title: normalLogs == null ? '—' : '$normalLogs',
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

  /// 4. "Involved Foods" Horizontal Grid
  Widget _buildInvolvedFoodsSection(BuildContext context, {required bool isEarlyObservation}) {
    final foods = <String>[];
    final seen = <String>{};

    for (final f in insight.involvedFoods) {
      final key = f.trim().toLowerCase();
      if (key.isNotEmpty && seen.add(key)) foods.add(f.trim());
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
              decoration: BoxDecoration(color: context.insightColor(const Color(0xFFFEF3C7)), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(LucideIcons.utensils, size: 14.w, color: context.insightColor(const Color(0xFFB45309))),
            ),
            Gap.w8,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEarlyObservation ? 'Mentioned Food' : 'Involved Foods',
                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                  ),
                  Text(
                    isEarlyObservation ? 'Named in your report — not a confirmed trigger.' : 'Foods mentioned in this insight.',
                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, color: context.insightColor(const Color(0xFF64748B))),
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
  Widget _buildOccurrencesTimelineCard(BuildContext context, List<BodyPattern> relatedPatterns) {
    final style = PatternCardStyle.forType(insight.domain ?? insight.type);
    final matchingPattern = relatedPatterns.where((pattern) => pattern.commonFactors.isNotEmpty || pattern.occurrences.isNotEmpty).firstOrNull;

    if (matchingPattern == null || (matchingPattern.commonFactors.isEmpty && matchingPattern.occurrences.isEmpty)) {
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
              decoration: BoxDecoration(color: context.insightColor(style.accentColor).withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(LucideIcons.history, size: 12.w, color: context.insightColor(style.accentColor)),
            ),
            Gap.w8,
            Text(
              'Occurrences & Factors',
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
            ),
          ],
        ),
        Gap.h10,

        // Common Factors Card (if available)
        if (matchingPattern.commonFactors.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: context.insightTheme.card,
              borderRadius: BorderRadius.circular(18.w),
              border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0)), width: 1.w),
              boxShadow: [BoxShadow(color: context.insightColor(const Color(0xFF0F172A)).withValues(alpha: 0.03), blurRadius: 8.w, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Associated Factors',
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w700, color: context.insightColor(const Color(0xFF64748B))),
                ),
                Gap.h8,
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.w,
                  children: [
                    for (final factor in matchingPattern.commonFactors)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.w),
                        decoration: BoxDecoration(
                          color: context.insightColor(style.tagBg).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(100.w),
                          border: Border.all(color: context.insightColor(style.tagFg).withValues(alpha: 0.15), width: 0.7.w),
                        ),
                        child: Text(
                          '${_smartInsightFactorGlyph(factor.icon)} ${factor.label}',
                          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w600, color: context.insightColor(style.tagFg), height: 1.1),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Gap.h10,
        ],

        // Recent Occurrences List (Separate Item Cards)
        if (matchingPattern.occurrences.isNotEmpty) ...[
          for (final occ in matchingPattern.occurrences.take(4)) ...[OccurrenceTile(occurrence: occ, pattern: matchingPattern), Gap.h10],
        ],
      ],
    );
  }

  /// 6. Related Patterns Section
  Widget _buildRelatedPatternsSection(BuildContext context, List<BodyPattern> patterns) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(color: context.insightColor(const Color(0xFFEDE9FE)), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(LucideIcons.gitFork, size: 14.w, color: context.insightColor(const Color(0xFF7C3AED))),
            ),
            Gap.w8,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    InsightsCopy.relatedPatternsLabel,
                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                  ),
                  Text(
                    'Detected patterns related to this insight.',
                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, color: context.insightColor(const Color(0xFF64748B))),
                  ),
                ],
              ),
            ),
          ],
        ),
        Gap.h8,
        for (final p in patterns.take(3)) ...[
          InsightPatternPill(
            title: '${p.trigger} → ${p.reaction}',
            subtitle: '${p.frequency}× • ${p.confidence} confidence',
            emoji: p.involvedFoods.isEmpty ? null : InsightPresentation.emojiForFood(p.involvedFoods.first),
            onTap: () => context.push(AppRoutes.patternDetail, extra: p),
          ),
          Gap.h8,
        ],
      ],
    );

  /// The first follow-up action for this insight.
  Widget _buildYourNextStepsCard(BuildContext context, {required bool isEarlyObservation}) {
    final theme = context.insightTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accent = Color(0xFF6F67DD);
    final background = isDark ? const Color(0xFF211F31) : const Color(0xFFF7F5FF);
    final border = isDark ? accent.withValues(alpha: 0.28) : const Color(0xFFE7E2FF);
    final steps = insight.nextSteps.take(3).toList(growable: false);

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: border, width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(LucideIcons.listChecks, size: 17.w, color: isDark ? const Color(0xFFB9AEFF) : accent),
              ),
              Gap.w10,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your next step',
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: theme.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEarlyObservation ? 'A simple way to learn more' : 'A practical action from this insight',
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, color: theme.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.w),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.18 : 0.10),
                  borderRadius: BorderRadius.circular(999.w),
                ),
                child: Text(
                  'START HERE',
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.sp, fontWeight: FontWeight.w800, letterSpacing: 0.45, color: isDark ? const Color(0xFFB9AEFF) : accent),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.w),
          if (steps.isEmpty)
            Text(
              'Log meals and symptoms to build a more useful insight.',
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, color: theme.textSecondary, height: 1.4),
            )
          else ...[
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0) ...[SizedBox(height: 10.w), Divider(height: 1, color: border), SizedBox(height: 10.w)],
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.w),
                decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white, borderRadius: BorderRadius.circular(14.w)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24.w,
                      height: 24.w,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: isDark ? 0.18 : 0.1),
                        borderRadius: BorderRadius.circular(8.w),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFFB9AEFF) : accent),
                      ),
                    ),
                    Gap.w10,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            i == 0 && isEarlyObservation ? 'Track this' : 'Action ${i + 1}',
                            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w800, color: theme.textPrimary),
                          ),
                          SizedBox(height: 3.w),
                          Text(
                            steps[i],
                            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, color: theme.textSecondary, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSupportingEvidenceCard(BuildContext context) {
    final theme = context.insightTheme;

    AIInsight? latestInsight;
    try {
      latestInsight = context.read<InsightsNotifier>().latestInsight;
    } on ProviderNotFoundException {
      latestInsight = null;
    }

    final sameInsight = insight.id != null && latestInsight?.topInsight?.id == insight.id;
    final samples = sameInsight ? latestInsight?.evidence?.sampleSizes : null;
    if (samples == null || (samples.meals == 0 && samples.symptoms == 0 && samples.scans == 0)) {
      return const SizedBox.shrink();
    }

    Widget metric({required IconData icon, required String title, required String subtitle, required int value, required Color color, required Color soft}) => Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 11.w),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(14.w),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13.w, color: color),
              Gap.w5,
              Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w700, color: theme.textPrimary))),
            ],
          ),
          Gap.h8,
          Text('$value', style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 21.sp, fontWeight: FontWeight.w800, color: color, height: 1)),
          Gap.h3,
          Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.5.sp, color: theme.textSecondary)),
        ],
      ),
    );

    final metrics = <Widget>[
      if (samples.meals > 0) metric(icon: LucideIcons.utensils, title: 'Meals', subtitle: 'reviewed', value: samples.meals, color: theme.warning, soft: theme.warningSoft),
      if (samples.symptoms > 0) metric(icon: LucideIcons.activity, title: 'Symptoms', subtitle: 'logged', value: samples.symptoms, color: theme.error, soft: theme.errorSoft),
      if (samples.scans > 0) metric(icon: LucideIcons.scan, title: 'Scans', subtitle: 'reviewed', value: samples.scans, color: theme.purple, soft: theme.purple.withValues(alpha: 0.08)),
    ];
    final totalSamples = samples.meals + samples.symptoms + samples.scans;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: theme.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.12 : 0.035), blurRadius: 12.w, offset: Offset(0, 4.w))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(color: theme.purple.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12.w)),
                alignment: Alignment.center,
                child: Icon(LucideIcons.fileText, size: 17.w, color: theme.purple),
              ),
              Gap.w10,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What this insight used',
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 13.sp, fontWeight: FontWeight.w800, color: theme.textPrimary),
                    ),
                    Text('$totalSamples data points considered', style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, color: theme.textSecondary)),
                  ],
                ),
              ),
            ],
          ),

          Gap.h14,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [for (var i = 0; i < metrics.length; i++) ...[if (i > 0) Gap.w8, Expanded(child: metrics[i])]],
          ),
        ],
      ),
    );
  }
}
