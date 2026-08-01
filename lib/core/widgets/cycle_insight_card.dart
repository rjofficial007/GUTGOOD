import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';

import '../theme/app_color_scheme.dart';
import '../theme/app_palette.dart';

class CycleInsightCard extends StatelessWidget {
  final CycleInsight insight;

  const CycleInsightCard({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    final Color mainColor = context.appColorScheme.textPrimary;

    return Container(
      margin: EdgeInsets.only(bottom: AppSizes.p16),
      padding: EdgeInsets.all(AppSizes.p20),
      decoration: BoxDecoration(
        color: context.appColorScheme.border.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.r16),
        border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSizes.p8),
                decoration: BoxDecoration(color: context.appColorScheme.border.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: Icon(AppIcons.flower, size: 16, color: mainColor),
              ),
              Gap.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CYCLE SYNC INSIGHT',
                      style: context.overline.copyWith(color: mainColor, fontWeight: FontWeight.w800),
                    ),
                    Text(insight.phase.toUpperCase(), style: context.bodyBold.copyWith(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
          Gap.h16,
          Text(insight.description, style: context.bodySm.copyWith(height: 1.5, color: context.appColorScheme.textSecondary, fontSize: 13)),
          if (insight.tags != null && insight.tags!.isNotEmpty) ...[Gap.h16, Wrap(spacing: 8, runSpacing: 8, children: insight.tags!.map((tag) => _CycleTagPill(tag: tag)).toList())],
        ],
      ),
    );
  }
}

class _CycleTagPill extends StatelessWidget {
  final CycleTag tag;
  const _CycleTagPill({required this.tag});

  @override
  Widget build(BuildContext context) {
    final Color tagColor = context.appColorScheme.textPrimary;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.appColorScheme.elevatedSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIcon(tag.icon), size: 12, color: tagColor),
          Gap.w6,
          Text(
            tag.text,
            style: context.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w800, color: context.appColorScheme.textSecondary),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String icon) {
    switch (icon) {
      case 'zap':
        return AppIcons.zap;
      case 'leaf':
        return AppIcons.leaf;
      case 'sparkle':
        return AppIcons.sparkles;
      default:
        return AppIcons.sparkles;
    }
  }
}
