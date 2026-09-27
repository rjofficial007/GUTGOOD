import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_assets.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_score_card.dart';
import 'package:gutgood/features/insights/presentation/widgets/arc_pattern_card.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/bento_data.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/bento_widgets.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/pattern_style.dart';
import 'package:gutgood/features/insights/presentation/widgets/why_score_sheet.dart';

/// Screen 01 — the bento Insights feed.
///
/// Replaces `InsightDiscoverSliver` as the Insights tab body. Same data in
/// (`AIInsight` + prioritized `BodyPattern`s), v4 bento presentation out.
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
    final score = data.gutScore.clamp(0, 100);
    final delta = BentoData.parseDelta(data.scoreDiff);
    final foods = BentoData.topFoods(data, limit: 4);

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16.w, 8.w, 16.w, 24.w),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          GutScoreCard(score: score, delta: delta, series: series, labels: seriesLabels, onTap: () => WhyScoreSheet.show(context, data)),
          Gap.h14,
          BentoGrid(children: _tiles(context, t, foods)),
        ]),
      ),
    );
  }

  List<BentoTile> _tiles(BuildContext context, InsightBentoTheme t, List<BentoFood> foods) {
    final tiles = <BentoTile>[];

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
            body: (data.healingTrend ?? '').isNotEmpty ? data.healingTrend! : healing.effects,
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
                body: (data.healingTrend ?? '').isNotEmpty ? data.healingTrend! : healing.effects,
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
    final trigger = data.topTrigger;
    if (trigger != null) {
      tiles.add(
        BentoTile(
          InsightHighlightCard(
            tag: AppStrings.bentoToWatch,
            emoji: trigger.emoji,
            imageUrl: trigger.imageUrl,
            userImageUrl: trigger.userImageUrl,
            title: trigger.food,
            body: (data.triggerTrend ?? '').isNotEmpty ? data.triggerTrend! : trigger.effects,
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
                body: (data.triggerTrend ?? '').isNotEmpty ? data.triggerTrend! : trigger.effects,
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
/// Uses a centered, clean AIUsageCard UI/UX pattern showing only essential progress
/// and a primary call to action.
class InsightBentoLearning extends StatelessWidget {
  const InsightBentoLearning({super.key, required this.meals, required this.symptoms, required this.scans});

  final int meals;
  final int symptoms;
  final int scans;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final textColor = scheme.textPrimary;
    final borderColor = scheme.borderSubtle;

    const maxFoodScans = 3;
    const maxSymptoms = 1;

    // Total food logs = scans + meals
    final totalFood = scans + meals;
    final currentFoodScans = totalFood.clamp(0, maxFoodScans);
    final currentSymptoms = symptoms.clamp(0, maxSymptoms);

    final foodDone = currentFoodScans >= maxFoodScans;
    final symptomsDone = currentSymptoms >= maxSymptoms;

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(AppSizes.p20, AppSizes.p12, AppSizes.p20, AppSizes.p32),
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 440.w),
            padding: EdgeInsets.all(AppSizes.p24),
            decoration: BoxDecoration(
              color: scheme.elevatedSurface,
              borderRadius: BorderRadius.circular(AppSizes.r28),
              border: Border.all(color: borderColor),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 16.w, offset: Offset(0, 4.w))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Centered Icon Badge
                Container(
                  width: 52.w,
                  height: 52.w,
                  decoration: BoxDecoration(color: textColor.withAlpha(12), shape: BoxShape.circle),
                  child: Icon(AppIcons.sparkles, size: 24.w, color: textColor),
                ),
                Gap.h16,

                // Title & Eyebrow
                Text(
                  'BUILDING YOUR BASELINE — ${AppStrings.bentoMappingEyebrow.toUpperCase()}',
                  textAlign: TextAlign.center,
                  style: context.captionBold.copyWith(color: textColor.withAlpha(153), letterSpacing: 0.8),
                ),
                Gap.h4,
                Text(
                  'Log to Unlock AI Insights',
                  textAlign: TextAlign.center,
                  style: context.bodyBold.copyWith(color: textColor, fontSize: 20.sp, height: 1.2),
                ),
                Gap.h8,
                Text(
                  'Scan 3 food meals and log 1 symptom to generate your personalized AI gut health analysis.',
                  textAlign: TextAlign.center,
                  style: context.bodySm.copyWith(color: scheme.textSecondary, height: 1.35),
                ),
                Gap.h20,

                // Requirements Progress Container
                Container(
                  padding: EdgeInsets.all(AppSizes.p16),
                  decoration: BoxDecoration(
                    color: scheme.cardBackground,
                    borderRadius: BorderRadius.circular(AppSizes.r16),
                    border: Border.all(color: scheme.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InsightUsageRow(label: 'FOOD SCANS', current: currentFoodScans, total: maxFoodScans, color: foodDone ? scheme.success : textColor),
                      Gap.h16,
                      Divider(color: scheme.borderSubtle, height: 1),
                      Gap.h16,
                      InsightUsageRow(label: 'SYMPTOM LOGS', current: currentSymptoms, total: maxSymptoms, color: symptomsDone ? scheme.success : textColor),
                    ],
                  ),
                ),
                Gap.h16,

                // Guidance callout
                Container(
                  padding: EdgeInsets.all(AppSizes.p12),
                  decoration: BoxDecoration(
                    color: scheme.softSuccess.withAlpha(40),
                    borderRadius: BorderRadius.circular(AppSizes.r12),
                    border: Border.all(color: scheme.success.withAlpha(60)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(AppIcons.alertCircle, size: 18.sp, color: scheme.success),
                      Gap.w10,
                      Expanded(
                        child: Text(
                          'AI analyzes your food logs alongside symptoms to calculate your Gut Score and uncover tailored health patterns.',
                          style: context.caption.copyWith(color: scheme.textSecondary, height: 1.3, fontSize: 11.sp),
                        ),
                      ),
                    ],
                  ),
                ),
                Gap.h20,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InsightUsageRow extends StatelessWidget {
  const InsightUsageRow({super.key, required this.label, required this.current, required this.total, required this.color});

  final String label;
  final int current;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = (current / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label.toUpperCase(), style: context.captionBold.copyWith(color: context.appColorScheme.textSecondary)),
            Text('$current / $total', style: context.captionBold.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
          ],
        ),
        Gap.h6,
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(value: progress, backgroundColor: context.appColorScheme.borderSubtle, valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 6.w),
        ),
      ],
    );
  }
}

