import 'package:flutter/material.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/constants/app_sizes.dart';

class GutStatusBadge extends StatelessWidget {
  final bool isActive;
  
  const GutStatusBadge({
    super.key,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.w(10.0), 
        vertical: Responsive.h(4.0),
      ),
      decoration: BoxDecoration(
        color: context.appColorScheme.textPrimary, 
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isActive ? AppStrings.live : AppStrings.off,
            style: TextStyle(
              color: context.appColorScheme.cardBackground, 
              fontSize: Responsive.sp(9.0), 
              fontWeight: FontWeight.bold,
            ),
          ),
          Gap.w4,
          Icon(
            Icons.power_settings_new_rounded, 
            size: 12, 
            color: context.appColorScheme.cardBackground,
          ),
        ],
      ),
    );
  }
}
