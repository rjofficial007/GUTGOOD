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
import 'package:gutgood/core/utils/extensions.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_dashboard_sections.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:provider/provider.dart';

import '../../../../features/product_details/presentation/widgets/scan_result_widgets.dart';

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

    return Scaffold(
      backgroundColor: context.appColorScheme.cardBackground,
      body: CustomScrollView(
        slivers: [
          const GutSliverAppBar(title: AppStrings.weeklyRecap, showBrandingIcon: false),
          _MainDashboardSliver(data: insight!, highlights: highlights),
        ],
      ),
    );
  }
}

class _MainDashboardSliver extends StatelessWidget {
  const _MainDashboardSliver({required this.data, required this.highlights});
  final AIInsight data;
  final List<RecapHighlight> highlights;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileNotifier>();
    final streak = profile.streak;
    final recap = data.weeklyRecap;

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Weekly Average Hero (Wallet Style with Date)
            DashboardEntrance(
              delay: 50,
              child: GutSnapshotHeroCard(
                score: recap?.avgScore ?? 0, 
                scoreDiff: recap?.scoreSub, 
                streak: streak, 
                isActive: false,
                title: recap?.dateRange ?? AppStrings.last7Days,
              ),
            ),
            Gap.h12,

            // 2. Weekly Metrics Grid
            DashboardEntrance(
              delay: 100,
              child: InsightMetricGrid(data: data),
            ),
            Gap.h12,

            // 3. Performance Highlight (Bento Card)
            DashboardEntrance(
              delay: 150,
              child: BentoCard(
                padding: const EdgeInsets.all(12),
                height: 180.h,
                backgroundColor: AppPalette.greenPastel,
                child: Row(
                  children: [
                    // Left block: Peak Performance
                    Container(
                      width: 156.h,
                      height: 156.h,
                      decoration: BoxDecoration(color: AppPalette.white.withAlpha(204), borderRadius: BorderRadius.circular(16)),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 12, left: 12,
                            child: Text('PEAK', style: context.captionMicro.copyWith(color: AppPalette.green, fontWeight: FontWeight.w900)),
                          ),
                          Center(child: Icon(AppIcons.star, size: 64.sp, color: AppPalette.green)),
                          Positioned(
                            bottom: 12, left: 12, right: 12,
                            child: Text(recap?.bestDay ?? 'N/A', textAlign: TextAlign.center, style: context.captionBold.copyWith(color: AppPalette.black)),
                          ),
                        ],
                      ),
                    ),
                    Gap.w16,
                    // Right info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(AppStrings.performanceHighlights.toUpperCase(), style: context.captionBold.copyWith(color: AppPalette.black.withAlpha(102))),
                          Gap.h8,
                          Text('${recap?.foodsLogged ?? 0} FOODS LOGGED', style: context.bodyBold.copyWith(color: AppPalette.black, fontWeight: FontWeight.w900, fontSize: 16.sp)),
                          Gap.h4,
                          Text(data.healingTrend ?? 'Stable weekly trend.', style: context.caption.copyWith(color: AppPalette.black.withAlpha(153), height: 1.3)),
                          Gap.h12,
                          Row(
                            children: [
                              Icon(AppIcons.trendingUp, size: 14, color: AppPalette.green),
                              Gap.w6,
                              Text('OPTIMIZING', style: context.captionBold.copyWith(color: AppPalette.green)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Gap.h12,

            // 4. Weekly Patterns (Discoveries)
            if (highlights.isNotEmpty) ...[
              ..._buildHighlightCards(context, highlights),
            ],

            // 5. Weekly Pulse (AI Intelligence)
            ModernSmartAlert(
              insight: InsightSummary(
                title: AppStrings.weeklyPulse,
                description: '${AppStrings.weeklyRecapNarrative}$streak${AppStrings.narrativeDaysAndGut}${data.healingTrend ?? AppStrings.optimizing}${AppStrings.narrativeBasedOnLogs}',
                type: 'Weekly',
              ),
            ),
            Gap.h40,
          ],
        ),
      ),
    );
  }

  List<Widget> _buildHighlightCards(BuildContext context, List<RecapHighlight> highlights) {
    final widgets = <Widget>[];
    final scheme = context.appColorScheme;
    
    for (var i = 0; i < highlights.length; i++) {
      final h = highlights[i];
      widgets.add(
        DashboardEntrance(
          delay: 200 + (i * 50),
          child: BentoCard(
            padding: const EdgeInsets.all(12),
            height: 140.h,
            backgroundColor: scheme.elevatedSurface,
            child: Row(
              children: [
                // Left Panel: Identity block
                Container(
                  width: 116.h,
                  height: 116.h,
                  decoration: BoxDecoration(color: AppPalette.purplePastel, borderRadius: BorderRadius.circular(16)),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Text(
                          'WEEKLY',
                          style: context.captionMicro.copyWith(color: AppPalette.black.withAlpha(102), fontWeight: FontWeight.w900),
                        ),
                      ),
                      Center(
                        child: Icon(AppIcons.lightbulb, size: 36.sp, color: AppPalette.black.withAlpha(153)),
                      ),
                    ],
                  ),
                ),
                Gap.w16,
                // Right Panel: Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.discovery.toUpperCase(),
                        style: context.captionBold.copyWith(color: scheme.textMuted, fontSize: 9.sp),
                      ),
                      Gap.h4,
                      Text(
                        h.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.bodyBold.copyWith(color: scheme.textPrimary, fontWeight: FontWeight.w900, fontSize: 15.sp, letterSpacing: -0.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      widgets.add(Gap.h12);
    }
    return widgets;
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
