import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/insight_ui_utils.dart';
import 'package:gutgood/core/utils/quota_guard.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/gut_action_banner.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_dashboard_sections.dart';
import 'package:gutgood/features/insights/presentation/widgets/modern_gut_score_card.dart';
import 'package:gutgood/features/product_details/presentation/widgets/scan_result_widgets.dart';

/// A shared sliver component that builds the comprehensive insight dashboard layout.
/// Used by both the main [InsightsScreen] (live) and [InsightDetailScreen] (historical).
class InsightDashboardSliver extends StatelessWidget {
  const InsightDashboardSliver({super.key, required this.data, required this.streak, this.notifier, this.patterns, this.isHistorical = false});

  final AIInsight data;
  final int streak;
  final InsightsNotifier? notifier;
  final List<BodyPattern>? patterns;
  final bool isHistorical;

  @override
  Widget build(BuildContext context) {
    final displayPatterns = patterns ?? data.detectedPatterns;

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Snapshot Hero (Modern Premium Style)
            DashboardEntrance(
              delay: 50,
              child: ModernGutScoreCard(
                score: data.gutScore,
                scoreDiff: data.scoreDiff,
                onTap: isHistorical
                    ? () {}
                    : () async {
                        if (await QuotaGuard.check(context, type: QuotaType.premium)) {
                          if (context.mounted) {
                            unawaited(context.push(AppRoutes.weeklyRecap, extra: data));
                          }
                        }
                      },
              ),
            ),
            Gap.h12,

            // 2. Metrics Quick View
            DashboardEntrance(
              delay: 100,
              child: InsightMetricGrid(data: data, notifier: notifier, streak: streak),
            ),
            Gap.h12,

            // 3. Strategic Summary (Redesigned Target & Watch List)
            if (data.healingGoal != null || data.triggerSymptom != null)
              DashboardEntrance(
                delay: 150,
                child: Row(
                  children: [
                    if (data.healingGoal != null)
                      Expanded(
                        child: BentoCard(
                          padding: const EdgeInsets.all(16),
                          height: 130.h,
                          backgroundColor: AppPalette.blue.withAlpha(15),
                          borderColor: AppPalette.blue.withAlpha(30),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(color: AppPalette.blue.withAlpha(40), shape: BoxShape.circle),
                                    child: const Icon(AppIcons.target, size: 12, color: AppPalette.blue),
                                  ),
                                  Gap.w8,
                                  Text('TARGET', style: context.captionBold.copyWith(color: AppPalette.blue, letterSpacing: 1.1)),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                data.healingGoal!.toUpperCase(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: context.bodyBold.copyWith(color: context.appColorScheme.textPrimary, fontWeight: FontWeight.w900, fontSize: 15.sp, height: 1.1),
                              ),
                              Gap.h4,
                              Text(
                                AppStrings.primaryHealingObjective,
                                style: context.captionMicro.copyWith(color: context.appColorScheme.textMuted, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (data.healingGoal != null && data.triggerSymptom != null) Gap.w12,
                    if (data.triggerSymptom != null)
                      Expanded(
                        child: BentoCard(
                          padding: const EdgeInsets.all(16),
                          height: 130.h,
                          backgroundColor: AppPalette.pink.withAlpha(15),
                          borderColor: AppPalette.pink.withAlpha(30),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(color: AppPalette.pink.withAlpha(40), shape: BoxShape.circle),
                                    child: const Icon(AppIcons.activity, size: 12, color: AppPalette.pink),
                                  ),
                                  Gap.w8,
                                  Text('WATCH LIST', style: context.captionBold.copyWith(color: AppPalette.pink, letterSpacing: 1.1)),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                data.triggerSymptom!.toUpperCase(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: context.bodyBold.copyWith(color: context.appColorScheme.textPrimary, fontWeight: FontWeight.w900, fontSize: 15.sp, height: 1.1),
                              ),
                              Gap.h4,
                              Text(
                                AppStrings.symptomTrackedForPatterns,
                                style: context.captionMicro.copyWith(color: context.appColorScheme.textMuted, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            if (data.healingGoal != null || data.triggerSymptom != null) Gap.h12,

            // 4. Performance & Performance Highlights (Energy Section)
            if (data.healingFoods.isNotEmpty || data.topHealing != null)
              DashboardEntrance(
                delay: 200,
                child: BentoCard(
                  padding: const EdgeInsets.all(12),
                  height: 140.h,
                  backgroundColor: AppPalette.greenPastel,
                  child: Row(
                    children: [
                      // Left block: Healing Score/Count
                      Container(
                        width: 116.h,
                        height: 116.h,
                        decoration: BoxDecoration(color: AppPalette.white.withAlpha(204), borderRadius: BorderRadius.circular(16)),
                        child: Stack(
                          children: [
                            const Positioned(top: 10, left: 10, child: Icon(AppIcons.zap, size: 12, color: AppPalette.green)),
                            Center(
                              child: Text(
                                '${data.healingFoods.length}',
                                style: context.displayHero.copyWith(color: AppPalette.black, fontSize: 56.sp, letterSpacing: -4),
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              left: 10,
                              right: 10,
                              child: Text(
                                'HEALING',
                                textAlign: TextAlign.center,
                                style: context.captionMicro.copyWith(color: AppPalette.black, fontWeight: FontWeight.w900, fontSize: 8.sp),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Gap.w16,
                      // Right info: Vertical Cycler
                      Expanded(
                        child: BentoFoodCycler(foods: data.healingFoods, title: AppStrings.betterEnergy, trend: data.healingTrend, isPositive: true),
                      ),
                    ],
                  ),
                ),
              ),
            if (data.healingFoods.isNotEmpty || data.topHealing != null) Gap.h12,

            // 4b. Potential Triggers Section
            if (data.triggerFoods.isNotEmpty || data.topTrigger != null)
              DashboardEntrance(
                delay: 220,
                child: BentoCard(
                  padding: const EdgeInsets.all(12),
                  height: 140.h,
                  backgroundColor: context.appColorScheme.errorSubtle,
                  child: Row(
                    children: [
                      // Left block: Trigger Count
                      Container(
                        width: 116.h,
                        height: 116.h,
                        decoration: BoxDecoration(color: AppPalette.white.withAlpha(204), borderRadius: BorderRadius.circular(16)),
                        child: Stack(
                          children: [
                            const Positioned(top: 10, left: 10, child: Icon(AppIcons.alertTriangle, size: 12, color: AppPalette.red)),
                            Center(
                              child: Text(
                                '${data.triggerFoods.length}',
                                style: context.displayHero.copyWith(color: AppPalette.black, fontSize: 56.sp, letterSpacing: -4),
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              left: 10,
                              right: 10,
                              child: Text(
                                'TRIGGERS',
                                textAlign: TextAlign.center,
                                style: context.captionMicro.copyWith(color: AppPalette.black, fontWeight: FontWeight.w900, fontSize: 8.sp),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Gap.w16,
                      // Right info
                      Expanded(
                        child: BentoFoodCycler(foods: data.triggerFoods, title: AppStrings.bloating, trend: data.triggerTrend, isPositive: false),
                      ),
                    ],
                  ),
                ),
              ),
            if (data.triggerFoods.isNotEmpty || data.topTrigger != null) Gap.h12,

            // 5. Individual Pattern Discoveries (Identity cards style)
            ..._buildPatternCards(context, displayPatterns),

            // 6. Recent Body Feedback (Bento Cycler)
            if (data.foodImpacts.isNotEmpty) ...[BentoActivityCard(impacts: data.foodImpacts), Gap.h12],

            // 7. AI Intelligence Card
            if (data.topInsight != null) ...[DashboardEntrance(delay: 450, child: ModernSmartAlert(insight: data.topInsight!)), Gap.h24],

            // 8. Action Banner
            DashboardEntrance(
              delay: 500,
              child: GutActionBanner(
                title: AppStrings.weeklySnapshot.toUpperCase(),
                subtitle: AppStrings.last7DaysReady,
                icon: AppIcons.salad,
                backgroundColor: context.appColorScheme.textPrimary,
                iconColor: context.appColorScheme.cardBackground,
                onTap: () async {
                  if (await QuotaGuard.check(context, type: QuotaType.premium)) {
                    if (context.mounted) {
                      unawaited(context.push(AppRoutes.weeklyRecap, extra: data));
                    }
                  }
                },
              ),
            ),
            Gap.h40,
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPatternCards(BuildContext context, List<BodyPattern> patterns) {
    if (patterns.isEmpty) return [];
    final widgets = <Widget>[];
    final scheme = context.appColorScheme;

    // Deduplicate patterns
    final seenPatterns = <String>{};
    final uniquePatterns = <BodyPattern>[];
    for (final p in patterns) {
      final key = '${p.type}_${p.trigger.toLowerCase().trim()}';
      if (!seenPatterns.contains(key)) {
        seenPatterns.add(key);
        uniquePatterns.add(p);
      }
    }

    for (var i = 0; i < uniquePatterns.length; i++) {
      final p = uniquePatterns[i];
      final themeColor = InsightUiUtils.getPatternPastelColor(p.type);
      final accentColor = InsightUiUtils.getPatternColor(p.type);

      widgets
        ..add(
          DashboardEntrance(
            delay: 300 + (i * 50),
            child: InkWell(
              onTap: () => context.push(AppRoutes.patternDetail, extra: p),
              borderRadius: BorderRadius.circular(AppSizes.r24),
              child: BentoCard(
                padding: const EdgeInsets.all(12),
                height: 140.h,
                backgroundColor: themeColor,
                child: Row(
                  children: [
                    // Left Panel: Identity block
                    Container(
                      width: 116.h,
                      height: 116.h,
                      decoration: BoxDecoration(color: scheme.cardBackground.withAlpha(204), borderRadius: BorderRadius.circular(16)),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Text(
                              'AI DISCOVERY',
                              style: context.captionMicro.copyWith(color: accentColor, fontWeight: FontWeight.w900),
                            ),
                          ),
                          Center(
                            child: Icon(InsightUiUtils.getPatternTypeIcon(p.type), size: 36.sp, color: accentColor),
                          ),
                          Positioned(
                            bottom: 8,
                            left: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: accentColor.withAlpha(26), borderRadius: BorderRadius.circular(100)),
                              child: Text(
                                '${p.confidence.toUpperCase()} CONFIDENCE',
                                textAlign: TextAlign.center,
                                style: context.captionMicro.copyWith(color: accentColor, fontSize: 7.sp, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Gap.w16,
                    // Right Panel: Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            InsightUiUtils.getPatternName(p.type).toUpperCase(),
                            style: context.captionBold.copyWith(color: AppPalette.black.withAlpha(153), fontSize: 9.sp),
                          ),
                          Gap.h4,
                          Text(
                            p.trigger,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.bodyBold.copyWith(color: AppPalette.black, fontWeight: FontWeight.w900, fontSize: 16.sp, letterSpacing: -0.5),
                          ),
                          Gap.h4,
                          Text(
                            p.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.caption.copyWith(color: AppPalette.black.withAlpha(178), height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    Icon(AppIcons.chevronRight, color: AppPalette.black.withAlpha(102), size: 16),
                  ],
                ),
              ),
            ),
          ),
        )
        ..add(Gap.h12);
    }
    return widgets;
  }
}
