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
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/insight_ui_utils.dart';
import 'package:gutgood/core/utils/quota_guard.dart';
import 'package:gutgood/core/widgets/shimmer_grid_loader.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
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
          final patterns = notifier.prioritizedPatterns;
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
              if (isLoading)
                const _InsightsLoadingState()
              else if (patterns.isEmpty && latestInsight == null)
                const _NoInsightsState()
              else
                _MainDashboardSliver(latestInsight: latestInsight, patterns: patterns),
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
              child: Icon(AppIcons.brain, size: 48, color: context.appColorScheme.textPrimary),
            ),
            Gap.h24,
            Text(
              'Analyzing your patterns...',
              style: AppTextStyles.title.copyWith(color: context.appColorScheme.textPrimary),
              textAlign: TextAlign.center,
            ),
            Gap.h12,
            Text(
              'Keep logging your meals and symptoms. GutGood needs more information before it can identify personalized patterns.',
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
    final symptomProgress = (symptoms / 3).clamp(0.0, 1.0);

    return Column(
      children: [
        _ProgressRow(label: 'Recent Meals', progress: mealProgress, count: meals, total: 3),
        Gap.h16,
        _ProgressRow(label: 'Symptom Logs', progress: symptomProgress, count: symptoms, total: 3),
        Gap.h24,
        Text(
          'Target: At least 3 of each to unlock insights',
          style: AppTextStyles.caption.copyWith(color: context.appColorScheme.textMuted, fontWeight: FontWeight.w600),
        ),
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
          minHeight: 8,
          backgroundColor: context.appColorScheme.border.withValues(alpha: 0.3),
          valueColor: AlwaysStoppedAnimation<Color>(context.appColorScheme.textPrimary),
        ),
      ),
    ],
  );
}

class _MainDashboardSliver extends StatelessWidget {
  const _MainDashboardSliver({this.latestInsight, required this.patterns});
  final AIInsight? latestInsight;
  final List<BodyPattern> patterns;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileNotifier>();
    final streak = profile.profile?.streak ?? 0;
    final gutScore = latestInsight?.gutScore ?? profile.profile?.gutScore ?? 0;

    // Filter out the top insight from patterns list if it's already shown as a Smart Alert
    final displayPatterns = latestInsight?.topInsight != null ? patterns.where((p) => p.trigger != latestInsight!.topInsight!.title).toList() : patterns;

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p10),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          GutSnapshotHeroCard(score: gutScore, scoreDiff: latestInsight?.scoreDiff, streak: streak),
          Gap.h24,
          if (latestInsight?.topInsight != null) ...[ModernSmartAlert(insight: latestInsight!.topInsight!), Gap.h24],
          if (latestInsight != null && (latestInsight!.healingGoal != null || latestInsight!.triggerSymptom != null)) ...[GoalDashboardSection(insight: latestInsight!), Gap.h24],
          ...displayPatterns.map(
            (p) => Padding(
              padding: EdgeInsets.only(bottom: AppSizes.p24),
              child: _DynamicPatternCard(pattern: p),
            ),
          ),
          if (latestInsight != null) ...[
            if (latestInsight!.healingFoods.isNotEmpty || latestInsight!.foodImpacts.any((i) => i.impactType == 'positive')) ...[PowerSourcesDashboardSection(insight: latestInsight!), Gap.h24],
            if (latestInsight!.triggerFoods.isNotEmpty || latestInsight!.foodImpacts.any((i) => i.impactType == 'negative')) ...[TriggersDashboardSection(insight: latestInsight!), Gap.h24],
            Gap.h8,
            GutActionBanner(
              title: AppStrings.weeklyGutRecap,
              subtitle: AppStrings.last7DaysReady,
              icon: AppIcons.salad,
              onTap: () async {
                if (await QuotaGuard.check(context, type: QuotaType.premium)) {
                  if (context.mounted) {
                    unawaited(context.push(AppRoutes.weeklyRecap, extra: latestInsight));
                  }
                }
              },
            ),
          ],
          Gap.h40,
        ]),
      ),
    );
  }
}

class _DynamicPatternCard extends StatelessWidget {
  const _DynamicPatternCard({required this.pattern});
  final BodyPattern pattern;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;
    final patternIcon = InsightUiUtils.getPatternTypeIcon(pattern.type);

    return ModernInsightCard(
      title: '${pattern.type} pattern',
      icon: patternIcon,
      iconColor: colorScheme.textPrimary,
      backgroundColor: colorScheme.cardBackground,
      onTap: () => context.push(AppRoutes.patternDetail, extra: pattern),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${pattern.confidence.toUpperCase()} CONFIDENCE',
            style: context.caption.copyWith(color: colorScheme.cardBackground, fontWeight: FontWeight.w900, fontSize: AppSizes.s10, letterSpacing: 1.2),
          ),
          Gap.w8,
          Icon(Icons.arrow_forward, size: 12, color: colorScheme.cardBackground),
        ],
      ),
      footerColor: colorScheme.textPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pattern.description,
            style: context.body.copyWith(color: colorScheme.textPrimary, height: 1.5, fontWeight: FontWeight.w500),
          ),
          Gap.h16,
          if (pattern.involvedFoods.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: pattern.involvedFoods
                  .take(3)
                  .map(
                    (food) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.textPrimary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.textPrimary.withValues(alpha: 0.1)),
                      ),
                      child: Text(
                        food,
                        style: context.caption.copyWith(color: colorScheme.textPrimary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                  .toList(),
            ),
            Gap.h12,
          ],
        ],
      ),
    );
  }
}

class _InsightsLoadingState extends StatelessWidget {
  const _InsightsLoadingState();

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: EdgeInsets.fromLTRB(AppSizes.p20, 0, AppSizes.p20, AppSizes.p10),
    sliver: const SliverToBoxAdapter(child: ShimmerGridLoader(itemCount: 3, variant: ShimmerVariant.scanResult)),
  );
}
