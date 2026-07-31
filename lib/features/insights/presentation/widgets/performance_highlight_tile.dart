import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';

class PerformanceHighlightTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const PerformanceHighlightTile({
    super.key, 
    required this.icon, 
    required this.text, 
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.0.h),
      padding: EdgeInsets.all(16.0.w),
      decoration: BoxDecoration(
        color: context.appColorScheme.cardBackground,
        borderRadius: BorderRadius.circular(24.0.r),
        border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.0.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1), 
              borderRadius: BorderRadius.circular(16.0.r),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(icon, size: 20.0.w, color: color),
          ),
          Gap.w16,
          Expanded(
            child: Text(
              text, 
              style: context.bodyBold.copyWith(
                height: 1.4, 
                fontSize: 13.0.sp,
                color: context.appColorScheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