/// A dedicated Smart Insight / Deep Discovery hero card matching the referral banner style:
/// rich purple gradient background, white headline, bottom-left pill CTA button,
/// and [AppAssets.deepDiscovery] illustration aligned on the right side.
class DeepDiscoveryCard extends StatelessWidget {
  const DeepDiscoveryCard({super.key, required this.insight, this.onTap, this.assetImage = AppAssets.mascotDiscovery, this.gradientColors = const [Color(0xFF7C66EE), Color(0xFF6352DD)]});

  final InsightSummary insight;
  final VoidCallback? onTap;
  final String assetImage;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    final radius = 20.w;

    return Semantics(
      button: onTap != null,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap ?? () => context.push(AppRoutes.smartInsightDetail, extra: insight),
          borderRadius: BorderRadius.circular(radius),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: gradientColors),
              boxShadow: PatternSurface.shadow(context),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Stack(
                children: [
                  // Right Side Hero Illustration
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 0,
                    child: SizedBox(
                      width: 130.w,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Image.asset(assetImage, fit: BoxFit.contain, alignment: Alignment.centerRight, errorBuilder: (_, _, _) => const SizedBox.shrink()),
                      ),
                    ),
                  ),

                  // Left Side Content Column
                  Padding(
                    padding: EdgeInsets.fromLTRB(18.w, 16.w, 130.w, 16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Subtitle / Eyebrow Text
                        Text(
                          AppStrings.bentoSmartInsight,
                          style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.85), letterSpacing: 0.2),
                        ),

                        Gap.h6,

                        // Main Bold White Headline
                        Text(
                          insight.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 17.sp, fontWeight: FontWeight.w800, height: 1.20, letterSpacing: -0.4, color: Colors.white),
                        ),

                        Gap.h14,

                        // Bottom Left Pill CTA Button
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.20), borderRadius: BorderRadius.circular(100)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppStrings.bentoReadAnalysis,
                                style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The PatternCard-language content card: tone wash, 32px accent tile
