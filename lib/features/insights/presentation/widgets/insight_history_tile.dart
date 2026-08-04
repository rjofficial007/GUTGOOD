import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:intl/intl.dart';

class InsightHistoryTile extends StatelessWidget {
  final AIInsight insight;
  final VoidCallback onTap;

  const InsightHistoryTile({super.key, required this.insight, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final String type = insight.topInsight?.type ?? 'Insight';
    final Color effectColor = context.appColorScheme.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: AppSizes.p12),
        padding: EdgeInsets.all(AppSizes.p12),
        decoration: BoxDecoration(
          color: context.appColorScheme.elevatedSurface,
          borderRadius: BorderRadius.circular(AppSizes.r20),
          border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            // 1. Icon Container
            Container(
              width: AppSizes.w52,
              height: AppSizes.w52,
              decoration: BoxDecoration(color: context.appColorScheme.border.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(AppSizes.r12)),
              child: Icon(_getIconForType(type), color: effectColor, size: AppSizes.icon24),
            ),
            Gap.w16,
            // 2. Info (Title, Type, Time)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.topInsight?.title ?? 'Analysis Complete',
                    style: context.bodyBold.copyWith(fontSize: AppSizes.s15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Gap.h4,
                  Text(
                    '${type.toUpperCase()} • ${DateFormat('h:mm a').format(insight.updatedAt)}',
                    style: context.caption.copyWith(color: context.appColorScheme.textMuted, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Gap.w12,
            // 3. Score Badge (Circular Progress)
            SizedBox(
              width: AppSizes.w52,
              height: AppSizes.w52,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: insight.gutScore / 100,
                    strokeWidth: 5,
                    strokeCap: StrokeCap.round,
                    backgroundColor: context.appColorScheme.border.withValues(alpha: 0.5),
                    valueColor: AlwaysStoppedAnimation<Color>(effectColor),
                  ),
                  Text(
                    '${insight.gutScore}',
                    style: context.bodyBold.copyWith(fontSize: AppSizes.s13, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
        return AppIcons.sparkles;
    }
  }
}
