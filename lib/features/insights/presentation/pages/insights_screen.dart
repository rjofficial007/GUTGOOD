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
import 'package:gutgood/core/models/health_alert.dart';
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
      StreakCard(streak: profile?.streak ?? 0, lastActivityDate: profile?.lastActivityDate),
      TrendCard(insights: notifier.insightHistory, currentInsight: data),
      if (notifier.healthAlerts.isNotEmpty) _RecentAlertsCard(alerts: notifier.healthAlerts),
      if (data.topInsight != null) _ModernSmartAlert(insight: data.topInsight!),
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
      if (data.healingFoods.isNotEmpty || data.triggerFoods.isNotEmpty)
        DashboardEntrance(
          delay: 200,
          child: GutDashboardSection(
            title: AppStrings.healingFoods,
            subtitle: AppStrings.recoveryProtocol,
            visualization: const DashboardVisualizationBar(ratio: 0.8, label: AppStrings.highHealingDensity),
            items: [
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
            footerLabel: AppStrings.viewRecommendedFoods,
            onFooterTap: () => _showRecoveryDetails(context),
            titleColor: context.appColorScheme.textPrimary,
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
            items: notifier.bodyPatterns.take(2).map((p) => Padding(
                padding: EdgeInsets.only(bottom: AppSizes.p12),
                child: DashboardDetailItem(title: p.trigger, subtitle: p.reaction, icon: AppIcons.activity, color: context.appColorScheme.textPrimary),
              )).toList(),
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
      if (data.foodImpacts.isNotEmpty)
        DashboardEntrance(
          delay: 400,
          child: GutDashboardSection(
            title: AppStrings.whenIEatThis,
            subtitle: AppStrings.bodyResponses,
            visualization: const DashboardVisualizationBar(ratio: 0.9, label: AppStrings.responseSensitivity),
            items: data.foodImpacts.where((i) => i.food.isNotEmpty && i.food != 'Unknown').take(2).map((i) {
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
            footerLabel: AppStrings.viewRecentReactions,
            onFooterTap: () => _showReactionDetails(context),
            titleColor: context.appColorScheme.textPrimary,
          ),
        ),
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

  void _showReactionDetails(BuildContext context) {
    BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: AppStrings.bodyReactions,
      children: [
        SheetHeroSection(title: AppStrings.bioFeedback, subtitle: AppStrings.foodBodyMapping, color: context.appColorScheme.textPrimary, icon: AppIcons.activity),
        Gap.h32,
        ...data.foodImpacts.where((i) => i.food.isNotEmpty && i.food != 'Unknown').map((i) {
          final isNegative = i.impactType == 'negative';
          return Padding(
            padding: EdgeInsets.only(bottom: AppSizes.p16),
            child: DashboardDetailItem(
              title: i.food,
              subtitle: '${i.timeframeLabel}: ${i.effect}',
              icon: InsightUiUtils.getReactionIcon(i.emoji),
              color: isNegative ? context.appColorScheme.error : context.appColorScheme.success,
            ),
          );
        }),
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

class _RecentAlertsCard extends StatelessWidget {
  const _RecentAlertsCard({required this.alerts});
  final List<HealthAlert> alerts;

  @override
  Widget build(BuildContext context) => Container(
      margin: EdgeInsets.only(top: AppSizes.p16),
      padding: EdgeInsets.all(AppSizes.p20),
      decoration: BoxDecoration(
        color: context.appColorScheme.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.r28),
        border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: AppPalette.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.bell, color: context.appColorScheme.textPrimary, size: AppSizes.icon20),
              Gap.w8,
              Text('RECENT HEALTH ALERTS', style: context.eyebrow.copyWith(color: context.appColorScheme.textPrimary, letterSpacing: 1.2)),
              const Spacer(),
              if (alerts.any((a) => !a.isRead))
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: context.appColorScheme.error, shape: BoxShape.circle),
                ),
            ],
          ),
          Gap.h20,
          ...alerts.take(2).map((alert) => Padding(
              padding: EdgeInsets.only(bottom: AppSizes.p16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(AppSizes.p8),
                    decoration: BoxDecoration(color: _getAlertColor(alert.type, context).withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(_getAlertIcon(alert.type), color: _getAlertColor(alert.type, context), size: 16),
                  ),
                  Gap.w12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alert.title, style: context.bodyBold.copyWith(fontSize: AppSizes.s14)),
                        Text(
                          alert.message,
                          style: context.caption.copyWith(color: context.appColorScheme.textMuted),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          if (alerts.length > 2)
            GestureDetector(
              onTap: () => unawaited(context.push(AppRoutes.notificationArchive)),
              child: Center(
                child: Text(
                  'View All Alerts',
                  style: context.bodyBold.copyWith(color: context.appColorScheme.textPrimary, fontSize: AppSizes.s13),
                ),
              ),
            ),
        ],
      ),
    );

  IconData _getAlertIcon(String type) {
    switch (type) {
      case 'processed_food':
        return AppIcons.alertTriangle;
      case 'insight_ready':
        return AppIcons.sparkles;
      case 'streak_saver':
        return AppIcons.flame;
      default:
        return AppIcons.bell;
    }
  }

  Color _getAlertColor(String type, BuildContext context) {
    switch (type) {
      case 'processed_food':
        return context.appColorScheme.error;
      case 'insight_ready':
        return context.appColorScheme.success;
      case 'streak_saver':
        return context.appColorScheme.warning;
      default:
        return context.appColorScheme.textPrimary;
    }
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
