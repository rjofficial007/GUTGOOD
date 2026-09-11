import 'package:flutter/material.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/utils/date_formatter.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/insight_bento_feed.dart';

/// Historical insight detail (bento screen 01 applied to a past snapshot).
///
/// Renders the same [InsightBentoFeed] as the Insights tab so every
/// insight-related screen shares one UI language; the only difference is the
/// data source (a stored `AIInsight` and its own `detectedPatterns`) and the
/// date-stamped app bar.
class InsightDetailScreen extends StatelessWidget {
  const InsightDetailScreen({super.key, required this.insight});
  final AIInsight insight;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.appColorScheme.cardBackground,
    body: CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        GutSliverAppBar(title: DateFormatter.formatDate(insight.updatedAt).toUpperCase(), centerTitle: true),
        InsightBentoFeed(data: insight, patterns: insight.detectedPatterns),
      ],
    ),
  );
}
