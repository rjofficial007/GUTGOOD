part of 'insights_feed.dart';

/// Weekly recap shell and summary presentation components.

class WeeklyRecapView extends StatelessWidget {
  const WeeklyRecapView({super.key, required this.data, this.series = const [], this.patterns = const [], this.history = const []});

  final AIInsight data;
  final List<double> series;
  final List<BodyPattern> patterns;
  final List<AIInsight> history;

  @override
  Widget build(BuildContext context) {
    final recap = data.weeklyRecap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Average Gut Score Card
        _WeeklyAverageScoreCard(recap: recap, data: data),
        Gap.h10,

        // 2. Row of 3 Stat Cards (Best Day, Foods Logged, Your Evidence)
        _WeeklyRecapStatCardsRow(recap: recap, data: data),
        Gap.h10,

        // 3. Weekly Highlights Card
        _WeeklyHighlightsCard(recap: recap),
        Gap.h10,

        // 4. Side-by-Side Top Healing Food & Top Trigger Food
        _WeeklyTopFoodsRow(data: data),
        Gap.h10,

        // 5. Your Weekly Insight Card
        _YourWeeklyInsightCard(data: data),
      ],
    );
  }
}

class _WeeklyAverageScoreCard extends StatelessWidget {
  const _WeeklyAverageScoreCard({required this.recap, required this.data});
  final WeeklyRecap? recap;
  final AIInsight data;

  @override
  Widget build(BuildContext context) {
    GutScoreRecord? scoreRecord;
    try {
      scoreRecord = context.read<InsightsNotifier>().latestScoreRecord;
    } catch (_) {}

    var trendInts = const <int>[];
    if (scoreRecord != null && scoreRecord.dailyScores.isNotEmpty) {
      trendInts = scoreRecord.dailyScores;
    } else if (recap?.gutScoreTrend != null && recap!.gutScoreTrend!.isNotEmpty) {
      trendInts = recap!.gutScoreTrend!;
    }

    final trendDoubles = trendInts.map((e) => e.toDouble()).toList();
    final scored = trendInts.where((s) => s > 0).toList();
    final trendAvg = scored.isEmpty ? null : (scored.reduce((a, b) => a + b) / scored.length).round();

    final recordScore = scoreRecord?.gutScore;
    final avgScore = (recordScore != null && recordScore > 0) ? recordScore : (recap?.avgScore ?? trendAvg ?? (data.hasGutScore ? data.gutScore : 0));

    final hasAnyScore = (recordScore != null && recordScore > 0) || data.hasGutScore || scored.isNotEmpty || (recap?.avgScore ?? 0) > 0;

    if (!hasAnyScore) {
      return InsightScoreCard(score: null, delta: null, onTap: null, onWhyTap: () => WhyScoreSheet.show(context, data));
    }

    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return GutScoreCard(
      score: avgScore,
      title: 'WEEKLY AVERAGE',
      subtitle: recap?.scoreSub ?? 'Your gut score trend over the last 7 days.',
      showChevron: false,
      series: trendDoubles.isNotEmpty ? trendDoubles : [avgScore.toDouble()],
      labels: labels,
    );
  }
}

class _ForYouGutScoreCard extends StatelessWidget {
  const _ForYouGutScoreCard({required this.data, required this.series, this.delta});
  final AIInsight data;
  final List<double> series;
  final int? delta;

  @override
  Widget build(BuildContext context) {
    GutScoreRecord? scoreRecord;
    try {
      scoreRecord = context.read<InsightsNotifier>().latestScoreRecord;
    } catch (_) {}

    var trendInts = const <int>[];
    if (scoreRecord != null && scoreRecord.dailyScores.isNotEmpty) {
      trendInts = scoreRecord.dailyScores;
    } else if (data.weeklyRecap?.gutScoreTrend != null && data.weeklyRecap!.gutScoreTrend!.isNotEmpty) {
      trendInts = data.weeklyRecap!.gutScoreTrend!;
    }

    final trendDoubles = trendInts.map((e) => e.toDouble()).toList();
    final scored = trendInts.where((s) => s > 0).toList();
    final trendAvg = scored.isEmpty ? null : (scored.reduce((a, b) => a + b) / scored.length).round();

    final recordScore = scoreRecord?.gutScore;
    final displayScore = (recordScore != null && recordScore > 0) ? recordScore : (data.hasGutScore ? data.gutScore : (data.weeklyRecap?.avgScore ?? trendAvg ?? 0));

    final hasAnyScore = (recordScore != null && recordScore > 0) || data.hasGutScore || scored.isNotEmpty || (data.weeklyRecap?.avgScore ?? 0) > 0;

    if (!hasAnyScore) {
      return InsightScoreCard(score: null, delta: null, onTap: null, onWhyTap: () => WhyScoreSheet.show(context, data));
    }

    final chartSeries = trendDoubles.isNotEmpty ? trendDoubles : (series.isNotEmpty ? series : [displayScore.toDouble()]);

    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return GutScoreCard(
      score: displayScore,
      delta: delta,
      title: 'GUTGOOD SCORE',
      subtitle: data.weeklyRecap?.scoreSub ?? 'Based on your recent meal and symptom logs.',
      series: chartSeries,
      labels: labels,
      onTap: () => WhyScoreSheet.show(context, data),
    );
  }
}

