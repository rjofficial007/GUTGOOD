import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/ai_insight_details.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/insight_ui_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_insight_list.dart';
import 'package:gutgood/core/widgets/shimmer_grid_loader.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/usage_service.dart';

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
                  onPressed: () => context.push('/insight-history'),
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
  Widget build(BuildContext context) {
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: EmptyStateWidget(icon: AppIcons.barChart, title: AppStrings.noInsightsYet, description: AppStrings.keepLoggingForPatterns),
    );
  }
}

class _MainDashboardSliver extends StatelessWidget {
  final AIInsight data;
  const _MainDashboardSliver({required this.data});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(Responsive.w(20.0), 0, Responsive.w(20.0), Responsive.h(20.0)),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          GutSnapshotHeroCard(score: data.gutScore, scoreDiff: data.scoreDiff, streak: data.streak, simpleTrend: data.simpleTrend),
          Gap.h24,
          if (data.topInsight != null) ...[_ModernSmartAlert(insight: data.topInsight!), Gap.h24],
          if (data.healingGoal != null || data.triggerSymptom != null) ...[
            GutSection(
              title: AppStrings.currentFocus,
              info: AppStrings.currentFocusDesc,
              topPadding: 0,
              child: _FocusList(data: data),
            ),
            Gap.h24,
          ],
          if (data.healingFoods.isNotEmpty || data.triggerFoods.isNotEmpty) ...[
            GutSection(
              title: AppStrings.recommendations,
              info: AppStrings.recommendationsDesc,
              topPadding: 0,
              child: _RecommendationsList(data: data),
            ),
            Gap.h24,
          ],
          if (data.detectedPatterns.isNotEmpty) ...[
            GutSection(
              title: AppStrings.detectedPatternsLabel,
              info: AppStrings.detectedPatternsDesc,
              topPadding: 0,
              child: _PatternsList(patterns: data.detectedPatterns),
            ),
            Gap.h24,
          ],
          if (data.topHealing != null || data.topTrigger != null) ...[
            GutSection(
              title: AppStrings.highlightsLabel,
              info: AppStrings.highlightsDesc,
              topPadding: 0,
              child: _HighlightsList(data: data),
            ),
            Gap.h24,
          ],
          if (data.foodImpacts.isNotEmpty) ...[
            GutSection(
              title: AppStrings.bodyReactionsLabel,
              info: AppStrings.bodyReactionsDesc,
              topPadding: 0,
              child: _AnalyticsList(impacts: data.foodImpacts),
            ),
            Gap.h24,
          ],
          GutActionBanner(
            title: AppStrings.weeklyGutRecap,
            subtitle: AppStrings.last7DaysReady,
            icon: AppIcons.sparkles,
            onTap: () async {
              final isPremium = await sl<UsageService>().isPremium();
              if (!context.mounted) return;
              if (isPremium) {
                context.push('/weekly-recap', extra: data.toMap());
              } else {
                showPaywallBottomSheet(context, onProceedWithLimited: () {});
              }
            },
          ),
          Gap.h40,
        ]),
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
      padding: EdgeInsets.fromLTRB(Responsive.w(20.0), 0, Responsive.w(20.0), Responsive.h(20.0)),
      footer: Text(
        '${insight.type.toUpperCase()} INSIGHT',
        textAlign: TextAlign.center,
        style: context.caption.copyWith(color: context.appColorScheme.cardBackground, fontWeight: FontWeight.w900, fontSize: 10.0.sp, letterSpacing: 1.0),
      ),
      footerColor: context.appColorScheme.textPrimary,
      child: Text(
        insight.description,
        style: context.bodySm.copyWith(color: context.appColorScheme.textPrimary, height: 1.4, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _InsightsLoadingState extends StatelessWidget {
  const _InsightsLoadingState();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(20.0.w, 0, 20.0.w, 10.0.h),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          const ShimmerGridLoader(itemCount: 1, crossAxisCount: 1, variant: ShimmerVariant.hero),
          Gap.h24,
          const ShimmerGridLoader(itemCount: 1, crossAxisCount: 1, variant: ShimmerVariant.card),
          Gap.h24,
          const ShimmerGridLoader(itemCount: 4, variant: ShimmerVariant.grid),
        ]),
      ),
    );
  }
}

