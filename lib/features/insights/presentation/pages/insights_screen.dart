import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/ai_insight_details.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/services/usage_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/bottom_sheet_helper.dart';
import 'package:gutgood/core/utils/insight_ui_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/shimmer_grid_loader.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:provider/provider.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<InsightsNotifier>();
    final data = notifier.latestInsight;

    return Scaffold(
      backgroundColor: context.appColorScheme.cardBackground,
      body: RefreshIndicator(
        onRefresh: () => context.read<InsightsNotifier>().generateNewInsight(),
        color: AppPalette.black,
        child: CustomScrollView(
          slivers: [
            GutSliverAppBar(
              title: AppStrings.insights,
              showBrandingIcon: true,
              actions: [
                IconButton(
                  icon: Icon(AppIcons.history, color: context.appColorScheme.textPrimary),
                  onPressed: () => unawaited(context.push(AppRoutes.insightHistory)),
                ),
                Gap.w10,
              ],
            ),
            if (notifier.isLoading) const _InsightsLoadingState() else if (data == null) const _NoInsightsState() else _MainDashboardSliver(data: data),
          ],
        ),
      ),
    );
  }
}

class _NoInsightsState extends StatelessWidget {
  const _NoInsightsState();

  @override
  Widget build(BuildContext context) => const SliverFillRemaining(
    hasScrollBody: false,
    child: EmptyStateWidget(icon: AppIcons.barChart, title: AppStrings.noInsightsYet, description: AppStrings.keepLoggingForPatterns),
  );
}

class _MainDashboardSliver extends StatelessWidget {
  const _MainDashboardSliver({required this.data});
  final AIInsight data;

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<InsightsNotifier>();
    final profile = context.watch<ProfileNotifier>().profile;

