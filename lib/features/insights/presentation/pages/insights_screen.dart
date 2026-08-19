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
import 'package:gutgood/core/utils/quota_guard.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/shimmer_grid_loader.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/analysis_card.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_dashboard_sections.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:provider/provider.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;

    return Scaffold(
      backgroundColor: colorScheme.cardBackground,
      body: Consumer<InsightsNotifier>(
        builder: (context, notifier, _) {
          final latestInsight = notifier.latestInsight;
          final prioritizedPatterns = notifier.prioritizedPatterns;
          final isLoading = notifier.isLoading;

          return CustomScrollView(
            slivers: [
              GutSliverAppBar(
                title: AppStrings.insights,
                actions: [
                  IconButton(
                    icon: Icon(AppIcons.history, color: colorScheme.textPrimary),
                    onPressed: () => unawaited(context.push(AppRoutes.insightHistory)),
                  ),
                  Gap.w10,
                ],
              ),
              if (isLoading) const _InsightsLoadingState() else if (latestInsight == null) const _NoInsightsState() else _MainDashboardSliver(data: latestInsight, patterns: prioritizedPatterns),
            ],
          );
        },
      ),
    );
  }
}

class _NoInsightsState extends StatelessWidget {
  const _NoInsightsState();

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<InsightsNotifier>();
    final meals = notifier.totalMeals;
    final symptoms = notifier.totalSymptoms;
    final scans = notifier.totalScans;

    String title;
    String description;
    IconData icon = AppIcons.barChart;

    if (scans == 0 && meals == 0) {
      title = 'Keep logging meals.';
      description = 'GutGood needs a little more information before it can identify patterns.';
    } else if (scans < 3 && meals < 3) {
      title = "You're getting closer.";
      description = 'Log a few more meals and symptoms so GutGood can start identifying meaningful trends.';
    } else if (symptoms == 0) {
      title = 'Meals recorded ✔';
      description = "Add a few symptom check-ins so GutGood can connect food with how you're feeling.";
      icon = AppIcons.activity;
    } else {
      title = AppStrings.noInsightsYet;
      description = AppStrings.keepLoggingForPatterns;
    }

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: EdgeInsets.all(AppSizes.p40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(AppSizes.p24),
              decoration: BoxDecoration(color: context.appColorScheme.aiResponseBackground, shape: BoxShape.circle),
              child: Icon(icon, size: 48, color: context.appColorScheme.textPrimary),
            ),
            Gap.h24,
            Text(
              title,
              style: AppTextStyles.title.copyWith(color: context.appColorScheme.textPrimary),
              textAlign: TextAlign.center,
            ),
            Gap.h12,
            Text(
              description,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm.copyWith(color: context.appColorScheme.textSecondary),
            ),
            Gap.h32,
            _ProgressIndicator(meals: meals, symptoms: symptoms, scans: scans),
          ],
        ),
      ),
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({required this.meals, required this.symptoms, required this.scans});
  final int meals;
  final int symptoms;
  final int scans;

  @override
  Widget build(BuildContext context) {
    final mealProgress = (meals / 3).clamp(0.0, 1.0);
    final symptomProgress = (symptoms / 1).clamp(0.0, 1.0);
    final scanProgress = (scans / 3).clamp(0.0, 1.0);

    return Column(
      children: [
        _ProgressRow(label: 'Meals', progress: mealProgress, count: meals, total: 3),
        Gap.h12,
        _ProgressRow(label: 'Symptoms', progress: symptomProgress, count: symptoms, total: 1),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'OR',
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: context.appColorScheme.textSecondary),
          ),
        ),
        _ProgressRow(label: 'AI Scans', progress: scanProgress, count: scans, total: 3),
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.label, required this.progress, required this.count, required this.total});
  final String label;
  final double progress;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label.toUpperCase(), style: AppTextStyles.eyebrow.copyWith(color: context.appColorScheme.textMuted)),
          Text(
            '$count/$total',
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: context.appColorScheme.textSecondary),
          ),
        ],
      ),
      Gap.h6,
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 6,
          backgroundColor: context.appColorScheme.border.withValues(alpha: 0.3),
          valueColor: AlwaysStoppedAnimation<Color>(context.appColorScheme.textPrimary),
        ),
      ),
    ],
  );
}

class _MainDashboardSliver extends StatelessWidget {
  const _MainDashboardSliver({required this.data, required this.patterns});
  final AIInsight data;
  final List<BodyPattern> patterns;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileNotifier>();

