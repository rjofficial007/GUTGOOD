import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';
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
        margin: EdgeInsets.only(bottom: 12.0.h),
        padding: EdgeInsets.all(12.0.w),
        decoration: BoxDecoration(
          color: context.appColorScheme.elevatedSurface,
          borderRadius: BorderRadius.circular(20.0.r),
          border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            // 1. Icon Container
            Container(
              width: 52.0.w,
              height: 52.0.w,
              decoration: BoxDecoration(color: context.appColorScheme.border.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12.0.r)),
              child: Icon(_getIconForType(type), color: effectColor, size: 24.0.w),
            ),
            Gap.w16,
            // 2. Info (Title, Type, Time)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.topInsight?.title ?? 'Analysis Complete',
                    style: context.bodyBold.copyWith(fontSize: 15.0.sp),
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
              width: 52.0.w,
              height: 52.0.w,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: insight.gutScore / 100,
                    strokeWidth: 5.w,
                    strokeCap: StrokeCap.round,
                    backgroundColor: context.appColorScheme.border.withValues(alpha: 0.5),
                    valueColor: AlwaysStoppedAnimation<Color>(effectColor),
                  ),
                  Text(
                    '${insight.gutScore}',
                    style: context.bodyBold.copyWith(fontSize: 13.0.sp, fontWeight: FontWeight.w900),
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
