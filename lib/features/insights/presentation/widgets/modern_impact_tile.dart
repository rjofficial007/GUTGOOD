import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/ai_insight_details.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';

class ModernImpactTile extends StatelessWidget {
  final FoodImpact impact;

  const ModernImpactTile({super.key, required this.impact});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.0.h),
      padding: EdgeInsets.symmetric(horizontal: 12.0.w, vertical: 12.0.h),
      decoration: BoxDecoration(
        color: context.appColorScheme.cardBackground,
        borderRadius: BorderRadius.circular(16.0.r),
        border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(impact.emoji, style: TextStyle(fontSize: 18.0.sp)),
              Gap.w10,
              Expanded(
                child: Text(
                  impact.food,
                  style: context.bodyBold.copyWith(fontSize: 13.0.sp),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _ReactionTag(impact: impact),
            ],
          ),
          Gap.h4,
          Text(
            impact.timeframeLabel,
            style: context.caption.copyWith(fontSize: 9.0.sp, color: context.appColorScheme.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ReactionTag extends StatelessWidget {
  final FoodImpact impact;
  const _ReactionTag({required this.impact});

  @override
  Widget build(BuildContext context) {
    final bool isNegative = impact.impactType == 'negative';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.0.w, vertical: 2.0.h),
      decoration: BoxDecoration(
        color: (isNegative ? context.appColorScheme.error : context.appColorScheme.success).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        impact.effect.toUpperCase(),
        style: context.overline.copyWith(
          color: isNegative ? context.appColorScheme.error : context.appColorScheme.success,
          fontSize: 7.0.sp,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
