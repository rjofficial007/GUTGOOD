import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/bottom_sheet_helper.dart';
import 'package:gutgood/core/utils/insight_ui_utils.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_dashboard_sections.dart';
import 'package:gutgood/features/insights/presentation/widgets/neon_glow_card.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class InsightDetailScreen extends StatelessWidget {
  const InsightDetailScreen({super.key, required this.insight});
  final AIInsight insight;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM dd, yyyy').format(insight.updatedAt);

    return Scaffold(
      backgroundColor: context.appColorScheme.cardBackground,
      body: CustomScrollView(
        slivers: [
          GutSliverAppBar(title: '${AppStrings.reportDate}${dateStr.toUpperCase()}', showBrandingIcon: false),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p10),
            sliver: _InsightContentList(insight: insight),
          ),
        ],
      ),
    );
  }
}

class _InsightContentList extends StatelessWidget {
  const _InsightContentList({required this.insight});
  final AIInsight insight;

  @override
  Widget build(BuildContext context) {
    final sections = _buildSections(context);
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final isLast = index == sections.length - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? AppSizes.p64 : AppSizes.p32),
          child: sections[index],
        );
      }, childCount: sections.length),
    );
  }

  List<Widget> _buildSections(BuildContext context) {
    final notifier = context.watch<InsightsNotifier>();
    final profile = context.watch<ProfileNotifier>();
    final patterns = notifier.bodyPatterns;

    final sections = <Widget>[GutSnapshotHeroCard(score: insight.gutScore, scoreDiff: insight.scoreDiff, streak: profile.profile?.streak ?? 0, isActive: false)];

    // 2. BETTER ENERGY Section
    if (insight.healingFoods.isNotEmpty || insight.foodImpacts.any((i) => i.impactType == 'positive')) {
      final healingCount = insight.healingFoods.length + insight.foodImpacts.where((i) => i.impactType == 'positive').length;
      sections.add(
        DashboardEntrance(
          delay: 100,
          child: GestureDetector(
            onTap: () => _showBetterEnergyDetails(context),
            child: NeonGlowCard(
              metric: '$healingCount',
              label: AppStrings.betterEnergy,
              icon: AppIcons.zap,
              glowColor: AppPalette.green,
              items: [
                ...insight.healingFoods.map((f) => NeonGlowItem(title: f.name, subtitle: f.effect, isDone: true)),
                ...insight.foodImpacts.where((i) => i.impactType == 'positive').map((i) => NeonGlowItem(title: i.food, subtitle: i.effect, isDone: true)),
              ],
            ),
          ),
        ),
      );
    }

    // 3. BLOATING Section
    if (insight.triggerFoods.isNotEmpty || insight.foodImpacts.any((i) => i.impactType == 'negative')) {
      final triggerCount = insight.triggerFoods.length + insight.foodImpacts.where((i) => i.impactType == 'negative').length;
      sections.add(
        DashboardEntrance(
          delay: 200,
          child: GestureDetector(
            onTap: () => _showBloatingDetails(context),
            child: NeonGlowCard(
              metric: '$triggerCount',
              label: AppStrings.bloating,
              icon: AppIcons.alertTriangle,
              glowColor: AppPalette.red,
              items: [
                ...insight.triggerFoods.map((f) => NeonGlowItem(title: f.name, subtitle: f.effect, isDone: true)),
                ...insight.foodImpacts.where((i) => i.impactType == 'negative').map((i) => NeonGlowItem(title: i.food, subtitle: i.effect, isDone: true)),
              ],
            ),
          ),
        ),
      );
    }

    // 4. SYSTEM DISCOVERIES (PatternEngine Data)
    if (patterns.isNotEmpty) {
      sections.add(
        DashboardEntrance(
          delay: 300,
          child: GestureDetector(
            onTap: () => _showSystemDiscoveryDetails(context, patterns),
            child: NeonGlowCard(
              metric: '${patterns.length}',
              label: AppStrings.systemDiscoveries,
              icon: AppIcons.brain,
              glowColor: AppPalette.purple,
              items: patterns.map((p) => NeonGlowItem(title: p.trigger.toUpperCase(), subtitle: p.description, isDone: true)).toList(),
            ),
          ),
        ),
      );
    }

    // 5. RECENT LOGS
    if (insight.foodImpacts.isNotEmpty) {
      sections.add(
        DashboardEntrance(
          delay: 400,
          child: GestureDetector(
            onTap: () => _showRecentPatternsDetails(context),
            child: NeonGlowCard(
              metric: '${insight.foodImpacts.length}',
              label: AppStrings.recentLogs,
              icon: AppIcons.history,
              glowColor: AppPalette.blue,
              items: insight.foodImpacts.map((i) => NeonGlowItem(title: i.food, subtitle: '${i.timeframeLabel}: ${i.effect}')).toList(),
            ),
          ),
        ),
      );
    }

    // 6. TOP PERFORMERS Section
    if (insight.topHealing != null || insight.topTrigger != null) {
      sections.add(
        DashboardEntrance(
          delay: 500,
          child: GestureDetector(
            onTap: () => _showTopPerformersDetails(context),
            child: NeonGlowCard(
              metric: insight.topHealing?.frequency ?? 'MVP',
              label: AppStrings.topPerformers,
              icon: AppIcons.trophy,
              glowColor: AppPalette.green,
              items: [
                if (insight.topHealing != null) NeonGlowItem(title: 'BEST: ${insight.topHealing!.food}', subtitle: insight.topHealing!.effects, isDone: true),
                if (insight.topTrigger != null) NeonGlowItem(title: 'MOST REACTIVE: ${insight.topTrigger!.food}', subtitle: insight.topTrigger!.effects),
              ],
            ),
          ),
        ),
      );
    }

    if (insight.topInsight != null) {
      sections.add(ModernSmartAlert(insight: insight.topInsight!));
    }

    return sections;
  }

  // Detail Sheet Handlers
  void _showBetterEnergyDetails(BuildContext context) {
    final healing = insight.healingFoods;
    final successes = insight.foodImpacts.where((i) => i.impactType == 'positive' && i.food != 'Unknown').toList();

    BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: AppStrings.betterEnergyTitle,
      children: [
        SheetHeroSection(title: AppStrings.heal, subtitle: AppStrings.evidenceBackedBenefits, color: context.appColorScheme.success, icon: AppIcons.leaf),
        if (insight.healingTrend != null) ...[
          Gap.h24,
          Text(
            insight.healingTrend!,
            style: context.body.copyWith(color: context.appColorScheme.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
        Gap.h32,
        if (healing.isNotEmpty) ...[
          SheetSectionHeader(title: AppStrings.recommendations, color: context.appColorScheme.textPrimary),
          ...healing.map(
            (f) => Padding(
              padding: EdgeInsets.only(bottom: AppSizes.p16),
              child: DashboardDetailItem(title: f.name, subtitle: f.effect, icon: InsightUiUtils.getReactionIcon(f.emoji), color: context.appColorScheme.success),
            ),
          ),
          Gap.h24,
        ],
        if (successes.isNotEmpty) ...[
          SheetSectionHeader(title: AppStrings.loggedSuccesses, color: context.appColorScheme.textPrimary),
          ...successes.map(
            (i) => Padding(
              padding: EdgeInsets.only(bottom: AppSizes.p16),
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

  void _showBloatingDetails(BuildContext context) {
    final triggers = insight.triggerFoods;
    final reactions = insight.foodImpacts.where((i) => i.impactType == 'negative' && i.food != 'Unknown').toList();

    BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: AppStrings.bloatingAndTriggersTitle,
      children: [
        SheetHeroSection(title: AppStrings.alert, subtitle: AppStrings.potentialTriggers, color: context.appColorScheme.error, icon: AppIcons.alertTriangle),
        if (insight.triggerTrend != null) ...[
          Gap.h24,
          Text(
            insight.triggerTrend!,
            style: context.body.copyWith(color: context.appColorScheme.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
        Gap.h32,
        if (triggers.isNotEmpty) ...[
          SheetSectionHeader(title: AppStrings.warnings, color: context.appColorScheme.textPrimary),
          ...triggers.map(
            (f) => Padding(
              padding: EdgeInsets.only(bottom: AppSizes.p16),
              child: DashboardDetailItem(title: f.name, subtitle: f.effect, icon: InsightUiUtils.getReactionIcon(f.emoji), color: context.appColorScheme.error),
            ),
          ),
          Gap.h24,
        ],
        if (reactions.isNotEmpty) ...[
          SheetSectionHeader(title: AppStrings.loggedReactions, color: context.appColorScheme.textPrimary),
          ...reactions.map(
            (i) => Padding(
              padding: EdgeInsets.only(bottom: AppSizes.p16),
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

  void _showSystemDiscoveryDetails(BuildContext context, List<BodyPattern> patterns) {
    BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: AppStrings.systemDiscoveriesTitle,
      children: [
        SheetHeroSection(title: AppStrings.logic, subtitle: AppStrings.deterministicCorrelations, color: context.appColorScheme.textPrimary, icon: AppIcons.database),
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

  void _showRecentPatternsDetails(BuildContext context) {
    BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: AppStrings.recentActivityTitle,
      children: [
        SheetHeroSection(title: AppStrings.logs, subtitle: AppStrings.historicalCorrelations, color: context.appColorScheme.textPrimary, icon: AppIcons.activity),
        Gap.h32,
        ...insight.foodImpacts.map(
          (i) => Padding(
            padding: EdgeInsets.only(bottom: AppSizes.p16),
            child: DashboardDetailItem(
              title: i.food,
              subtitle: '${i.dateLabel} • ${i.timeframeLabel}: ${i.effect}',
              icon: InsightUiUtils.getReactionIcon(i.emoji),
              color: i.impactType == 'positive' ? context.appColorScheme.success : context.appColorScheme.error,
            ),
          ),
        ),
        Gap.h32,
        GutButton(label: AppStrings.gotItThanks, onTap: () => context.pop()),
        Gap.h24,
      ],
    );
  }

  void _showTopPerformersDetails(BuildContext context) {
    BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: AppStrings.frequencyStatsTitle,
      children: [
        SheetHeroSection(title: AppStrings.bioStats, subtitle: AppStrings.highConfidenceFrequency, color: context.appColorScheme.textPrimary, icon: AppIcons.barChart),
        Gap.h32,
        if (insight.topHealing != null) ...[
          SheetSectionHeader(title: AppStrings.bestForGut, color: context.appColorScheme.success),
          DashboardDetailItem(
            title: insight.topHealing!.food,
            subtitle: '${insight.topHealing!.frequency} Log Consistency: ${insight.topHealing!.effects}',
            icon: AppIcons.checkCircle,
            color: context.appColorScheme.success,
          ),
          Gap.h24,
        ],
        if (insight.topTrigger != null) ...[
          SheetSectionHeader(title: AppStrings.mostReactive, color: context.appColorScheme.error),
          DashboardDetailItem(
            title: insight.topTrigger!.food,
            subtitle: '${insight.topTrigger!.frequency} Log Consistency: ${insight.topTrigger!.effects}',
            icon: AppIcons.alertCircle,
            color: context.appColorScheme.error,
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
