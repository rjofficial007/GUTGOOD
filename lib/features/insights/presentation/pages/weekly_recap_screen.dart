import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/insight_bento_screens.dart';
import 'package:provider/provider.dart';

class WeeklyRecapScreen extends StatelessWidget {
  const WeeklyRecapScreen({super.key, this.insight});
  final AIInsight? insight;

  @override
  Widget build(BuildContext context) {
    final recap = insight?.weeklyRecap;

    if (insight != null) {
      unawaited(sl<AnalyticsService>().logEvent(name: 'view_weekly_recap', parameters: {'avg_score': recap?.avgScore ?? 0, 'foods_logged': recap?.foodsLogged ?? 0}));
    }

    if (insight == null || recap == null) {
      return const _RecapLoadingView();
    }

    return Scaffold(
      backgroundColor: context.appColorScheme.cardBackground,
      body: CustomScrollView(
        slivers: [
          const GutSliverAppBar(title: AppStrings.weeklyRecap, centerTitle: true),
          // Bento weekly grid (v4 screen 03). The sparkline is fed the real
          // per-day scores from history and hides itself below 2 points.
          InsightBentoRecap(recap: recap, insight: insight, series: _scoreSeries(context)),
        ],
      ),
    );
  }

  /// Chronological gut-score history for the sparkline.
  static List<double> _scoreSeries(BuildContext context) {
    final history = context.read<InsightsNotifier>().insightHistory;
    final sorted = [...history]..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    return [for (final i in sorted) i.gutScore.toDouble()];
  }
}

class _RecapLoadingView extends StatelessWidget {
  const _RecapLoadingView();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).brightness == Brightness.dark ? context.appColorScheme.cardBackground : AppPalette.gray50,
    appBar: const GutAppBar(title: AppStrings.weeklyRecap),
    body: Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p10),
      child: const ShimmerGridLoader(variant: ShimmerVariant.recap),
    ),
  );
}
