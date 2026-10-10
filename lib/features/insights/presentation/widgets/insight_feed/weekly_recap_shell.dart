part of 'insights_feed.dart';

/// Weekly recap shell and summary presentation components.

bool isWeeklyRecapAvailable(WeeklyRecap? recap, {DateTime? at}) {
  if (recap == null) return false;
  final hasFoodEvidence = (recap.foodsLogged ?? 0) > 0;
  final hasScoreEvidence = recap.scoredDayCount > 0;
  if (!hasFoodEvidence && !hasScoreEvidence) return false;

  // A recap without an explicit period is an unbounded/current snapshot, not
  // a validated weekly result. Recaps cover Sunday–Saturday and become
  // available on Saturday, the final day of that window.
  final periodFrom = recap.periodFrom?.toLocal();
  final periodTo = recap.periodTo?.toLocal();
  if (periodFrom == null || periodTo == null) return false;

  final fromDay = DateTime(periodFrom.year, periodFrom.month, periodFrom.day);
  final toDay = DateTime(periodTo.year, periodTo.month, periodTo.day);
  final isSundayThroughSaturday = fromDay.weekday == DateTime.sunday && toDay.weekday == DateTime.saturday && toDay.difference(fromDay).inDays == 6;

  final now = at ?? DateTime.now();
  final currentWeekStart = DateTime(now.year, now.month, now.day - now.weekday % 7);
  final isCurrentSaturdayRecap = now.weekday == DateTime.saturday && fromDay.isAtSameMomentAs(currentWeekStart);
  return isSundayThroughSaturday && (periodTo.isBefore(now) || isCurrentSaturdayRecap);
}

class WeeklyRecapView extends StatelessWidget {
  const WeeklyRecapView({super.key, required this.data, this.series = const [], this.patterns = const [], this.history = const []});

  final AIInsight data;
  final List<double> series;
  final List<BodyPattern> patterns;
  final List<AIInsight> history;

  @override
  Widget build(BuildContext context) {
    final recap = data.weeklyRecap;

    if (!isWeeklyRecapAvailable(recap)) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InsightsEmptyState(
            headline: 'Your week.\nYour score.\nYour recap.',
            description: 'Keep logging meals and symptoms this week. Your Sunday–Saturday recap will appear here on Saturday.',
            banner: _InsightsLearningBannerCard(title: 'Your weekly recap gets clearer over time', description: 'Keep logging meals and symptoms to unlock a more meaningful weekly summary.'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WeeklyRecapOverview(recap: recap, history: history),
        Gap.h10,
        _WeeklyRecapObservation(data: data, recap: recap, patterns: patterns),
        Gap.h10,
        _WeeklyRecapHighlights(recap: recap, impacts: data.foodImpacts),
        Gap.h10,
        _RecentFoodImpactsSection(
          impacts: data.foodImpacts,
          onSeeAll: () => context.push(AppRoutes.foodIntelligence, extra: data),
        ),
      ],
    );
  }
}

class _WeeklyRecapOverview extends StatelessWidget {
  const _WeeklyRecapOverview({required this.recap, required this.history});
  final WeeklyRecap? recap;
  final List<AIInsight> history;

