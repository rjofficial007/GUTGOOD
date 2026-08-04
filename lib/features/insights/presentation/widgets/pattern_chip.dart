import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/ai_insight_details.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';

class ModernPatternCard extends StatelessWidget {

  const ModernPatternCard({super.key, required this.pattern});
  final DetectedPattern pattern;

  @override
  Widget build(BuildContext context) {
    final mainColor = context.appColorScheme.textPrimary;
    
    return Container(
      height: 140.0.h,
      padding: EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: context.appColorScheme.elevatedSurface,
        borderRadius: BorderRadius.circular(AppSizes.r28),
        border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppPalette.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8.0.w),
                decoration: BoxDecoration(
                  color: context.appColorScheme.border.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIcon(pattern.icon),
                  size: 16.0.w,
                  color: mainColor,
                ),
              ),
              Icon(
                AppIcons.chevronRight,
                size: 14.0.w,
                color: mainColor.withValues(alpha: 0.4),
              ),
            ],
          ),
          const Spacer(),
          Text(
            pattern.title,
            style: context.bodyBold.copyWith(
              fontSize: 14.0.sp,
              color: context.appColorScheme.textPrimary,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Gap.h4,
          Text(
            pattern.description,
            style: context.caption.copyWith(
              fontSize: 10.0.sp,
              color: context.appColorScheme.textMuted,
              height: 1.4,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'wind':
        return AppIcons.wind;
      case 'zap':
        return AppIcons.zap;
      case 'leaf':
        return AppIcons.leaf;
      case 'sparkles':
        return AppIcons.sparkles;
      case 'moon':
        return AppIcons.moon;
      case 'utensils':
        return AppIcons.utensils;
      default:
        return AppIcons.brain;
    }
  }
}
