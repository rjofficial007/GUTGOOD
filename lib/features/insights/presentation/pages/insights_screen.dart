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
import 'package:gutgood/core/utils/extensions.dart';
import 'package:gutgood/core/utils/insight_ui_utils.dart';
import 'package:gutgood/core/utils/quota_guard.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_dashboard_sections.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:provider/provider.dart';

import '../../../../features/product_details/presentation/widgets/scan_result_widgets.dart';

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
              if (isLoading)
                const _InsightsLoadingState()
              else if (latestInsight == null)
                const _NoInsightsState()
              else
                _MainDashboardSliver(data: latestInsight, patterns: prioritizedPatterns),
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
    final notifier = context.watch<InsightsNotifier>();

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Snapshot Hero (Premium Bento Style)
            DashboardEntrance(
              delay: 50,
              child: GutSnapshotHeroCard(score: data.gutScore, scoreDiff: data.scoreDiff, streak: streak),
            ),
            Gap.h12,

            // 2. Metrics Quick View
            DashboardEntrance(
              delay: 100,
              child: InsightMetricGrid(data: data, notifier: notifier),
            ),
            Gap.h12,

            // 3. Strategic Summary
            if (data.healingGoal != null || data.triggerSymptom != null)
              DashboardEntrance(
                delay: 150,
                child: Row(
                  children: [
                    if (data.healingGoal != null)
                      Expanded(
                        child: BentoCard(
                          padding: const EdgeInsets.all(12),
                          height: 180.h,
                          backgroundColor: AppPalette.bluePastel,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('TARGET', style: context.captionMicro.copyWith(color: AppPalette.blue, fontWeight: FontWeight.w900)),
                                  Icon(AppIcons.target, size: 14, color: AppPalette.blue),
                                ],
                              ),
                              const Spacer(),
                              Text(data.healingGoal!.toUpperCase(), style: context.bodyBold.copyWith(color: AppPalette.black, fontWeight: FontWeight.w900, fontSize: 16.sp, height: 1.1)),
                              Text(AppStrings.primaryHealingObjective, style: context.captionMicro.copyWith(color: AppPalette.black.withAlpha(153))),
                              const Spacer(),
                            ],
                          ),
                        ),
                      ),
                    if (data.healingGoal != null && data.triggerSymptom != null) Gap.w12,
                    if (data.triggerSymptom != null)
                      Expanded(
                        child: BentoCard(
                          padding: const EdgeInsets.all(12),
                          height: 180.h,
                          backgroundColor: AppPalette.purplePastel,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('WATCH LIST', style: context.captionMicro.copyWith(color: AppPalette.purple, fontWeight: FontWeight.w900)),
                                  Icon(AppIcons.activity, size: 14, color: AppPalette.purple),
                                ],
                              ),
                              const Spacer(),
                              Text(data.triggerSymptom!.toUpperCase(), style: context.bodyBold.copyWith(color: AppPalette.black, fontWeight: FontWeight.w900, fontSize: 16.sp, height: 1.1)),
                              Text(AppStrings.symptomTrackedForPatterns, style: context.captionMicro.copyWith(color: AppPalette.black.withAlpha(153))),
                              const Spacer(),
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
                  height: 180.h,
                  backgroundColor: AppPalette.greenPastel,
                  child: Row(
                    children: [
                      // Left block: Healing Score/Count
                      Container(
                        width: 136.h,
                        height: 136.h,
                        decoration: BoxDecoration(color: AppPalette.white.withAlpha(204), borderRadius: BorderRadius.circular(16)),
                        child: Stack(
                          children: [
                             Positioned(
                              top: 12, left: 12,
                              child: Icon(AppIcons.zap, size: 14, color: AppPalette.green),
                             ),
                             Center(child: Text('${data.healingFoods.length}', style: context.displayHero.copyWith(color: AppPalette.black, fontSize: 64.sp, letterSpacing: -4))),
                             Positioned(bottom: 12, left: 12, right: 12, child: Text('HEALING', textAlign: TextAlign.center, style: context.captionMicro.copyWith(color: AppPalette.black, fontWeight: FontWeight.w900))),
                          ],
                        ),
                      ),
                      Gap.w16,
                      // Right info: Vertical Cycler
                      Expanded(
                        child: BentoFoodCycler(
                          foods: data.healingFoods, 
                          title: AppStrings.betterEnergy, 
                          trend: data.healingTrend, 
                          isPositive: true,
                        ),
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
                  height: 180.h,
                  backgroundColor: context.appColorScheme.errorSubtle,
                  child: Row(
                    children: [
                      // Left block: Trigger Count
                      Container(
                        width: 136.h,
                        height: 136.h,
                        decoration: BoxDecoration(color: AppPalette.white.withAlpha(204), borderRadius: BorderRadius.circular(16)),
                        child: Stack(
                          children: [
                             Positioned(
                              top: 12, left: 12,
                              child: Icon(AppIcons.alertTriangle, size: 14, color: AppPalette.red),
                             ),
                             Center(child: Text('${data.triggerFoods.length}', style: context.displayHero.copyWith(color: AppPalette.black, fontSize: 64.sp, letterSpacing: -4))),
                             Positioned(bottom: 12, left: 12, right: 12, child: Text('TRIGGERS', textAlign: TextAlign.center, style: context.captionMicro.copyWith(color: AppPalette.black, fontWeight: FontWeight.w900))),
                          ],
                        ),
                      ),
                      Gap.w16,
                      // Right info
                      Expanded(
                        child: BentoFoodCycler(
                          foods: data.triggerFoods, 
                          title: AppStrings.bloating, 
                          trend: data.triggerTrend, 
                          isPositive: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (data.triggerFoods.isNotEmpty || data.topTrigger != null) Gap.h12,

            // 5. Individual Pattern Discoveries (Identity cards style)
            ..._buildPatternCards(context, patterns.isNotEmpty ? patterns : data.detectedPatterns),

            // 6. Recent Body Feedback (Bento Cycler)
            if (data.foodImpacts.isNotEmpty) ...[
              BentoActivityCard(impacts: data.foodImpacts),
              Gap.h12,
            ],

            // 7. AI Intelligence Card
            if (data.topInsight != null) ...[
              DashboardEntrance(
                delay: 450,
                child: ModernSmartAlert(insight: data.topInsight!),
              ),
              Gap.h24,
            ],

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
    
    for (var i = 0; i < patterns.length; i++) {
      final p = patterns[i];
      final themeColor = InsightUiUtils.getPatternPastelColor(p.type);
      final accentColor = InsightUiUtils.getPatternColor(p.type);

      widgets.add(
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
      );
      widgets.add(Gap.h12);
    }
    return widgets;
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
