part of 'highlight_detail_screen.dart';

/// Healing and progress sections for the highlight detail page.
///
/// This screen is deliberately evidence-aware: a one-day score is presented as
/// a starting point, not as a positive or negative trend. The layout keeps the
/// useful next step visible while avoiding empty section chrome and misleading
/// "+0" progress language.

extension HighlightHealingSections on HighlightDetailScreen {
  Widget _buildHealingTrendDetail(BuildContext context) {
    final theme = context.insightTheme;
    final insight = _highlightInsightOf(context);
    final scoreRecord = WhyScoreSheet.resolveRecord(context);
    int? profileScore;
    bool? profileHasScore;
    try {
      final profile = context.watch<ProfileNotifier>();
      profileScore = profile.gutScore;
      profileHasScore = profile.hasGutScore;
    } on ProviderNotFoundException {
      // Ignore if ProfileNotifier is not available in context.
    }

    var series = scoreRecord == null ? [...args.chartValues] : [for (final score in scoreRecord.dailyScores) score.toDouble()];
    if (series.isEmpty && insight?.weeklyRecap?.gutScoreTrend?.isNotEmpty == true) {
      series = [for (final score in insight!.weeklyRecap!.gutScoreTrend!) score.toDouble()];
    }
    if (series.isEmpty && insight?.hasGutScore == true) {
      series = [insight!.gutScore.toDouble()];
    }

    final cleanSeries = InsightValues.scores(series);
    final scoredSeries = scoreRecord?.scoredScores.map((score) => score.toDouble()).toList() ?? cleanSeries.where((score) => score > 0).toList(growable: false);
    final hasScore = scoreRecord?.hasScore ?? profileHasScore ?? (insight?.hasGutScore == true || scoredSeries.isNotEmpty);
    final scoredDayCount = scoreRecord?.scoredDayCount ?? (scoredSeries.isEmpty && insight?.hasGutScore == true ? 1 : scoredSeries.length);
    final hasHistory = scoredSeries.length > 1;
    final currentScore = scoreRecord?.gutScore ?? profileScore ?? (insight?.hasGutScore == true ? insight!.gutScore.clamp(0, 100).toInt() : (scoredSeries.isNotEmpty ? scoredSeries.last.round() : 0));

    // A single score is a baseline regardless of scoreDiff. Do not turn a
    // persisted "+0" into a green progress state.
    final routedDiff = InsightFeedDerivations.parseScoreDelta(args.frequency);
    final recordDiff = scoredSeries.length > 1 ? scoredSeries.last.round() - scoredSeries[scoredSeries.length - 2].round() : null;
    final diff = hasHistory ? (recordDiff ?? routedDiff ?? scoredSeries.last.round() - scoredSeries.first.round()) : 0;
    final isImproving = hasHistory && diff > 0;
    final isDeclining = hasHistory && diff < 0;
    final isBaseline = !hasHistory;
    final isEarlyProgress = isImproving && scoredDayCount <= 3;

    final accent = isBaseline
        ? theme.success
        : isImproving
        ? theme.success
        : isDeclining
        ? theme.error
        : theme.textSecondary;
    final accentSoft = isBaseline
        ? theme.successSoft
        : isImproving
        ? theme.successSoft
        : isDeclining
        ? theme.errorSoft
        : theme.cardSubtle;

    final appBarTitle = isBaseline ? 'BUILDING BASELINE' : 'YOUR PROGRESS';
    final statusLabel = isBaseline
        ? 'FIRST BASELINE'
        : isImproving
        ? isEarlyProgress
              ? 'EARLY PROGRESS'
              : 'IMPROVING'
        : isDeclining
        ? 'AREA TO WATCH'
        : 'STEADY';
    final headline = isBaseline
        ? (hasScore ? 'Your starting point is here.' : 'Your baseline is taking shape.')
        : diff != 0
        ? _scoreChangeHeadline(diff)
        : isEarlyProgress
        ? 'Your progress is beginning.'
        : (args.title.isNotEmpty ? _neutralProgressCopy(args.title) : 'Your gut score is steady.');
    final body = isBaseline
        ? hasScore
              ? 'We have ${scoredDayCount == 1 ? 'one scored day' : '$scoredDayCount scored days'} so far. Keep logging to make the next comparison more useful.'
              : 'Log meals and symptoms to create your first meaningful baseline.'
        : hasHistory && diff != 0
        ? 'Keep logging to see if this trend continues.'
        : (args.body?.trim().isNotEmpty == true ? _neutralProgressCopy(args.body!) : 'Your score is now based on more than one recorded day.');
    final rangeLabel = hasHistory ? '${scoredSeries.reduce((a, b) => a < b ? a : b).round()} → ${scoredSeries.reduce((a, b) => a > b ? a : b).round()}' : (hasScore ? '$currentScore/100' : '0/100');
    final coverageLabel = scoredSeries.isEmpty ? '0 / 7' : '${scoredSeries.length} / 7';
    final coverageDetail = scoredDayCount == 1 ? '1 day scored' : '$scoredDayCount days scored';
    final scoreDetail = hasScore ? 'Current score' : 'Awaiting first score';

    // Keep the chart on a stable seven-day coordinate system. A one-value
    // series is anchored to today instead of being drawn in the middle of the
    // chart, while shorter histories are right-aligned to the current week.
    final chartSeries = _normalizeChartSeries(series, anchorIndex: DateTime.now().weekday % 7);

    final foods = _healingFoods(insight);
    final highlights = _progressHighlights(insight);
    final nextSteps = _nextStepLabels(insight).map(_neutralProgressCopy).where((step) => !step.toLowerCase().contains('keep the momentum going')).toList();
    if (isBaseline && nextSteps.isEmpty) {
      nextSteps.add(hasScore ? 'Log one more day of meals and symptoms to compare with this starting point.' : 'Log a full day of meals and symptoms to create your starting point.');
    } else if (nextSteps.isEmpty && isImproving) {
      nextSteps.add('Keep logging meals and symptoms to see whether this trend continues.');
    }

    return Scaffold(
      backgroundColor: theme.scaffold,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          GutSliverAppBar(title: appBarTitle, centerTitle: true, showBrandingIcon: false, backgroundColor: theme.scaffold),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 6.w, 16.w, 20.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildProgressHero(
                  context,
                  theme: theme,
                  chartSeries: chartSeries,
                  scoredDayIndices: scoreRecord?.scoredDayIndices,
                  hasScore: hasScore,
                  currentScore: currentScore,
                  hasHistory: hasHistory,
                  diff: diff,
                  statusLabel: statusLabel,
                  headline: headline,
                  body: body,
                  rangeLabel: rangeLabel,
                  coverageLabel: coverageLabel,
                  coverageDetail: coverageDetail,
                  scoreDetail: scoreDetail,
                  accent: accent,
                  accentSoft: accentSoft,
                ),
                Gap.h12,
                _buildObservationStatusCard(context, insight: insight, isBaseline: isBaseline, scoredDayCount: scoredDayCount, diff: diff),
                if (foods.isNotEmpty) ...[Gap.h12, _buildWhatsContributingSection(context, foods)],
                if (highlights.isNotEmpty) ...[Gap.h12, _buildProgressHighlightsSection(context, highlights)],
                if (nextSteps.isNotEmpty) ...[Gap.h12, _buildNextStepsSection(context, nextSteps, isBaseline: isBaseline)],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBaselineHero({
    required InsightTheme theme,
    required bool hasScore,
    required int currentScore,
    required String statusLabel,
    required String headline,
    required String body,
    required Color accent,
    required Color accentSoft,
  }) {
    final statusDetail = hasScore ? 'Starting point recorded' : 'Waiting for first scored day';
    final statusNote = hasScore ? 'The next logged day will give us a useful comparison.' : 'Log a meal and how you feel to start your baseline.';

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: accentSoft,
        borderRadius: BorderRadius.circular(24.w),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
        boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.08), blurRadius: 18.w, offset: Offset(0, 7.w))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.16), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: hasScore
                    ? Text(
                        '$currentScore',
                        style: TextStyle(fontFamily: InsightTheme.displayFont, fontSize: currentScore == 100 ? 16.sp : 20.sp, fontWeight: FontWeight.w800, color: accent),
                      )
                    : Icon(LucideIcons.calendar, size: 18.w, color: accent),
              ),
              Gap.w10,
              Expanded(
                child: Text(
                  statusLabel,
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w900, letterSpacing: 0.65, color: accent),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.w),
                decoration: BoxDecoration(color: theme.card.withValues(alpha: 0.72), borderRadius: BorderRadius.circular(999.w)),
                child: Text(
                  hasScore ? 'NO TREND YET' : 'READY TO LOG',
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w800, letterSpacing: 0.35, color: accent),
                ),
              ),
            ],
          ),
          Gap.h12,
          Text(
            headline,
            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 22.sp, fontWeight: FontWeight.w900, height: 1.05, letterSpacing: -0.5, color: theme.textPrimary),
          ),
          Gap.h8,
          Text(
            body,
            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.5.sp, height: 1.4, color: theme.textSecondary),
          ),
          Gap.h12,
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: theme.card.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(15.w),
              border: Border.all(color: accent.withValues(alpha: 0.12)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.checkCircle, size: 17.w, color: accent),
                Gap.w8,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BASELINE STATUS',
                        style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w900, letterSpacing: 0.55, color: accent),
                      ),
                      Gap.h3,
                      Text(
                        statusDetail,
                        style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: theme.textPrimary),
                      ),
                      Gap.h2,
                      Text(
                        statusNote,
                        style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, height: 1.3, color: theme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHero(
    BuildContext context, {
    required InsightTheme theme,
    required List<double> chartSeries,
    List<int>? scoredDayIndices,
    required bool hasScore,
    required int currentScore,
    required bool hasHistory,
    required int diff,
    required String statusLabel,
    required String headline,
    required String body,
    required String rangeLabel,
    required String coverageLabel,
    required String coverageDetail,
    required String scoreDetail,
    required Color accent,
    required Color accentSoft,
  }) {
    if (!hasHistory) {
      return _buildBaselineHero(theme: theme, hasScore: hasScore, currentScore: currentScore, statusLabel: statusLabel, headline: headline, body: body, accent: accent, accentSoft: accentSoft);
    }

    const dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final scoreText = hasScore ? '$currentScore' : '0';
    final deltaText = hasHistory ? '${diff > 0 ? '+' : ''}$diff pts' : 'Baseline';

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [accentSoft.withValues(alpha: 0.72), theme.card]),
        borderRadius: BorderRadius.circular(24.w),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
        boxShadow: [BoxShadow(color: theme.textPrimary.withValues(alpha: 0.045), blurRadius: 18.w, offset: Offset(0, 7.w))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 6.w),
                decoration: BoxDecoration(color: accentSoft, borderRadius: BorderRadius.circular(999.w)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasHistory
                          ? (diff < 0
                                ? LucideIcons.trendingDown
                                : diff == 0
                                ? LucideIcons.minus
                                : LucideIcons.trendingUp)
                          : LucideIcons.sparkles,
                      size: 13.w,
                      color: accent,
                    ),
                    Gap.w5,
                    Text(
                      statusLabel,
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: accent),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                deltaText,
                style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w800, color: accent),
              ),
            ],
          ),
          Gap.h10,
          Text(
            headline,
            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 20.sp, fontWeight: FontWeight.w900, height: 1.05, letterSpacing: -0.45, color: theme.textPrimary),
          ),
          Gap.h6,
          Text(
            body,
            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.5.sp, height: 1.35, color: theme.textSecondary),
          ),
          Gap.h12,
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 98.w,
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(color: accentSoft.withValues(alpha: 0.72), borderRadius: BorderRadius.circular(14.w)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scoreText,
                      style: TextStyle(fontFamily: InsightTheme.displayFont, fontSize: 40.sp, height: 0.9, color: accent),
                    ),
                    Gap.h6,
                    Text(
                      scoreDetail,
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w700, color: theme.textTertiary),
                    ),
                  ],
                ),
              ),
              Gap.w14,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          '7-DAY SCORE',
                          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: theme.textTertiary),
                        ),
                        const Spacer(),
                        Text(
                          hasHistory ? 'Trend' : 'Starting point',
                          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w700, color: accent),
                        ),
                      ],
                    ),
                    Gap.h5,
                    SizedBox(
                      height: 56.w,
                      child: InsightTrendChart(values: chartSeries, scoredDayIndices: scoredDayIndices, height: 56, color: accent, endDot: true),
                    ),
                    Gap.h6,
                    AlignedDayLabelsRow(labels: dayLabels, todayIndex: DateTime.now().weekday % 7),
                  ],
                ),
              ),
            ],
          ),
          Gap.h12,
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: accentSoft.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(16.w),
              border: Border.all(color: accent.withValues(alpha: 0.12)),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _BaselineMetric(label: 'WEEKLY COVERAGE', value: coverageLabel, detail: coverageDetail, color: accent),
                  ),
                  Container(
                    width: 1.w,
                    margin: EdgeInsets.symmetric(vertical: 5.w),
                    color: accent.withValues(alpha: 0.16),
                  ),
                  Expanded(
                    child: _BaselineMetric(label: 'SCORE RANGE', value: rangeLabel, detail: hasHistory ? '7-day low to high' : 'Starting point', color: accent),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObservationStatusCard(BuildContext context, {required AIInsight? insight, required bool isBaseline, required int scoredDayCount, required int diff}) {
    final theme = context.insightTheme;
    final top = insight?.topInsight;
    final title = isBaseline
        ? 'No recurring pattern yet'
        : diff != 0
        ? (diff > 0 ? 'Progress signal' : 'Score change')
        : top?.title.trim().isNotEmpty == true
        ? _neutralProgressCopy(top!.title)
        : 'No recurring pattern yet';
    final description = isBaseline
        ? scoredDayCount == 0
              ? 'There is not enough logged evidence yet. Keep recording meals and symptoms so we can learn what is typical for you.'
              : 'One scored day gives us a starting point. More logs are needed before we can compare patterns.'
        : diff != 0
        ? _scoreChangeCopy(diff)
        : top?.description.trim().isNotEmpty == true
        ? _neutralProgressCopy(top!.description)
        : 'Your recent logs are helping reveal what is typical for you.';
    final observationCount = isBaseline ? scoredDayCount : (top?.frequency ?? 1);
    final accent = isBaseline
        ? theme.success
        : diff < 0
        ? theme.error
        : theme.success;
    final accentSoft = isBaseline
        ? theme.successSoft
        : diff < 0
        ? theme.errorSoft
        : theme.successSoft;

    return Container(
      padding: EdgeInsets.all(13.w),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(color: accentSoft, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(LucideIcons.radar, size: 18.w, color: accent),
              ),
              Gap.w10,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBaseline ? 'WHAT WE\'RE LEARNING' : 'EVIDENCE SNAPSHOT',
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w800, letterSpacing: 0.65, color: accent),
                    ),
                    Gap.h3,
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, height: 1.15, color: theme.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Gap.h10,
          Text(
            description,
            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, height: 1.35, color: theme.textSecondary),
          ),
          Gap.h10,
          Wrap(
            spacing: 7.w,
            runSpacing: 7.w,
            children: [
              _EvidencePill(
                icon: LucideIcons.listChecks,
                label: observationCount == 0
                    ? 'No observations yet'
                    : observationCount == 1
                    ? '1 observation'
                    : '$observationCount observations',
                color: accent,
                background: accentSoft.withValues(alpha: 0.72),
              ),
              _EvidencePill(icon: LucideIcons.info, label: observationCount <= 1 ? 'Needs more evidence' : 'Pattern developing', color: theme.textSecondary, background: theme.cardSubtle),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsContributingSection(BuildContext context, List<InsightFood> foods) {
    final theme = context.insightTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BaselineSectionHeader(
          icon: LucideIcons.leaf,
          iconColor: theme.success,
          iconBackground: theme.successSoft,
          title: 'What\'s contributing?',
          subtitle: 'Foods supported by repeated observations.',
        ),
        Gap.h10,
        SizedBox(
          height: 150.w,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: foods.length,
            separatorBuilder: (_, _) => Gap.w10,
            itemBuilder: (context, index) {
              final food = foods[index];
              return _ContributingCard(
                title: food.name,
                subtitle: food.effect?.trim().isNotEmpty == true ? _neutralProgressCopy(food.effect!) : 'Observed in your logs.',
                badgeText: 'Supportive observation',
                badgeColor: theme.successSoft,
                badgeTextColor: theme.success,
                imageKeyword: food.name,
                icon: LucideIcons.leaf,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProgressHighlightsSection(BuildContext context, List<String> highlights) {
    final theme = context.insightTheme;
    final items = highlights.take(2).map(_neutralProgressCopy).toList();

    return Container(
      padding: EdgeInsets.all(13.w),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(color: theme.successSoft, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(LucideIcons.sparkles, size: 18.w, color: theme.success),
              ),
              Gap.w10,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROGRESS HIGHLIGHTS',
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w800, letterSpacing: 0.65, color: theme.success),
                    ),
                    Gap.h3,
                    Text(
                      'Signals from your recent logs',
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, height: 1.15, color: theme.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Gap.h10,
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0) ...[Gap.h6, Divider(height: 1.w, color: theme.borderSubtle), Gap.h6],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.circleCheck, size: 15.w, color: theme.success),
                Gap.w8,
                Expanded(
                  child: Text(
                    items[index],
                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, height: 1.35, color: theme.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNextStepsSection(BuildContext context, List<String> nextSteps, {required bool isBaseline}) {
    final theme = context.insightTheme;
    final accent = isBaseline ? theme.success : theme.purple;
    final accentSoft = isBaseline ? theme.successSoft : theme.purplePastel.withValues(alpha: 0.18);

    final items = nextSteps.take(2).toList();
    return Container(
      padding: EdgeInsets.all(13.w),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(color: accentSoft, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(LucideIcons.arrowUpRight, size: 18.w, color: accent),
              ),
              Gap.w10,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR NEXT BEST STEP',
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w800, letterSpacing: 0.65, color: accent),
                    ),
                    Gap.h3,
                    Text(
                      'One small log makes the next comparison stronger.',
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, height: 1.15, color: theme.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Gap.h10,
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0) ...[Gap.h6, Divider(height: 1.w, color: theme.borderSubtle), Gap.h6],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20.w,
                  height: 20.w,
                  decoration: BoxDecoration(color: accentSoft, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.sp, fontWeight: FontWeight.w800, color: accent),
                  ),
                ),
                Gap.w8,
                Expanded(
                  child: Text(
                    items[index],
                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, height: 1.35, color: theme.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<double> _normalizeChartSeries(List<double> raw, {required int anchorIndex}) {
    if (raw.isEmpty) return const [];

    // Daily score records are already seven-slot Sunday–Saturday arrays. For
    // longer legacy series, keep the latest seven values for this detail view.
    if (raw.length >= 7) {
      return raw.length == 7 ? [...raw] : raw.sublist(raw.length - 7);
    }

    final slots = List<double>.filled(7, 0);
    final safeAnchor = anchorIndex.clamp(0, 6).toInt();
    final start = (safeAnchor - raw.length + 1).clamp(0, 7 - raw.length).toInt();
    for (var index = 0; index < raw.length; index++) {
      slots[start + index] = raw[index];
    }
    return slots;
  }

  List<InsightFood> _healingFoods(AIInsight? insight) {
    if (insight == null) return const [];
    if (insight.healingSummary?.foods.isNotEmpty == true) {
      return insight.healingSummary!.foods;
    }
    return [for (final food in insight.healingFoods) InsightFood(foodId: 'f_${food.name}', name: food.name, emoji: food.emoji, imageUrl: food.userImageUrl ?? food.imageUrl, effect: food.effect)];
  }

  List<String> _progressHighlights(AIInsight? insight) =>
      insight?.weeklyRecap?.highlights
          .map(
            (item) => item is RecapHighlight
                ? item.text
                : item is String
                ? item
                : '',
          )
          .where((text) => text.trim().isNotEmpty && !text.toLowerCase().contains('keep the momentum going'))
          .take(2)
          .toList() ??
      const [];

  List<String> _nextStepLabels(AIInsight? insight) {
    if (insight == null) return const [];
    final actionLabels = insight.actionsList.map((action) => action.title.trim()).where((title) => title.isNotEmpty).toList();
    if (actionLabels.isNotEmpty) return actionLabels;
    return insight.topInsight?.nextSteps.where((step) => step.trim().isNotEmpty).toList() ?? const [];
  }

  String _scoreChangeCopy(int points) => points > 0
      ? 'Your score increased $points ${points == 1 ? 'point' : 'points'} since your previous scored day — keep logging to see if this trend continues.'
      : 'Your score decreased ${points.abs()} ${points.abs() == 1 ? 'point' : 'points'} since your previous scored day — keep logging to see if this trend continues.';

  String _scoreChangeHeadline(int points) => 'Your score ${points > 0 ? 'increased' : 'decreased'} ${points.abs()} ${points.abs() == 1 ? 'point' : 'points'}';

  String _neutralProgressCopy(String value) => value.replaceAll(RegExp('healing', caseSensitive: false), 'progress');
}

class _BaselineMetric extends StatelessWidget {
  const _BaselineMetric({required this.label, required this.value, required this.detail, required this.color});

  final String label;
  final String value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = context.insightTheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 5.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w800, letterSpacing: 0.45, color: theme.textTertiary),
            ),
            Gap.h3,
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w900, color: color),
            ),
            Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.sp, color: theme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvidencePill extends StatelessWidget {
  const _EvidencePill({required this.icon, required this.label, required this.color, required this.background});

  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.w),
    decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999.w)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12.w, color: color),
        Gap.w4,
        Text(
          label,
          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.sp, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    ),
  );
}

class _BaselineSectionHeader extends StatelessWidget {
  const _BaselineSectionHeader({required this.icon, required this.iconColor, required this.iconBackground, required this.title, required this.subtitle});

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = context.insightTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34.w,
          height: 34.w,
          decoration: BoxDecoration(color: iconBackground, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Icon(icon, size: 17.w, color: iconColor),
        ),
        Gap.w10,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 14.5.sp, fontWeight: FontWeight.w800, color: theme.textPrimary),
              ),
              Gap.h2,
              Text(
                subtitle,
                style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, color: theme.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}