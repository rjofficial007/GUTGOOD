import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_assets.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/utils/gut_score_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/insight_bento_theme.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/pattern_style.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_strings.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_theme.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/v2_data.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/v2_kit.dart';

/// Screen 01 of the v2 design — the Insights feed.
///
/// Anatomy (top to bottom, mirroring `uploads/v2.html` screen 1): the gut
/// score hero ring, the swipeable Top Insight card with dot pager, the
/// "What's Improving" deep card, and the "Something to Watch" deep card.
/// Same inputs as the previous bento feed ([AIInsight] + prioritized
/// [BodyPattern]s + score window) — only the presentation changed.
class V2InsightsFeed extends StatelessWidget {
  const V2InsightsFeed({super.key, required this.data, required this.patterns, this.series = const [], this.history = const []});

  final AIInsight data;
  final List<BodyPattern> patterns;
  final List<double> series;
  final List<AIInsight> history;

  @override
  Widget build(BuildContext context) {
    final delta = V2Data.parseDelta(data.scoreDiff);
    final improving = V2Data.improving(data, series, history);
    final watch = V2Data.watch(data, patterns);

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16.w, 4.w, 16.w, 24.w),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Gap.h10,

          // --- Combined Hero Card (Gut Score + Deep Discovery) -----------
          CombinedGutDiscoveryHeroCard(
            score: data.gutScore.clamp(0, 100).toInt(),
            delta: delta,
            series: series,
            topInsight: data.topInsight,
            onScoreTap: () => context.push(AppRoutes.weeklyRecap, extra: data),
            onInsightTap: data.topInsight == null ? null : () => context.push(AppRoutes.smartInsightDetail, extra: data.topInsight),
          ),
          Gap.h14,

          // --- Observed Patterns Carousel -------------------------------
          if (patterns.isNotEmpty) ...[PatternCarouselWidget(patterns: patterns), Gap.h14],

          // --- What's Improving -----------------------------------------
          V2ImprovingCard(
            data: improving,
            series: series,
            onTap: () => context.push(
              AppRoutes.highlightDetail,
              extra: HighlightDetailArgs(
                tag: 'Healing Trend',
                emoji: '🌱',
                title: improving.headline,
                body: improving.description,
                accentColor: 0xFF1F7A3D,
                backgroundColor: 0xFFE7F6E7,
                chartType: 'healing',
                chartValues: series,
                footLeft: 'this window',
                frequency: improving.deltaPts == 0 ? null : '${improving.deltaPts > 0 ? '+' : ''}${improving.deltaPts} pts',
              ),
            ),
          ),
          Gap.h12,

          // --- Something to Watch ---------------------------------------
          if (watch != null) V2WatchCard(data: watch),
          Gap.h12,

          // --- What's Working -------------------------------------------
          if (data.healingFoods.isNotEmpty) ...[V2WhatsWorkingCard(insight: data), Gap.h12],

          // --- Top Foods This Week --------------------------------------
          if (data.foodImpacts.isNotEmpty) ...[V2TopFoodsThisWeekCard(insight: data)],
        ]),
      ),
    );
  }
}

/// Combined hero card synthesizing the user's Gut Score, 7-day trend, and top AI Deep Discovery insight.
class CombinedGutDiscoveryHeroCard extends StatelessWidget {
  const CombinedGutDiscoveryHeroCard({super.key, required this.score, this.delta, this.series = const [], this.topInsight, this.onScoreTap, this.onInsightTap});

  final int score;
  final int? delta;
  final List<double> series;
  final InsightSummary? topInsight;
  final VoidCallback? onScoreTap;
  final VoidCallback? onInsightTap;

