import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/utils/responsive.dart';

import '../theme/app_color_scheme.dart';
import '../theme/app_text_styles.dart';

class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.0.w, vertical: 6.0.h),
      decoration: BoxDecoration(
        color: context.appColorScheme.cardBackground,
        border: Border.all(color: context.appColorScheme.border),
        borderRadius: BorderRadius.circular(20.0.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.sparkles, color: context.appColorScheme.textPrimary, size: 12.0.w),
          Gap.w4,
          Text(
            AppStrings.premium,
            style: AppTextStyles.overline.copyWith(color: context.appColorScheme.textPrimary, fontSize: 10.0.sp),
          ),
        ],
      ),
    );
  }
}
