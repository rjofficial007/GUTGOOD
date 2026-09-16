import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_theme.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/v2_feed.dart';
import 'package:provider/provider.dart';

/// The Insights tab — "v2 Real Tokens" presentation.
///
/// The data plumbing (notifier stream, 24h generation cadence, threshold
/// bootstrap) is unchanged; this screen now renders the v2 language: a quiet
/// editorial header (GutGood / serif *Insights* / tagline), then the v2 feed
/// (score hero → top-insight pager → What's Improving → Something to Watch).
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
    final v2 = context.v2Theme;

    return Scaffold(
      backgroundColor: v2.scaffold,
      body: Consumer<InsightsNotifier>(
        builder: (context, notifier, _) {
          final latestInsight = notifier.latestInsight;
          // P2-10: Prioritize deterministic patterns from the dashboard state,
          // but fallback to the insight's own detected patterns if the
          // dashboard state is still loading or empty.
          final prioritizedPatterns = notifier.prioritizedPatterns.isNotEmpty ? notifier.prioritizedPatterns : (latestInsight?.detectedPatterns ?? []);

          // Real per-day score window for the improving card's trend chart.
          final scoreSeries = scoreWindowFor(notifier, latestInsight);

          // P2-10: show the shimmer when either the initial stream is loading
          // OR an explicit manual/bootstrap generation is in progress.
          final isLoading = notifier.isLoading || (latestInsight == null && notifier.isGenerating);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Standardized shared app bar — same component, background,
              // typography and action pattern as every other tab.
              GutSliverAppBar(
                title: AppStrings.insights,
                actions: [
                  IconButton(
                    icon: Icon(AppIcons.history, color: context.appColorScheme.textPrimary),
                    onPressed: () => unawaited(context.push(AppRoutes.insightHistory)),
                  ),
                  Gap.w10,
                ],
              ),
              if (isLoading)
                const _InsightsLoadingState()
              else if (latestInsight == null)
                // Pre-threshold learning state (v2 language, same unlock rule).
                V2InsightsLearning(meals: notifier.totalMeals, symptoms: notifier.totalSymptoms, scans: notifier.totalScans)
              else
                V2InsightsFeed(data: latestInsight, patterns: prioritizedPatterns, series: scoreSeries, history: notifier.insightHistory),
            ],
          );
        },
      ),
    );
  }

  /// Chronological ≤7-point score window ending at [insight] (the same rule
  /// the previous feed used via `BentoData.scoreWindow`).
  static List<double> scoreWindowFor(InsightsNotifier notifier, AIInsight? insight) {
    if (insight == null) return const <double>[];
    try {
      final history = notifier.insightHistory;
      final sorted = [...history]..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      if (!sorted.any((i) => i.updatedAt == insight.updatedAt)) {
        sorted.add(insight);
      }
      final window = sorted.length > 7 ? sorted.sublist(sorted.length - 7) : sorted;
      return [for (final i in window) i.gutScore.toDouble()];
    } catch (_) {
      return [insight.gutScore.toDouble()];
    }
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
