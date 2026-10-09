part of 'insight_bento_feed.dart';

/// Primary bento insights feed screen.

class InsightBentoFeed extends StatelessWidget {
  const InsightBentoFeed({super.key, required this.data, required this.patterns, this.series = const [], this.seriesLabels = const []});

  final AIInsight data;
  final List<BodyPattern> patterns;

  /// Chronological gut-score window (≤7 points) feeding the hero's bar chart.
  /// Empty or single-point series fall back to the gradient score track.
  final List<double> series;
  final List<String> seriesLabels;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final score = WhyScoreSheet.resolveScore(context, data);
    final scoreRecord = WhyScoreSheet.resolveRecord(context);
    final scored = scoreRecord?.scoredScores ?? const <int>[];
    final delta = scored.length < 2 ? null : scored.last - scored[scored.length - 2];
    final foods = BentoData.topFoods(data, limit: 4);

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16.w, 8.w, 16.w, 24.w),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          if (WhyScoreSheet.hasScore(context, data))
            GutScoreCard(
              score: score,
              delta: delta,
              series: scoreRecord?.dailyScores.map((score) => score.toDouble()).toList() ?? series,
              scoredDayIndices: scoreRecord?.scoredDayIndices,
              labels: seriesLabels,
              onTap: () => WhyScoreSheet.show(context, data),
            )
          else
            InsightScoreCard(score: null, onWhyTap: () => WhyScoreSheet.show(context, data)),
          Gap.h14,
          BentoGrid(children: _tiles(context, t, foods)),
        ]),
      ),
    );
  }

  List<BentoTile> _tiles(BuildContext context, InsightBentoTheme t, List<BentoFood> foods) {
    final tiles = <BentoTile>[];
    String highlightBody(String? trend, String effects, {required String fallback}) => InsightValues.text(trend, fallback: InsightValues.text(effects, fallback: fallback));

    // 0. Smart Insight Card
    if (data.topInsight != null) {
      final top = data.topInsight!;
      tiles.add(
        BentoTile(
          spanTwo: true,
          DeepDiscoveryCard(
            insight: top,
            onTap: () => context.push(AppRoutes.smartInsightDetail, extra: top),
          ),
        ),
      );
    }

    // 1. Patterns Grid
    if (patterns.isNotEmpty) {
      final visiblePatterns = patterns.take(4).toList();
      tiles.add(
        BentoTile(
          spanTwo: true,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PatternCarouselWidget(patterns: visiblePatterns),
              Gap.h12,
            ],
          ),
        ),
      );
    }

    // Add Section Header for Weekly Highlights
    tiles.add(
      BentoTile(
        spanTwo: true,
        Padding(
          padding: EdgeInsets.fromLTRB(4.w, 12.w, 4.w, 4.w),
          child: Text(
            AppStrings.highlights,
            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 16.sp, fontWeight: FontWeight.w700, color: t.textPrimary),
          ),
        ),
      ),
    );

    // 2. Improving Card (Healing Highlights)
    final healing = data.topHealing;
    if (healing != null) {
      tiles.add(
        BentoTile(
          InsightHighlightCard(
            tag: AppStrings.bentoImproving,
            emoji: healing.emoji,
            imageUrl: healing.imageUrl,
            userImageUrl: healing.userImageUrl,
            title: healing.food,
            body: highlightBody(data.healingTrend, healing.effects, fallback: 'Keep logging meals to learn which foods support your wellbeing.'),
            bigTitle: true,
            footLeft: AppStrings.bentoSeeAll,
            accentColor: const Color(0xFF14A38F),
            backgroundColor: const Color(0xFFE9F6F3),

            onTap: () => context.push(
              AppRoutes.highlightDetail,
              extra: HighlightDetailArgs(
                tag: AppStrings.bentoImproving,
                emoji: healing.emoji,
                imageUrl: healing.imageUrl,
                userImageUrl: healing.userImageUrl,
                title: healing.food,
                body: highlightBody(data.healingTrend, healing.effects, fallback: 'Keep logging meals to learn which foods support your wellbeing.'),
                accentColor: 0xFF14A38F,
                backgroundColor: 0xFFE9F6F3,
                chartType: 'healing',
                footLeft: AppStrings.bentoSeeAll,
              ),
            ),
            actionIcon: AppIcons.chevronRight,
          ),
        ),
      );
    }

    // 3. Watch Card (Trigger Alerts)
    final trigger = data.validTopTrigger;
    if (trigger != null) {
      tiles.add(
        BentoTile(
          InsightHighlightCard(
            tag: AppStrings.bentoToWatch,
            emoji: trigger.emoji,
            imageUrl: trigger.imageUrl,
            userImageUrl: trigger.userImageUrl,
            title: trigger.food,
            body: highlightBody(data.triggerTrend, trigger.effects, fallback: 'More logs will help reveal whether this food is linked to your symptoms.'),
            bigTitle: true,
            footLeft: trigger.timeframe,
            accentColor: const Color(0xFFF08019),
            backgroundColor: const Color(0xFFFDF1E7),

            onTap: () => context.push(
              AppRoutes.highlightDetail,
              extra: HighlightDetailArgs(
                tag: AppStrings.bentoToWatch,
                emoji: trigger.emoji,
                imageUrl: trigger.imageUrl,
                userImageUrl: trigger.userImageUrl,
                title: trigger.food,
                body: highlightBody(data.triggerTrend, trigger.effects, fallback: 'More logs will help reveal whether this food is linked to your symptoms.'),
                accentColor: 0xFFF08019,
                backgroundColor: 0xFFFDF1E7,
                chartType: 'trigger',
                footLeft: trigger.timeframe,
              ),
            ),
            actionIcon: AppIcons.chevronRight,
          ),
        ),
      );
    }

    // 4. "What's working" (Secondary Healing)
    if (data.healingFoods.length > 1) {
      final second = data.healingFoods[1];
      tiles.add(
        BentoTile(
          InsightHighlightCard(
            tag: AppStrings.bentoWorking,
            emoji: second.emoji,
            imageUrl: second.imageUrl,
            userImageUrl: second.userImageUrl,
            title: second.name,
            body: second.effect,
            bigTitle: true,
            footLeft: AppStrings.bentoSeeAll,
            accentColor: const Color(0xFFEFB008),
            backgroundColor: const Color(0xFFFDF6E2),

            onTap: () => context.push(
              AppRoutes.highlightDetail,
              extra: HighlightDetailArgs(
                tag: AppStrings.bentoWorking,
                emoji: second.emoji,
                imageUrl: second.imageUrl,
                userImageUrl: second.userImageUrl,
                title: second.name,
                body: second.effect,
                accentColor: 0xFFEFB008,
                backgroundColor: 0xFFFDF6E2,
                chartType: 'working',
                footLeft: AppStrings.bentoSeeAll,
              ),
            ),
            actionIcon: AppIcons.chevronRight,
          ),
        ),
      );
    }

    // 5. Curiosity prompt (Investigation)
    final curiosity = _curiosity();
    if (curiosity != null) {
      tiles.add(
        BentoTile(
          InsightHighlightCard(
            tag: AppStrings.bentoInvestigating,
            emoji: '💡',
            title: curiosity.$1,
            body: curiosity.$2,
            bigTitle: true,
            footLeft: AppStrings.bentoLogToSolve,
            accentColor: const Color(0xFF8B5CF6),
            backgroundColor: const Color(0xFFF5EEFC),

            onTap: () => context.push(
              AppRoutes.highlightDetail,
              extra: HighlightDetailArgs(
                tag: AppStrings.bentoInvestigating,
                emoji: '💡',
                title: curiosity.$1,
                body: curiosity.$2,
                accentColor: 0xFF8B5CF6,
                backgroundColor: 0xFFF5EEFC,
                chartType: 'curiosity',
                footLeft: AppStrings.bentoLogToSolve,
              ),
            ),
            actionIcon: AppIcons.plus,
          ),
        ),
      );
    }

    // 6. Top Foods (Full Width Summary)
    if (foods.isNotEmpty) {
      final boosters = foods.where((f) => f.isPositive).length;
      tiles.add(
        BentoTile(
          spanTwo: true,
          PatternHeroCard(
            accent: const Color(0xFF10B981),
            tone: const Color(0xFFECFDF5),
            icon: AppIcons.salad,
            title: AppStrings.bentoTopFoods,
            sub: AppStrings.last7Days,
            value: '$boosters',
            valueSuffix: '/ ${foods.length}',
            pill: AppStrings.bentoGutBoosters,
            chart: SlotSegs(filled: boosters, total: foods.length, color: const Color(0xFF10B981), height: 18),
            bottomWidget: MiniFoodGrid(
              tiles: [for (final f in foods) FoodTile(name: f.name, stat: f.stat, emoji: f.emoji, imageUrl: f.imageUrl, statColor: f.isPositive ? t.positive : t.negative)],
            ),
            footLeft: 'Analyze your unique body-food synergy',
            onTap: () => context.push(AppRoutes.foodIntelligence, extra: data),
          ),
        ),
      );
    }

    return tiles;
  }

  (String, String)? _curiosity() {
    final goal = data.healingGoal;
    if (goal != null && goal.trim().isNotEmpty) {
      return (goal, data.triggerSymptom ?? '');
    }
    // Skip patterns already displayed
    for (final p in patterns) {
      final rec = p.recommendation;
      if (rec != null && rec.trim().isNotEmpty) return (p.trigger, rec);
    }
    return null;
  }
}

/// Screen 02 — the empty insight screen shown before enough evidence exists.
///
/// Matches the Chat Empty State UI/UX design language: large display headline,
/// 3-column action card grid with progress bars, and a bottom guidance component.
