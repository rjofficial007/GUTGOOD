import 'package:flutter/material.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/utils/date_formatter.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_theme.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/v2_feed.dart';
import 'package:provider/provider.dart';

/// Historical insight detail — the v2 feed applied to a past snapshot.
///
/// Renders the same [V2InsightsFeed] as the Insights tab so every
/// insight-related screen shares one visual language; the data source is the
/// stored [AIInsight] and its own detected patterns, with the score window
/// truncated at this insight's date so a past snapshot never charts the
/// future.
class InsightDetailScreen extends StatelessWidget {
  const InsightDetailScreen({super.key, required this.insight});

  final AIInsight insight;

  @override
  Widget build(BuildContext context) {
    var series = [insight.gutScore.toDouble()];
    try {
      final notifier = context.read<InsightsNotifier>();
      final sorted = [...notifier.insightHistory]
        ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      final upto = sorted
          .where((i) => !i.updatedAt.isAfter(insight.updatedAt))
          .toList();
      if (!upto.any((i) => i.updatedAt == insight.updatedAt)) upto.add(insight);
      final window = upto.length > 7 ? upto.sublist(upto.length - 7) : upto;
      series = [for (final i in window) i.gutScore.toDouble()];
    } catch (_) {
      // No notifier in scope (e.g. an isolated preview): the chart degrades
      // to a flat line instead of the 7-day trend.
    }

    return Scaffold(
      backgroundColor: context.v2Theme.scaffold,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          GutSliverAppBar(
            title: DateFormatter.formatDate(insight.updatedAt).toUpperCase(),
            centerTitle: true,
            backgroundColor: context.v2Theme.scaffold,
          ),
          V2InsightsFeed(
            data: insight,
            patterns: insight.detectedPatterns,
            series: series,
            history: const [],
          ),
        ],
      ),
    );
  }
}
