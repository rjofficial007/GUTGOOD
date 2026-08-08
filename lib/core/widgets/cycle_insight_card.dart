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
    final colorScheme = context.appColorScheme;
    const mainColor = AppPalette.pink;
    const bgColor = AppPalette.pinkLight;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSizes.p12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.r10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.flower, color: mainColor, size: 18.0.w),
          Gap.w8,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.phase.toUpperCase(),
                  style: context.caption.copyWith(
                    color: mainColor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    fontSize: 10.0.sp,
                  ),
                ),
                Gap.h4,
                Text(
                  insight.description,
                  style: context.caption.copyWith(
                    color: colorScheme.textSecondary,
                    height: 1.3,
                  ),
                ),
                if (insight.tags != null && insight.tags!.isNotEmpty) ...[
                  Gap.h8,
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: insight.tags!
                        .map((tag) => _CycleTagPill(tag: tag))
                        .toList(),
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
  const _CycleTagPill({required this.tag});
  final CycleTag tag;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.textPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: colorScheme.textPrimary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(tag.icon),
            size: 10,
            color: colorScheme.textPrimary.withValues(alpha: 0.7),
          ),
          Gap.w4,
          Text(
            tag.text.toUpperCase(),
            style: context.caption.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: colorScheme.textPrimary.withValues(alpha: 0.7),
              letterSpacing: 0.2,
            ),
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
