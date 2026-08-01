import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/ai_insight_details.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/bottom_sheet_helper.dart';
import 'package:gutgood/core/utils/insight_ui_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/usage_service.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_palette.dart';

class WeeklyRecapScreen extends StatelessWidget {
  final AIInsight? insight;
  const WeeklyRecapScreen({super.key, this.insight});

  @override
  Widget build(BuildContext context) {
    final recap = insight?.weeklyRecap;
    final highlights = recap?.highlights ?? [];

    final List<Widget?> sections = [
      // Date Range Header
      Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 6.0.h),
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
      GutSnapshotHeroCard(
          score: recap?.avgScore ?? 0,
          scoreDiff: recap?.scoreSub,
          streak: insight?.streak ?? 0,
          simpleTrend: insight?.simpleTrend ?? [],
          isActive: true),

      // 2. Narrative Summary (Gradient Widget)
      DashboardEntrance(
        delay: 100,
        child: _WeeklyNarrativeDashboard(insight: insight),
      ),

      // 3. Recap Dashboard (Metrics)
      DashboardEntrance(
        delay: 200,
        child: _RecapDashboardSection(recap: recap, insight: insight),
      ),

      // 4. Weekly Discoveries
      if (highlights.isNotEmpty)
        DashboardEntrance(
          delay: 300,
          child: _DiscoveriesDashboardSection(highlights: highlights),
        ),

      // 5. Achievement Banner
      DashboardEntrance(
        delay: 400,
        child: _buildAchievementBanner(context),
      ),
    ];

    final visibleSections = sections.whereType<Widget>().toList();

    return Scaffold(
      backgroundColor: context.appColorScheme.cardBackground,
      appBar: const GutAppBar(title: AppStrings.weeklyRecap),
      body: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: Responsive.w(20.0), vertical: Responsive.h(10.0)),
        itemCount: visibleSections.length,
        itemBuilder: (context, index) {
          final isLast = index == visibleSections.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 64.0.h : 32.0.h),
            child: visibleSections[index],
          );
        },
      ),
    );
  }

  Widget _buildAchievementBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.w(20.0)),
      decoration: BoxDecoration(
        color: context.appColorScheme.cardBackground,
        borderRadius: BorderRadius.circular(28.0.r),
        border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.0.w),
            decoration: BoxDecoration(color: context.appColorScheme.border.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Icon(AppIcons.trophy, color: context.appColorScheme.textPrimary, size: 24.0.w),
          ),
          Gap.w16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.champion.toUpperCase(),
                  style: context.eyebrow.copyWith(color: context.appColorScheme.textPrimary, fontSize: 10.0.sp, letterSpacing: 1.5),
                ),
                Gap.h4,
                Text(
                  AppStrings.greatConsistency,
                  style: context.bodyBold.copyWith(color: context.appColorScheme.textPrimary, fontSize: 13.0.sp),
                ),
              ],
            ),
          ),
          Icon(AppIcons.sparkles, color: context.appColorScheme.textPrimary, size: 16.0.w),
        ],
      ),
    );
  }
}

