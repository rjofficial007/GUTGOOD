import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';

class CycleInsightCard extends StatelessWidget {
  const CycleInsightCard({super.key, required this.insight});
  final CycleInsight insight;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = context.appColorScheme;

    final mainColor = isDark ? AppPalette.pinkDark : AppPalette.pink; // Lighter pink for dark mode
    final bgColor = isDark ? mainColor.withAlpha(20) : AppPalette.pinkLight.withAlpha(127);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSizes.p12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.r12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: mainColor.withAlpha(26), shape: BoxShape.circle),
            child: Icon(AppIcons.flower, color: mainColor, size: 16.0.w),
          ),
          Gap.w10,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  insight.phase.toUpperCase(),
                  style: context.eyebrow.copyWith(color: mainColor),
                ),
                Gap.h4,
                Text(
                  insight.description,
                  style: context.caption.copyWith(color: isDark ? colorScheme.textPrimary : colorScheme.textSecondary, height: 1.4, fontWeight: isDark ? FontWeight.w500 : FontWeight.w400),
                ),
                if (insight.tags != null && insight.tags!.isNotEmpty) ...[
                  Gap.h10,
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: insight.tags!.map((tag) => _CycleTagPill(tag: tag, baseColor: mainColor)).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CycleTagPill extends StatelessWidget {
  const _CycleTagPill({required this.tag, required this.baseColor});
  final CycleTag tag;
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: baseColor.withAlpha(isDark ? 26 : 13),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: baseColor.withAlpha(38)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIcon(tag.icon), size: 10, color: isDark ? baseColor : baseColor.withAlpha(204)),
          Gap.w4,
          Text(
            tag.text.toUpperCase(),
            style: context.captionBold.copyWith(color: isDark ? baseColor : baseColor.withAlpha(204)),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String icon) {
    switch (icon.toLowerCase()) {
      case 'zap':
        return AppIcons.zap;
      case 'leaf':
        return AppIcons.leaf;
      case 'sparkles':
      case 'sparkle':
        return AppIcons.sparkles;
      case 'activity':
        return AppIcons.activity;
      default:
        return AppIcons.sparkles;
    }
  }
}
