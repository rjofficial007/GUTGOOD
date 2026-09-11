import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/bento_data.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/bento_widgets.dart';

/// Screen 01 — the bento Insights feed.
///
/// Replaces `InsightDiscoverSliver` as the Insights tab body. Same data in
/// (`AIInsight` + prioritized `BodyPattern`s), v4 bento presentation out.
class InsightBentoFeed extends StatelessWidget {
  const InsightBentoFeed({super.key, required this.data, required this.patterns});

  final AIInsight data;
  final List<BodyPattern> patterns;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final score = data.gutScore.clamp(0, 100);
    final delta = BentoData.parseDelta(data.scoreDiff);
    final foods = BentoData.topFoods(data, limit: 4);

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16.w, 8.w, 16.w, 24.w),
      sliver: SliverList(
        delegate: SliverChildListDelegate([_ScoreHero(score: score, delta: delta), Gap.h14, BentoGrid(children: _tiles(context, t, foods))]),
      ),
    );
  }

  List<BentoTile> _tiles(BuildContext context, InsightBentoTheme t, List<BentoFood> foods) {
    final tiles = <BentoTile>[];

    // 1. Patterns List (Full Width Cards - List Style)
    for (final p in patterns) {
      final tone = _toneForPattern(p.type);
      tiles.add(
        BentoTile(
          spanTwo: true,
          BentoCard(
            tone: tone,
            spanTwo: true,
            tag: AppStrings.bentoPatternNoticed,
            tagIcon: '🔍',
            badge: BentoData.matchLabel(p.evidenceRatio),
            title: BentoData.patternHeadline(p),
            body: p.description,
            media: BentoArtPlate(emoji: p.involvedFoods.isEmpty ? _emojiForPattern(p.type) : _emojiFor(p.involvedFoods.first), tone: tone),
            footLeft: _swapFoot(p),
            footRight: '→',
            onTap: () => context.push(AppRoutes.patternDetail, extra: p),
          ),
        ),
      );
    }

    // 2. Improving Card (Healing Highlights)
    final healing = data.topHealing;
    if (healing != null) {
      tiles.add(
        BentoTile(
          BentoCard(
            tone: BentoTone.mint,
            tag: AppStrings.bentoImproving,
            tagIcon: '📈',
            badge: data.healingTrend,
            media: BentoArtPlate(emoji: healing.emoji, tone: BentoTone.mint, width: 48, height: 42),
            title: healing.food,
            body: healing.effects,
            footLeft: AppStrings.bentoSeeAll,
            footRight: '→',
            onTap: () => context.push(AppRoutes.insightDetail, extra: data),
          ),
        ),
      );
    }

    // 3. Watch Card (Trigger Alerts)
    final trigger = data.topTrigger;
    if (trigger != null) {
      tiles.add(
        BentoTile(
          BentoCard(
            tone: BentoTone.coral,
            tag: AppStrings.bentoToWatch,
            tagIcon: '⚠️',
            badge: data.triggerTrend,
            media: BentoArtPlate(emoji: trigger.emoji, tone: BentoTone.coral, width: 46, height: 42),
            title: trigger.food,
            body: trigger.effects,
            footLeft: trigger.timeframe,
            footRight: '→',
            onTap: () => context.push(AppRoutes.insightDetail, extra: data),
          ),
        ),
      );
    }

    // 4. "What's working" (Secondary Healing)
    if (data.healingFoods.length > 1) {
      final second = data.healingFoods[1];
      tiles.add(
        BentoTile(
          BentoCard(
            tone: BentoTone.amber,
            tag: AppStrings.bentoWorking,
            tagIcon: '✨',
            media: BentoArtPlate(emoji: second.emoji, tone: BentoTone.amber, width: 48, height: 42),
            title: second.name,
            body: second.effect,
            footLeft: AppStrings.bentoSeeAll,
            footRight: '→',
            onTap: () => context.push(AppRoutes.insightDetail, extra: data),
          ),
        ),
      );
    }

    // 5. Curiosity prompt (Investigation)
    final curiosity = _curiosity();
    if (curiosity != null) {
      tiles.add(
        BentoTile(
          BentoCard(
            tone: BentoTone.purple,
            tag: AppStrings.bentoInvestigating,
            tagIcon: '💡',
            emphasis: const Text('🫧', style: TextStyle(fontSize: 24, height: 1)),
            title: curiosity.$1,
            body: curiosity.$2,
            footLeft: AppStrings.bentoLogToSolve,
            footRight: '+',
            onTap: () => context.push(AppRoutes.insightHistory),
          ),
        ),
      );
    }

    // 6. Top Foods (Full Width Summary)
    if (foods.isNotEmpty) {
      tiles.add(
        BentoTile(
          spanTwo: true,
          BentoCard(
            tone: BentoTone.white,
            spanTwo: true,
            tag: AppStrings.bentoTopFoods,
            tagIcon: '🥗',
            badge: AppStrings.bentoSeeCount(BentoData.loggedFoodCount(data)),
            title: '',
            extra: MiniFoodGrid(
              tiles: [for (final f in foods) FoodTile(name: f.name, stat: f.stat, emoji: f.emoji, imageUrl: f.imageUrl, statColor: f.isPositive ? t.positive : t.negative)],
            ),
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

  BentoTone _toneForPattern(String type) => switch (type) {
    BodyPattern.typeBloating => BentoTone.mint,
    BodyPattern.typeEnergy => BentoTone.amber,
    BodyPattern.typeHeadache => BentoTone.coral,
    BodyPattern.typeDigestion => BentoTone.peach,
    BodyPattern.typeSleep => BentoTone.purple,
    _ => BentoTone.peach,
  };

  String _emojiForPattern(String type) => switch (type) {
    BodyPattern.typeBloating => '💨',
    BodyPattern.typeEnergy => '⚡',
    BodyPattern.typeHeadache => '🧠',
    BodyPattern.typeDigestion => '🤢',
    BodyPattern.typeFullness => '🍽️',
    BodyPattern.typeSleep => '🌙',
    _ => '🔍',
  };

  String _swapFoot(BodyPattern p) {
    final n = p.involvedFoods.length;
    return n > 0 ? 'View timeline & $n safe swaps' : 'View timeline';
  }
}

class _ScoreHero extends StatelessWidget {
  const _ScoreHero({required this.score, required this.delta});
  final int score;
  final int? delta;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final d = delta;
    final positive = d != null && d > 0;
    return ScoreHeroCard(
      eyebrow: AppStrings.bentoScoreEyebrow,
      value: '$score',
      statusBadge: BentoData.statusForScore(score, delta: d),
      dotColor: t.mint,
      delta: d == null ? null : BentoData.deltaLabel('${d > 0 ? '+' : '-'}${d.abs()}'),
      deltaSub: AppStrings.bentoVsLastWeek,
      deltaForeground: positive ? t.positive : t.negative,
      deltaBackground: positive ? t.deltaPillBackground : t.negative.withValues(alpha: 0.12),
      trackProgress: score / 100,
      footLeft: '${AppStrings.bentoPositiveDays}: $score%',
      footRight: '${AppStrings.bentoPeak}: $score',
    );
  }
}

String _emojiFor(String food) {
  const fallback = {
    'bread': '🍞',
    'rice': '🍚',
    'coffee': '☕',
    'milk': '🥛',
    'egg': '🥚',
    'meat': '🍖',
    'fish': '🐟',
    'salad': '🥗',
    'soup': '🍲',
    'pizza': '🍕',
    'burger': '🍔',
    'pasta': '🍝',
    'fruit': '🍎',
    'chicken': '🍗',
  };
  final key = food.toLowerCase();
  for (final e in fallback.entries) {
    if (key.contains(e.key)) return e.value;
  }
  return '🍽️';
}

/// Screen 02 — the "learning grid" shown before enough evidence exists.
///
/// Replaces `_NoInsightsState`. Keeps the same unlock rule the app already
/// enforces (`InsightsNotifier.isSufficient`) but presents progress as a
/// partially-mapped score hero plus hypothesis bentos.
class InsightBentoLearning extends StatelessWidget {
  const InsightBentoLearning({super.key, required this.meals, required this.symptoms, required this.scans});

  final int meals;
  final int symptoms;
  final int scans;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    const scanGoal = 3;
    const mealGoal = 3;
    final mapped = (scans.clamp(0, scanGoal) + meals.clamp(0, mealGoal)) / (scanGoal + mealGoal);
    final pct = (mapped * 100).round().clamp(0, 99);
    final remaining = (scanGoal - scans).clamp(0, scanGoal);
    final peach = t.bento(BentoTone.peach);
    final coral = t.bento(BentoTone.coral);

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16.w, 8.w, 16.w, 24.w),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          ScoreHeroCard(
            eyebrow: AppStrings.bentoMappingEyebrow,
            value: '--',
            valueColor: t.orange,
            dotColor: t.orange,
            statusBadge: AppStrings.bentoPctMapped(pct),
            statusBackground: peach.tagBackground,
            statusForeground: peach.tagForeground,
            statusBorder: peach.border,
            delta: AppStrings.bentoScanLeft(remaining == 0 ? 1 : remaining),
            deltaSub: AppStrings.bentoScanToUnlock,
            deltaBackground: peach.tagBackground,
            deltaForeground: peach.tagForeground,
            trackProgress: pct / 100,
            trackGradient: [t.scoreTrackStart, t.scoreTrackMid],
            gradientBackground: LinearGradient(begin: BentoPalette.begin, end: BentoPalette.end, colors: [t.cardBackground, peach.gradientStart]),
            borderOverride: peach.border,
            footLeft: '${AppStrings.logs} $meals/$mealGoal · ${AppStrings.aiScanHistory} $scans/$scanGoal',
            footRight: AppStrings.bentoScoreEyebrow,
            footRightColor: t.orange,
          ),
          Gap.h14,
          BentoGrid(
            children: [
              const BentoTile(
                spanTwo: true,
                BentoCard(
                  tone: BentoTone.peach,
                  spanTwo: true,
                  tag: AppStrings.bentoUnlockPatterns,
                  tagIcon: '🔒',
                  title: AppStrings.bentoScanDinnerToUnlock,
                  body: AppStrings.understandBodyImpact,
                  // extra: BentoCta(
                  //   label: AppStrings.startScanningProducts,
                  //   onTap: () => context.go(
                  //     AppRoutes.scannerPath(ScannerMode.food.name),
                  //   ),
                  // ),
                ),
              ),
              if (meals > 0)
                BentoTile(
                  BentoCard(
                    tone: BentoTone.mint,
                    tag: '${AppStrings.bentoHypothesis} 1',
                    emphasis: BentoEmphasis(text: '${((meals / mealGoal) * 100).round().clamp(0, 100)}%', color: t.positive),
                    title: AppStrings.bentoPositiveDays,
                    body: AppStrings.keepLoggingForHighlights,
                  ),
                ),
              BentoTile(
                BentoCard(
                  tone: BentoTone.coral,
                  tag: '${AppStrings.bentoHypothesis} 2',
                  emphasis: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.w),
                    decoration: BoxDecoration(color: coral.tagBackground, borderRadius: BorderRadius.circular(6.w)),
                    child: Text(
                      AppStrings.bentoLocked.toUpperCase(),
                      style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w700, color: coral.tagForeground),
                    ),
                  ),
                  title: AppStrings.symptoms,
                  body: '$symptoms/1 ${AppStrings.bentoLogged}',
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}
