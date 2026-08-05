import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/ai_insight_details.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/bottom_sheet_helper.dart';
import 'package:gutgood/core/utils/insight_ui_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class InsightDetailScreen extends StatelessWidget {
  const InsightDetailScreen({super.key, required this.insight});
  final AIInsight insight;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM dd, yyyy').format(insight.updatedAt);
    final profile = context.watch<ProfileNotifier>().profile;
    final notifier = context.watch<InsightsNotifier>();

    final sections = <Widget?>[
      // 1. Snapshot Hero (Shared Style)
      GutSnapshotHeroCard(score: insight.gutScore, scoreDiff: insight.scoreDiff, streak: profile?.streak ?? 0, isActive: false),

      // 1b. Trend Chart
      TrendCard(insights: notifier.insightHistory, currentInsight: insight, referenceDate: insight.updatedAt),

      // 2. Summary Alert
      if (insight.topInsight != null) _ModernSmartAlert(insight: insight.topInsight!),

      // 3. Analysis Dashboards
      if (insight.healingGoal != null || insight.triggerSymptom != null)
        DashboardEntrance(
          delay: 100,
          child: GutDashboardSection(
            title: AppStrings.topBodyInsights,
            subtitle: AppStrings.primaryObjectives,
            visualization: const DashboardVisualizationBar(ratio: 0.65, label: AppStrings.trackingStability),
            items: [
              if (insight.healingGoal != null) DashboardDetailItem(title: insight.healingGoal!, subtitle: AppStrings.activeGoal, icon: AppIcons.target, color: context.appColorScheme.success),
              if (insight.healingGoal != null && insight.triggerSymptom != null) Gap.h12,
              if (insight.triggerSymptom != null)
                DashboardDetailItem(title: insight.triggerSymptom!, subtitle: AppStrings.symptomWatch, icon: AppIcons.activity, color: context.appColorScheme.warning),
            ],
            footerLabel: AppStrings.viewGoalProgress,
            onFooterTap: () => _showFocusDetails(context),
          ),
        ),
      if (insight.healingFoods.isNotEmpty || insight.foodImpacts.any((i) => i.impactType == 'positive'))
        DashboardEntrance(
          delay: 200,
          child: GutDashboardSection(
            title: 'POWER SOURCES',
            subtitle: AppStrings.foodsToPrioritize,
            visualization: const DashboardVisualizationBar(ratio: 0.85, label: AppStrings.highHealingDensity),
            items: [
              ...insight.healingFoods
                  .take(2)
                  .map(
                    (f) => Padding(
                      padding: EdgeInsets.only(bottom: AppSizes.p12),
                      child: DashboardDetailItem(title: f.name, subtitle: f.effect, icon: InsightUiUtils.getReactionIcon(f.emoji), color: context.appColorScheme.success),
                    ),
                  ),
              ...insight.foodImpacts
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
      if (insight.triggerFoods.isNotEmpty || insight.foodImpacts.any((i) => i.impactType == 'negative'))
        DashboardEntrance(
          delay: 250,
          child: GutDashboardSection(
            title: 'SYSTEM TRIGGERS',
            subtitle: AppStrings.foodsToMinimize,
            visualization: const DashboardVisualizationBar(ratio: 0.35, label: 'Active Triggers'),
            items: [
              ...insight.triggerFoods
                  .take(2)
                  .map(
                    (f) => Padding(
                      padding: EdgeInsets.only(bottom: AppSizes.p12),
                      child: DashboardDetailItem(title: f.name, subtitle: f.effect, icon: InsightUiUtils.getReactionIcon(f.emoji), color: context.appColorScheme.error),
                    ),
                  ),
              ...insight.foodImpacts
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
      if (insight.detectedPatterns.isNotEmpty)
        DashboardEntrance(
          delay: 300,
          child: GutDashboardSection(
            title: AppStrings.aiPatterns,
            subtitle: AppStrings.detectedPatterns,
            visualization: const DashboardVisualizationBar(ratio: 0.45, label: AppStrings.patternConsistency),
            items: insight.detectedPatterns.take(2).map((p) {
              final color = InsightUiUtils.getPatternColor(p.icon);
              return Padding(
                padding: EdgeInsets.only(bottom: AppSizes.p12),
                child: DashboardDetailItem(title: p.title, subtitle: AppStrings.observation, icon: InsightUiUtils.getReactionIcon(p.icon), color: color),
              );
            }).toList(),
            footerLabel: AppStrings.viewDetailedPatterns,
            onFooterTap: () => _showTrendDetails(context),
          ),
        ),
      if (insight.topHealing != null || insight.topTrigger != null)
        DashboardEntrance(
          delay: 350,
          child: GutDashboardSection(
            title: AppStrings.performanceHighlights,
            subtitle: AppStrings.performanceHighs,
            visualization: const DashboardVisualizationBar(ratio: 0.75, label: AppStrings.optimizationEfficiency),
            items: [
              if (insight.topHealing != null)
                DashboardDetailItem(
                  title: insight.topHealing!.food,
                  subtitle: AppStrings.bestForGut,
                  icon: InsightUiUtils.getReactionIcon(insight.topHealing?.emoji ?? ''),
                  color: context.appColorScheme.success,
                ),
              if (insight.topHealing != null && insight.topTrigger != null) Gap.h12,
              if (insight.topTrigger != null)
                DashboardDetailItem(
                  title: insight.topTrigger!.food,
                  subtitle: AppStrings.avoidNextTime,
                  icon: InsightUiUtils.getReactionIcon(insight.topTrigger?.emoji ?? ''),
                  color: context.appColorScheme.error,
                ),
            ],
            footerLabel: AppStrings.viewPerformanceHighs,
            onFooterTap: () => _showHighlightDetails(context),
            titleColor: context.appColorScheme.textPrimary,
          ),
        ),
    ];

    final visibleSections = sections.whereType<Widget>().toList();

    return Scaffold(
      backgroundColor: context.appColorScheme.cardBackground,
      body: CustomScrollView(
        slivers: [
          GutSliverAppBar(title: '${AppStrings.reportDate}${dateStr.toUpperCase()}', showBrandingIcon: false),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p10),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final isLast = index == visibleSections.length - 1;
                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? AppSizes.p64 : AppSizes.p32),
                  child: visibleSections[index],
                );
              }, childCount: visibleSections.length),
            ),
          ),
        ],
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
        if (insight.healingGoal != null) DashboardDetailItem(title: insight.healingGoal!, subtitle: AppStrings.primaryHealingObjective, icon: AppIcons.leaf, color: context.appColorScheme.success),
        Gap.h16,
        if (insight.triggerSymptom != null)
          DashboardDetailItem(title: insight.triggerSymptom!, subtitle: AppStrings.symptomTrackedForPatterns, icon: AppIcons.alertTriangle, color: context.appColorScheme.warning),
        Gap.h32,
        GutButton(label: AppStrings.gotItThanks, onTap: () => context.pop()),
        Gap.h24,
      ],
    );
  }

  void _showPowerSourcesDetails(BuildContext context) {
    final healing = insight.healingFoods;
    final successes = insight.foodImpacts.where((i) => i.impactType == 'positive' && i.food != 'Unknown').toList();

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
    final triggers = insight.triggerFoods;
    final reactions = insight.foodImpacts.where((i) => i.impactType == 'negative' && i.food != 'Unknown').toList();

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
      title: AppStrings.observedPatterns,
      children: [
        SheetHeroSection(title: AppStrings.trends, subtitle: AppStrings.behavioralAnalysis, color: context.appColorScheme.textPrimary, icon: AppIcons.activity),
        Gap.h32,
        ...insight.detectedPatterns.map(
          (p) => Padding(
            padding: EdgeInsets.only(bottom: AppSizes.p16),
            child: DashboardDetailItem(title: p.title, subtitle: p.description, icon: InsightUiUtils.getReactionIcon(p.icon), color: context.appColorScheme.textPrimary),
          ),
        ),
        Gap.h32,
        GutButton(label: AppStrings.gotItThanks, onTap: () => Navigator.pop(context)),
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
        if (insight.topHealing != null) ...[
          SheetSectionHeader(title: AppStrings.topPerformer, color: context.appColorScheme.textPrimary),
          DashboardDetailItem(
            title: insight.topHealing!.food,
            subtitle: insight.topHealing!.effects,
            icon: InsightUiUtils.getReactionIcon(insight.topHealing?.emoji ?? ''),
            color: context.appColorScheme.textPrimary,
          ),
          Gap.h24,
        ],
        if (insight.topTrigger != null) ...[
          SheetSectionHeader(title: AppStrings.criticalTrigger, color: context.appColorScheme.textPrimary),
          DashboardDetailItem(
            title: insight.topTrigger!.food,
            subtitle: insight.topTrigger!.effects,
            icon: InsightUiUtils.getReactionIcon(insight.topTrigger?.emoji ?? ''),
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
