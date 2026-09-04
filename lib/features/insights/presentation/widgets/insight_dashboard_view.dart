import 'dart:async';
import 'dart:math' as math;

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
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/super_card.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/product_details/presentation/widgets/scan_result_widgets.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:provider/provider.dart';

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
    final profileNotifier = context.watch<ProfileNotifier>();
    final currentScore = (profileNotifier.profile?.gutScore ?? 0) > 0 ? profileNotifier.profile!.gutScore : profileNotifier.avgFoodScore;

    debugPrint('--- InsightDashboardSliver: Building ---');
    debugPrint('Direct Profile Score: $currentScore');
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
            // 1. Super Gut Score Card (from super_card.dart)
            DashboardEntrance(
              delay: 50,
              child: SuperGutScoreCard(
                score: currentScore,
                streak: streak,
                loggedCount: (notifier?.totalMeals ?? 0) + (notifier?.totalSymptoms ?? 0) + (notifier?.totalScans ?? 0),
                onTap: isHistorical
                    ? () {}
                    : () async {
                        if (context.mounted) {
                          unawaited(context.push(AppRoutes.weeklyRecap, extra: data));
                        }
                      },
              ),
            ),
            Gap.h16,

            // 3. Super Autopilot Card (from super_card.dart)
            DashboardEntrance(
              delay: 100,
              child: SuperAutopilotCard(
                description: data.topInsight?.description,
                healingCount: data.healingFoods.length,
                triggerCount: data.triggerFoods.length,
                onTap: isHistorical
                    ? () {}
                    : () async {
                        if (context.mounted && data.topInsight != null) {
                          unawaited(context.push(AppRoutes.smartInsightDetail, extra: data.topInsight!));
                        }
                      },
              ),
            ),
            Gap.h16,

            if (data.healingGoal != null || data.triggerSymptom != null) ...[
              DashboardEntrance(
                delay: 180,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (data.healingGoal != null)
                      SuperPhysicalGoalCard(title: data.healingGoal!.toUpperCase(), subtitle: 'PRIMARY GOAL', label: AppStrings.primaryHealingObjective, icon: AppIcons.target, color: AppPalette.blue),
                    if (data.healingGoal != null && data.triggerSymptom != null) Gap.h12,
                    if (data.triggerSymptom != null)
                      SuperPhysicalGoalCard(
                        title: data.triggerSymptom!.toUpperCase(),
                        subtitle: 'WATCH LIST',
                        label: AppStrings.symptomTrackedForPatterns,
                        icon: AppIcons.activity,
                        color: AppPalette.pink,
                      ),
                  ],
                ),
              ),
              Gap.h16,
            ],

            if (notifier != null && !notifier!.isSufficient) ...[
              DashboardEntrance(
                delay: 150,
                child: TrackingInProgressCard(mealsLogged: notifier!.totalMeals, symptomsLogged: notifier!.totalSymptoms, scansDone: notifier!.totalScans),
              ),
              Gap.h16,
            ],

            if (displayPatterns.isNotEmpty) ...[..._buildPatternCards(context, displayPatterns)],

            if (data.healingFoods.isNotEmpty || data.triggerFoods.isNotEmpty) ...[
              if (data.healingFoods.isNotEmpty) ...[
                BentoFoodCard(
                  title: 'HEALING',
                  foods: data.healingFoods,
                  isPositive: true,
                  icon: AppIcons.zap,
                  trend: data.healingTrend,
                  score: _calculateHealingScore(data),
                  highlight: data.topHealing,
                ),
                Gap.h12,
              ],
              if (data.triggerFoods.isNotEmpty) ...[
                BentoFoodCard(
                  title: 'TRIGGERS',
                  foods: data.triggerFoods,
                  isPositive: false,
                  icon: AppIcons.alertTriangle,
                  trend: data.triggerTrend,
                  score: _calculateTriggerScore(data),
                  highlight: data.topTrigger,
                ),
                Gap.h12,
              ],
            ],

            if (data.foodImpacts.isNotEmpty) ...[
              Builder(
                builder: (context) {
                  debugPrint('--- InsightDashboardSliver: RECENT LOGS (FoodImpacts) Data ---');
                  for (var impact in data.foodImpacts) {
                    debugPrint('Impact: food=${impact.food}, impactType=${impact.impactType}, imageUrl=${impact.imageUrl}');
                  }
                  debugPrint('-----------------------------------------------------------');
                  return BentoActivityCard(impacts: data.foodImpacts, score: currentScore);
                },
              ),
              Gap.h24,
            ],
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

      widgets
        ..add(
          DashboardEntrance(
            delay: 300 + (i * 50),
            child: SuperPatternCard(
              pattern: p,
              onTap: () => context.push(AppRoutes.patternDetail, extra: p),
            ),
          ),
        )
        ..add(Gap.h12);
    }
    return widgets;
  }

  int _calculateHealingScore(AIInsight data) {
    final total = math.max(1, data.healingFoods.length + data.triggerFoods.length);
    return ((data.healingFoods.length / total) * 100).round();
  }

  int _calculateTriggerScore(AIInsight data) {
    final total = math.max(1, data.healingFoods.length + data.triggerFoods.length);
    return ((data.triggerFoods.length / total) * 100).round();
  }
}

