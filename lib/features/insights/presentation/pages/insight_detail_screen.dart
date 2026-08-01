import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/ai_insight_details.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/bottom_sheet_helper.dart';
import 'package:gutgood/core/utils/insight_ui_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_sizes.dart';

class InsightDetailScreen extends StatelessWidget {
  final AIInsight insight;

  const InsightDetailScreen({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM dd, yyyy').format(insight.updatedAt);

    final List<Widget?> sections = [
      // 1. Snapshot Hero (Shared Style)
      GutSnapshotHeroCard(
        score: insight.gutScore,
        scoreDiff: insight.scoreDiff,
        streak: insight.streak,
        simpleTrend: insight.simpleTrend,
        isActive: false,
      ),

      // 2. Trends Dashboard
      if (insight.detectedPatterns.isNotEmpty)
        DashboardEntrance(
          delay: 100,
          child: _TrendsDashboardSection(patterns: insight.detectedPatterns),
        ),

      // 3. Stats Dashboard
      if (insight.topHealing != null || insight.topTrigger != null)
        DashboardEntrance(
          delay: 200,
          child: _StatsDashboardSection(insight: insight),
        ),

      // 4. Reactions Dashboard
      if (insight.foodImpacts.isNotEmpty)
        DashboardEntrance(
          delay: 300,
          child: _ReactionsDashboardSection(impacts: insight.foodImpacts),
        ),
    ];

    final visibleSections = sections.whereType<Widget>().toList();

    return Scaffold(
      backgroundColor: context.appColorScheme.cardBackground,
      body: CustomScrollView(
        slivers: [
          GutSliverAppBar(
            title: '${AppStrings.reportDate}${dateStr.toUpperCase()}',
            showBrandingIcon: false,
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p10),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final isLast = index == visibleSections.length - 1;
                  return Padding(
                    padding: EdgeInsets.only(bottom: isLast ? AppSizes.p64 : AppSizes.p32),
                    child: visibleSections[index],
                  );
                },
                childCount: visibleSections.length,
              ),
            ),
          ),
        ],
      ),
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
                    child: DashboardDetailItem(
                      title: p.title,
                      subtitle: AppStrings.observation,
                      icon: InsightUiUtils.getReactionIcon(p.icon),
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

  void _showTrendDetails(BuildContext context) {
    BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: AppStrings.observedPatterns,
      children: [
        SheetHeroSection(title: AppStrings.trends, subtitle: AppStrings.behavioralAnalysis, color: context.appColorScheme.textPrimary, icon: AppIcons.activity),
        Gap.h32,
        ...patterns.map((p) => Padding(
              padding: EdgeInsets.only(bottom: AppSizes.p16),
              child: DashboardDetailItem(
                title: p.title,
                subtitle: p.description,
                icon: InsightUiUtils.getReactionIcon(p.icon),
                color: context.appColorScheme.textPrimary,
              ),
            )),
        Gap.h32,
        GutButton(label: AppStrings.gotItThanks, onTap: () => Navigator.pop(context)),
        Gap.h24,
      ],
    );
  }
}

class _StatsDashboardSection extends StatelessWidget {
  final AIInsight insight;
  const _StatsDashboardSection({required this.insight});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      onFooterTap: () => _showStatDetails(context),
      footerLabel: AppStrings.viewPowerSources,
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
                    AppStrings.highlights,
                    style: context.caption.copyWith(color: context.appColorScheme.textMuted, fontSize: AppSizes.s12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Gap.h24,
                  const DashboardVisualizationBar(ratio: 0.85, label: AppStrings.dietaryEfficiency),
                ],
              ),
            ),
            Gap.w16,
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  if (insight.topHealing != null)
                    DashboardDetailItem(
                      title: insight.topHealing!.food,
                      subtitle: AppStrings.powerSource,
                      icon: InsightUiUtils.getReactionIcon(insight.topHealing!.emoji),
                      color: context.appColorScheme.success,
                    ),
                  if (insight.topHealing != null && insight.topTrigger != null) Gap.h12,
                  if (insight.topTrigger != null)
                    DashboardDetailItem(
                      title: insight.topTrigger!.food,
                      subtitle: AppStrings.triggerAlert,
                      icon: InsightUiUtils.getReactionIcon(insight.topTrigger!.emoji),
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

  void _showStatDetails(BuildContext context) {
    BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: AppStrings.weeklyHighlights,
      children: [
        SheetHeroSection(title: AppStrings.bioStats, subtitle: AppStrings.performanceAnalysis, color: context.appColorScheme.textPrimary, icon: AppIcons.trophy),
        Gap.h32,
        if (insight.topHealing != null) ...[
          SheetSectionHeader(title: AppStrings.topHealingFood, color: context.appColorScheme.textPrimary),
          DashboardDetailItem(
            title: insight.topHealing!.food,
            subtitle: insight.topHealing!.effects,
            icon: AppIcons.leaf,
            color: context.appColorScheme.textPrimary,
          ),
          Gap.h24,
        ],
        if (insight.topTrigger != null) ...[
          SheetSectionHeader(title: AppStrings.criticalTrigger, color: context.appColorScheme.textPrimary),
          DashboardDetailItem(
            title: insight.topTrigger!.food,
            subtitle: insight.topTrigger!.effects,
            icon: AppIcons.alertTriangle,
            color: context.appColorScheme.textPrimary,
          ),
          Gap.h24,
        ],
        Gap.h32,
        GutButton(label: AppStrings.gotItThanks, onTap: () => Navigator.pop(context)),
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
            child: DashboardDetailItem(
              title: i.food,
              subtitle: '${i.timeframeLabel}: ${i.effect}',
              icon: InsightUiUtils.getReactionIcon(i.emoji),
              color: context.appColorScheme.textPrimary,
            ),
          );
        }),
        Gap.h32,
        GutButton(label: AppStrings.gotItThanks, onTap: () => Navigator.pop(context)),
        Gap.h24,
      ],
    );
  }
}
