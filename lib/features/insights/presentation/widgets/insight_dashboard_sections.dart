import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/ai_insight_details.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/bottom_sheet_helper.dart';
import 'package:gutgood/core/utils/insight_ui_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/product_details/presentation/widgets/scan_result_widgets.dart';

class StrategicFocusBadge extends StatelessWidget {
  const StrategicFocusBadge({super.key, required this.goal});
  final String goal;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p16),
    decoration: BoxDecoration(color: context.appColorScheme.aiResponseBackground, borderRadius: BorderRadius.circular(AppSizes.r20)),
    child: Row(
      children: [
        Container(
          padding: EdgeInsets.all(AppSizes.p8),
          decoration: BoxDecoration(color: context.appColorScheme.textPrimary.withValues(alpha: 0.05), shape: BoxShape.circle),
          child: Icon(AppIcons.target, color: context.appColorScheme.textPrimary, size: AppSizes.icon18),
        ),
        Gap.w16,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.currentFocusLabel,
                style: context.caption.copyWith(color: context.appColorScheme.textSecondary, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: AppSizes.s10),
              ),
              Gap.h2,
              Text(
                goal.toUpperCase(),
                style: context.bodyBold.copyWith(color: context.appColorScheme.textPrimary, fontSize: AppSizes.s15, height: 1.1),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class GoalDashboardSection extends StatelessWidget {
  const GoalDashboardSection({super.key, required this.insight});
  final AIInsight insight;

  @override
  Widget build(BuildContext context) => DashboardEntrance(
    delay: 100,
    child: GutDashboardSection(
      title: AppStrings.topBodyInsights,
      subtitle: AppStrings.primaryObjectives,
      visualization: const NutrientVisualization(),
      items: [
        if (insight.healingGoal != null) DashboardDetailItem(title: insight.healingGoal!, subtitle: AppStrings.activeGoal, icon: AppIcons.target, color: context.appColorScheme.textPrimary),
        if (insight.healingGoal != null && insight.triggerSymptom != null) Gap.h12,
        if (insight.triggerSymptom != null)
          DashboardDetailItem(title: insight.triggerSymptom!, subtitle: AppStrings.symptomWatch, icon: AppIcons.activity, color: context.appColorScheme.textSecondary),
      ],
      footerLabel: AppStrings.viewGoalProgress,
      onFooterTap: () => _showFocusDetails(context),
    ),
  );

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
}

class PowerSourcesDashboardSection extends StatelessWidget {
  const PowerSourcesDashboardSection({super.key, required this.insight});
  final AIInsight insight;

  @override
  Widget build(BuildContext context) {
    final items = [
      ...insight.healingFoods
          .take(2)
          .map(
            (f) => Padding(
              padding: EdgeInsets.only(bottom: AppSizes.p12),
              child: DashboardDetailItem(title: f.name, subtitle: f.effect, icon: InsightUiUtils.getReactionIcon(f.emoji), color: context.appColorScheme.textPrimary),
            ),
          ),
      ...insight.foodImpacts
          .where((i) => i.impactType == 'positive' && i.food != 'Unknown')
          .take(2)
          .map(
            (i) => Padding(
              padding: EdgeInsets.only(bottom: AppSizes.p12),
              child: DashboardDetailItem(title: i.food, subtitle: i.effect, icon: InsightUiUtils.getReactionIcon(i.emoji), color: context.appColorScheme.textPrimary),
            ),
          ),
    ].take(3).toList();

    return DashboardEntrance(
      delay: 200,
      child: GutDashboardSection(
        title: AppStrings.powerSources,
        subtitle: AppStrings.foodsToPrioritize,
        visualization: const CautionRiskIcon(isSafe: true),
        items: items,
        footerLabel: AppStrings.viewAllPowerSources,
        onFooterTap: () => _showPowerSourcesDetails(context),
      ),
    );
  }

  void _showPowerSourcesDetails(BuildContext context) {
    final healing = insight.healingFoods;
    final successes = insight.foodImpacts.where((i) => i.impactType == 'positive' && i.food != 'Unknown').toList();

    BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: AppStrings.powerSourcesTitle,
      children: [
        SheetHeroSection(title: AppStrings.heal, subtitle: AppStrings.evidenceBackedBenefits, color: context.appColorScheme.success, icon: AppIcons.leaf),
        Gap.h32,
        if (healing.isNotEmpty) ...[
          SheetSectionHeader(title: AppStrings.aiRecommendations, color: context.appColorScheme.textPrimary),
          ...healing.map(
            (f) => Padding(
              padding: EdgeInsets.only(bottom: 16.0.h),
              child: DashboardDetailItem(title: f.name, subtitle: f.effect, icon: InsightUiUtils.getReactionIcon(f.emoji), color: context.appColorScheme.success),
            ),
          ),
          Gap.h24,
        ],
        if (successes.isNotEmpty) ...[
          SheetSectionHeader(title: AppStrings.yourSuccesses, color: context.appColorScheme.textPrimary),
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
}

class TriggersDashboardSection extends StatelessWidget {
  const TriggersDashboardSection({super.key, required this.insight});
  final AIInsight insight;

  @override
  Widget build(BuildContext context) {
    final items = [
      ...insight.triggerFoods
          .take(2)
          .map(
            (f) => Padding(
              padding: EdgeInsets.only(bottom: AppSizes.p12),
              child: DashboardDetailItem(title: f.name, subtitle: f.effect, icon: InsightUiUtils.getReactionIcon(f.emoji), color: context.appColorScheme.textPrimary),
            ),
          ),
      ...insight.foodImpacts
          .where((i) => i.impactType == 'negative' && i.food != 'Unknown')
          .take(2)
          .map(
            (i) => Padding(
              padding: EdgeInsets.only(bottom: AppSizes.p12),
              child: DashboardDetailItem(title: i.food, subtitle: i.effect, icon: InsightUiUtils.getReactionIcon(i.emoji), color: context.appColorScheme.textPrimary),
            ),
          ),
    ].take(3).toList();

    return DashboardEntrance(
      delay: 250,
      child: GutDashboardSection(
        title: AppStrings.systemTriggers,
        subtitle: AppStrings.foodsToMinimize,
        visualization: const CautionRiskIcon(isSafe: false),
        items: items,
        footerLabel: AppStrings.viewAllTriggers,
        onFooterTap: () => _showTriggersDetails(context),
      ),
    );
  }

  void _showTriggersDetails(BuildContext context) {
    final triggers = insight.triggerFoods;
    final reactions = insight.foodImpacts.where((i) => i.impactType == 'negative' && i.food != 'Unknown').toList();

    BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: AppStrings.systemTriggersTitle,
      children: [
        SheetHeroSection(title: AppStrings.alert, subtitle: AppStrings.potentialTriggers, color: context.appColorScheme.error, icon: AppIcons.alertTriangle),
        Gap.h32,
        if (triggers.isNotEmpty) ...[
          SheetSectionHeader(title: AppStrings.aiWarnings, color: context.appColorScheme.textPrimary),
          ...triggers.map(
            (f) => Padding(
              padding: EdgeInsets.only(bottom: 16.0.h),
              child: DashboardDetailItem(title: f.name, subtitle: f.effect, icon: InsightUiUtils.getReactionIcon(f.emoji), color: context.appColorScheme.error),
            ),
          ),
          Gap.h24,
        ],
        if (reactions.isNotEmpty) ...[
          SheetSectionHeader(title: AppStrings.yourReactions, color: context.appColorScheme.textPrimary),
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
}

class PatternsDashboardSection extends StatelessWidget {
  const PatternsDashboardSection({super.key, required this.insight, this.delay = 300});
  final AIInsight insight;
  final int delay;

  @override
  Widget build(BuildContext context) => DashboardEntrance(
    delay: delay,
    child: GutDashboardSection(
      title: AppStrings.yourPatterns,
      subtitle: AppStrings.detectedPatterns,
      visualization: const DashboardIconVisualization(icon: AppIcons.brain),
      items: insight.detectedPatterns.take(2).map<Widget>((BodyPattern p) {
        final color = InsightUiUtils.getPatternColor(p.type);
        final probability = (p.evidenceRatio * 100).toInt();
        return Padding(
          padding: EdgeInsets.only(bottom: AppSizes.p12),
          child: DashboardDetailItem(
            title: p.trigger.toUpperCase(),
            subtitle: '${InsightUiUtils.getPatternName(p.type)} • $probability% Probability',
            icon: InsightUiUtils.getPatternTypeIcon(p.type),
            color: color,
            onTap: () => context.push(AppRoutes.patternDetail, extra: p),
          ),
        );
      }).toList(),
      footerLabel: AppStrings.viewDetailedPatterns,
      onFooterTap: () => _showTrendDetails(context),
    ),
  );

  void _showTrendDetails(BuildContext context) {
    BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: AppStrings.observedPatterns,
      children: [
        SheetHeroSection(title: AppStrings.trends, subtitle: AppStrings.behavioralAnalysis, color: context.appColorScheme.textPrimary, icon: AppIcons.activity),
        Gap.h32,
        ...insight.detectedPatterns.map(
          (BodyPattern p) {
            final probability = (p.evidenceRatio * 100).toInt();
            return Padding(
              padding: EdgeInsets.only(bottom: AppSizes.p16),
              child: DashboardDetailItem(
                title: p.trigger.toUpperCase(),
                subtitle: '${InsightUiUtils.getPatternName(p.type)} • $probability% Probability (${p.frequency}/${p.totalSimilarMeals} logs)',
                icon: InsightUiUtils.getPatternTypeIcon(p.type),
                color: InsightUiUtils.getPatternColor(p.type),
                onTap: () => context.push(AppRoutes.patternDetail, extra: p),
              ),
            );
          },
        ),
        Gap.h32,
        GutButton(label: AppStrings.gotItThanks, onTap: () => context.pop()),
        Gap.h24,
      ],
    );
  }
}

class HighlightsDashboardSection extends StatelessWidget {
  const HighlightsDashboardSection({super.key, required this.insight, this.delay = 350});
  final AIInsight insight;
  final int delay;

  @override
  Widget build(BuildContext context) => DashboardEntrance(
    delay: delay,
    child: GutDashboardSection(
      title: AppStrings.performanceHighlights,
      subtitle: AppStrings.performanceHighs,
      visualization: const SwapVisualization(),
      items: [
        if (insight.topHealing != null)
          DashboardDetailItem(
            title: insight.topHealing!.food,
            subtitle: AppStrings.bestForGut,
            icon: InsightUiUtils.getReactionIcon(insight.topHealing?.emoji ?? ''),
            color: context.appColorScheme.textPrimary,
          ),
        if (insight.topHealing != null && insight.topTrigger != null) Gap.h12,
        if (insight.topTrigger != null)
          DashboardDetailItem(
            title: insight.topTrigger!.food,
            subtitle: AppStrings.avoidNextTime,
            icon: InsightUiUtils.getReactionIcon(insight.topTrigger?.emoji ?? ''),
            color: context.appColorScheme.textPrimary,
          ),
      ],
      footerLabel: AppStrings.viewPerformanceHighs,
      onFooterTap: () => _showHighlightDetails(context),
      titleColor: context.appColorScheme.textPrimary,
    ),
  );

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

class ModernSmartAlert extends StatelessWidget {
  const ModernSmartAlert({super.key, required this.insight});
  final InsightSummary insight;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.push(AppRoutes.smartInsightDetail, extra: insight),
    child: ModernInsightCard(
      title: insight.title,
      icon: AppIcons.salad,
      backgroundColor: context.appColorScheme.cardBackground,
      titleColor: context.appColorScheme.textPrimary,
      iconColor: context.appColorScheme.textPrimary,
      padding: EdgeInsets.fromLTRB(AppSizes.p20, 0, AppSizes.p20, AppSizes.p20),
      footer: Text(
        '${insight.type.toUpperCase()}${AppStrings.insightLabelSuffix}  ➜',
        textAlign: TextAlign.center,
        style: context.caption.copyWith(color: context.appColorScheme.cardBackground, fontWeight: FontWeight.w900, fontSize: AppSizes.s10, letterSpacing: 1.0),
      ),
      footerColor: context.appColorScheme.textPrimary,
      child: Text(
        insight.description,
        style: context.bodySm.copyWith(color: context.appColorScheme.textPrimary, height: 1.4, fontWeight: FontWeight.w500),
        softWrap: true,
        maxLines: null,
      ),
    ),
  );
}
