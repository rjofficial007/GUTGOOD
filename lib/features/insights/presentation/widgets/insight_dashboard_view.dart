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
    final displayPatterns = (patterns != null && patterns!.isNotEmpty) ? patterns! : data.detectedPatterns;

    debugPrint('--- InsightDashboardSliver: Building ---');
    debugPrint('Gut Score: ${data.gutScore}');
    debugPrint('Healing Foods: ${data.healingFoods.length}');
    debugPrint('Trigger Foods: ${data.triggerFoods.length}');
    debugPrint('Detected Patterns (Model): ${data.detectedPatterns.length}');
    debugPrint('Prioritized Patterns (Notifier): ${patterns?.length}');
    debugPrint('Display Patterns Count: ${displayPatterns.length}');
    if (displayPatterns.isNotEmpty) {
      for (var i = 0; i < displayPatterns.length; i++) {
        debugPrint('Display Pattern [$i]: ${displayPatterns[i].trigger}');
      }
    }
    debugPrint('-----------------------------------------');

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
                        child: PhysicalGoalCard(
                          title: data.healingGoal!.toUpperCase(),
                          subtitle: 'CURRENT GOAL',
                          label: AppStrings.primaryHealingObjective,
                          icon: AppIcons.target,
                          color: AppPalette.blue,
                          progress: 0.50,
                        ),
                      ),
                    if (data.healingGoal != null && data.triggerSymptom != null) Gap.w12,
                    if (data.triggerSymptom != null)
                      Expanded(
                        child: PhysicalGoalCard(
                          title: data.triggerSymptom!.toUpperCase(),
                          subtitle: 'WATCH LIST',
                          label: AppStrings.symptomTrackedForPatterns,
                          icon: AppIcons.activity,
                          color: AppPalette.pink,
                          progress: 0.45,
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

class PhysicalGoalCard extends StatelessWidget {
  const PhysicalGoalCard({super.key, required this.title, required this.subtitle, required this.label, required this.icon, required this.color, this.progress = 0.65});

  final String title;
  final String subtitle;
  final String label;
  final IconData icon;
  final Color color;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Adaptive Theme Colors
    final cardBg = isDark ? AppPalette.darkCard : color.withAlpha(15);
    final cardBorder = isDark ? AppPalette.white.withAlpha(20) : color.withAlpha(30);
    final subtitleColor = isDark ? AppPalette.white.withAlpha(153) : scheme.textSecondary;
    final labelColor = isDark ? AppPalette.white.withAlpha(102) : scheme.textMuted;

    return BentoCard(
      padding: EdgeInsets.zero,
      height: 140.h,
      backgroundColor: cardBg,
      borderColor: cardBorder,
      child: Stack(
        children: [
          // 🌊 Large Icon with Liquid Fill effect
          Positioned(
            right: -20,
            bottom: -20,
            child: Opacity(
              opacity: isDark ? 0.8 : 0.4,
              child: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (rect) => LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [color, color, color.withAlpha(isDark ? 40 : 80), color.withAlpha(isDark ? 40 : 80)],
                  stops: [0.0, progress, progress, 1.0],
                ).createShader(rect),
                child: Icon(icon, size: 140.h),
              ),
            ),
          ),

          // 📝 Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.displayHero.copyWith(color: color, fontSize: 20.sp, letterSpacing: -1, fontWeight: FontWeight.w900),
                ),
                Text(subtitle, style: context.captionBold.copyWith(color: subtitleColor)),
                const Spacer(),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.captionMicro.copyWith(color: labelColor, fontWeight: FontWeight.w600, height: 1.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
