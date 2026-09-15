import 'package:flutter/material.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/insight_bento_screens.dart';
import 'package:provider/provider.dart';

/// Trigger synergy screen (v4 bento screen 06).
///
/// Keeps the standard [GutSliverAppBar]; the body is the bento grid: the
/// multiplier hero, its ranked drivers, and the rescue protocol.
class SmartInsightDetailScreen extends StatelessWidget {
  const SmartInsightDetailScreen({super.key, required this.insight});
  final InsightSummary insight;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.appColorScheme.cardBackground,
    body: CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const GutSliverAppBar(title: 'DEEP DISCOVERY', centerTitle: true),
        InsightBentoSynergy(summary: insight, patterns: context.read<InsightsNotifier>().prioritizedPatterns),
      ],
    ),
  );
}
