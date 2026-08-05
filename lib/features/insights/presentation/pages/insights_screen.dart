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
import 'package:gutgood/core/utils/bottom_sheet_helper.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/shimmer_grid_loader.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_dashboard_sections.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:provider/provider.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
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
            const _InsightsView(),
          ],
        ),
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

        return _MainDashboardSliver(data: data);
      },
    );
}

class _NoInsightsState extends StatelessWidget {
  const _NoInsightsState();

  @override
  Widget build(BuildContext context) => const SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyStateWidget(
          icon: AppIcons.barChart,
          title: AppStrings.noInsightsYet,
          description: AppStrings.keepLoggingForPatterns,
        ),
      );
}

class _MainDashboardSliver extends StatelessWidget {
  const _MainDashboardSliver({required this.data});
  final AIInsight data;

  @override
  Widget build(BuildContext context) {
    final sections = _buildSections(context);

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(AppSizes.p20, 0, AppSizes.p20, AppSizes.p20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final isLast = index == sections.length - 1;
            return Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? AppSizes.p64 : AppSizes.p32,
              ),
              child: sections[index],
            );
          },
          childCount: sections.length,
        ),
      ),
    );
  }

  List<Widget> _buildSections(BuildContext context) => [
      Selector<ProfileNotifier, int>(
        selector: (_, provider) => provider.profile?.streak ?? 0,
        builder: (context, streak, _) => GutSnapshotHeroCard(
          score: data.gutScore,
          scoreDiff: data.scoreDiff,
          streak: streak,
        ),
      ),
      Selector<InsightsNotifier, List<AIInsight>>(
        selector: (_, provider) => provider.insightHistory,
        builder: (context, history, _) => TrendCard(
          insights: history,
          currentInsight: data,
        ),
      ),
      if (data.healingGoal != null || data.triggerSymptom != null) GoalDashboardSection(insight: data),
      if (data.healingFoods.isNotEmpty || data.foodImpacts.any((i) => i.impactType == 'positive'))
        PowerSourcesDashboardSection(insight: data),
      if (data.triggerFoods.isNotEmpty || data.foodImpacts.any((i) => i.impactType == 'negative'))
        TriggersDashboardSection(insight: data),
      if (data.detectedPatterns.isNotEmpty)
        PatternsDashboardSection(
          insight: data,
          delay: 300,
        ),
      Selector<InsightsNotifier, List<BodyPattern>>(
        selector: (_, provider) => provider.bodyPatterns,
        builder: (context, patterns, _) {
          if (patterns.isEmpty) return const SizedBox.shrink();
          return _SystemDiscoverySection(patterns: patterns);
        },
      ),
      if (data.topHealing != null || data.topTrigger != null)
        HighlightsDashboardSection(
          insight: data,
          delay: 350,
        ),
      if (data.topInsight != null) ModernSmartAlert(insight: data.topInsight!),
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
}

class _SystemDiscoverySection extends StatelessWidget {
  const _SystemDiscoverySection({required this.patterns});
  final List<BodyPattern> patterns;

  @override
  Widget build(BuildContext context) => DashboardEntrance(
      delay: 320,
      child: GutDashboardSection(
        title: 'SYSTEM DISCOVERIES',
        subtitle: 'Evidence-based correlations',
        visualization: Container(
          padding: EdgeInsets.all(AppSizes.p12),
          decoration: BoxDecoration(
            color: context.appColorScheme.border.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            AppIcons.database,
            color: context.appColorScheme.textPrimary,
            size: AppSizes.icon32,
          ),
        ),
        items: patterns
            .take(2)
            .map(
              (p) => Padding(
                padding: EdgeInsets.only(bottom: AppSizes.p12),
                child: DashboardDetailItem(
                  title: p.trigger,
                  subtitle: p.reaction,
                  icon: AppIcons.activity,
                  color: context.appColorScheme.textPrimary,
                ),
              ),
            )
            .toList(),
        footerLabel: 'View All Correlations',
        onFooterTap: () => _showSystemDiscoveryDetails(context, patterns),
      ),
    );

  void _showSystemDiscoveryDetails(BuildContext context, List<BodyPattern> patterns) {
    BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: 'SYSTEM DISCOVERIES',
      children: [
        SheetHeroSection(
          title: 'DATA',
          subtitle: 'Verified Correlations',
          color: context.appColorScheme.textPrimary,
          icon: AppIcons.database,
        ),
        Gap.h32,
        ...patterns.map(
          (p) => Padding(
            padding: EdgeInsets.only(bottom: AppSizes.p16),
            child: DashboardDetailItem(
              title: p.trigger,
              subtitle: p.description,
              icon: AppIcons.checkCircle,
              color: context.appColorScheme.textPrimary,
            ),
          ),
        ),
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
