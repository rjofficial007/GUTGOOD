import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/widgets/super_card.dart';
import 'package:intl/intl.dart';

class InsightHistoryTile extends StatelessWidget {
  const InsightHistoryTile({super.key, required this.insight, required this.onTap});
  final AIInsight insight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = insight.topInsight?.type ?? 'Insight';

    return SuperHistoryTile(
      title: insight.topInsight?.title ?? 'Analysis Complete',
      subtitle: '${type.toUpperCase()} • ${DateFormat('h:mm a').format(insight.updatedAt)}',
      score: insight.gutScore,
      onTap: onTap,
      icon: _getIconForType(type),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'pattern':
        return AppIcons.brain;
      case 'ingredient':
        return AppIcons.leaf;
      case 'behavioral':
        return AppIcons.activity;
      case 'goal':
        return AppIcons.target;
      default:
        return AppIcons.salad;
    }
  }
}