class _WeeklyRecapStatCardsRow extends StatelessWidget {
  const _WeeklyRecapStatCardsRow({required this.recap, required this.data});

  final WeeklyRecap? recap;
  final AIInsight data;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bestDay = (recap?.bestDay != null && recap!.bestDay!.isNotEmpty) ? recap!.bestDay! : '—';
    // Prefer recap counts (7-day). Fall back to evidence sample sizes so the
    // card never shows a blank "—" when the insight has real logs.
    final foodsLogged = recap?.foodsLogged ?? ((data.evidence?.sampleSizes.meals ?? 0) + (data.evidence?.sampleSizes.scans ?? 0));
    final foodsLabel = recap?.loggedSub ?? 'meals and scans';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Best Day Card
          Expanded(
            child: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF102319) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16.w),
                border: Border.all(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.28) : const Color(0xFFDCFCE7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.18) : const Color(0xFFDCFCE7), shape: BoxShape.circle),
                        child: Icon(LucideIcons.calendar, size: 11.w, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)),
                      ),
                      Gap.w4,
                      Expanded(
                        child: Text(
                          'Best Day',
                          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)),
                        ),
                      ),
                    ],
                  ),
                  Gap.h6,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bestDay,
                              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 16.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A)), height: 1.1),
                            ),
                            Gap.h2,
                            Text(
                              recap?.dateRange ?? 'No best day recorded',
                              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.5.sp, color: context.insightColor(const Color(0xFF64748B))),
                            ),
                          ],
                        ),
                      ),
                      Icon(LucideIcons.leaf, size: 20.w, color: isDark ? const Color(0xFF4ADE80).withValues(alpha: 0.25) : const Color(0xFF86EFAC).withValues(alpha: 0.7)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Gap.w6,

          // 2. Foods Logged Card
          Expanded(
            child: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF231A14) : const Color(0xFFFFFBF5),
                borderRadius: BorderRadius.circular(16.w),
                border: Border.all(color: isDark ? const Color(0xFFF97316).withValues(alpha: 0.28) : const Color(0xFFFFEDD5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(color: isDark ? const Color(0xFFF97316).withValues(alpha: 0.18) : const Color(0xFFFFEDD5), shape: BoxShape.circle),
                        child: Icon(LucideIcons.utensils, size: 11.w, color: isDark ? const Color(0xFFFB923C) : const Color(0xFFC2410C)),
                      ),
                      Gap.w4,
                      Expanded(
                        child: Text(
                          'Foods Logged',
                          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFFFB923C) : const Color(0xFF9A3412)),
                        ),
                      ),
                    ],
                  ),
                  Gap.h6,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$foodsLogged',
                              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 17.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A)), height: 1.1),
                            ),
                            Gap.h2,
                            Text(
                              foodsLabel,
                              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.5.sp, color: context.insightColor(const Color(0xFF64748B))),
                            ),
                          ],
                        ),
                      ),
                      Icon(LucideIcons.utensils, size: 18.w, color: isDark ? const Color(0xFFFB923C).withValues(alpha: 0.20) : const Color(0xFFFED7AA).withValues(alpha: 0.7)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Gap.w6,

          // 3. Your Evidence Card
          Expanded(
            child: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111E2E) : const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(16.w),
                border: Border.all(color: isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.28) : const Color(0xFFE0F2FE)),
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
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(color: isDark ? const Color(0xFF0284C7).withValues(alpha: 0.20) : const Color(0xFFE0F2FE), shape: BoxShape.circle),
                            child: Icon(LucideIcons.barChart2, size: 11.w, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1)),
                          ),
                          Gap.w3,
                          Expanded(
                            child: Text(
                              'Your Evidence',
                              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1)),
                            ),
                          ),
                          Icon(LucideIcons.info, size: 10.w, color: isDark ? const Color(0xFF64748B) : context.insightColor(const Color(0xFF94A3B8))),
                        ],
                      ),
                      Gap.h6,
                      _EvidenceRow(label: 'Meals', count: data.evidence?.sampleSizes.meals),
                      Gap.h2,
                      _EvidenceRow(label: 'Symptoms', count: data.evidence?.sampleSizes.symptoms),
                      Gap.h2,
                      _EvidenceRow(label: 'Scans', count: data.evidence?.sampleSizes.scans),
                    ],
                  ),
                  Gap.h4,
                  Text(
                    'More data = more insights',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 7.5.sp, color: context.insightColor(const Color(0xFF64748B))),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