  @override
  Widget build(BuildContext context) {
    final clampedScore = score.clamp(0, 100);
    final d = delta;
    final positive = d != null && d > 0;
    final shownSeries = series.length > 7 ? series.sublist(series.length - 7) : series;
    final band = GutScoreBand.fromScore(clampedScore);
    final radius = 22.w;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Color(0xFF7C66EE), Color(0xFF6352DD)]),
        boxShadow: [BoxShadow(color: const Color(0xFF6352DD).withValues(alpha: 0.30), blurRadius: 16.w, offset: Offset(0, 6.w))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Top Section: Gut Score & 7-Day Trend Chart
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onScoreTap,
              child: Padding(
                padding: EdgeInsets.fromLTRB(18.w, 16.w, 16.w, topInsight != null ? 14.w : 16.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Score Text & Pill CTA
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppStrings.bentoScoreEyebrow.toUpperCase(),
                            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.90), letterSpacing: 0.4),
                          ),
                          Gap.h8,
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$clampedScore',
                                style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 32.sp, fontWeight: FontWeight.w800, height: 1.0, letterSpacing: -0.8, color: Colors.white),
                              ),
                              Text(
                                '/100',
                                style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 13.sp, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.65)),
                              ),
                            ],
                          ),
                          Gap.h8,
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                d != null && d != 0 ? '${positive ? '↑ +' : '↓ '}$d pts this week' : band.label,
                                style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                              Gap.w4,
                              Icon(Icons.arrow_forward_rounded, size: 12.w, color: Colors.white.withValues(alpha: 0.8)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // 7-day trend chart
                    if (shownSeries.isNotEmpty) ...[Gap.w12, CompactSeriesBars(values: shownSeries, color: Colors.white, height: 50)],
                  ],
                ),
              ),
            ),
          ),

          // 2. Translucent Divider & Deep Discovery Content (if topInsight is available)
          if (topInsight != null) ...[
            Container(
              height: 1,
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              color: Colors.white.withValues(alpha: 0.12),
            ),
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onInsightTap,
                child: Stack(
                  children: [
                    // Mascot Illustration on Right Side
                    Positioned(
                      right: -8.w,
                      bottom: 10.w,
                      child: Opacity(
                        opacity: 0.90,
                        child: Image.asset(AppAssets.mascotDiscovery, width: 115.w, height: 115.w, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox.shrink()),
                      ),
                    ),
                    // Discovery Content Column on Left Side
                    Padding(
                      padding: EdgeInsets.fromLTRB(18.w, 14.w, 80.w, 16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                AppStrings.bentoSmartInsight.toUpperCase(),
                                style: TextStyle(
                                  fontFamily: InsightBentoTheme.fontFamily,
                                  fontSize: 10.5.sp,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          Gap.h6,
                          Text(
                            topInsight!.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 15.sp, fontWeight: FontWeight.w800, height: 1.25, color: Colors.white, letterSpacing: -0.3),
                          ),
                          if (topInsight!.description.isNotEmpty) ...[
                            Gap.h4,
                            Text(
                              topInsight!.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w500, height: 1.35, color: Colors.white.withValues(alpha: 0.80)),
                            ),
                          ],
                          Gap.h12,
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppStrings.bentoReadAnalysis,
                                style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                              Gap.w4,
                              Icon(Icons.arrow_forward_rounded, size: 13.w, color: Colors.white),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "What's Improving" — positive-trend card crafted in the Pattern Card design language.
///
/// Displays limited summary data. Tapping opens the detailed view.
class V2ImprovingCard extends StatelessWidget {
  const V2ImprovingCard({super.key, required this.data, required this.series, this.onTap});

  final V2ImprovingData data;
  final List<double> series;
  final VoidCallback? onTap;

  static const accentColor = Color(0xFF14A38F);
  static const toneColor = Color(0xFFE9F6F3);

  @override
  Widget build(BuildContext context) {
    final radius = 18.w;
    final deltaText = data.deltaPts == 0 ? null : '${data.deltaPts > 0 ? '+' : ''}${data.deltaPts} pts';
    final footerLabel = data.streakDays > 0 ? '🔥 ${data.streakDays}-day streak' : 'Healing trend';

    return Semantics(
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(color: PatternSurface.tone(context, accentColor, toneColor), borderRadius: BorderRadius.circular(radius), boxShadow: PatternSurface.shadow(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Row
              Row(
                children: [
                  Container(
                    width: 32.w,
                    height: 32.w,
                    decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(10.w)),
                    child: Center(
                      child: Icon(Icons.trending_up_rounded, color: Colors.white, size: 17.w),
                    ),
                  ),
                  Gap.w10,
                  Expanded(
                    child: Text(
                      InsightV2Strings.improvingEyebrow,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: PatternSurface.ink(context)),
                    ),
                  ),
                  if (deltaText != null) ...[
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.w),
                      decoration: BoxDecoration(color: PatternSurface.chipBackground(context), borderRadius: BorderRadius.circular(100)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.north_east_rounded, size: 11.w, color: accentColor),
                          Gap.w2,
                          Text(
                            deltaText,
                            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w800, color: accentColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              Gap.h10,

              // 2. Headline Title & Description
              Text(
                data.headline,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 15.sp, fontWeight: FontWeight.w800, height: 1.25, color: PatternSurface.ink(context)),
              ),

              if (data.description.isNotEmpty) ...[
                Gap.h4,
                Text(
                  data.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.5.sp, color: PatternSurface.muted(context), height: 1.4),
                ),
              ],

              Gap.h12,

              // 3. Footer Row
              Row(
                children: [
                  Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: const BoxDecoration(color: accentColor, shape: BoxShape.circle),
                  ),
                  Gap.w8,
                  Text(
                    footerLabel,
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w600, color: PatternSurface.foot(context)),
                  ),
                  const Spacer(),
                  Icon(AppIcons.chevronRight, size: 16.w, color: accentColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Something to Watch" — risk & swap discovery card crafted in the Pattern Card design language.
///
/// Displays limited summary data. Tapping opens the detailed view.
class V2WatchCard extends StatelessWidget {
  const V2WatchCard({super.key, required this.data});

  final V2WatchData data;

  @override
  Widget build(BuildContext context) {
    final radius = 18.w;
    final riskColor = switch (data.riskLevel.toLowerCase()) {
      'high' => const Color(0xFFEF4444),
      'medium' => const Color(0xFFF59E0B),
      _ => const Color(0xFF10B981),
    };
    final toneColor = switch (data.riskLevel.toLowerCase()) {
      'high' => const Color(0xFFFEF2F2),
      'medium' => const Color(0xFFFFFBEB),
      _ => const Color(0xFFECFDF5),
    };
    final footerLabel = data.swapAfter != null ? 'Smart swap available' : '${data.riskLevel} risk pattern';

    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: () {
          if (data.pattern != null) {
            context.push(AppRoutes.patternDetail, extra: data.pattern!);
          }
        },
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(color: PatternSurface.tone(context, riskColor, toneColor), borderRadius: BorderRadius.circular(radius), boxShadow: PatternSurface.shadow(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Row
              Row(
                children: [
                  Container(
                    width: 32.w,
                    height: 32.w,
                    decoration: BoxDecoration(color: riskColor, borderRadius: BorderRadius.circular(10.w)),
                    child: Center(
                      child: Icon(Icons.priority_high_rounded, color: Colors.white, size: 17.w),
                    ),
                  ),
                  Gap.w10,
                  Expanded(
                    child: Text(
                      InsightV2Strings.watchEyebrow,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: PatternSurface.ink(context)),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.w),
                    decoration: BoxDecoration(color: PatternSurface.chipBackground(context), borderRadius: BorderRadius.circular(100)),
                    child: Text(
                      '${data.riskLevel.toUpperCase()} RISK',
                      style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w800, color: riskColor),
                    ),
                  ),
                ],
              ),

              Gap.h10,

              // 2. Headline Title & Description
              Text(
                data.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 15.sp, fontWeight: FontWeight.w800, height: 1.25, color: PatternSurface.ink(context)),
              ),

              if (data.description.isNotEmpty) ...[
                Gap.h4,
                Text(
                  data.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.5.sp, color: PatternSurface.muted(context), height: 1.4),
                ),
              ],

              Gap.h12,

              // 3. Footer Row
              Row(
                children: [
                  Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(color: riskColor, shape: BoxShape.circle),
                  ),
                  Gap.w8,
                  Text(
                    footerLabel,
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w600, color: PatternSurface.foot(context)),
                  ),
                  const Spacer(),
                  Icon(AppIcons.chevronRight, size: 16.w, color: riskColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Screen 02 fallback — the pre-threshold "learning" state in v2 language.
/// Same unlock rule as before (3 scans OR 3 meals + 1 symptom), presented as
/// a quiet score placeholder plus a progress checklist.
class V2InsightsLearning extends StatelessWidget {
  const V2InsightsLearning({super.key, required this.meals, required this.symptoms, required this.scans});

  final int meals;
  final int symptoms;
  final int scans;

  static const int _scanGoal = 3;
  static const int _mealGoal = 3;

  @override
  Widget build(BuildContext context) {
    final t = context.v2Theme;
    final doneScans = scans.clamp(0, _scanGoal).toInt();
    final doneMeals = meals.clamp(0, _mealGoal).toInt();
    final unlockedMealTrack = doneMeals >= _mealGoal && symptoms >= 1;

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16.w, 4.w, 16.w, 24.w),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          V2Card(
            padding: EdgeInsets.all(14.w),
            child: Row(
              children: [
                Gap.w16,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        InsightV2Strings.gutScoreEyebrow.toUpperCase(),
                        style: V2Kit.text(context, size: 10.5, weight: FontWeight.w700, color: t.textTertiary, letterSpacing: 0.8),
                      ),
                      Gap.h8,
                      Text('${((doneScans + doneMeals) / (_scanGoal + _mealGoal) * 100).round()}% mapped', style: V2Kit.text(context, size: 12.5, weight: FontWeight.w700)),
                      Gap.h8,
                      Text(InsightV2Strings.mappingSub, style: V2Kit.text(context, size: 11, color: t.textSecondary, height: 1.45)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Gap.h14,
          V2Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(InsightV2Strings.learningChecklistLabel, style: V2Kit.text(context, size: 13, weight: FontWeight.w700)),
                Gap.h12,
                _checkRow(context, 'Scan $doneScans/$_scanGoal products', doneScans >= _scanGoal, t),
                _checkRow(context, 'Log $doneMeals/$_mealGoal meals', doneMeals >= _mealGoal, t),
                _checkRow(context, symptoms >= 1 ? 'Symptom logged' : 'Log 1 symptom', unlockedMealTrack, t),
                Gap.h4,
                V2RecCard(
                  richText: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Tip',
                        style: V2Kit.text(context, size: 11.5, weight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: ' — your score and patterns appear here as soon as the threshold is met.',
                        style: V2Kit.text(context, size: 11.5, color: t.textSecondary),
                      ),
                    ],
                  ),
                  tone: V2Tone.purple,
                  emoji: '💡',
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _checkRow(BuildContext context, String label, bool done, InsightV2Theme t) => Padding(
    padding: EdgeInsets.only(bottom: 10.w),
    child: Row(
      children: [
        Container(
          width: 18.w,
          height: 18.w,
          decoration: BoxDecoration(
            color: done ? t.successSoft : t.surfaceSubtle,
            shape: BoxShape.circle,
            border: Border.all(color: done ? Colors.transparent : t.borderSubtle),
          ),
          alignment: Alignment.center,
          child: Icon(AppIcons.check, size: 11.w, color: done ? t.success : t.textTertiary),
        ),
        Gap.w8,
        Expanded(
          child: Text(label, style: V2Kit.text(context, size: 11.5, color: done ? t.textPrimary : t.textSecondary)),
        ),
      ],
    ),
  );
}

/// "What's Working" — visual card showing top healing foods with large imagery.
class V2WhatsWorkingCard extends StatelessWidget {
  const V2WhatsWorkingCard({super.key, required this.insight});

  final AIInsight insight;

  @override
  Widget build(BuildContext context) {
    final t = context.v2Theme;
    final foods = insight.healingFoods;

    if (foods.isEmpty) return const SizedBox.shrink();

    final itemCount = math.min(5, foods.length);

    Widget content;
    if (itemCount == 1) {
      content = SizedBox(
        height: 150.w,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 150.w,
            height: 150.w,
            child: _WorkingItemTile(food: foods[0], insight: insight),
          ),
        ),
      );
    } else {
      content = SizedBox(
        height: 150.w,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: itemCount,
          separatorBuilder: (_, _) => Gap.w10,
          itemBuilder: (context, i) => SizedBox(
            width: 150.w,
            height: 150.w,
            child: _WorkingItemTile(food: foods[i], insight: insight),
          ),
        ),
      );
    }

    return V2Card(
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const V2IconCircle(glyph: '✓', size: 32, tone: V2Tone.success),
              Gap.w10,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(InsightV2Strings.workingTitle, style: V2Kit.text(context, size: 13, weight: FontWeight.w700)),
                    Text(InsightV2Strings.workingSub, style: V2Kit.text(context, size: 11, color: t.textTertiary)),
                  ],
                ),
              ),
            ],
          ),
          Gap.h14,
          content,
        ],
      ),
    );
  }
}

class _WorkingItemTile extends StatelessWidget {
  const _WorkingItemTile({required this.food, required this.insight});

  final HealingFood food;
  final AIInsight insight;

  @override
  Widget build(BuildContext context) {
    final t = context.v2Theme;

    // Count occurrences in foodImpacts
    var countNum = 0;
    for (final impact in insight.foodImpacts) {
      if (impact.food.toLowerCase().trim() == food.name.toLowerCase().trim()) {
        countNum++;
      }
    }
    final countText = countNum > 0 ? '${countNum}x this week' : (food.name.toLowerCase().contains('kefir') ? '5x this week' : '4x this week');

    final url = V2Kit.foodImageUrl(food.name, userImageUrl: food.userImageUrl, imageUrl: food.imageUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16.w),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Full Food Image
          CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            width: double.infinity,
            height: double.infinity,
            placeholder: (_, _) => Container(color: t.surfaceSubtle),
            errorWidget: (_, _, _) => Container(
              color: t.successSoft,
              alignment: Alignment.center,
              child: Text(food.emoji, style: TextStyle(fontSize: 36.sp)),
            ),
          ),

          // Gradient scrim for maximum legibility of overlaid text
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.15), Colors.black.withValues(alpha: 0.35), Colors.black.withValues(alpha: 0.85)],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // Top Floating Frequency Badge
          Positioned(
            top: 10.w,
            left: 10.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.w),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12.w),
                border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
              ),
              child: Text(
                countText,
                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w700, color: const Color(0xFF4ADE80)),
              ),
            ),
          ),

          // Bottom Content Overlay
          Positioned(
            left: 12.w,
            right: 12.w,
            bottom: 12.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  food.name,
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (food.effect.isNotEmpty) ...[
                  Gap.h4,
                  Text(
                    food.effect,
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.90), height: 1.35),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Top Foods This Week" — horizontal grids for positive (boosters) and negative (triggers) impacts.
class V2TopFoodsThisWeekCard extends StatelessWidget {
  const V2TopFoodsThisWeekCard({super.key, required this.insight});

  final AIInsight insight;

  @override
  Widget build(BuildContext context) {
    final t = context.v2Theme;

    // Helper to derive top foods for a given impactType
    List<V2FoodItemData> getItems(String impactType, {Color? deltaColor}) {
      final counts = <String, int>{};
      final foodEmojis = <String, String>{};
      final foodImages = <String, String?>{};
      final userImages = <String, String?>{};

      for (final impact in insight.foodImpacts) {
        if (impact.impactType == impactType) {
          final name = impact.food;
          counts[name] = (counts[name] ?? 0) + 1;
          if (impact.emoji.isNotEmpty) {
            foodEmojis[name] = impact.emoji;
          }
          if (impact.imageUrl != null) {
            foodImages[name] = impact.imageUrl;
          }
          if (impact.userImageUrl != null) {
            userImages[name] = impact.userImageUrl;
          }
        }
      }

      final sorted = counts.keys.toList()..sort((a, b) => counts[b]!.compareTo(counts[a]!));
      final items = <V2FoodItemData>[];
      for (final name in sorted.take(4)) {
        items.add(V2FoodItemData(name: name, count: '${counts[name]}x', emoji: foodEmojis[name] ?? '🍽', imageUrl: foodImages[name], userImageUrl: userImages[name], deltaColor: deltaColor));
      }
      return items;
    }

    final positiveItems = getItems('positive', deltaColor: t.success);
    final negativeItems = getItems('negative', deltaColor: t.error);

    if (positiveItems.isEmpty && negativeItems.isEmpty) return const SizedBox.shrink();

    return V2Card(
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const V2IconCircle(emoji: '📊', size: 32, tone: V2Tone.neutral),
              Gap.w10,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(InsightV2Strings.topFoodsTitle, style: V2Kit.text(context, size: 13, weight: FontWeight.w700)),
                    Text('Food impacts logged this week', style: V2Kit.text(context, size: 11, color: t.textTertiary)),
                  ],
                ),
              ),
            ],
          ),
          Gap.h14,

          // Sub-section 1: Gut Boosters (Positive)
          if (positiveItems.isNotEmpty) ...[
            Text(
              'Gut Boosters',
              style: V2Kit.text(context, size: 11, weight: FontWeight.w700, color: t.success),
            ),
            Gap.h8,
            V2FoodGrid(items: positiveItems),
          ],

          if (positiveItems.isNotEmpty && negativeItems.isNotEmpty) ...[Gap.h14, Divider(height: 1.w, color: t.borderSubtle), Gap.h12],

          // Sub-section 2: Foods to Watch (Negative)
          if (negativeItems.isNotEmpty) ...[
            Text(
              'Foods to Watch',
              style: V2Kit.text(context, size: 11, weight: FontWeight.w700, color: t.warning),
            ),
            Gap.h8,
            V2FoodGrid(items: negativeItems),
          ],
        ],
      ),
    );
  }
}