class _FocusList extends StatelessWidget {
  final AIInsight data;
  const _FocusList({required this.data});

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = [];
    if (data.healingGoal != null) {
      items.add(GutInsightTile(title: 'GOAL', value: data.healingGoal!, subtitle: 'Primary focus', icon: AppIcons.target, statusColor: context.appColorScheme.success));
    }
    if (data.triggerSymptom != null) {
      items.add(GutInsightTile(title: 'TRACKING', value: data.triggerSymptom!, subtitle: 'Recurring symptom', icon: AppIcons.activity, statusColor: context.appColorScheme.warning));
    }
    return GutInsightGrid(items: items);
  }
}

class _RecommendationsList extends StatelessWidget {
  final AIInsight data;
  const _RecommendationsList({required this.data});

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = [];

    for (var food in data.healingFoods) {
      items.add(GutInsightTile(title: 'HEALING', value: food.name, subtitle: food.effect, icon: AppIcons.leaf, statusColor: context.appColorScheme.success));
    }
    for (var food in data.triggerFoods) {
      items.add(GutInsightTile(title: 'TRIGGER', value: food.name, subtitle: food.effect, icon: AppIcons.alertCircle, statusColor: context.appColorScheme.error));
    }

    return GutInsightList(items: items);
  }
}

class _PatternsList extends StatelessWidget {
  final List<DetectedPattern> patterns;
  const _PatternsList({required this.patterns});

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = patterns.map((p) {
      final accentColor = InsightUiUtils.getPatternColor(p.icon);
      return GutInsightTile(title: 'PATTERN', value: p.title, subtitle: p.description, icon: InsightUiUtils.getReactionIcon(p.icon), statusColor: accentColor);
    }).toList();

    return GutInsightList(items: items);
  }
}

class _HighlightsList extends StatelessWidget {
  final AIInsight data;
  const _HighlightsList({required this.data});

  @override
  Widget build(BuildContext context) {
    final hasHealing = data.topHealing != null;
    final hasTrigger = data.topTrigger != null;

    if (!hasHealing && !hasTrigger) return const SizedBox.shrink();

    final List<Widget> items = [];
    if (hasHealing) {
      items.add(
        GutInsightTile(
          title: data.healingTrend ?? 'Power Source',
          value: data.topHealing!.food,
          subtitle: data.topHealing!.effects,
          statusColor: context.appColorScheme.success,
          icon: InsightUiUtils.getReactionIcon(data.topHealing?.emoji ?? ''),
        ),
      );
    }
    if (hasTrigger) {
      items.add(
        GutInsightTile(
          title: data.triggerTrend ?? 'Critical Alert',
          value: data.topTrigger!.food,
          subtitle: data.topTrigger!.effects,
          statusColor: context.appColorScheme.error,
          icon: InsightUiUtils.getReactionIcon(data.topTrigger!.emoji),
        ),
      );
    }

    return GutInsightList(items: items);
  }
}

class _AnalyticsList extends StatelessWidget {
  final List<FoodImpact> impacts;
  const _AnalyticsList({required this.impacts});

  @override
  Widget build(BuildContext context) {
    final validImpacts = impacts.where((i) => i.food.isNotEmpty && i.food != 'Unknown').toList();
    if (validImpacts.isEmpty) return const SizedBox.shrink();

    final List<Widget> items = validImpacts.take(4).map((impact) {
      final bool isNegative = impact.impactType == 'negative';
      return GutInsightTile(
        title: impact.timeframeLabel.isEmpty ? 'Reaction' : impact.timeframeLabel,
        value: impact.food,
        subtitle: impact.effect,
        statusColor: isNegative ? context.appColorScheme.error : context.appColorScheme.success,
        icon: InsightUiUtils.getReactionIcon(impact.emoji),
      );
    }).toList();

    return GutInsightList(items: items);
  }
}
