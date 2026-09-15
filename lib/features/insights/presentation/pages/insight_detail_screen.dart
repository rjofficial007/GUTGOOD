import 'package:flutter/material.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/utils/date_formatter.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/bento_data.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/insight_bento_feed.dart';
import 'package:provider/provider.dart';

/// Historical insight detail (bento screen 01 applied to a past snapshot).
///
/// Renders the same [InsightBentoFeed] as the Insights tab so every
/// insight-related screen shares one UI language; the only difference is the
/// data source (a stored `AIInsight` and its own `detectedPatterns`) and the
/// date-stamped app bar. The hero's bar chart shows the score window *up to*
/// this insight's date, so a past snapshot never charts future scores.
class InsightDetailScreen extends StatelessWidget {
  const InsightDetailScreen({super.key, required this.insight});
  final AIInsight insight;

  @override
  Widget build(BuildContext context) {
    var series = const <double>[];
    var labels = const <String>[];
    try {
      final notifier = context.read<InsightsNotifier>();
      (series, labels) = BentoData.scoreWindow(notifier.insightHistory, until: insight.updatedAt, ensure: insight);
    } catch (_) {
      // No notifier in scope (e.g. an isolated preview): the hero degrades to
      // the gradient track bar instead of the 7-day chart.
    }

    return Scaffold(
      backgroundColor: context.appColorScheme.cardBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          GutSliverAppBar(title: DateFormatter.formatDate(insight.updatedAt).toUpperCase(), centerTitle: true),
          InsightBentoFeed(data: insight, patterns: insight.detectedPatterns, series: series, seriesLabels: labels),
        ],
      ),
    );
  }
}
