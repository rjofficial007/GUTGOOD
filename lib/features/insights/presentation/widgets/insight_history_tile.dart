import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/widgets/gut_score_list_tile.dart';
import 'package:intl/intl.dart';

class InsightHistoryTile extends StatelessWidget {
  const InsightHistoryTile({super.key, required this.insight, required this.onTap});
  final AIInsight insight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = insight.topInsight?.type ?? 'Insight';
    final effectColor = context.appColorScheme.textPrimary;

    final leadingWidget = Container(
      width: AppSizes.w52,
      height: AppSizes.w52,
      decoration: BoxDecoration(
        color: context.appColorScheme.border.withAlpha(51),
        borderRadius: BorderRadius.circular(AppSizes.r12),
      ),
      child: Icon(_getIconForType(type), color: effectColor, size: AppSizes.icon24),
    );

    return GutScoreListTile(
      leading: leadingWidget,
      title: insight.topInsight?.title ?? AppStrings.analysisCompleteLabel,
      subtitle: '${type.toUpperCase()} • ${DateFormat('h:mm a').format(insight.updatedAt)}',
      score: insight.gutScore,
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
