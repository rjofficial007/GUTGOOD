import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';

class AlertCard extends StatelessWidget {

  const AlertCard({super.key, required this.text, this.color, this.icon = AppIcons.shield});
  final String text;
  final Color? color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? context.appColorScheme.success;

    return Container(
      padding: EdgeInsets.all(AppSizes.p12),
      decoration: BoxDecoration(color: effectiveColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppSizes.r12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16.0.w, color: effectiveColor),
          Gap.w12,
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySm.copyWith(color: effectiveColor, fontWeight: FontWeight.w500, fontSize: 11.0.sp, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
