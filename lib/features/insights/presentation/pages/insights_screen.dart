import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/insight_bento_feed.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_states.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_theme.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/v2_feed.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// The Insights tab — presenting the GutGood Insights feed.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  /// 7-day chart series for score cards.
  ///
  /// Prefers the deterministic `weeklyRecap.gutScoreTrend` / gut_scores
  /// `dailyScores` (0 = no data that day). Falls back to insight-history
  /// points only when the weekly trend is missing.
  static List<double> scoreWindowFor(InsightsNotifier notifier, AIInsight? insight) {
    if (insight == null) return const <double>[];
    try {
      final trend = insight.weeklyRecap?.gutScoreTrend;
      if (trend != null && trend.isNotEmpty) {
        return [for (final s in trend) s.toDouble()];
      }

      final record = notifier.latestScoreRecord;
      if (record != null && record.dailyScores.isNotEmpty) {
        return [for (final s in record.dailyScores) s.toDouble()];
      }

      final history = notifier.insightHistory;
      final sorted = history.where((item) => item.hasGutScore && !item.updatedAt.isAfter(insight.updatedAt)).toList()..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      if (insight.hasGutScore && !sorted.any((i) => i.updatedAt == insight.updatedAt)) {
        sorted.add(insight);
      }
      final window = sorted.length > 7 ? sorted.sublist(sorted.length - 7) : sorted;
      return [for (final i in window) i.gutScore.toDouble()];
    } catch (_) {
      return insight.hasGutScore ? [insight.gutScore.toDouble()] : [];
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
  Widget build(BuildContext context) {
    final v2 = context.v2Theme;

    return Scaffold(
      backgroundColor: context.appColorScheme.cardBackground,
      body: SafeArea(
        child: Consumer<InsightsNotifier>(
          builder: (context, notifier, _) {
            final latestInsight = notifier.latestInsight;
            final prioritizedPatterns = notifier.prioritizedPatterns.isNotEmpty ? notifier.prioritizedPatterns : (latestInsight?.detectedPatterns ?? []);

            final scoreSeries = InsightsScreen.scoreWindowFor(notifier, latestInsight);
            final isLoading = latestInsight == null && (notifier.isLoading || notifier.isGenerating);

            return RefreshIndicator(
              onRefresh: notifier.retry,
              color: v2.textPrimary,
              backgroundColor: v2.card,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
                      V2InsightsFeed(data: latestInsight, patterns: prioritizedPatterns, series: scoreSeries, history: notifier.insightHistory)
                    else if (notifier.errorMessage == null && notifier.isSufficient)
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverToBoxAdapter(
                          child: InsightEmptyStateCard(
                            title: 'Your logs are ready',
                            message: 'You have enough logs for your first personalized insight.',
                            actionLabel: 'Generate insights',
                            onAction: notifier.generateNewInsight,
                          ),
                        ),
                      )
                    else if (notifier.errorMessage == null)
                      InsightBentoLearning(meals: notifier.todayMeals, symptoms: notifier.todaySymptoms, scans: notifier.todayScans),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