class _WeeklyNarrativeDashboard extends StatelessWidget {
  final AIInsight? insight;
  const _WeeklyNarrativeDashboard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final streak = insight?.streak ?? 0;
    final healingTrend = insight?.healingTrend ?? AppStrings.optimizing;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.0.w),
      decoration: BoxDecoration(
        color: context.appColorScheme.textPrimary,
        borderRadius: BorderRadius.circular(28.0.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI SUMMARY',
                      style: context.eyebrow.copyWith(color: context.appColorScheme.cardBackground.withValues(alpha: 0.8), letterSpacing: 2.0),
                    ),
                    Text(
                      'WEEKLY PULSE',
                      style: context.bodyBold.copyWith(
                        color: context.appColorScheme.cardBackground,
                        fontSize: 28.0.sp,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(12.0.w),
                decoration: BoxDecoration(
                  color: context.appColorScheme.cardBackground.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(AppIcons.sparkles, color: context.appColorScheme.cardBackground, size: 28.0.w),
              ),
            ],
          ),
          Gap.h24,
          Text(
            "${AppStrings.weeklyRecapNarrative}$streak${AppStrings.narrativeDaysAndGut}$healingTrend${AppStrings.narrativeBasedOnLogs}",
            style: context.body.copyWith(
              color: context.appColorScheme.cardBackground.withValues(alpha: 0.9),
              fontSize: 15.0.sp,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecapDashboardSection extends StatelessWidget {
  final WeeklyRecap? recap;
  final AIInsight? insight;
  const _RecapDashboardSection({required this.recap, required this.insight});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      onFooterTap: () => _showRecapDetails(context),
      footerLabel: 'View Detailed Metrics',
      child: Padding(
        padding: EdgeInsets.all(20.0.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Side: Avg Score Hero
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RECAP',
                    style: context.bodyBold.copyWith(
                      fontSize: 28.0.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '7-Day Average',
                    style: context.caption.copyWith(
                      color: context.appColorScheme.textMuted,
                      fontSize: 12.0.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Gap.h24,
                  DashboardVisualizationBar(
                    ratio: (recap?.avgScore ?? 0) / 100,
                    label: '${recap?.avgScore ?? 0} average gut score',
                  ),
                ],
              ),
            ),
            Gap.w16,
            // Right Side: Metrics List
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  DashboardDetailItem(
                    title: recap?.bestDay ?? 'N/A',
                    subtitle: 'Peak Performance',
                    icon: AppIcons.trophy,
                    color: context.appColorScheme.textPrimary,
                  ),
                  Gap.h12,
                  DashboardDetailItem(
                    title: '${recap?.foodsLogged ?? 0}',
                    subtitle: 'Total Logs',
                    icon: AppIcons.clipboardList,
                    color: context.appColorScheme.textPrimary,
                  ),
                  Gap.h12,
                  DashboardDetailItem(
                    title: insight?.healingTrend?.toUpperCase() ?? 'STABLE',
                    subtitle: 'Weekly Trend',
                    icon: AppIcons.zap,
                    color: context.appColorScheme.textPrimary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecapDetails(BuildContext context) {
    BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: 'Weekly Performance',
      children: [
        SheetHeroSection(
          title: '${recap?.avgScore ?? 0}',
          subtitle: 'AVERAGE GUT SCORE',
          color: context.appColorScheme.textPrimary,
          icon: AppIcons.activity,
        ),
        Gap.h32,
        SheetSectionHeader(title: 'Activity Breakdown', color: context.appColorScheme.textPrimary),
        DashboardDetailItem(
          title: '${recap?.foodsLogged ?? 0} Foods Logged',
          subtitle: recap?.loggedSub ?? 'Keep it up!',
          icon: AppIcons.utensils,
          color: context.appColorScheme.textPrimary,
        ),
        Gap.h16,
        DashboardDetailItem(
          title: 'Best Day: ${recap?.bestDay ?? 'N/A'}',
          subtitle: AppStrings.bestPerformanceSubtitle,
          icon: AppIcons.trophy,
          color: context.appColorScheme.textPrimary,
        ),
        Gap.h32,
        GutButton(label: AppStrings.gotItThanks, onTap: () => context.pop()),
        Gap.h24,
      ],
    );
  }
}

class _DiscoveriesDashboardSection extends StatelessWidget {
  final List<RecapHighlight> highlights;
  const _DiscoveriesDashboardSection({required this.highlights});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      onFooterTap: () => _showDiscoveryDetails(context),
      footerLabel: 'View All Discoveries',
      child: Padding(
        padding: EdgeInsets.all(20.0.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Side: Discoveries Hero
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FINDINGS',
                    style: context.bodyBold.copyWith(
                      fontSize: 28.0.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      color: context.appColorScheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Weekly Highlights',
                    style: context.caption.copyWith(
                      color: context.appColorScheme.textMuted,
                      fontSize: 12.0.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Gap.h24,
                  Container(
                    padding: EdgeInsets.all(12.0.w),
                    decoration: BoxDecoration(
                      color: context.appColorScheme.border.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(AppIcons.sparkles, color: context.appColorScheme.textPrimary, size: 32.0.w),
                  ),
                ],
              ),
            ),
            Gap.w16,
            // Right Side: Highlights List
            Expanded(
              flex: 5,
              child: Column(
                children: highlights.take(3).map((RecapHighlight h) {
                  final color = InsightUiUtils.getIngredientColor(
                    h.color,
                    error: context.appColorScheme.error,
                    warning: context.appColorScheme.warning,
                    success: context.appColorScheme.success,
                  );
                  return Padding(
                    padding: EdgeInsets.only(bottom: 12.0.h),
                    child: DashboardDetailItem(
                      title: 'Discovery',
                      subtitle: h.text,
                      icon: InsightUiUtils.getReactionIcon(h.icon),
                      color: color,
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

  void _showDiscoveryDetails(BuildContext context) {
    BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: 'Weekly Discoveries',
      children: [
        SheetHeroSection(
          title: 'INSIGHTS',
          subtitle: 'AI-DRIVEN FINDINGS',
          color: context.appColorScheme.textPrimary,
          icon: AppIcons.sparkles,
        ),
        Gap.h32,
        ...highlights.map((RecapHighlight h) {
          return Padding(
            padding: EdgeInsets.only(bottom: 16.0.h),
            child: DashboardDetailItem(
              title: h.text,
              subtitle: 'Detected this week',
              icon: InsightUiUtils.getReactionIcon(h.icon),
              color: context.appColorScheme.textPrimary,
            ),
          );
        }),
        Gap.h32,
        GutButton(label: AppStrings.gotItThanks, onTap: () => context.pop()),
        Gap.h24,
      ],
    );
  }
}