/// (emoji or Lucide icon), w800 name with an accent meta on the right,
/// a title + muted paragraph, a chart slot, and the dot footer.
class InsightHighlightCard extends StatelessWidget {
  const InsightHighlightCard({
    super.key,
    required this.tag,
    this.emoji,
    this.icon,
    this.imageUrl,
    this.userImageUrl,
    this.assetImage,
    required this.title,
    this.body,
    this.meta,
    this.metaChip = false,
    this.bigTitle = false,
    this.footLeft,
    required this.accentColor,
    required this.backgroundColor,
    this.chartPainter,
    this.chart,
    this.onTap,
    this.actionIcon = AppIcons.chevronRight,
  });

  /// Head-row card name ("To watch", "Top win", "Driver 1"…).
  final String tag;

  /// Tile content: either an emoji, Lucide icon, or asset image.
  final String? emoji;
  final IconData? icon;
  final String? imageUrl;
  final String? userImageUrl;
  final String? assetImage;

  final String title;

  /// Muted paragraph under the title.
  final String? body;

  /// Right-aligned accent meta in the head row ("+18%", "5 of 7 days").
  /// Renders as a small chip when [metaChip] is set ("LOCKED").
  final String? meta;
  final bool metaChip;

  /// Feed-scale title: 15px w700 on a single line (the gallery feed cards).
  /// The default is the recap-scale 13.5px w800 over two lines.
  final bool bigTitle;

  final String? footLeft;
  final Color accentColor;
  final Color backgroundColor;

  /// Chart slot: a prebuilt [chart] widget wins over [chartPainter].
  final CustomPainter? chartPainter;
  final Widget? chart;

  final VoidCallback? onTap;

  /// Trailing footer action; only rendered when [onTap] is set.
  final IconData? actionIcon;

  @override
  Widget build(BuildContext context) {
    final chartSlot =
        chart ??
        (chartPainter == null
            ? null
            : SizedBox(
                height: 38.w,
                width: double.infinity,
                child: CustomPaint(size: Size.infinite, painter: chartPainter!),
              ));
    final tappable = onTap != null;
    final displayImg = userImageUrl ?? imageUrl;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(color: PatternSurface.tone(context, accentColor, backgroundColor), borderRadius: BorderRadius.circular(18.w), boxShadow: PatternSurface.shadow(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(10.w)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.w),
                    child: (assetImage != null && assetImage!.isNotEmpty)
                        ? Image.asset(
                            assetImage!,
                            width: 32.w,
                            height: 32.w,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Center(
                              child: emoji != null ? Text(emoji!, style: TextStyle(fontSize: 16.sp, height: 1)) : Icon(icon ?? AppIcons.sparkles, size: 16.w, color: Colors.white),
                            ),
                          )
                        : (displayImg != null && displayImg.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: displayImg,
                            width: 32.w,
                            height: 32.w,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => Center(
                              child: emoji != null ? Text(emoji!, style: TextStyle(fontSize: 16.sp, height: 1)) : Icon(icon ?? AppIcons.sparkles, size: 16.w, color: Colors.white),
                            ),
                          )
                        : Center(
                            child: emoji != null ? Text(emoji!, style: TextStyle(fontSize: 16.sp, height: 1)) : Icon(icon ?? AppIcons.sparkles, size: 16.w, color: Colors.white),
                          ),
                  ),
                ),
                Gap.w8,
                Expanded(
                  child: Text(
                    tag.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 13.sp, fontWeight: FontWeight.w800, color: PatternSurface.ink(context)),
                  ),
                ),
                if (meta != null) ...[
                  Gap.w6,
                  if (metaChip)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.5.w),
                      decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6.w)),
                      child: Text(
                        meta!.toUpperCase(),
                        style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: accentColor),
                      ),
                    )
                  else
                    Text(
                      meta!,
                      maxLines: 1,
                      style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: accentColor),
                    ),
                ],
              ],
            ),
            Gap.h10,
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: InsightBentoTheme.fontFamily,
                fontSize: bigTitle ? 15.sp : 13.5.sp,
                fontWeight: bigTitle ? FontWeight.w700 : FontWeight.w800,
                height: bigTitle ? 1.2 : 1.3,
                letterSpacing: -0.2,
                color: PatternSurface.ink(context),
              ),
            ),
            if ((body ?? '').isNotEmpty) ...[
              Gap.h4,
              Text(
                body!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.5.sp, color: PatternSurface.muted(context), height: 1.4),
              ),
            ],
            Gap.h10,
            if (chartSlot != null) ...[chartSlot, Gap.h10],
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
                    footLeft ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w600, color: PatternSurface.foot(context)),
                  ),
                ),
                if (tappable && actionIcon != null) Icon(actionIcon, size: 15, color: accentColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HealingSparklinePainter extends CustomPainter {
  HealingSparklinePainter({required this.color, this.values = const []});
  final Color color;
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final data = values.where((value) => value.isFinite && value >= 0 && value <= 100).toList();
    if (data.length < 2 || size.width <= 0 || size.height <= 0) return;
    final visible = data.length > 7 ? data.sublist(data.length - 7) : data;
    final min = visible.reduce(math.min);
    final max = visible.reduce(math.max);
    final range = max - min;
    final points = [for (var i = 0; i < visible.length; i++) Offset(size.width * i / (visible.length - 1), size.height * (0.85 - (range == 0 ? .35 : (visible[i] - min) / range * .7)))];
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      line.lineTo(point.dx, point.dy);
    }
    final area = Path.from(line)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    final fill = Paint()
      ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color.withValues(alpha: .2), color.withValues(alpha: 0)]).createShader(Offset.zero & size);
    canvas
      ..drawPath(area, fill)
      ..drawPath(
        line,
        Paint()
          ..color = color
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      )
      ..drawCircle(points.last, 3.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(HealingSparklinePainter old) => old.color != color || !listEquals(old.values, values);
}

