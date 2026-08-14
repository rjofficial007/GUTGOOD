import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/ai_insight_details.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/shimmer_grid_loader.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/analysis_card.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:provider/provider.dart';

class WeeklyRecapScreen extends StatelessWidget {
  const WeeklyRecapScreen({super.key, this.insight});
  final AIInsight? insight;

  @override
  Widget build(BuildContext context) {
    final recap = insight?.weeklyRecap;
    final highlights = recap?.highlights ?? [];

    if (insight != null) {
      unawaited(sl<AnalyticsService>().logEvent(name: 'view_weekly_recap', parameters: {'avg_score': recap?.avgScore ?? 0, 'foods_logged': recap?.foodsLogged ?? 0}));
    }

    if (insight == null) {
      return const _RecapLoadingView();
    }

    final visibleSections = _buildSections(context, recap, highlights);

    return Scaffold(
      backgroundColor: context.appColorScheme.cardBackground,
      appBar: const GutAppBar(title: AppStrings.weeklyRecap),
      body: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p10),
        itemCount: visibleSections.length,
        itemBuilder: (context, index) {
          final isLast = index == visibleSections.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? AppSizes.p20 : AppSizes.p20),
            child: visibleSections[index],
          );
        },
      ),
    );
  }

  List<Widget> _buildSections(BuildContext context, WeeklyRecap? recap, List<RecapHighlight> highlights) {
    final profile = context.watch<ProfileNotifier>();

    final sections = <Widget>[
      const _RecapDateHeader(),
      GutSnapshotHeroCard(score: recap?.avgScore ?? 0, scoreDiff: recap?.scoreSub, streak: profile.profile?.streak ?? 0, isActive: true),

      DashboardEntrance(
        delay: 200,
        child: AnalysisCard(
          metric: '${recap?.avgScore ?? 0}',
          label: AppStrings.performanceHighlights,
          icon: AppIcons.barChart,
          glowColor: AppPalette.green,
          items: [
            AnalysisItem(title: recap?.bestDay ?? 'N/A', subtitle: AppStrings.peakPerformance, icon: AppIcons.star, isDone: true),
            AnalysisItem(title: '${recap?.foodsLogged ?? 0}', subtitle: AppStrings.totalLogs, icon: AppIcons.utensils, isDone: true),
            AnalysisItem(title: insight!.healingTrend?.toUpperCase() ?? AppStrings.stable, subtitle: AppStrings.weeklyTrend, icon: AppIcons.trendingUp, isDone: true),
          ],
        ),
      ),
    ];

    if (highlights.isNotEmpty) {
      sections.add(
        DashboardEntrance(
          delay: 300,
          child: AnalysisCard(
            metric: '${highlights.length}',
            label: AppStrings.yourPatterns,
            icon: AppIcons.brain,
            glowColor: AppPalette.purple,
            items: highlights.map((h) => AnalysisItem(title: h.text, subtitle: AppStrings.discovery, icon: AppIcons.lightbulb, isDone: true)).toList(),
          ),
        ),
      );
    }

    sections.add(DashboardEntrance(delay: 300, child: _ModernSmartAlert(insight: insight!)));

    return sections;
  }
}

class _RecapLoadingView extends StatelessWidget {
  const _RecapLoadingView();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.appColorScheme.cardBackground,
    appBar: const GutAppBar(title: AppStrings.weeklyRecap),
    body: Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p10),
      child: const ShimmerGridLoader(variant: ShimmerVariant.recap),
    ),
  );
}

class _RecapDateHeader extends StatelessWidget {
  const _RecapDateHeader();

  @override
  Widget build(BuildContext context) {
    final recap = context.read<InsightsNotifier>().latestInsight?.weeklyRecap;
    return Center(
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
    );
  }
}

class _ModernSmartAlert extends StatelessWidget {
  const _ModernSmartAlert({required this.insight});
  final AIInsight insight;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileNotifier>().profile;
    final streak = profile?.streak ?? 0;
    final healingTrend = insight.healingTrend ?? AppStrings.optimizing;
    final description = '${AppStrings.weeklyRecapNarrative}$streak${AppStrings.narrativeDaysAndGut}$healingTrend${AppStrings.narrativeBasedOnLogs}';

    return ModernInsightCard(
      title: AppStrings.weeklyPulse,
      icon: AppIcons.salad,
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
