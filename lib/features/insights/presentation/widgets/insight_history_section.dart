import 'package:flutter/material.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/widgets.dart';

import 'insight_history_tile.dart';

class InsightHistorySection extends StatelessWidget {
  final String title;
  final List<AIInsight> insights;
  final Function(AIInsight) onTileTap;

  const InsightHistorySection({super.key, required this.title, required this.insights, required this.onTileTap});

  @override
  Widget build(BuildContext context) {
    return GutSection(
      title: title,
      topPadding: 8.0.h,
      children: insights.map((insight) {
        return InsightHistoryTile(insight: insight, onTap: () => onTileTap(insight));
      }).toList(),
    );
  }
}
