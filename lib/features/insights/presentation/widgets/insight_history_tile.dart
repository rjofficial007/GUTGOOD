import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/utils/gut_score_utils.dart';
import 'package:gutgood/core/widgets/gut_score_list_tile.dart';
import 'package:intl/intl.dart';

class InsightHistoryTile extends StatelessWidget {
  const InsightHistoryTile({super.key, required this.insight, required this.onTap});
  final AIInsight insight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = insight.topInsight?.type ?? 'Insight';
    final icon = _getIconForType(type);
    final band = GutScoreBand.fromScore(insight.gutScore);

    return GutScoreListTile(
      leading: Container(
        width: AppSizes.w52,
        height: AppSizes.w52,
        decoration: BoxDecoration(
          color: context.appColorScheme.cardBackground,
          borderRadius: BorderRadius.circular(AppSizes.r12),
          border: Border.all(color: context.appColorScheme.borderSubtle),
        ),
        child: Icon(icon, color: context.appColorScheme.textPrimary, size: AppSizes.icon24),
      ),
      title: insight.topInsight?.title ?? 'Analysis Complete',
      subtitle: '${type.toUpperCase()} • ${DateFormat('h:mm a').format(insight.updatedAt)}',
      score: insight.gutScore,
      scoreColor: band.color,
      onTap: onTap,
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
