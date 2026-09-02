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
import 'package:gutgood/features/insights/presentation/widgets/insight_dashboard_sections.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_dashboard_view.dart';
import 'package:gutgood/features/insights/presentation/widgets/modern_gut_score_card.dart';
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
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? context.appColorScheme.cardBackground : AppPalette.gray50,
      body: CustomScrollView(
        slivers: [
          const GutSliverAppBar(title: AppStrings.weeklyRecap, showBrandingIcon: false),
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
            // 1. Weekly Average Hero (Modern Style)
            DashboardEntrance(
              delay: 50,
              child: ModernGutScoreCard(
                score: recap?.avgScore ?? 0,
                title: 'WEEKLY AVERAGE',
                showDetails: false,
                description: recap?.dateRange ?? 'Last 7 Days',
                onTap: () {}, // Static view
              ),
            ),
            Gap.h16,

            // 2. Weekly Metrics Grid
            DashboardEntrance(
              delay: 100,
              child: InsightMetricGrid(data: data, streak: streak),
            ),
            Gap.h16,

            // 3. Weekly Pulse (AI Intelligence) - Hero Style
            DashboardEntrance(
              delay: 150,
              child: IntelligencePulseCard(
                title: AppStrings.weeklyPulse,
                description: '${AppStrings.weeklyRecapNarrative}$streak${AppStrings.narrativeDaysAndGut}${data.healingTrend ?? AppStrings.optimizing}${AppStrings.narrativeBasedOnLogs}',
                index: 1,
                onTap: () {}, // Static for recap
              ),
            ),
            Gap.h16,

            // 4. Performance & Discovery (Unified UI/UX)
            if (recap != null) ...[
              BentoFoodCard(
                title: AppStrings.performanceHighlights.toUpperCase(),
                foods: [HealingFood(name: '${recap.foodsLogged} FOODS LOGGED', effect: 'Best: ${recap.bestDay}', emoji: '⭐')],
                isPositive: true,
                icon: AppIcons.star,
                trend: data.healingTrend ?? 'Stable weekly trend.',
              ),
              Gap.h12,
              BentoFoodCard(
                title: AppStrings.discovery.toUpperCase(),
                foods: highlights,
                isPositive: true,
                icon: AppIcons.lightbulb,
                trend: highlights.isNotEmpty ? 'AI identified ${highlights.length} patterns.' : 'Keep logging for new patterns.',
              ),
            ],
            Gap.h40,
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
