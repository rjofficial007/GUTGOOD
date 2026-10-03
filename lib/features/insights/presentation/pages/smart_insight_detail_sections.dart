part of 'smart_insight_detail_screen.dart';

/// Smart insight detail sections and evidence presentation.

extension SmartInsightDetailSections on SmartInsightDetailScreen {
  /// 1. Top Hero Insight Card (Matching PatternCard hero layout with dynamic food color blending)
  Widget _buildHeroCard(BuildContext context) {
    final foodName = insight.involvedFoods.firstOrNull;
    final imageUrl = foodName == null ? null : InsightUiKit.foodImageUrl(foodName);
    final style = PatternCardStyle.forType(insight.type);

    final title = insight.title.isNotEmpty ? insight.title : 'Top Insight Discovery';
    final descStr = insight.description.trim();

    final confidenceLabel = (insight.strength?.trim().isNotEmpty == true ? insight.strength! : 'LIMITED DATA').toUpperCase();
    const heroColor = Color(0xFF6F67DD);

    return Container(
      constraints: BoxConstraints(minHeight: 140.w),
      decoration: BoxDecoration(color: heroColor, borderRadius: BorderRadius.circular(24.w)),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Left Content Section
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(18.w, 16.w, 12.w, 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Line 1: Bold Title
                    Text(
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 18.sp, fontWeight: FontWeight.w800, color: Colors.white, height: 1.15, letterSpacing: -0.4),
                    ),
                    if (descStr.isNotEmpty) ...[
                      Gap.h6,
                      // Line 2: Description
                      Text(
                        descStr,
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha: 0.90), height: 1.25),
                      ),
                    ],
                    Gap.h12,

                    // Bottom Badge Tag Row
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.w),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.20), borderRadius: BorderRadius.circular(100.w)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5.w,
                            height: 5.w,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          ),
                          Gap.w5,
                          Text(
                            '$confidenceLabel CONFIDENCE',
                            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.sp, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Right Side Image (Seamlessly blended with dynamic food background)
                if (imageUrl != null) SizedBox(
                  width: 138.w,
              child: Stack(
                children: [
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
  );
  }

  /// 2. "What We Observed" Card
  Widget _buildWhatWeObservedCard(BuildContext context) {
    final theme = context.insightTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = PatternCardStyle.forType(insight.type);
    final text = (insight.observation != null && insight.observation!.isNotEmpty)
        ? insight.observation!
        : (insight.description.isNotEmpty ? insight.description : 'No observation details are available for this insight.');

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
  Widget _buildTheEvidenceCard(BuildContext context, {required int? evidenceRatio, required int? frequency, required int? symptomLogs, required int? normalLogs}) {
    final theme = context.insightTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = PatternCardStyle.forType(insight.type);

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
                      'Based on your logged historical data.',
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
  Widget _buildInvolvedFoodsSection(BuildContext context) {
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
                    'Involved Foods',
                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                  ),
                  Text(
                    'Foods mentioned in this insight.',
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
  Widget _buildOccurrencesTimelineCard(BuildContext context) {
    final style = PatternCardStyle.forType(insight.type);
    final matchingPattern = _relatedPatterns(context).firstOrNull;

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
  Widget _buildRelatedPatternsSection(BuildContext context) {
    final patterns = _relatedPatterns(context);

    if (patterns.isEmpty) return const SizedBox.shrink();

    return Column(
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
  }

  /// 7. Split Grid Section ("Your Next Steps" & "Supporting Evidence")
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
    final style = PatternCardStyle.forType(insight.type);
    final steps = insight.nextSteps;

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
                steps.isEmpty ? 'No personalized next steps are available yet.' : 'Recommended actions for this insight:',
                style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, color: theme.textSecondary, height: 1.2),
              ),
              Gap.h10,

              if (steps.isEmpty)
                Text('Log meals and symptoms to help build a useful insight.', style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, color: theme.textSecondary))
              else
                for (var i = 0; i < steps.take(3).length; i++) ...[
                  if (i > 0) Gap.h8,
                  InsightNextStepCheckRow(
                    title: 'Action ${i + 1}',
                    subtitle: steps[i],
                    accentColor: isDark ? const Color(0xFF22C55E) : const Color(0xFF16A34A),
                    titleColor: theme.textPrimary,
                    subtitleColor: theme.textSecondary,
                  ),
                ],
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

    final mealsCount = latestInsight?.evidence?.sampleSizes.meals;
    final symptomsCount = latestInsight?.evidence?.sampleSizes.symptoms ?? insight.positiveCount;
    final scansCount = latestInsight?.evidence?.sampleSizes.scans;

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
            value: mealsCount?.toString() ?? '—',
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
            value: symptomsCount?.toString() ?? '—',
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
            value: scansCount?.toString() ?? '—',
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