class IntelligencePulseCard extends StatelessWidget {
  const IntelligencePulseCard({super.key, required this.title, required this.description, this.index = 1, this.icon, this.onTap, this.accentColor = const Color(0xFF0759E8)});

  final String title;
  final String description;
  final int index;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    constraints: BoxConstraints(minHeight: 180.h),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: const Color(0xFF02050D)),
    clipBehavior: Clip.antiAlias,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 1. RADIAL GRADIENT BACKGROUND
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(1.0, -0.35),
                    radius: 1.15,
                    colors: [const Color(0xFF08A9FF), accentColor, const Color(0xFF03104C), const Color(0xFF02050D)],
                    stops: const [0.0, 0.25, 0.52, 0.82],
                  ),
                ),
              ),
            ),

            // 2. DARK OVERLAY
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.black.withAlpha(64), Colors.transparent, Colors.black.withAlpha(46)]),
                ),
              ),
            ),

            // 3. BLUE GLOW TOP RIGHT
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 140.w,
                height: 140.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [const Color(0xFF00B7FF).withAlpha(128), Colors.transparent]),
                ),
              ),
            ),

            // 4. ICON BADGE TOP LEFT
            Positioned(
              left: 18,
              top: 18,
              child: Container(
                width: 34.sp,
                height: 34.sp,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(20),
                  border: Border.all(color: Colors.white.withAlpha(64), width: 1),
                ),
                alignment: Alignment.center,
                child: Icon(icon ?? AppIcons.salad, size: 16.sp, color: Colors.white),
              ),
            ),

            // 5. CONTENT (Title & Description)
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 64.h, 20.w, 22.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(color: Colors.white, fontSize: 22.sp, height: 1.1, fontWeight: FontWeight.w900, letterSpacing: -0.7),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    description,
                    style: TextStyle(color: Colors.white.withAlpha(217), fontSize: 12.5.sp, height: 1.4, fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class TrackingInProgressCard extends StatelessWidget {
  const TrackingInProgressCard({super.key, required this.mealsLogged, required this.symptomsLogged, required this.scansDone});

  final int mealsLogged;
  final int symptomsLogged;
  final int scansDone;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const totalTarget = 4;
    final currentProgress = (scansDone + mealsLogged + symptomsLogged).clamp(0, totalTarget);
    final progressPercent = (currentProgress / totalTarget).clamp(0.0, 1.0);

    return BentoCard(
      padding: const EdgeInsets.all(20),
      backgroundColor: isDark ? AppPalette.darkCard : scheme.cardBackground,
      borderColor: AppPalette.purple.withAlpha(50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppPalette.purple.withAlpha(26), shape: BoxShape.circle),
                child: Icon(AppIcons.brain, size: 16.sp, color: AppPalette.purple),
              ),
              Gap.w10,
              Text(
                'PATTERN ENGINE INITIALIZING',
                style: context.captionBold.copyWith(color: AppPalette.purple, letterSpacing: 1.2, fontSize: 9.sp, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          Gap.h12,
          Text(
            'Keep Logging Your Meals & Feelings',
            style: context.headingSm.copyWith(color: scheme.textPrimary, fontWeight: FontWeight.w900),
          ),
          Gap.h6,
          Text(
            'GutGood needs at least 3 meals and 1 feeling log to discover your unique body patterns. Progress: $currentProgress / $totalTarget items tracked.',
            style: context.bodySm.copyWith(color: scheme.textSecondary, height: 1.3),
          ),
          Gap.h16,
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: progressPercent, minHeight: 8.h, backgroundColor: scheme.borderSubtle, valueColor: const AlwaysStoppedAnimation<Color>(AppPalette.purple)),
          ),
        ],
      ),
    );
  }
}
