import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/ai_insight_details.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/bottom_sheet_helper.dart';
import 'package:gutgood/core/utils/insight_ui_utils.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/responsive.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/insights_notifier.dart';

class InsightDetailScreen extends StatelessWidget {
  final AIInsight insight;

  const InsightDetailScreen({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM dd, yyyy').format(insight.updatedAt);
    final profile = context.watch<ProfileNotifier>().profile;
    final notifier = context.watch<InsightsNotifier>();

    final List<Widget?> sections = [
      // 1. Snapshot Hero (Shared Style)
      GutSnapshotHeroCard(score: insight.gutScore, scoreDiff: insight.scoreDiff, streak: profile?.streak ?? 0, isActive: false),

      // 1b. Trend Chart
      TrendCard(insights: notifier.insightHistory, currentInsight: insight, referenceDate: insight.updatedAt),

      // 2. Summary Alert
      if (insight.topInsight != null) _ModernSmartAlert(insight: insight.topInsight!),

      // 3. Analysis Dashboards
      if (insight.healingGoal != null || insight.triggerSymptom != null) DashboardEntrance(delay: 100, child: _FocusDashboardSection(data: insight)),
      if (insight.healingFoods.isNotEmpty || insight.triggerFoods.isNotEmpty) DashboardEntrance(delay: 200, child: _RecoveryDashboardSection(data: insight)),
      if (insight.detectedPatterns.isNotEmpty) DashboardEntrance(delay: 300, child: _TrendsDashboardSection(patterns: insight.detectedPatterns)),
      if (insight.topHealing != null || insight.topTrigger != null) DashboardEntrance(delay: 350, child: _HighlightsDashboardSection(data: insight)),
      if (insight.foodImpacts.isNotEmpty) DashboardEntrance(delay: 400, child: _ReactionsDashboardSection(impacts: insight.foodImpacts)),
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
}

class _ModernSmartAlert extends StatelessWidget {
  final InsightSummary insight;
  const _ModernSmartAlert({required this.insight});

  @override
  Widget build(BuildContext context) {
    return ModernInsightCard(
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
}

class _FocusDashboardSection extends StatelessWidget {
  final AIInsight data;
  const _FocusDashboardSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      onFooterTap: () => _showFocusDetails(context),
      footerLabel: AppStrings.viewGoalProgress,
      child: Padding(
        padding: EdgeInsets.all(AppSizes.p20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.focus,
                    style: context.bodyBold.copyWith(fontSize: AppSizes.s28, fontWeight: FontWeight.w900, letterSpacing: -1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    AppStrings.primaryObjectives,
                    style: context.caption.copyWith(color: context.appColorScheme.textMuted, fontSize: AppSizes.s12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Gap.h24,
                  const DashboardVisualizationBar(ratio: 0.65, label: AppStrings.trackingStability),
                ],
              ),
            ),
            Gap.w16,
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  if (data.healingGoal != null) DashboardDetailItem(title: data.healingGoal!, subtitle: AppStrings.activeGoal, icon: AppIcons.target, color: context.appColorScheme.success),
                  if (data.healingGoal != null && data.triggerSymptom != null) Gap.h12,
                  if (data.triggerSymptom != null) DashboardDetailItem(title: data.triggerSymptom!, subtitle: AppStrings.symptomWatch, icon: AppIcons.activity, color: context.appColorScheme.warning),
                ],
              ),
            ),
          ],
        ),
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
}

class _RecoveryDashboardSection extends StatelessWidget {
  final AIInsight data;
  const _RecoveryDashboardSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      onFooterTap: () => _showRecoveryDetails(context),
      footerLabel: AppStrings.viewRecommendedFoods,
      child: Padding(
        padding: EdgeInsets.all(AppSizes.p20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.heal,
                    style: context.bodyBold.copyWith(fontSize: AppSizes.s28, fontWeight: FontWeight.w900, letterSpacing: -1, color: context.appColorScheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    AppStrings.recoveryProtocol,
                    style: context.caption.copyWith(color: context.appColorScheme.textMuted, fontSize: AppSizes.s12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Gap.h24,
                  const DashboardVisualizationBar(ratio: 0.8, label: AppStrings.highHealingDensity),
                ],
              ),
            ),
            Gap.w16,
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  ...data.healingFoods
                      .take(2)
                      .map(
                        (f) => Padding(
                          padding: EdgeInsets.only(bottom: AppSizes.p12),
                          child: DashboardDetailItem(title: f.name, subtitle: AppStrings.healing, icon: AppIcons.leaf, color: context.appColorScheme.success),
                        ),
                      ),
                  if (data.healingFoods.isEmpty && data.triggerFoods.isNotEmpty)
                    DashboardDetailItem(title: data.triggerFoods.first.name, subtitle: AppStrings.trigger, icon: AppIcons.alertCircle, color: context.appColorScheme.error),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecoveryDetails(BuildContext context) {
    BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: AppStrings.recommendations,
      children: [
        SheetHeroSection(title: AppStrings.heal, subtitle: AppStrings.recoveryProtocol, color: context.appColorScheme.textPrimary, icon: AppIcons.leaf),
        Gap.h32,
        if (data.healingFoods.isNotEmpty) ...[
          SheetSectionHeader(title: AppStrings.foodsToPrioritize, color: context.appColorScheme.textPrimary),
          ...data.healingFoods.map(
            (f) => Padding(
              padding: EdgeInsets.only(bottom: 16.0.h),
              child: DashboardDetailItem(title: f.name, subtitle: f.effect, icon: AppIcons.checkCircle, color: context.appColorScheme.textPrimary),
            ),
          ),
          Gap.h24,
        ],
        if (data.triggerFoods.isNotEmpty) ...[
          SheetSectionHeader(title: AppStrings.foodsToMinimize, color: context.appColorScheme.textPrimary),
          ...data.triggerFoods.map(
            (f) => Padding(
              padding: EdgeInsets.only(bottom: 16.0.h),
              child: DashboardDetailItem(title: f.name, subtitle: f.effect, icon: AppIcons.alertCircle, color: context.appColorScheme.textPrimary),
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
}

class _TrendsDashboardSection extends StatelessWidget {
  final List<DetectedPattern> patterns;
  const _TrendsDashboardSection({required this.patterns});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      onFooterTap: () => _showTrendDetails(context),
      footerLabel: AppStrings.viewDetailedPatterns,
      child: Padding(
        padding: EdgeInsets.all(AppSizes.p20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.trends,
                    style: context.bodyBold.copyWith(fontSize: AppSizes.s28, fontWeight: FontWeight.w900, letterSpacing: -1, color: context.appColorScheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    AppStrings.observedPatterns,
                    style: context.caption.copyWith(color: context.appColorScheme.textMuted, fontSize: AppSizes.s12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Gap.h24,
                  const DashboardVisualizationBar(ratio: 0.45, label: AppStrings.patternConsistency),
                ],
              ),
            ),
            Gap.w16,
            Expanded(
              flex: 5,
              child: Column(
                children: patterns.take(2).map((p) {
                  final color = InsightUiUtils.getPatternColor(p.icon);
                  return Padding(
                    padding: EdgeInsets.only(bottom: AppSizes.p12),
                    child: DashboardDetailItem(title: p.title, subtitle: AppStrings.observation, icon: InsightUiUtils.getReactionIcon(p.icon), color: color),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTrendDetails(BuildContext context) {
    BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: AppStrings.observedPatterns,
      children: [
        SheetHeroSection(title: AppStrings.trends, subtitle: AppStrings.behavioralAnalysis, color: context.appColorScheme.textPrimary, icon: AppIcons.activity),
        Gap.h32,
        ...patterns.map(
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
}

class _HighlightsDashboardSection extends StatelessWidget {
  final AIInsight data;
  const _HighlightsDashboardSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      onFooterTap: () => _showHighlightDetails(context),
      footerLabel: AppStrings.viewPerformanceHighs,
      child: Padding(
        padding: EdgeInsets.all(AppSizes.p20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.stats,
                    style: context.bodyBold.copyWith(fontSize: AppSizes.s28, fontWeight: FontWeight.w900, letterSpacing: -1, color: context.appColorScheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    AppStrings.performanceHighs,
                    style: context.caption.copyWith(color: context.appColorScheme.textMuted, fontSize: AppSizes.s12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Gap.h24,
                  const DashboardVisualizationBar(ratio: 0.75, label: AppStrings.optimizationEfficiency),
                ],
              ),
            ),
            Gap.w16,
            Expanded(
              flex: 5,
              child: Column(
                children: [
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
              ),
            ),
          ],
        ),
      ),
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
}

class _ReactionsDashboardSection extends StatelessWidget {
  final List<FoodImpact> impacts;
  const _ReactionsDashboardSection({required this.impacts});

  @override
  Widget build(BuildContext context) {
    final validImpacts = impacts.where((i) => i.food.isNotEmpty && i.food != 'Unknown').toList();

    return DashboardCard(
      onFooterTap: () => _showReactionDetails(context),
      footerLabel: AppStrings.viewRecentFeedback,
      child: Padding(
        padding: EdgeInsets.all(AppSizes.p20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.reactions,
                    style: context.bodyBold.copyWith(fontSize: AppSizes.s28, fontWeight: FontWeight.w900, letterSpacing: -1, color: context.appColorScheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    AppStrings.bodyFeedback,
                    style: context.caption.copyWith(color: context.appColorScheme.textMuted, fontSize: AppSizes.s12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Gap.h24,
                  const DashboardVisualizationBar(ratio: 0.7, label: AppStrings.responseTracking),
                ],
              ),
            ),
            Gap.w16,
            Expanded(
              flex: 5,
              child: Column(
                children: validImpacts.take(2).map((i) {
                  final isNegative = i.impactType == 'negative';
                  return Padding(
                    padding: EdgeInsets.only(bottom: AppSizes.p12),
                    child: DashboardDetailItem(
                      title: i.food,
                      subtitle: i.timeframeLabel,
                      icon: InsightUiUtils.getReactionIcon(i.emoji),
                      color: isNegative ? context.appColorScheme.error : context.appColorScheme.success,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReactionDetails(BuildContext context) {
    BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: AppStrings.bodyReactions,
      children: [
        SheetHeroSection(title: AppStrings.bioFeedback, subtitle: AppStrings.reactionMapping, color: context.appColorScheme.textPrimary, icon: AppIcons.activity),
        Gap.h32,
        ...impacts.map((i) {
          final isNegative = i.impactType == 'negative';
          return Padding(
            padding: EdgeInsets.only(bottom: AppSizes.p16),
            child: DashboardDetailItem(title: i.food, subtitle: '${i.timeframeLabel}: ${i.effect}', icon: InsightUiUtils.getReactionIcon(i.emoji), color: context.appColorScheme.textPrimary),
          );
        }),
        Gap.h32,
        GutButton(label: AppStrings.gotItThanks, onTap: () => Navigator.pop(context)),
        Gap.h24,
      ],
    );
  }
}
