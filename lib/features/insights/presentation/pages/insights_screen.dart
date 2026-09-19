import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_theme.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/v2_feed.dart';
import 'package:provider/provider.dart';

/// The Insights tab — presenting the GutGood Insights feed.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  static List<double> scoreWindowFor(InsightsNotifier notifier, AIInsight? insight) {
    if (insight == null) return const <double>[74, 75, 76, 77, 78];
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
      backgroundColor: v2.scaffold,
      body: SafeArea(
        child: Consumer<InsightsNotifier>(
          builder: (context, notifier, _) {
            final latestInsight = notifier.latestInsight;
            final prioritizedPatterns = notifier.prioritizedPatterns.isNotEmpty ? notifier.prioritizedPatterns : (latestInsight?.detectedPatterns ?? []);

            final scoreSeries = InsightsScreen.scoreWindowFor(notifier, latestInsight);
            final isLoading = notifier.isLoading || (latestInsight == null && notifier.isGenerating);

            // Fallback default insight for preview / initial state if empty
            final displayInsight =
                latestInsight ??
                AIInsight(
                  gutScore: 78,
                  scoreDiff: '+4',
                  healingGoal: 'Fermented foods + prebiotic fiber significantly reduce bloating episodes.',
                  healingTrend: 'Your gut barrier score is up!',
                  triggerTrend: 'Fried Foods → Bloating',
                  updatedAt: DateTime.now(),
                );

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const GutSliverAppBar(title: AppStrings.insightsTab),
                if (isLoading) const _InsightsLoadingState() else V2InsightsFeed(data: displayInsight, patterns: prioritizedPatterns, series: scoreSeries, history: notifier.insightHistory),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InsightsLoadingState extends StatelessWidget {
  const _InsightsLoadingState();

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: EdgeInsets.fromLTRB(AppSizes.p20, AppSizes.p16, AppSizes.p20, AppSizes.p10),
    sliver: const SliverToBoxAdapter(child: ShimmerGridLoader(itemCount: 4, variant: ShimmerVariant.scanResult)),
  );
}
