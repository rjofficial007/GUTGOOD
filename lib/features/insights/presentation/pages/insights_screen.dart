import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/insight_bento_feed.dart';
import 'package:provider/provider.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  @override
  void initState() {
    super.initState();
    // 🚀 §H/P2-10: Trigger a background check whenever the Insights tab is
    // visited. The UseCase internally gates this to a 24h cadence, so it's
    // a cheap no-op unless a new insight is actually due.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<InsightsNotifier>().generateNewInsight();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;

    return Scaffold(
      backgroundColor: context.appColorScheme.cardBackground,
      body: Consumer<InsightsNotifier>(
        builder: (context, notifier, _) {
          final latestInsight = notifier.latestInsight;
          // P2-10: Prioritize deterministic patterns from the dashboard state,
          // but fallback to the insight's own detected patterns if the
          // dashboard state is still loading or empty.
          final prioritizedPatterns = notifier.prioritizedPatterns.isNotEmpty ? notifier.prioritizedPatterns : (latestInsight?.detectedPatterns ?? []);

          // P2-10: show the shimmer when either the initial stream is loading
          // OR an explicit manual/bootstrap generation is in progress.
          final isLoading = notifier.isLoading || (latestInsight == null && notifier.isGenerating);

          return RefreshIndicator(
            onRefresh: notifier.generateNewInsight,
            color: colorScheme.cardBackground,
            backgroundColor: colorScheme.cardBackground,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                GutSliverAppBar(
                  title: AppStrings.insights,
                  actions: [
                    IconButton(
                      icon: Icon(AppIcons.history, color: colorScheme.textPrimary),
                      onPressed: () => unawaited(context.push(AppRoutes.insightHistory)),
                    ),
                    Gap.w10,
                  ],
                ),
                if (isLoading)
                  const _InsightsLoadingState()
                else if (latestInsight == null)
                  // Bento "learning grid" (v4 screen 02) — same unlock rule as
                  // before, presented as a partially mapped score hero.
                  InsightBentoLearning(meals: notifier.totalMeals, symptoms: notifier.totalSymptoms, scans: notifier.totalScans)
                else
                  // Bento grid feed (v4 screen 01). The app bar above and the
                  // MainShell bottom nav are unchanged, per the design brief.
                  InsightBentoFeed(data: latestInsight, patterns: prioritizedPatterns),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InsightsLoadingState extends StatelessWidget {
  const _InsightsLoadingState();

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: EdgeInsets.fromLTRB(AppSizes.p20, 0, AppSizes.p20, AppSizes.p10),
    sliver: const SliverToBoxAdapter(child: ShimmerGridLoader(itemCount: 4, variant: ShimmerVariant.scanResult)),
  );
}
