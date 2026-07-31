import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/insight_ui_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/widgets.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_palette.dart';

class WeeklyRecapScreen extends StatelessWidget {
  final AIInsight? insight;
  const WeeklyRecapScreen({super.key, this.insight});

  @override
  Widget build(BuildContext context) {
    final recap = insight?.weeklyRecap;
    final highlights = recap?.highlights ?? [];

    return Scaffold(
      backgroundColor: context.appColorScheme.cardBackground,
      appBar: const GutAppBar(title: AppStrings.weeklyRecap),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: Responsive.w(20.0), vertical: Responsive.h(10.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Range Header
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 6.0.h),
                decoration: BoxDecoration(
                  color: AppPalette.purple.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppPalette.purple.withValues(alpha: 0.1)),
                ),
                child: Text(
                  recap?.dateRange ?? AppStrings.last7Days,
                  style: context.eyebrow.copyWith(color: AppPalette.purple, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            Gap.h24,

            // 1. Primary Hero (Gauge View - Average Score)
            GutSnapshotHeroCard(score: recap?.avgScore ?? 0, scoreDiff: recap?.scoreSub, streak: insight?.streak ?? 0, simpleTrend: insight?.simpleTrend ?? [], isActive: true),
            Gap.h24,
            // 3. Narrative Summary
            _buildNarrativeCard(context),
            Gap.h32,
            // 2. Key Metrics Grid
            AdaptiveGrid(
              mainAxisExtent: Responsive.h(140.0),
              items: [
                GutInsightTile(
                  title: AppStrings.avgGutScore,
                  value: '${recap?.avgScore ?? 0}',
                  subtitle: AppStrings.overallHealth,
                  icon: AppIcons.activity,
                  statusColor: context.appColorScheme.success,
                ),
                GutInsightTile(title: AppStrings.peakDay, value: recap?.bestDay ?? 'N/A', subtitle: AppStrings.bestPerformanceSubtitle, icon: AppIcons.trophy, statusColor: AppPalette.lime),
                GutInsightTile(
                  title: AppStrings.logs,
                  value: '${recap?.foodsLogged ?? 0}',
                  subtitle: recap?.loggedSub ?? '',
                  icon: AppIcons.clipboardList,
                  statusColor: context.appColorScheme.warning,
                ),
                GutInsightTile(
                  title: AppStrings.weeklyTrend,
                  value: insight?.healingTrend?.toUpperCase() ?? AppStrings.stable,
                  subtitle: AppStrings.recentProgress,
                  icon: AppIcons.zap,
                  statusColor: AppPalette.purple,
                ),
              ],
            ),
            Gap.h24,
            // 4. Weekly Discoveries Section
            GutSection(
              title: AppStrings.discoveriesTitle,
              info: AppStrings.discoveriesSubtitle,
              topPadding: 0,
              child: highlights.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0.h),
                        child: Text(AppStrings.keepLoggingForHighlights, style: context.bodySm.copyWith(color: context.appColorScheme.textMuted)),
                      ),
                    )
                  : Column(
                      children: highlights.map((h) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12.0.h),
                          child: GutInsightTile(
                            title: AppStrings.discovery,
                            value: h.text,
                            subtitle: '',
                            icon: InsightUiUtils.getReactionIcon(h.icon),
                            statusColor: InsightUiUtils.getIngredientColor(
                              h.color,
                              error: context.appColorScheme.error,
                              warning: context.appColorScheme.warning,
                              success: context.appColorScheme.success,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
            Gap.h32,

            // 5. Achievement Banner
            _buildAchievementBanner(context).animate().scale(duration: 400.ms, curve: Curves.easeOutBack).fadeIn(),
            Gap.h40,
          ],
        ),
      ),
    );
  }

  Widget _buildNarrativeCard(BuildContext context) {
    final streak = insight?.streak ?? 0;
    final healingTrend = insight?.healingTrend ?? AppStrings.optimizing;

    return ModernInsightCard(
      title: AppStrings.weeklySummaryTitle,
      icon: AppIcons.sparkles,
      iconColor: context.appColorScheme.textPrimary,
      padding: EdgeInsets.fromLTRB(Responsive.w(24.0), 0, Responsive.w(24.0), Responsive.h(24.0)),
      backgroundColor: context.appColorScheme.cardBackground,
      titleColor: context.appColorScheme.textPrimary,
      footer: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(AppIcons.sparkles, size: 14.0.w, color: AppPalette.black),
          Gap.w8,
          Text(
            AppStrings.aiGeneratedAnalysis,
            style: context.caption.copyWith(color: context.appColorScheme.cardBackground, fontWeight: FontWeight.w900, fontSize: 10.0.sp, letterSpacing: 1.0),
          ),
        ],
      ),
      footerColor: context.appColorScheme.textPrimary,
      child: Text(
        "${AppStrings.weeklyRecapNarrative}$streak${AppStrings.narrativeDaysAndGut}$healingTrend${AppStrings.narrativeBasedOnLogs}",
        style: context.body.copyWith(color: context.appColorScheme.textPrimary, height: 1.5, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildAchievementBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.w(20.0)),
      decoration: BoxDecoration(
        color: context.appColorScheme.cardBackground,
        borderRadius: BorderRadius.circular(24.0.r),
        border: Border.all(color: context.appColorScheme.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.0.w),
            decoration: BoxDecoration(color: AppPalette.lime.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(AppIcons.trophy, color: AppPalette.lime, size: 24.0.w),
          ),
          Gap.w16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.champion.toUpperCase(),
                  style: context.eyebrow.copyWith(color: AppPalette.lime, fontSize: 10.0.sp, letterSpacing: 1.5),
                ),
                Gap.h4,
                Text(
                  AppStrings.greatConsistency,
                  style: context.bodyBold.copyWith(color: context.appColorScheme.textPrimary, fontSize: 13.0.sp),
                ),
              ],
            ),
          ),
          Icon(AppIcons.sparkles, color: AppPalette.lime, size: 16.0.w),
        ],
      ),
    );
  }
}
