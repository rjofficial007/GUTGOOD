import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';

class GutStatusBadge extends StatelessWidget {
  const GutStatusBadge({super.key, required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: AppSizes.p10,
      vertical: AppSizes.p4,
    ),
    decoration: BoxDecoration(
      color: context.appColorScheme.textPrimary,
      borderRadius: BorderRadius.circular(AppSizes.r100),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isActive ? AppStrings.live : AppStrings.off,
          style: context.caption.copyWith(
            color: context.appColorScheme.cardBackground,
            fontSize: AppSizes.s9,
            fontWeight: FontWeight.bold,
          ),
        ),
        Gap.w4,
        Icon(
          Icons.power_settings_new_rounded,
          size: AppSizes.icon12,
          color: context.appColorScheme.cardBackground,
        ),
      ],
    ),
  );
}
