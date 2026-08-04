import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/ai_insight_details.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/bottom_sheet_helper.dart';
import 'package:gutgood/core/utils/insight_ui_utils.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/widgets/shimmer_grid_loader.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/insights_notifier.dart';

class WeeklyRecapScreen extends StatelessWidget {
  final AIInsight? insight;
  const WeeklyRecapScreen({super.key, this.insight});

  @override
  Widget build(BuildContext context) {
    final recap = insight?.weeklyRecap;
    final highlights = recap?.highlights ?? [];
    final notifier = context.watch<InsightsNotifier>();

    if (insight != null) {
      sl<AnalyticsService>().logEvent(name: 'view_weekly_recap', parameters: {
        'avg_score': recap?.avgScore ?? 0,
        'foods_logged': recap?.foodsLogged ?? 0,
      });
    }

    final List<Widget?> sections = [
      // Date Range Header
      Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p6),
          decoration: BoxDecoration(
            color: context.appColorScheme.border.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: context.appColorScheme.border),
          ),
          child: Text(
            recap?.dateRange ?? AppStrings.last7Days,
            style: context.eyebrow.copyWith(color: context.appColorScheme.textPrimary, fontWeight: FontWeight.w900),
          ),
        ),
      ),

      // 1. Primary Hero
      GutSnapshotHeroCard(score: recap?.avgScore ?? 0, scoreDiff: recap?.scoreSub, streak: context.watch<ProfileNotifier>().profile?.streak ?? 0, isActive: true),

      // 1b. Trend Chart
      TrendCard(insights: notifier.insightHistory, currentInsight: insight),

      // 2. Narrative Summary (Gradient Widget)
      if (insight != null) DashboardEntrance(delay: 100, child: _ModernSmartAlert(insight: insight!)),

      // 3. Recap Dashboard (Metrics)
      DashboardEntrance(
        delay: 200,
        child: GutDashboardSection(
          title: AppStrings.performanceHighlights,
          subtitle: AppStrings.sevenDayAverage,
          visualization: DashboardVisualizationBar(ratio: (recap?.avgScore ?? 0) / 100, label: '${recap?.avgScore ?? 0} ${AppStrings.averageGutScore.toLowerCase()}'),
          items: [
            DashboardDetailItem(title: recap?.bestDay ?? 'N/A', subtitle: AppStrings.peakPerformance, icon: AppIcons.trophy, color: context.appColorScheme.textPrimary),
            Gap.h12,
            DashboardDetailItem(title: '${recap?.foodsLogged ?? 0}', subtitle: AppStrings.totalLogs, icon: AppIcons.clipboardList, color: context.appColorScheme.textPrimary),
            Gap.h12,
            DashboardDetailItem(title: insight?.healingTrend?.toUpperCase() ?? AppStrings.stable, subtitle: AppStrings.weeklyTrend, icon: AppIcons.zap, color: context.appColorScheme.textPrimary),
          ],
          footerLabel: AppStrings.viewDetailedMetrics,
          onFooterTap: () => _showRecapDetails(context, recap, insight),
        ),
      ),

      // 4. Weekly Discoveries
      if (highlights.isNotEmpty)
        DashboardEntrance(
          delay: 300,
          child: GutDashboardSection(
            title: AppStrings.aiPatterns,
            subtitle: AppStrings.weeklyHighlights,
            visualization: Container(
              padding: EdgeInsets.all(AppSizes.p12),
              decoration: BoxDecoration(color: context.appColorScheme.border.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(AppIcons.sparkles, color: context.appColorScheme.textPrimary, size: AppSizes.icon32),
            ),
            items: highlights.take(3).map((RecapHighlight h) {
              final color = InsightUiUtils.getIngredientColor(h.color, error: context.appColorScheme.error, warning: context.appColorScheme.warning, success: context.appColorScheme.success);
              return Padding(
                padding: EdgeInsets.only(bottom: AppSizes.p12),
                child: DashboardDetailItem(title: AppStrings.discovery, subtitle: h.text, icon: InsightUiUtils.getReactionIcon(h.icon), color: color),
              );
            }).toList(),
            footerLabel: AppStrings.viewAllDiscoveries,
            onFooterTap: () => _showDiscoveryDetails(context, highlights),
            titleColor: context.appColorScheme.textPrimary,
          ),
        ),

      // 5. Achievement Banner
      DashboardEntrance(delay: 400, child: _buildAchievementBanner(context)),
    ];

    final visibleSections = sections.whereType<Widget>().toList();

    return Scaffold(
      backgroundColor: context.appColorScheme.cardBackground,
      appBar: const GutAppBar(title: AppStrings.weeklyRecap),
      body: insight == null
          ? Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p10),
              child: const ShimmerGridLoader(variant: ShimmerVariant.recap),
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p10),
              itemCount: visibleSections.length,
              itemBuilder: (context, index) {
                final isLast = index == visibleSections.length - 1;
                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? AppSizes.p64 : AppSizes.p32),
                  child: visibleSections[index],
                );
              },
            ),
    );
  }

  Widget _buildAchievementBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSizes.p20),
      decoration: BoxDecoration(
        color: context.appColorScheme.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.r28),
        border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: AppPalette.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSizes.p12),
            decoration: BoxDecoration(color: context.appColorScheme.border.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Icon(AppIcons.trophy, color: context.appColorScheme.textPrimary, size: AppSizes.icon24),
          ),
          Gap.w16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.champion.toUpperCase(),
                  style: context.eyebrow.copyWith(color: context.appColorScheme.textPrimary, fontSize: AppSizes.s10, letterSpacing: 1.5),
                ),
                Gap.h4,
                Text(
                  AppStrings.greatConsistency,
                  style: context.bodyBold.copyWith(color: context.appColorScheme.textPrimary, fontSize: AppSizes.s13),
                ),
              ],
            ),
          ),
          Icon(AppIcons.sparkles, color: context.appColorScheme.textPrimary, size: AppSizes.icon16),
        ],
      ),
    );
  }

  void _showRecapDetails(BuildContext context, WeeklyRecap? recap, AIInsight? insight) {
    sl<AnalyticsService>().logEvent(name: 'view_recap_metrics');
    BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: AppStrings.weeklyPerformance,
      children: [
        SheetHeroSection(title: '${recap?.avgScore ?? 0}', subtitle: AppStrings.averageGutScore, color: context.appColorScheme.textPrimary, icon: AppIcons.activity),
        Gap.h32,
        SheetSectionHeader(title: AppStrings.activityBreakdown, color: context.appColorScheme.textPrimary),
        DashboardDetailItem(
          title: '${recap?.foodsLogged ?? 0} ${AppStrings.foodsLogged}',
          subtitle: recap?.loggedSub ?? 'Keep it up!',
          icon: AppIcons.utensils,
          color: context.appColorScheme.textPrimary,
        ),
        Gap.h16,
        DashboardDetailItem(title: '${AppStrings.bestDay}: ${recap?.bestDay ?? 'N/A'}', subtitle: AppStrings.bestPerformanceSubtitle, icon: AppIcons.trophy, color: context.appColorScheme.textPrimary),
        Gap.h32,
        GutButton(label: AppStrings.gotItThanks, onTap: () => context.pop()),
        Gap.h24,
      ],
    );
  }

  void _showDiscoveryDetails(BuildContext context, List<RecapHighlight> highlights) {
    sl<AnalyticsService>().logEvent(name: 'view_recap_discoveries');
    BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: AppStrings.discoveriesTitle,
      children: [
        SheetHeroSection(title: AppStrings.insights, subtitle: AppStrings.aiDrivenFindings, color: context.appColorScheme.textPrimary, icon: AppIcons.sparkles),
        Gap.h32,
        ...highlights.map((RecapHighlight h) {
          return Padding(
            padding: EdgeInsets.only(bottom: AppSizes.p16),
            child: DashboardDetailItem(title: h.text, subtitle: AppStrings.detectedThisWeek, icon: InsightUiUtils.getReactionIcon(h.icon), color: context.appColorScheme.textPrimary),
          );
        }),
        Gap.h32,
        GutButton(label: AppStrings.gotItThanks, onTap: () => context.pop()),
        Gap.h24,
      ],
    );
  }
}