  @override
  Widget build(BuildContext context) {
    final score = recap?.avgScore;
    final previous = history.where((item) => item.weeklyRecap?.avgScore != null && (recap?.periodFrom == null || item.weeklyRecap?.periodTo?.isBefore(recap!.periodFrom!) == true)).toList()
      ..sort((a, b) => (b.weeklyRecap?.periodTo ?? DateTime(0)).compareTo(a.weeklyRecap?.periodTo ?? DateTime(0)));
    final previousScore = previous.firstOrNull?.weeklyRecap?.avgScore;
    final delta = score != null && previousScore != null ? score - previousScore : null;
    final from = recap?.periodFrom?.toLocal();
    final to = recap?.periodTo?.toLocal();
    final date = from != null && to != null ? '${_month(from.month)} ${from.day} – ${_month(to.month)} ${to.day}' : (recap?.dateRange ?? 'This week');
    final stats = [
      (LucideIcons.utensils, const Color(0xFF2563EB), const Color(0xFFEFF6FF), const Color(0xFFDBEAFE), (recap?.foodsLogged ?? 0).toString(), 'Meals Logged'),
      (LucideIcons.gauge, const Color(0xFF15803D), const Color(0xFFF0FDF4), const Color(0xFFDCFCE7), (score ?? 0).toString(), 'Avg GutGood Score'),
      (LucideIcons.trendingUp, const Color(0xFF7C3AED), const Color(0xFFF5F3FF), const Color(0xFFEDE9FE), '${delta != null && delta > 0 ? '+' : ''}${delta ?? 0}', 'Score Change'),
    ];
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: context.insightTheme.card,
        borderRadius: BorderRadius.circular(22.w),
        border: Border.all(color: const Color(0xFFE8EAF2)),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: .04), blurRadius: 14.w, offset: Offset(0, 4.w))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 30.w,
                          height: 30.w,
                          decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                          child: Icon(LucideIcons.calendarDays, size: 15.w, color: const Color(0xFF2563EB)),
                        ),
                        Gap.w6,
                        Expanded(
                          child: Text(
                            date.toUpperCase(),
                            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w700, letterSpacing: .5, color: const Color(0xFF7A8193)),
                          ),
                        ),
                      ],
                    ),
                    Gap.h8,
                    Text(
                      'Your Weekly Recap',
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 20.sp, fontWeight: FontWeight.w800, letterSpacing: -.5, color: context.insightColor(const Color(0xFF101828))),
                    ),
                    Text(
                      'Here’s what we learned from your meals and how you felt.',
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, height: 1.35, color: context.insightColor(const Color(0xFF667085))),
                    ),
                  ],
                ),
              ),
              Image.asset(AppAssets.calender, width: 76.w, height: 82.w, fit: BoxFit.contain),
            ],
          ),
          Gap.h14,
          Row(
            children: [
              for (var i = 0; i < stats.length; i++) ...[
                if (i > 0) Gap.w6,
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(10.w),
                    constraints: BoxConstraints(minHeight: 94.w),
                    decoration: BoxDecoration(color: stats[i].$3, borderRadius: BorderRadius.circular(17.w)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 29.w,
                          height: 29.w,
                          decoration: BoxDecoration(color: stats[i].$4, shape: BoxShape.circle),
                          child: Icon(stats[i].$1, size: 17.w, color: stats[i].$2),
                        ),
                        Gap.h5,
                        Text(
                          stats[i].$5,
                          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 18.sp, fontWeight: FontWeight.w800, color: const Color(0xFF101828)),
                        ),
                        Text(
                          stats[i].$6,
                          maxLines: 2,
                          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, height: 1.2, color: const Color(0xFF667085)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _month(int month) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month - 1];
}

class _WeeklyRecapObservation extends StatelessWidget {
  const _WeeklyRecapObservation({required this.data, required this.recap, required this.patterns});
  final AIInsight data;
  final WeeklyRecap? recap;
  final List<BodyPattern> patterns;

  @override
  Widget build(BuildContext context) {
    final negative = data.foodImpacts.where((item) => const {'negative', 'trigger', 'bad', 'watch'}.contains(item.impactType.toLowerCase())).toList();
    final text = recap?.summary?.trim().isNotEmpty == true
        ? recap!.summary!.trim()
        : data.topInsight?.description.trim().isNotEmpty == true
        ? data.topInsight!.description.trim()
        : patterns.firstOrNull?.description.trim().isNotEmpty == true
        ? patterns.first.description.trim()
        : 'Keep logging meals and symptoms to reveal a useful pattern for this week.';
    final color = negative.isEmpty ? const Color(0xFF15803D) : const Color(0xFFB42318);
    final surface = negative.isEmpty ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);
    final image = negative.firstOrNull;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: color.withValues(alpha: .16)),
      ),
      child: Row(
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(negative.isEmpty ? LucideIcons.sparkles : LucideIcons.triangleAlert, size: 19.w, color: Colors.white),
          ),
          Gap.w10,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  negative.isEmpty ? 'A Positive Pattern' : 'Key Observation',
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: color),
                ),
                Gap.h4,
                Text(
                  text,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.5.sp, height: 1.35, color: context.insightColor(const Color(0xFF475467))),
                ),
              ],
            ),
          ),
          if (image != null) ...[
            Gap.w8,
            ClipRRect(
              borderRadius: BorderRadius.circular(13.w),
              child: DynamicFoodImage(keyword: image.food, imageUrl: image.userImageUrl ?? image.imageUrl, width: 62.w, height: 62.w, fit: BoxFit.cover),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeeklyRecapHighlights extends StatelessWidget {
  const _WeeklyRecapHighlights({required this.recap, required this.impacts});
  final WeeklyRecap? recap;
  final List<FoodImpact> impacts;

  @override
  Widget build(BuildContext context) {
    final highlights = (recap?.highlights ?? const []).where((item) => item is RecapHighlight ? item.text.trim().isNotEmpty : item is String && item.trim().isNotEmpty).toList();
    final good = <String>[];
    final watch = <String>[];
    for (final item in highlights) {
      final text = item is RecapHighlight ? item.text : item.toString();
      final positive = item is RecapHighlight && item.color.toLowerCase().contains('green');
      (positive ? good : watch).add(text);
    }
    if (good.isEmpty) good.addAll(impacts.where((i) => const {'positive', 'healing', 'good', 'supportive'}.contains(i.impactType.toLowerCase())).take(3).map((i) => '${i.food}: ${i.effect}'));
    if (watch.isEmpty) watch.addAll(impacts.where((i) => const {'negative', 'trigger', 'bad', 'watch'}.contains(i.impactType.toLowerCase())).take(3).map((i) => '${i.food}: ${i.effect}'));
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _RecapListCard(
              title: 'What Went Well',
              icon: LucideIcons.arrowUp,
              color: const Color(0xFF15803D),
              background: const Color(0xFFF0FDF7),
              items: good,
              empty: 'Keep logging to discover what is working well.',
            ),
          ),
          Gap.w8,
          Expanded(
            child: _RecapListCard(
              title: 'Keep an Eye On',
              icon: LucideIcons.eye,
              color: const Color(0xFFB7791F),
              background: const Color(0xFFFFFBEB),
              items: watch,
              empty: 'No watch patterns recorded this week.',
            ),
          ),
        ],
      ),
    );
  }
}

