import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';

import '../theme/app_color_scheme.dart';

class PatternCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color? color;

  const PatternCard({super.key, required this.title, required this.description, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? context.appColorScheme.textPrimary;

    return Container(
      margin: EdgeInsets.only(bottom: AppSizes.p16),
      padding: EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSizes.r16),
        border: Border.all(color: effectiveColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(AppSizes.p12),
            decoration: BoxDecoration(color: effectiveColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppSizes.r10)),
            child: Icon(icon, color: effectiveColor, size: AppSizes.icon20),
          ),
          Gap.w16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyBold.copyWith(fontSize: 15.0.sp, color: context.appColorScheme.textPrimary),
                ),
                Gap.h6,
                Text(
                  description,
                  style: AppTextStyles.bodySm.copyWith(color: context.appColorScheme.textSecondary, height: 1.5, fontSize: 13.0.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
