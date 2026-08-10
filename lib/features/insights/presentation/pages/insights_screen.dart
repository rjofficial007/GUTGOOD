import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/services/usage_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/bottom_sheet_helper.dart';
import 'package:gutgood/core/utils/insight_ui_utils.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/shimmer_grid_loader.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_dashboard_sections.dart';
import 'package:gutgood/features/insights/presentation/widgets/neon_glow_card.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:provider/provider.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.appColorScheme.cardBackground,
    body: CustomScrollView(
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
        const _InsightsView(),
      ],
    ),
  );
}

class _InsightsView extends StatelessWidget {
  const _InsightsView();

  @override
  Widget build(BuildContext context) => Consumer<InsightsNotifier>(
    builder: (context, notifier, _) {
      if (notifier.isLoading) return const _InsightsLoadingState();

      final data = notifier.latestInsight;
      if (data == null) return const _NoInsightsState();

      return _MainDashboardSliver(data: data, patterns: notifier.bodyPatterns);
    },
  );
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
  const _MainDashboardSliver({required this.data, required this.patterns});
  final AIInsight data;
  final List<BodyPattern> patterns;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileNotifier>();

    final sections = _buildSections(context: context, streak: profile.profile?.streak ?? 0);

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p10),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final isLast = index == sections.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? AppSizes.p64 : AppSizes.p32),
            child: sections[index],
          );
        }, childCount: sections.length),
      ),
    );
  }

  List<Widget> _buildSections({required BuildContext context, required int streak}) {
    final sections = <Widget>[GutSnapshotHeroCard(score: data.gutScore, scoreDiff: data.scoreDiff, streak: streak)];

    // 2. BETTER ENERGY (healingFoods)
    if (data.healingFoods.isNotEmpty || data.foodImpacts.any((i) => i.impactType == 'positive')) {
      final healingCount = data.healingFoods.length + data.foodImpacts.where((i) => i.impactType == 'positive').length;
      sections.add(
        DashboardEntrance(
          delay: 100,
          child: GestureDetector(
            onTap: () => _showBetterEnergyDetails(context),
            child: NeonGlowCard(
              metric: '$healingCount',
              label: 'BETTER ENERGY',
              icon: Icons.bolt,
              glowColor: AppPalette.green,
              items: [
                ...data.healingFoods.map((f) => NeonGlowItem(title: f.name, subtitle: f.effect, isDone: true)),
                ...data.foodImpacts.where((i) => i.impactType == 'positive').map((i) => NeonGlowItem(title: i.food, subtitle: i.effect, isDone: true)),
              ],
            ),
          ),
        ),
      );
    }

    // 3. BLOATING (triggerFoods)
    if (data.triggerFoods.isNotEmpty || data.foodImpacts.any((i) => i.impactType == 'negative')) {
      final triggerCount = data.triggerFoods.length + data.foodImpacts.where((i) => i.impactType == 'negative').length;
      sections.add(
        DashboardEntrance(
          delay: 200,
          child: GestureDetector(
            onTap: () => _showBloatingDetails(context),
            child: NeonGlowCard(
              metric: '$triggerCount',
              label: 'BLOATING TRIGGERS',
              icon: Icons.error_outline,
              glowColor: AppPalette.red,
              items: [
                ...data.triggerFoods.map((f) => NeonGlowItem(title: f.name, subtitle: f.effect, isDone: true)),
                ...data.foodImpacts.where((i) => i.impactType == 'negative').map((i) => NeonGlowItem(title: i.food, subtitle: i.effect, isDone: true)),
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
            onTap: () => _showSystemDiscoveryDetails(context),
            child: NeonGlowCard(
              metric: '${patterns.length}',
              label: 'SYSTEM DISCOVERIES',
              icon: Icons.psychology,
              glowColor: AppPalette.purple,
              items: patterns.map((p) => NeonGlowItem(title: p.trigger.toUpperCase(), subtitle: p.description, isDone: true)).toList(),
            ),
          ),
        ),
      );
    }

    // 5. RECENT PATTERNS (foodImpacts)
    if (data.foodImpacts.isNotEmpty) {
      sections.add(
        DashboardEntrance(
          delay: 400,
          child: GestureDetector(
            onTap: () => _showRecentPatternsDetails(context),
            child: NeonGlowCard(
              metric: '${data.foodImpacts.length}',
              label: 'RECENT LOGS',
              icon: Icons.history,
              glowColor: AppPalette.blue,
              items: data.foodImpacts.map((i) => NeonGlowItem(title: i.food, subtitle: '${i.timeframeLabel}: ${i.effect}')).toList(),
            ),
          ),
        ),
      );
    }

    // 6. STATISTICAL MVP (topHealing/topTrigger)
    if (data.topHealing != null || data.topTrigger != null) {
      sections.add(
        DashboardEntrance(
          delay: 500,
          child: GestureDetector(
            onTap: () => _showTopPerformersDetails(context),
            child: NeonGlowCard(
              metric: data.topHealing?.frequency ?? 'MVP',
              label: 'TOP PERFORMANCE',
              icon: Icons.emoji_events_outlined,
              glowColor: AppPalette.green,
              items: [
                if (data.topHealing != null) NeonGlowItem(title: 'BEST: ${data.topHealing!.food}', subtitle: data.topHealing!.effects, isDone: true),
                if (data.topTrigger != null) NeonGlowItem(title: 'MOST REACTIVE: ${data.topTrigger!.food}', subtitle: data.topTrigger!.effects),
              ],
            ),
          ),
        ),
      );
    }

    // 7. AI SMART ALERT
    if (data.topInsight != null) {
      sections.add(ModernSmartAlert(insight: data.topInsight!));
    }

    sections.add(
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
    );

    return sections;
  }

  // Detail Sheet Handlers
  void _showBetterEnergyDetails(BuildContext context) {
    final healing = data.healingFoods;
    final successes = data.foodImpacts.where((i) => i.impactType == 'positive' && i.food != 'Unknown').toList();

    BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: AppStrings.betterEnergyTitle,
      children: [
        SheetHeroSection(title: AppStrings.heal, subtitle: AppStrings.evidenceBackedBenefits, color: context.appColorScheme.success, icon: AppIcons.leaf),
        if (data.healingTrend != null) ...[
          Gap.h24,
          Text(
            data.healingTrend!,
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
    final triggers = data.triggerFoods;
    final reactions = data.foodImpacts.where((i) => i.impactType == 'negative' && i.food != 'Unknown').toList();

    BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: AppStrings.bloatingAndTriggersTitle,
      children: [
        SheetHeroSection(title: AppStrings.alert, subtitle: AppStrings.potentialTriggers, color: context.appColorScheme.error, icon: AppIcons.alertTriangle),
        if (data.triggerTrend != null) ...[
          Gap.h24,
          Text(
            data.triggerTrend!,
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

  void _showSystemDiscoveryDetails(BuildContext context) {
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
        ...data.foodImpacts.map(
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
        if (data.topHealing != null) ...[
          SheetSectionHeader(title: AppStrings.bestForGut, color: context.appColorScheme.success),
          DashboardDetailItem(
            title: data.topHealing!.food,
            subtitle: '${data.topHealing!.frequency} Log Consistency: ${data.topHealing!.effects}',
            icon: AppIcons.checkCircle,
            color: context.appColorScheme.success,
          ),
          Gap.h24,
        ],
        if (data.topTrigger != null) ...[
          SheetSectionHeader(title: AppStrings.mostReactive, color: context.appColorScheme.error),
          DashboardDetailItem(
            title: data.topTrigger!.food,
            subtitle: '${data.topTrigger!.frequency} Log Consistency: ${data.topTrigger!.effects}',
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

class _InsightsLoadingState extends StatelessWidget {
  const _InsightsLoadingState();

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: EdgeInsets.fromLTRB(AppSizes.p20, 0, AppSizes.p20, AppSizes.p10),
    sliver: const ShimmerGridLoader(itemCount: 4, variant: ShimmerVariant.scanResult),
  );
}
