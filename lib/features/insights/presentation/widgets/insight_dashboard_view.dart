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
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
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
        padding: EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Health Wallet Hero
            DashboardEntrance(
              delay: 50,
              child: ModernGutScoreCard(
                description: data.topInsight?.description ?? '',
                score: data.gutScore,
                scoreDiff: data.scoreDiff,
                showDetails: !isHistorical,
                onTap: isHistorical
                    ? () {}
                    : () async {
                        if (context.mounted) {
                          unawaited(context.push(AppRoutes.smartInsightDetail, extra: data.topInsight!));
                        }
                      },
              ),
            ),

            Gap.h16,

            // Quick Metrics
            DashboardEntrance(
              delay: 100,
              child: InsightMetricGrid(data: data, notifier: notifier, streak: streak),
            ),
            Gap.h16,

            if (data.healingGoal != null || data.triggerSymptom != null) ...[
              DashboardEntrance(
                delay: 180,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (data.healingGoal != null)
                      PhysicalGoalCard(
                        title: data.healingGoal!.toUpperCase(),
                        subtitle: 'PRIMARY GOAL',
                        label: AppStrings.primaryHealingObjective,
                        icon: AppIcons.target,
                        color: AppPalette.blue,
                        progress: 0.50,
                      ),
                    if (data.healingGoal != null && data.triggerSymptom != null) Gap.h12,
                    if (data.triggerSymptom != null)
                      PhysicalGoalCard(
                        title: data.triggerSymptom!.toUpperCase(),
                        subtitle: 'WATCH LIST',
                        label: AppStrings.symptomTrackedForPatterns,
                        icon: AppIcons.activity,
                        color: AppPalette.pink,
                        progress: 0.45,
                      ),
                  ],
                ),
              ),
              Gap.h16,
            ],

            if (data.healingFoods.isNotEmpty || data.triggerFoods.isNotEmpty) ...[
              if (data.healingFoods.isNotEmpty) ...[BentoFoodCard(title: 'HEALING', foods: data.healingFoods, isPositive: true, icon: AppIcons.zap, trend: data.healingTrend), Gap.h12],
              if (data.triggerFoods.isNotEmpty) ...[BentoFoodCard(title: 'TRIGGERS', foods: data.triggerFoods, isPositive: false, icon: AppIcons.alertTriangle, trend: data.triggerTrend), Gap.h12],
              Gap.h4,
            ],

            if (displayPatterns.isNotEmpty) ...[..._buildPatternCards(context, displayPatterns)],

            if (data.foodImpacts.isNotEmpty) ...[BentoActivityCard(impacts: data.foodImpacts), Gap.h24],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPatternCards(BuildContext context, List<BodyPattern> patterns) {
    if (patterns.isEmpty) return [];
    final widgets = <Widget>[];
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

    // 🏆 Dynamic Layout: First pattern is a "Hero Discovery" (Full width),
    // others can be side-by-side or stylized differently.
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
                height: 160.h,
                backgroundColor: scheme.cardBackground,
                child: Row(
                  children: [
                    // Left Panel: Identity block
                    Container(
                      width: 136.h,
                      height: 136.h,
                      decoration: BoxDecoration(
                        color: themeColor.withAlpha(isDark ? 40 : 200),
                        borderRadius: BorderRadius.circular(16),
                        // boxShadow: [BoxShadow(color: accentColor.withAlpha(isDark ? 40 : 20), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(InsightUiUtils.getPatternTypeIcon(p.type), size: 36.sp, color: accentColor),
                          ),
                          Positioned(
                            bottom: 8,
                            left: 12,
                            right: 12,
                            child: Text(
                              '${p.confidence.toUpperCase()} CONFIDENCE',
                              textAlign: TextAlign.center,
                              style: context.captionMicro.copyWith(color: accentColor, fontSize: 7.sp, fontWeight: FontWeight.w900),
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
                            style: context.captionBold.copyWith(color: scheme.textSecondary, fontSize: 9.sp, letterSpacing: 1.1),
                          ),
                          Gap.h4,
                          Text(
                            p.trigger,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.headingSm.copyWith(color: scheme.textPrimary, fontWeight: FontWeight.w900, fontSize: 14.sp, letterSpacing: -0.5),
                          ),
                          Gap.h4,
                          Text(
                            p.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.caption.copyWith(color: scheme.textMuted, height: 1.3, fontSize: 11.sp),
                          ),
                        ],
                      ),
                    ),
                    Icon(AppIcons.chevronRight, color: scheme.textMuted, size: 16),
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
  const PhysicalGoalCard({super.key, required this.title, required this.subtitle, required this.label, required this.icon, required this.color, this.progress = 0.65, this.onTap});

  final String title;
  final String subtitle;
  final String label;
  final IconData icon;
  final Color color;
  final double progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Adaptive Theme Colors
    final cardBg = isDark ? AppPalette.darkCard : scheme.cardBackground;
    final cardBorder = isDark ? AppPalette.white.withAlpha(20) : scheme.borderSubtle;
    final labelColor = isDark ? AppPalette.white.withAlpha(102) : scheme.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: BentoCard(
        padding: EdgeInsets.zero,
        height: 140.h,
        width: double.maxFinite,
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
                child: Icon(icon, size: 100.h, color: color.withValues(alpha: 0.5)),
              ),
            ),

            // 📝 Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtitle,
                    style: context.captionBold.copyWith(color: color, letterSpacing: 1.2, fontSize: 8.sp),
                  ),
                  Gap.h2,
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.displaySm.copyWith(color: scheme.textPrimary, fontSize: 22.sp, letterSpacing: -1.2, fontWeight: FontWeight.w900, height: 1.1),
                  ),
                  const Spacer(),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.bodySm.copyWith(color: labelColor, fontWeight: FontWeight.w500, height: 1.2, fontSize: 13.sp),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IntelligencePulseCard extends StatelessWidget {
  const IntelligencePulseCard({super.key, required this.title, required this.description, this.index = 1, this.onTap, this.accentColor = AppPalette.blue});

  final String title;
  final String description;
  final int index;
  final VoidCallback? onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(minHeight: 180.h),
        decoration: BoxDecoration(
          color: AppPalette.black,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppPalette.white.withAlpha(20)),
          gradient: RadialGradient(center: Alignment.topRight, radius: 1.4, colors: [accentColor.withAlpha(isDark ? 100 : 160), AppPalette.black], stops: const [0.0, 0.7]),
        ),
        child: Stack(
          children: [
            // 📝 Content (Bottom)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: context.displaySm.copyWith(color: AppPalette.white, fontSize: 32.sp, fontWeight: FontWeight.w900, height: 1.0, letterSpacing: -1.5),
                  ),
                  Gap.h16,
                  Text(
                    description,
                    style: context.bodySm.copyWith(color: AppPalette.white.withAlpha(180), height: 1.4, fontSize: 13.sp),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
