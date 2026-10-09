import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/insight_bento_feed.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_feed/insights_feed.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_states.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// The Insights tab — presenting the GutGood Insights feed.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  /// 7-day chart series for score cards.
  ///
  /// Prefers the current deterministic gut_scores `dailyScores` (0 = no data
  /// that day). A completed Weekly Recap belongs to the previous calendar
  /// week, so it is never reused as the current For You trend.
  static List<double> scoreWindowFor(InsightsNotifier notifier, AIInsight? insight) {
    try {
      final record = notifier.latestScoreRecord;
      if (record != null && record.dailyScores.isNotEmpty) {
        return [for (final s in record.dailyScores) s.toDouble()];
      }

      // Weekly Recap represents the previous completed week. If no score
      // record is available, do not reuse that completed-week trend for the
      // current For You chart; show the current insight score as a baseline.
      if (insight != null && insight.weeklyRecap?.periodTo != null && insight.hasGutScore) {
        return [insight.gutScore.toDouble()];
      }

      final trend = insight?.weeklyRecap?.gutScoreTrend;
      if (trend != null && trend.isNotEmpty) {
        return [for (final s in trend) s.toDouble()];
      }

      if (insight != null && insight.hasGutScore) {
        return [insight.gutScore.toDouble()];
      }
      return const <double>[];
    } catch (_) {
      return const <double>[];
    }
  }

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<InsightsNotifier>().generateNewInsight();
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.appColorScheme.cardBackground,
    body: SafeArea(
      child: Consumer<InsightsNotifier>(
        builder: (context, notifier, _) {
          final latestInsight = notifier.latestInsight;
          final prioritizedPatterns = notifier.prioritizedPatterns.isNotEmpty ? notifier.prioritizedPatterns : (latestInsight?.detectedPatterns ?? []);

          final scoreSeries = InsightsScreen.scoreWindowFor(notifier, latestInsight);
          final isLoading = (latestInsight == null || latestInsight.status == AIInsight.statusInsufficientData) && (notifier.isLoading || notifier.isGenerating);

          if ((latestInsight == null || latestInsight.status == AIInsight.statusInsufficientData) && notifier.errorMessage == null && !isLoading && !notifier.isSufficient) {
            return Scaffold(
              backgroundColor: context.appColorScheme.cardBackground,
              appBar: GutAppBar(
                title: AppStrings.insightsTab,
                actions: [IconButton(icon: const Icon(LucideIcons.history), tooltip: 'Insight History', onPressed: () => context.push(AppRoutes.insightHistory))],
              ),
              body: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p16),
                  child: InsightBentoLearning(meals: notifier.todayMeals, symptoms: notifier.todaySymptoms, scans: notifier.todayScans),
                ),
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              GutSliverAppBar(
                title: AppStrings.insightsTab,
                actions: [IconButton(icon: const Icon(LucideIcons.history), tooltip: 'Insight History', onPressed: () => context.push(AppRoutes.insightHistory))],
              ),
              if (isLoading)
                const SliverPadding(
                  padding: EdgeInsets.all(20),
                  sliver: SliverToBoxAdapter(child: InsightLoadingState()),
                )
              else ...[
                if (notifier.errorMessage != null)
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverToBoxAdapter(
                      child: InsightErrorStateCard(onRetry: notifier.retry, hasCachedData: latestInsight != null),
                    ),
                  ),
                if (latestInsight != null && latestInsight.status != AIInsight.statusInsufficientData)
                  InsightsFeed(data: latestInsight, patterns: prioritizedPatterns, series: scoreSeries, history: notifier.insightHistory)
                else if (notifier.errorMessage == null && notifier.isSufficient)
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverToBoxAdapter(
                      child: InsightEmptyStateCard(
                        title: 'Your logs are ready',
                        message: 'You have enough logs for your first personalized insight.',
                        actionLabel: 'Generate insights',
                        onAction: () => notifier.generateNewInsight(force: true),
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    ),
  );
}
