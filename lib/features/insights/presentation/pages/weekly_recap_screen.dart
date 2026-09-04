import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/ai_insight_details.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:provider/provider.dart';

class WeeklyRecapScreen extends StatelessWidget {
  const WeeklyRecapScreen({super.key, this.insight});
  final AIInsight? insight;

  @override
  Widget build(BuildContext context) {
    final recap = insight?.weeklyRecap;
    final highlights = recap?.highlights ?? [];

    if (insight != null) {
      unawaited(sl<AnalyticsService>().logEvent(name: 'view_weekly_recap', parameters: {'avg_score': recap?.avgScore ?? 0, 'foods_logged': recap?.foodsLogged ?? 0}));
    }

    if (insight == null) {
      return const _RecapLoadingView();
    }

    return Scaffold(
      backgroundColor: context.appColorScheme.cardBackground,
      body: CustomScrollView(
        slivers: [
          const GutSliverAppBar(title: AppStrings.weeklyRecap, centerTitle: true),
          _MainDashboardSliver(data: insight!, highlights: highlights),
        ],
      ),
    );
  }
}

class _MainDashboardSliver extends StatelessWidget {
  const _MainDashboardSliver({required this.data, required this.highlights});
  final AIInsight data;
  final List<RecapHighlight> highlights;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileNotifier>();
    final streak = profile.streak;
    final recap = data.weeklyRecap;

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Weekly Average Hero (Super Style)
            DashboardEntrance(
              delay: 50,
              child: SuperGutScoreCard(
                score: recap?.avgScore ?? 0,
                streak: streak,
                loggedCount: recap?.foodsLogged ?? 0,
                onTap: () {}, // Static view for recap
              ),
            ),
            Gap.h16,

            // 2. Weekly Pulse (Super Autopilot style)
            DashboardEntrance(
              delay: 150,
              child: SuperAutopilotCard(
                description: '${AppStrings.weeklyRecapNarrative}$streak${AppStrings.narrativeDaysAndGut}${data.healingTrend ?? AppStrings.optimizing}${AppStrings.narrativeBasedOnLogs}',
                healingCount: data.healingFoods.length,
                triggerCount: data.triggerFoods.length,
                onTap: () {}, // Static for recap
              ),
            ),
            Gap.h16,

            // 3. Performance & Discovery (Super Style)
            if (recap != null) ...[
              DashboardEntrance(
                delay: 200,
                child: SuperPhysicalGoalCard(
                  title: AppStrings.performanceHighlights.toUpperCase(),
                  subtitle: 'WEEKLY PERFORMANCE',
                  label: '${recap.foodsLogged} foods logged this week. Best day: ${recap.bestDay}.',
                  icon: AppIcons.star,
                  color: AppPalette.green500,
                ),
              ),
              Gap.h16,
              DashboardEntrance(
                delay: 250,
                child: SuperPhysicalGoalCard(
                  title: AppStrings.discovery.toUpperCase(),
                  subtitle: 'AI DISCOVERY',
                  label: highlights.isNotEmpty ? highlights.map((h) => h.text).join(' • ') : 'Keep logging for new patterns.',
                  icon: AppIcons.lightbulb,
                  color: AppPalette.purple,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecapLoadingView extends StatelessWidget {
  const _RecapLoadingView();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).brightness == Brightness.dark ? context.appColorScheme.cardBackground : AppPalette.gray50,
    appBar: const GutAppBar(title: AppStrings.weeklyRecap),
    body: Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p10),
      child: const ShimmerGridLoader(variant: ShimmerVariant.recap),
    ),
  );
}
