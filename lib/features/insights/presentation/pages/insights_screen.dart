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
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
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
    var icon = AppIcons.barChart;

    if (scans == 0 && meals == 0) {
      title = AppStrings.keepLoggingForPatterns;
      description = AppStrings.understandBodyImpact;
    } else if (scans < 3 && meals < 3) {
      title = AppStrings.loggingMoreMeals;
      description = AppStrings.keepLoggingForHighlights;
    } else if (symptoms == 0) {
      title = AppStrings.greatConsistency;
      description = AppStrings.understandBodyImpact;
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
        _ProgressRow(label: AppStrings.logs, progress: mealProgress, count: meals, total: 3),
        Gap.h12,
        _ProgressRow(label: AppStrings.symptoms, progress: symptomProgress, count: symptoms, total: 1),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            AppStrings.orContinueWith,
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: context.appColorScheme.textSecondary),
          ),
        ),
        _ProgressRow(label: AppStrings.aiScanHistory, progress: scanProgress, count: scans, total: 3),
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
          backgroundColor: context.appColorScheme.borderSubtle,
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
    final streak = profile.streak;

    final sections = _buildSections(context: context, streak: streak);

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
            metric: AppStrings.target,
            label: AppStrings.currentFocus,
            icon: AppIcons.target,
            glowColor: AppPalette.blue,
            items: [
              if (data.healingGoal != null) AnalysisItem(title: '${AppStrings.heal}: ${data.healingGoal!.toUpperCase()}', subtitle: AppStrings.primaryHealingObjective, icon: AppIcons.leaf, isDone: true),
              if (data.triggerSymptom != null) AnalysisItem(title: '${AppStrings.symptomWatch}: ${data.triggerSymptom!.toUpperCase()}', subtitle: AppStrings.symptomTrackedForPatterns, icon: AppIcons.activity),
            ],
          ),
        ),
      );
    }

    // 2. BETTER ENERGY (healingFoods)
    if (data.healingFoods.isNotEmpty || data.foodImpacts.any((i) => i.impactType == 'positive')) {
      final healingCount = data.healingFoods.length + data.foodImpacts.where((i) => i.impactType == 'positive').length;
      final label = data.healingTrend != null ? '${AppStrings.betterEnergy} • ${data.healingTrend}' : AppStrings.betterEnergy;

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
      final label = data.triggerTrend != null ? '${AppStrings.bloating} • ${data.triggerTrend}' : AppStrings.bloating;

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

    // 4. INDIVIDUAL PATTERN CARDS
    final displayPatterns = patterns.isNotEmpty ? patterns : data.detectedPatterns;

    if (displayPatterns.isNotEmpty) {
      for (var i = 0; i < displayPatterns.length; i++) {
        final p = displayPatterns[i];
        sections.add(
          DashboardEntrance(
            delay: 300 + (i * 100),
            child: AnalysisCard(
              metric: p.frequency.toString(),
              label: InsightUiUtils.getPatternName(p.type),
              icon: InsightUiUtils.getPatternTypeIcon(p.type),
              glowColor: context.appColorScheme.textPrimary,
              onTap: () => context.push(AppRoutes.patternDetail, extra: p),
              items: [AnalysisItem(title: p.trigger.toUpperCase(), subtitle: p.description, icon: AppIcons.lightbulb, color: context.appColorScheme.textPrimary)],
            ),
          ),
        );
      }
    }

    // 5. RECENT PATTERNS (foodImpacts)
    if (data.foodImpacts.isNotEmpty) {
      sections.add(
        DashboardEntrance(
          delay: 400,
          child: AnalysisCard(
            metric: '${data.foodImpacts.length}',
            label: AppStrings.recentActivityTitle,
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
            metric: data.topHealing?.frequency ?? AppStrings.champion,
            label: AppStrings.performanceAnalysis,
            icon: AppIcons.trophy,
            glowColor: AppPalette.green,
            items: [
              if (data.topHealing != null) AnalysisItem(title: '${AppStrings.topPerformer}: ${data.topHealing!.food}', subtitle: data.topHealing!.effects, icon: AppIcons.star),
              if (data.topTrigger != null) AnalysisItem(title: '${AppStrings.mostReactive}: ${data.topTrigger!.food}', subtitle: data.topTrigger!.effects, icon: AppIcons.alertTriangle),
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
      Padding(
        padding: EdgeInsets.only(top: AppSizes.p10),
        child: GutActionBanner(
          title: AppStrings.weeklyGutRecap.toUpperCase(),
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
