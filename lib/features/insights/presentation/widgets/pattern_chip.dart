import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/ai_insight_details.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';

class ModernPatternCard extends StatelessWidget {
  final DetectedPattern pattern;

  const ModernPatternCard({super.key, required this.pattern});

  @override
  Widget build(BuildContext context) {
    final Color accentColor = _getColor(pattern.icon);
    
    return Container(
      height: Responsive.h(140.0),
      padding: EdgeInsets.all(16.0.w),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(28.0.r),
        border: Border.all(color: accentColor.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.05),
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
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  _getIcon(pattern.icon),
                  size: 16.0.w,
                  color: accentColor,
                ),
              ),
              Icon(
                AppIcons.chevronRight,
                size: 14.0.w,
                color: accentColor.withValues(alpha: 0.4),
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

  Color _getColor(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'zap':
        return AppPalette.yellow;
      case 'leaf':
        return AppPalette.lime;
      case 'wind':
        return AppPalette.softBlue;
      case 'sparkles':
        return AppPalette.purple;
      case 'utensils':
        return Colors.orange;
      default:
        return AppPalette.purple;
    }
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