class _RecapListCard extends StatelessWidget {
  const _RecapListCard({required this.title, required this.icon, required this.color, required this.background, required this.items, required this.empty});
  final String title;
  final IconData icon;
  final Color color;
  final Color background;
  final List<String> items;
  final String empty;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(11.w),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(19.w),
      border: Border.all(color: color.withValues(alpha: .12)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 17.w, color: color),
            Gap.w6,
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: color),
              ),
            ),
          ],
        ),
        Gap.h8,
        for (final item in (items.isEmpty ? [empty] : items.take(3)))
          Padding(
            padding: EdgeInsets.only(bottom: 7.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(items.isEmpty ? LucideIcons.dot : LucideIcons.circleCheck, size: 13.w, color: color),
                Gap.w5,
                Expanded(
                  child: Text(
                    item,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, height: 1.3, color: context.insightColor(const Color(0xFF475467))),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _ForYouGutScoreCard extends StatelessWidget {
  const _ForYouGutScoreCard({required this.data, required this.series, this.delta});
  final AIInsight data;
  final List<double> series;
  final int? delta;

  @override
  Widget build(BuildContext context) {
    final scoreRecord = WhyScoreSheet.resolveRecord(context);

    final isCompletedRecap = data.weeklyRecap?.periodTo != null;
    var trendInts = const <int>[];
    if (scoreRecord != null && scoreRecord.dailyScores.isNotEmpty) {
      trendInts = scoreRecord.dailyScores;
    } else if (!isCompletedRecap && data.weeklyRecap?.gutScoreTrend != null && data.weeklyRecap!.gutScoreTrend!.isNotEmpty) {
      trendInts = data.weeklyRecap!.gutScoreTrend!;
    } else if (data.hasGutScore) {
      trendInts = [data.gutScore];
    }

    final trendDoubles = trendInts.map((e) => e.toDouble()).toList();
    final scoredDayCount = scoreRecord?.scoredDayCount ?? trendInts.where((s) => s > 0).length;
    final displayScore = WhyScoreSheet.resolveScore(context, data);

    final hasAnyScore = WhyScoreSheet.hasScore(context, data);

    if (!hasAnyScore) {
      return InsightScoreCard(score: null, delta: null, onTap: null, onWhyTap: () => WhyScoreSheet.show(context, data));
    }

    final chartSeries = trendDoubles.isNotEmpty ? trendDoubles : (series.isNotEmpty ? series : [displayScore.toDouble()]);
    final isBaseline = scoredDayCount < 2;
    final baselineSummary = scoredDayCount == 1 ? '1 day scored' : '$scoredDayCount days scored';

    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return GutScoreCard(
      score: displayScore,
      delta: delta,
      title: isBaseline ? 'BASELINE SCORE' : 'GUTGOOD SCORE',
      subtitle: isBaseline
          ? '$baselineSummary · This is your starting point. Log more days to see a reliable trend.'
          : (data.weeklyRecap?.periodTo != null ? 'Based on your current meal and symptom logs.' : (data.weeklyRecap?.scoreSub ?? 'Based on your recent meal and symptom logs.')),
      series: chartSeries,
      scoredDayIndices: scoreRecord?.scoredDayIndices,
      labels: labels,
      onTap: () => WhyScoreSheet.show(context, data),
    );
  }
}
