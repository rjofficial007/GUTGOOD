import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/widgets/widgets.dart';

import 'package:gutgood/features/insights/presentation/widgets/insight_history_tile.dart';

class InsightHistorySection extends StatelessWidget {

  const InsightHistorySection({super.key, required this.title, required this.insights, required this.onTileTap});
  final String title;
  final List<AIInsight> insights;
  final Function(AIInsight) onTileTap;

  @override
  Widget build(BuildContext context) => GutSection(
      title: title,
      topPadding: AppSizes.p8,
      children: insights.map((insight) => InsightHistoryTile(insight: insight, onTap: () => onTileTap(insight))).toList(),
    );
}