    final sections = _buildSections(context: context, streak: profile.profile?.streak ?? 0);

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p10),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: EdgeInsets.only(bottom: AppSizes.p20),
            child: sections[index],
          ),
          childCount: sections.length,
        ),
      ),
    );
  }

  List<Widget> _buildSections({required BuildContext context, required int streak}) {
    final sections = <Widget>[GutSnapshotHeroCard(score: data.gutScore, scoreDiff: data.scoreDiff, streak: streak)];

    // 1. STRATEGIC FOCUS (healingGoal / triggerSymptom)
    if (data.healingGoal != null || data.triggerSymptom != null) {
      sections.add(
        DashboardEntrance(
          delay: 50,
          child: AnalysisCard(
            metric: 'FOCUS',
            label: 'CURRENT STRATEGY',
            icon: AppIcons.target,
            glowColor: AppPalette.blue,
            items: [
              if (data.healingGoal != null) AnalysisItem(title: 'GOAL: ${data.healingGoal!.toUpperCase()}', subtitle: 'Primary healing objective', icon: AppIcons.leaf, isDone: true),
              if (data.triggerSymptom != null) AnalysisItem(title: 'WATCHING: ${data.triggerSymptom!.toUpperCase()}', subtitle: 'Tracking for patterns', icon: AppIcons.activity),
            ],
          ),
        ),
      );
    }

    // 2. BETTER ENERGY (healingFoods)
    if (data.healingFoods.isNotEmpty || data.foodImpacts.any((i) => i.impactType == 'positive')) {
      final healingCount = data.healingFoods.length + data.foodImpacts.where((i) => i.impactType == 'positive').length;
      final label = data.healingTrend != null ? 'BETTER ENERGY • ${data.healingTrend}' : 'BETTER ENERGY';

      sections.add(
        DashboardEntrance(
          delay: 100,
          child: AnalysisCard(
            metric: '$healingCount',
            label: label,
            icon: AppIcons.zap,
            glowColor: AppPalette.green,
            items: [
              ...data.healingFoods.map((f) => AnalysisItem(title: f.name, subtitle: f.effect, icon: AppIcons.check)),
              ...data.foodImpacts.where((i) => i.impactType == 'positive').map((i) => AnalysisItem(title: i.food, subtitle: '${i.timeframeLabel}: ${i.effect}', icon: AppIcons.check)),
            ],
          ),
        ),
      );
    }

    // 3. BLOATING (triggerFoods)
    if (data.triggerFoods.isNotEmpty || data.foodImpacts.any((i) => i.impactType == 'negative')) {
      final triggerCount = data.triggerFoods.length + data.foodImpacts.where((i) => i.impactType == 'negative').length;
      final label = data.triggerTrend != null ? 'BLOATING TRIGGERS • ${data.triggerTrend}' : 'BLOATING TRIGGERS';

      sections.add(
        DashboardEntrance(
          delay: 200,
          child: AnalysisCard(
            metric: '$triggerCount',
            label: label,
            icon: AppIcons.alertTriangle,
            glowColor: AppPalette.red,
            items: [
              ...data.triggerFoods.map((f) => AnalysisItem(title: f.name, subtitle: f.effect, icon: AppIcons.alertCircle)),
              ...data.foodImpacts.where((i) => i.impactType == 'negative').map((i) => AnalysisItem(title: i.food, subtitle: '${i.timeframeLabel}: ${i.effect}', icon: AppIcons.alertCircle)),
            ],
          ),
        ),
      );
    }

    // 4. SYSTEM DISCOVERIES (PatternEngine Data)
    if (patterns.isNotEmpty) {
      sections.add(
        DashboardEntrance(
          delay: 300,
          child: AnalysisCard(
            metric: '${patterns.length}',
            label: 'SYSTEM DISCOVERIES',
            icon: AppIcons.brain,
            glowColor: AppPalette.purple,
            items: patterns.map((p) => AnalysisItem(title: p.trigger.toUpperCase(), subtitle: p.description, icon: AppIcons.lightbulb)).toList(),
          ),
        ),
      );
    }

    // 5. RECENT PATTERNS (foodImpacts)
    if (data.foodImpacts.isNotEmpty) {
      sections.add(
        DashboardEntrance(
          delay: 400,
          child: AnalysisCard(
            metric: '${data.foodImpacts.length}',
            label: 'RECENT LOGS',
            icon: AppIcons.history,
            glowColor: AppPalette.blue,
            items: data.foodImpacts
                .map((i) => AnalysisItem(title: i.food, subtitle: '${i.timeframeLabel}: ${i.effect}', icon: i.impactType == 'positive' ? AppIcons.check : AppIcons.alertCircle))
                .toList(),
          ),
        ),
      );
    }

    // 6. STATISTICAL MVP (topHealing/topTrigger)
    if (data.topHealing != null || data.topTrigger != null) {
      sections.add(
        DashboardEntrance(
          delay: 500,
          child: AnalysisCard(
            metric: data.topHealing?.frequency ?? 'MVP',
            label: 'TOP PERFORMANCE',
            icon: AppIcons.trophy,
            glowColor: AppPalette.green,
            items: [
              if (data.topHealing != null) AnalysisItem(title: 'BEST: ${data.topHealing!.food}', subtitle: data.topHealing!.effects, icon: AppIcons.star),
              if (data.topTrigger != null) AnalysisItem(title: 'MOST REACTIVE: ${data.topTrigger!.food}', subtitle: data.topTrigger!.effects, icon: AppIcons.alertTriangle),
            ],
          ),
        ),
      );
    }

    // 7. AI SMART ALERT
    if (data.topInsight != null) {
      sections.add(ModernSmartAlert(insight: data.topInsight!));
    }

    sections.add(
      GutActionBanner(
        title: AppStrings.weeklyGutRecap,
        subtitle: AppStrings.last7DaysReady,
        icon: AppIcons.salad,
        onTap: () async {
          if (await QuotaGuard.check(context, type: QuotaType.premium)) {
            if (context.mounted) {
              unawaited(context.push(AppRoutes.weeklyRecap, extra: data));
            }
          }
        },
      ),
    );

    return sections;
  }
}

class _InsightsLoadingState extends StatelessWidget {
  const _InsightsLoadingState();

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: EdgeInsets.fromLTRB(AppSizes.p20, 0, AppSizes.p20, AppSizes.p10),
    sliver: const SliverToBoxAdapter(child: ShimmerGridLoader(itemCount: 4, variant: ShimmerVariant.scanResult)),
  );
}