class _ModernSmartAlert extends StatelessWidget {
  final AIInsight insight;
  const _ModernSmartAlert({required this.insight});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileNotifier>().profile;
    final streak = profile?.streak ?? 0;
    final healingTrend = insight.healingTrend ?? AppStrings.optimizing;
    final String description = "${AppStrings.weeklyRecapNarrative}$streak${AppStrings.narrativeDaysAndGut}$healingTrend${AppStrings.narrativeBasedOnLogs}";

    return ModernInsightCard(
      title: AppStrings.weeklyPulse,
      icon: AppIcons.sparkles,
      backgroundColor: context.appColorScheme.cardBackground,
      titleColor: context.appColorScheme.textPrimary,
      iconColor: context.appColorScheme.textPrimary,
      padding: EdgeInsets.fromLTRB(AppSizes.p20, 0, AppSizes.p20, AppSizes.p20),
      footer: Text(
        AppStrings.aiSummary,
        textAlign: TextAlign.center,
        style: context.caption.copyWith(color: context.appColorScheme.cardBackground, fontWeight: FontWeight.w900, fontSize: AppSizes.s10, letterSpacing: 1.0),
      ),
      footerColor: context.appColorScheme.textPrimary,
      child: Text(
        description,
        style: context.bodySm.copyWith(color: context.appColorScheme.textPrimary, height: 1.4, fontWeight: FontWeight.w500),
      ),
    );
  }
}