    final sections = <Widget?>[
      GutSnapshotHeroCard(score: data.gutScore, scoreDiff: data.scoreDiff, streak: profile?.streak ?? 0),
      TrendCard(insights: notifier.insightHistory, currentInsight: data),

      if (data.healingGoal != null || data.triggerSymptom != null)
        DashboardEntrance(
          delay: 100,
          child: GutDashboardSection(
            title: AppStrings.topBodyInsights,
            subtitle: AppStrings.primaryObjectives,
            visualization: const DashboardVisualizationBar(ratio: 0.65, label: AppStrings.trackingStability),
            items: [
              if (data.healingGoal != null) DashboardDetailItem(title: data.healingGoal!, subtitle: AppStrings.activeGoal, icon: AppIcons.target, color: context.appColorScheme.success),
              if (data.healingGoal != null && data.triggerSymptom != null) Gap.h12,
              if (data.triggerSymptom != null) DashboardDetailItem(title: data.triggerSymptom!, subtitle: AppStrings.symptomWatch, icon: AppIcons.activity, color: context.appColorScheme.warning),
            ],
            footerLabel: AppStrings.viewGoalProgress,
            onFooterTap: () => _showFocusDetails(context),
          ),
        ),
      if (data.healingFoods.isNotEmpty || data.foodImpacts.any((i) => i.impactType == 'positive'))
        DashboardEntrance(
          delay: 200,
          child: GutDashboardSection(
            title: 'POWER SOURCES',
            subtitle: AppStrings.foodsToPrioritize,
            visualization: const DashboardVisualizationBar(ratio: 0.85, label: AppStrings.highHealingDensity),
            items: [
              ...data.healingFoods
                  .take(2)
                  .map(
                    (f) => Padding(
                      padding: EdgeInsets.only(bottom: AppSizes.p12),
                      child: DashboardDetailItem(title: f.name, subtitle: f.effect, icon: InsightUiUtils.getReactionIcon(f.emoji), color: context.appColorScheme.success),
                    ),
                  ),
              ...data.foodImpacts
                  .where((i) => i.impactType == 'positive' && i.food != 'Unknown')
                  .take(2)
                  .map(
                    (i) => Padding(
                      padding: EdgeInsets.only(bottom: AppSizes.p12),
                      child: DashboardDetailItem(title: i.food, subtitle: i.effect, icon: InsightUiUtils.getReactionIcon(i.emoji), color: context.appColorScheme.success),
                    ),
                  ),
            ].take(3).toList(),
            footerLabel: 'View All Power Sources',
            onFooterTap: () => _showPowerSourcesDetails(context),
            titleColor: context.appColorScheme.success,
          ),
        ),
      if (data.triggerFoods.isNotEmpty || data.foodImpacts.any((i) => i.impactType == 'negative'))
        DashboardEntrance(
          delay: 250,
          child: GutDashboardSection(
            title: 'SYSTEM TRIGGERS',
            subtitle: AppStrings.foodsToMinimize,
            visualization: const DashboardVisualizationBar(ratio: 0.35, label: 'Active Triggers'),
            items: [
              ...data.triggerFoods
                  .take(2)
                  .map(
                    (f) => Padding(
                      padding: EdgeInsets.only(bottom: AppSizes.p12),
                      child: DashboardDetailItem(title: f.name, subtitle: f.effect, icon: InsightUiUtils.getReactionIcon(f.emoji), color: context.appColorScheme.error),
                    ),
                  ),
              ...data.foodImpacts
                  .where((i) => i.impactType == 'negative' && i.food != 'Unknown')
                  .take(2)
                  .map(
                    (i) => Padding(
                      padding: EdgeInsets.only(bottom: AppSizes.p12),
                      child: DashboardDetailItem(title: i.food, subtitle: i.effect, icon: InsightUiUtils.getReactionIcon(i.emoji), color: context.appColorScheme.error),
                    ),
                  ),
            ].take(3).toList(),
            footerLabel: 'View All Triggers',
            onFooterTap: () => _showTriggersDetails(context),
            titleColor: context.appColorScheme.error,
          ),
        ),
      if (data.detectedPatterns.isNotEmpty)
        DashboardEntrance(
          delay: 300,
          child: GutDashboardSection(
            title: AppStrings.aiPatterns,
            subtitle: AppStrings.detectedPatterns,
            visualization: const DashboardVisualizationBar(ratio: 0.4, label: AppStrings.behavioralVariance),
            items: data.detectedPatterns.take(2).map((p) {
              final color = InsightUiUtils.getPatternColor(p.icon);
              return Padding(
                padding: EdgeInsets.only(bottom: AppSizes.p12),
                child: DashboardDetailItem(title: p.title, subtitle: AppStrings.observation, icon: InsightUiUtils.getReactionIcon(p.icon), color: color),
              );
            }).toList(),
            footerLabel: AppStrings.viewPatternAnalysis,
            onFooterTap: () => _showTrendDetails(context),
          ),
        ),
      if (notifier.bodyPatterns.isNotEmpty)
        DashboardEntrance(
          delay: 320,
          child: GutDashboardSection(
            title: 'SYSTEM DISCOVERIES',
            subtitle: 'Evidence-based correlations',
            visualization: Container(
              padding: EdgeInsets.all(AppSizes.p12),
              decoration: BoxDecoration(color: context.appColorScheme.border.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(AppIcons.database, color: context.appColorScheme.textPrimary, size: AppSizes.icon32),
            ),
            items: notifier.bodyPatterns
                .take(2)
                .map(
                  (p) => Padding(
                    padding: EdgeInsets.only(bottom: AppSizes.p12),
                    child: DashboardDetailItem(title: p.trigger, subtitle: p.reaction, icon: AppIcons.activity, color: context.appColorScheme.textPrimary),
                  ),
                )
                .toList(),
            footerLabel: 'View All Correlations',
            onFooterTap: () => _showSystemDiscoveryDetails(context, notifier.bodyPatterns),
          ),
        ),
      if (data.topHealing != null || data.topTrigger != null)
        DashboardEntrance(
          delay: 350,
          child: GutDashboardSection(
            title: AppStrings.performanceHighlights,
            subtitle: AppStrings.performanceHighs,
            visualization: const DashboardVisualizationBar(ratio: 0.75, label: AppStrings.optimizationEfficiency),
            items: [
              if (data.topHealing != null)
                DashboardDetailItem(
                  title: data.topHealing!.food,
                  subtitle: AppStrings.bestForGut,
                  icon: InsightUiUtils.getReactionIcon(data.topHealing?.emoji ?? ''),
                  color: context.appColorScheme.success,
                ),
              if (data.topHealing != null && data.topTrigger != null) Gap.h12,
              if (data.topTrigger != null)
                DashboardDetailItem(
                  title: data.topTrigger!.food,
                  subtitle: AppStrings.avoidNextTime,
                  icon: InsightUiUtils.getReactionIcon(data.topTrigger?.emoji ?? ''),
                  color: context.appColorScheme.error,
                ),
            ],
            footerLabel: AppStrings.viewPerformanceHighs,
            onFooterTap: () => _showHighlightDetails(context),
            titleColor: context.appColorScheme.textPrimary,
          ),
        ),
      if (data.topInsight != null) _ModernSmartAlert(insight: data.topInsight!),
      GutActionBanner(
        title: AppStrings.weeklyGutRecap,
        subtitle: AppStrings.last7DaysReady,
        icon: AppIcons.sparkles,
        onTap: () async {
          final isPremium = await sl<UsageService>().isPremium();
          if (!context.mounted) return;
          if (isPremium) {
            unawaited(context.push(AppRoutes.weeklyRecap, extra: data.toMap()));
          } else {
            unawaited(showPaywallBottomSheet(context, onProceedWithLimited: () {}));
          }
        },
      ),
    ];

    final visibleSections = sections.whereType<Widget>().toList();

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(AppSizes.p20, 0, AppSizes.p20, AppSizes.p20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final isLast = index == visibleSections.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? AppSizes.p64 : AppSizes.p32),
            child: visibleSections[index],
          );
        }, childCount: visibleSections.length),
      ),
    );
  }

  void _showFocusDetails(BuildContext context) {
    BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: AppStrings.currentFocus,
      children: [
        SheetHeroSection(title: AppStrings.target, subtitle: AppStrings.healthGoals, color: context.appColorScheme.textPrimary, icon: AppIcons.target),
        Gap.h32,
        if (data.healingGoal != null) DashboardDetailItem(title: data.healingGoal!, subtitle: AppStrings.primaryHealingObjective, icon: AppIcons.leaf, color: context.appColorScheme.success),
        Gap.h16,
        if (data.triggerSymptom != null)
          DashboardDetailItem(title: data.triggerSymptom!, subtitle: AppStrings.symptomTrackedForPatterns, icon: AppIcons.alertTriangle, color: context.appColorScheme.warning),
        Gap.h32,
        GutButton(label: AppStrings.gotItThanks, onTap: () => context.pop()),
        Gap.h24,
      ],
    );
  }

  void _showPowerSourcesDetails(BuildContext context) {
    final healing = data.healingFoods;
    final successes = data.foodImpacts.where((i) => i.impactType == 'positive' && i.food != 'Unknown').toList();

    BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: 'Power Sources',
      children: [
        SheetHeroSection(title: AppStrings.heal, subtitle: 'Evidence-backed benefits', color: context.appColorScheme.success, icon: AppIcons.leaf),
        Gap.h32,
        if (healing.isNotEmpty) ...[
          SheetSectionHeader(title: 'AI RECOMMENDATIONS', color: context.appColorScheme.textPrimary),
          ...healing.map(
            (f) => Padding(
              padding: EdgeInsets.only(bottom: 16.0.h),
              child: DashboardDetailItem(title: f.name, subtitle: f.effect, icon: InsightUiUtils.getReactionIcon(f.emoji), color: context.appColorScheme.success),
            ),
          ),
          Gap.h24,
        ],
        if (successes.isNotEmpty) ...[
          SheetSectionHeader(title: 'YOUR SUCCESSES', color: context.appColorScheme.textPrimary),
          ...successes.map(
            (i) => Padding(
              padding: EdgeInsets.only(bottom: 16.0.h),
              child: DashboardDetailItem(title: i.food, subtitle: '${i.timeframeLabel}: ${i.effect}', icon: InsightUiUtils.getReactionIcon(i.emoji), color: context.appColorScheme.success),
            ),
          ),
          Gap.h24,
        ],
        Gap.h32,
        GutButton(label: AppStrings.gotItThanks, onTap: () => context.pop()),
        Gap.h24,
      ],
    );
  }

  void _showTriggersDetails(BuildContext context) {
    final triggers = data.triggerFoods;
    final reactions = data.foodImpacts.where((i) => i.impactType == 'negative' && i.food != 'Unknown').toList();

    BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: 'System Triggers',
      children: [
        SheetHeroSection(title: 'ALERT', subtitle: 'Potential Triggers', color: context.appColorScheme.error, icon: AppIcons.alertTriangle),
        Gap.h32,
        if (triggers.isNotEmpty) ...[
          SheetSectionHeader(title: 'AI WARNINGS', color: context.appColorScheme.textPrimary),
          ...triggers.map(
            (f) => Padding(
              padding: EdgeInsets.only(bottom: 16.0.h),
              child: DashboardDetailItem(title: f.name, subtitle: f.effect, icon: InsightUiUtils.getReactionIcon(f.emoji), color: context.appColorScheme.error),
            ),
          ),
          Gap.h24,
        ],
        if (reactions.isNotEmpty) ...[
          SheetSectionHeader(title: 'YOUR REACTIONS', color: context.appColorScheme.textPrimary),
          ...reactions.map(
            (i) => Padding(
              padding: EdgeInsets.only(bottom: 16.0.h),
              child: DashboardDetailItem(title: i.food, subtitle: '${i.timeframeLabel}: ${i.effect}', icon: InsightUiUtils.getReactionIcon(i.emoji), color: context.appColorScheme.error),
            ),
          ),
          Gap.h24,
        ],
        Gap.h32,
        GutButton(label: AppStrings.gotItThanks, onTap: () => context.pop()),
        Gap.h24,
      ],
    );
  }

  void _showTrendDetails(BuildContext context) {
    BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: AppStrings.detectedPatterns,
      children: [
        SheetHeroSection(title: AppStrings.trends, subtitle: AppStrings.behavioralAnalysis, color: context.appColorScheme.textPrimary, icon: AppIcons.activity),
        Gap.h32,
        ...data.detectedPatterns.map(
          (p) => Padding(
            padding: EdgeInsets.only(bottom: AppSizes.p16),
            child: DashboardDetailItem(title: p.title, subtitle: p.description, icon: InsightUiUtils.getReactionIcon(p.icon), color: InsightUiUtils.getPatternColor(p.icon)),
          ),
        ),
        Gap.h32,
        GutButton(label: AppStrings.gotItThanks, onTap: () => context.pop()),
        Gap.h24,
      ],
    );
  }

  void _showHighlightDetails(BuildContext context) {
    BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: AppStrings.performanceHighlights,
      children: [
        SheetHeroSection(title: AppStrings.bioStats, subtitle: AppStrings.performanceAnalysis, color: context.appColorScheme.textPrimary, icon: AppIcons.trophy),
        Gap.h32,
        if (data.topHealing != null) ...[
          SheetSectionHeader(title: AppStrings.topPerformer, color: context.appColorScheme.textPrimary),
          DashboardDetailItem(
            title: data.topHealing!.food,
            subtitle: data.topHealing!.effects,
            icon: InsightUiUtils.getReactionIcon(data.topHealing?.emoji ?? ''),
            color: context.appColorScheme.textPrimary,
          ),
          Gap.h24,
        ],
        if (data.topTrigger != null) ...[
          SheetSectionHeader(title: AppStrings.criticalTrigger, color: context.appColorScheme.textPrimary),
          DashboardDetailItem(
            title: data.topTrigger!.food,
            subtitle: data.topTrigger!.effects,
            icon: InsightUiUtils.getReactionIcon(data.topTrigger?.emoji ?? ''),
            color: context.appColorScheme.textPrimary,
          ),
          Gap.h24,
        ],
        Gap.h32,
        GutButton(label: AppStrings.gotItThanks, onTap: () => context.pop()),
        Gap.h24,
      ],
    );
  }

  void _showSystemDiscoveryDetails(BuildContext context, List<BodyPattern> patterns) {
    BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: 'SYSTEM DISCOVERIES',
      children: [
        SheetHeroSection(title: 'DATA', subtitle: 'Verified Correlations', color: context.appColorScheme.textPrimary, icon: AppIcons.database),
        Gap.h32,
        ...patterns.map(
          (p) => Padding(
            padding: EdgeInsets.only(bottom: AppSizes.p16),
            child: DashboardDetailItem(title: p.trigger, subtitle: p.description, icon: AppIcons.checkCircle, color: context.appColorScheme.textPrimary),
          ),
        ),
        Gap.h32,
        GutButton(label: AppStrings.gotItThanks, onTap: () => context.pop()),
        Gap.h24,
      ],
    );
  }
}