class TriggerSpikePainter extends CustomPainter {
  TriggerSpikePainter({required this.color, this.values = const []});
  final Color color;
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final data = values.where((value) => value.isFinite && value >= 0).toList();
    if (data.length < 2 || size.width <= 0 || size.height <= 0) return;
    final visible = data.length > 7 ? data.sublist(data.length - 7) : data;
    final min = visible.reduce(math.min);
    final max = visible.reduce(math.max);
    final range = max - min;
    final points = [for (var i = 0; i < visible.length; i++) Offset(size.width * i / (visible.length - 1), size.height * (0.85 - (range == 0 ? .35 : (visible[i] - min) / range * .7)))];
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      line.lineTo(point.dx, point.dy);
    }
    canvas
      ..drawPath(
        line,
        Paint()
          ..color = color
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      )
      ..drawCircle(points[visible.indexOf(max)], 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(TriggerSpikePainter old) => old.color != color || !listEquals(old.values, values);
}

class WorkingBarsPainter extends CustomPainter {
  WorkingBarsPainter({required this.color, this.values = const []});
  final Color color;

  /// Real series (e.g. per-day pattern episodes). Empty leaves the chart blank.
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;
    final gap = 6.w;

    final safeValues = values.where((value) => value.isFinite && value >= 0).toList();
    if (safeValues.length >= 2) {
      final data = safeValues.length > 7 ? safeValues.sublist(safeValues.length - 7) : safeValues;
      final n = data.length;
      final maxV = data.reduce(math.max);
      final barW = (w - (gap * (n - 1))) / n;
      for (var i = 0; i < n; i++) {
        final t = maxV <= 0 ? 0.5 : (0.25 + 0.75 * (data[i] / maxV)).clamp(0.0, 1.0);
        final rectH = h * t;
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(i * (barW + gap), h - rectH, barW, rectH), Radius.circular(math.min(4, barW / 2))),
          Paint()..color = color.withValues(alpha: n == 1 ? 1.0 : 0.45 + 0.55 * (i / (n - 1))),
        );
      }
      return;
    }

    return;
  }

  @override
  bool shouldRepaint(WorkingBarsPainter old) => old.color != color || !listEquals(old.values, values);
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

    canvas
      ..drawPath(path, dashPaint)
      ..drawCircle(Offset(w * 0.5, h * 0.5 + math.sin(w * 0.5 * 0.08) * (h * 0.3)), 4.0, Paint()..color = color);
  }

  @override
  bool shouldRepaint(CustomPainter old) => false;
}
