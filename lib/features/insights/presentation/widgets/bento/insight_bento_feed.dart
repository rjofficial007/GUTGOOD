import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/bento_data.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/bento_widgets.dart';
import 'package:gutgood/features/insights/presentation/widgets/pattern_grid.dart';

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

    // 1. Patterns Grid
    if (patterns.isNotEmpty) {
      final visiblePatterns = patterns.take(4).toList();
      tiles.add(
        BentoTile(
          spanTwo: true,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.observedPatterns,
                      style: TextStyle(
                        fontFamily: InsightBentoTheme.fontFamily,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: t.textPrimary,
                      ),
                    ),
                    if (patterns.length > 4)
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.patterns),
                        child: Text(
                          AppStrings.bentoSeeAll,
                          style: TextStyle(
                            fontFamily: InsightBentoTheme.fontFamily,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: t.positive,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              PatternGrid(patterns: visiblePatterns),
              if (patterns.length <= 4) Gap.h12,
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
            AppStrings.weeklyHighlights,
            style: TextStyle(
              fontFamily: InsightBentoTheme.fontFamily,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: t.textPrimary,
            ),
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
            title: healing.food,
            body: healing.effects,
            badge: data.healingTrend,
            footLeft: AppStrings.bentoSeeAll,
            accentColor: const Color(0xFF14A38F),
            backgroundColor: const Color(0xFFE9F6F3),
            chartPainter: HealingSparklinePainter(color: const Color(0xFF14A38F)),
            onTap: () => context.push(AppRoutes.insightDetail, extra: data),
            actionIcon: AppIcons.chevronRight,
          ),
        ),
      );
    }

    // 3. Watch Card (Trigger Alerts)
    final trigger = data.topTrigger;
    if (trigger != null) {
      tiles.add(
        BentoTile(
          InsightHighlightCard(
            tag: AppStrings.bentoToWatch,
            emoji: trigger.emoji,
            title: trigger.food,
            body: trigger.effects,
            badge: data.triggerTrend,
            footLeft: trigger.timeframe,
            accentColor: const Color(0xFFF08019),
            backgroundColor: const Color(0xFFFDF1E7),
            chartPainter: TriggerSpikePainter(color: const Color(0xFFF08019)),
            onTap: () => context.push(AppRoutes.insightDetail, extra: data),
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
            title: second.name,
            body: second.effect,
            badge: 'Active',
            footLeft: AppStrings.bentoSeeAll,
            accentColor: const Color(0xFFEFB008),
            backgroundColor: const Color(0xFFFDF6E2),
            chartPainter: WorkingBarsPainter(color: const Color(0xFFEFB008)),
            onTap: () => context.push(AppRoutes.insightDetail, extra: data),
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
            badge: 'Explore',
            footLeft: AppStrings.bentoLogToSolve,
            accentColor: const Color(0xFF8B5CF6),
            backgroundColor: const Color(0xFFF5EEFC),
            chartPainter: CuriosityPulsePainter(color: const Color(0xFF8B5CF6)),
            onTap: () => context.push(AppRoutes.insightHistory),
            actionIcon: AppIcons.plus,
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

class InsightHighlightCard extends StatelessWidget {
  const InsightHighlightCard({
    super.key,
    required this.tag,
    required this.emoji,
    required this.title,
    required this.body,
    this.badge,
    this.footLeft,
    required this.accentColor,
    required this.backgroundColor,
    required this.chartPainter,
    required this.onTap,
    this.actionIcon = AppIcons.chevronRight,
  });

  final String tag;
  final String emoji;
  final String title;
  final String body;
  final String? badge;
  final String? footLeft;
  final Color accentColor;
  final Color backgroundColor;
  final CustomPainter chartPainter;
  final VoidCallback onTap;
  final IconData actionIcon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18.w),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5A4678).withValues(alpha: 0.07),
              blurRadius: 20.w,
              offset: Offset(0, 8.w),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(10.w),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: TextStyle(fontSize: 16.sp, height: 1),
                    ),
                  ),
                ),
                Gap.w8,
                Expanded(
                  child: Text(
                    tag,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: InsightBentoTheme.fontFamily,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF181A2C),
                    ),
                  ),
                ),
                // if (badge != null)
                //   Text(
                //     badge!,
                //     style: TextStyle(
                //       fontFamily: InsightBentoTheme.fontFamily,
                //       fontSize: 11.sp,
                //       fontWeight: FontWeight.w700,
                //       color: accentColor,
                //     ),
                //   ),
              ],
            ),
            Gap.h10,
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: InsightBentoTheme.fontFamily,
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF181A2C),
              ),
            ),
            Gap.h4,
            Text(
              badge!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: InsightBentoTheme.fontFamily,
                fontSize: 11.5.sp,
                color: const Color(0xFF5C6070),
                height: 1.4,
              ),
            ),
            Gap.h10,
            SizedBox(
              height: 38.w,
              child: CustomPaint(
                size: Size.infinite,
                painter: chartPainter,
              ),
            ),
            Gap.h10,
            Row(
              children: [
                Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                ),
                Gap.w6,
                Expanded(
                  child: Text(
                    footLeft ?? AppStrings.bentoSeeAll,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: InsightBentoTheme.fontFamily,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF33364A),
                    ),
                  ),
                ),
                Icon(actionIcon, size: 15, color: accentColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HealingSparklinePainter extends CustomPainter {
  HealingSparklinePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final path = Path()
      ..moveTo(0, h * 0.8)
      ..cubicTo(w * 0.25, h * 0.75, w * 0.4, h * 0.4, w * 0.65, h * 0.3)
      ..cubicTo(w * 0.8, h * 0.25, w * 0.9, h * 0.1, w, h * 0.05);

    final fillPath = Path.from(path)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    canvas.drawCircle(Offset(w, h * 0.05), 3.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(CustomPainter old) => false;
}

class TriggerSpikePainter extends CustomPainter {
  TriggerSpikePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final path = Path()
      ..moveTo(0, h * 0.8)
      ..lineTo(w * 0.2, h * 0.8)
      ..lineTo(w * 0.3, h * 0.2)
      ..lineTo(w * 0.4, h * 0.8)
      ..lineTo(w * 0.6, h * 0.8)
      ..lineTo(w * 0.75, h * 0.1)
      ..lineTo(w * 0.85, h * 0.8)
      ..lineTo(w, h * 0.8);

    final fillPath = Path.from(path)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    canvas.drawCircle(Offset(w * 0.3, h * 0.2), 3.0, Paint()..color = color);
    canvas.drawCircle(Offset(w * 0.75, h * 0.1), 3.0, Paint()..color = color);
  }

  @override
  bool shouldRepaint(CustomPainter old) => false;
}

class WorkingBarsPainter extends CustomPainter {
  WorkingBarsPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final w = size.width;
    final h = size.height;
    final barCount = 5;
    final gap = 6.w;
    final barW = (w - (gap * (barCount - 1))) / barCount;
    final heights = [0.35, 0.5, 0.48, 0.72, 0.9];

    for (var i = 0; i < barCount; i++) {
      final rectH = h * heights[i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * (barW + gap), h - rectH, barW, rectH),
          const Radius.circular(4),
        ),
        paint..color = color.withValues(alpha: 0.4 + (i * 0.12)),
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter old) => false;
}

class CuriosityPulsePainter extends CustomPainter {
  CuriosityPulsePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final dashPaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (var x = 0.0; x <= w; x += 4) {
      final y = h * 0.5 + math.sin(x * 0.08) * (h * 0.3);
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, dashPaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.5 + math.sin(w * 0.5 * 0.08) * (h * 0.3)), 4.0, Paint()..color = color);
  }

  @override
  bool shouldRepaint(CustomPainter old) => false;
}