class _ModernSmartAlert extends StatelessWidget {
  const _ModernSmartAlert({required this.insight});
  final InsightSummary insight;

  @override
  Widget build(BuildContext context) => ModernInsightCard(
    title: insight.title,
    icon: AppIcons.sparkles,
    backgroundColor: context.appColorScheme.cardBackground,
    titleColor: context.appColorScheme.textPrimary,
    iconColor: context.appColorScheme.textPrimary,
    padding: EdgeInsets.fromLTRB(AppSizes.p20, 0, AppSizes.p20, AppSizes.p20),
    footer: Text(
      '${insight.type.toUpperCase()} INSIGHT',
      textAlign: TextAlign.center,
      style: context.caption.copyWith(color: context.appColorScheme.cardBackground, fontWeight: FontWeight.w900, fontSize: AppSizes.s10, letterSpacing: 1.0),
    ),
    footerColor: context.appColorScheme.textPrimary,
    child: Text(
      insight.description,
      style: context.bodySm.copyWith(color: context.appColorScheme.textPrimary, height: 1.4, fontWeight: FontWeight.w500),
    ),
  );
}

class _InsightsLoadingState extends StatelessWidget {
  const _InsightsLoadingState();

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: EdgeInsets.fromLTRB(AppSizes.p20, 0, AppSizes.p20, AppSizes.p10),
    sliver: SliverList(
      delegate: SliverChildListDelegate([
        const ShimmerGridLoader(itemCount: 1, crossAxisCount: 1, variant: ShimmerVariant.hero),
        Gap.h32,
        const ShimmerGridLoader(itemCount: 1, crossAxisCount: 1, variant: ShimmerVariant.card),
        Gap.h32,
        const ShimmerGridLoader(itemCount: 4, variant: ShimmerVariant.grid),
      ]),
    ),
  );
}
