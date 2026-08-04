import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/haptic_helper.dart';

class GutChip extends StatelessWidget {

  const GutChip({super.key, this.icon, required this.label, required this.isSelected, required this.onTap});
  final IconData? icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: () {
        HapticHelper.selection();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: AppSizes.p18, vertical: AppSizes.p13),
        decoration: BoxDecoration(
          color: isSelected ? context.appColorScheme.textPrimary : context.appColorScheme.cardBackground,
          border: Border.all(color: isSelected ? context.appColorScheme.textPrimary : context.appColorScheme.border, width: 1.5),
          borderRadius: BorderRadius.circular(AppSizes.r14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: AppSizes.icon16, color: isSelected ? context.appColorScheme.cardBackground : context.appColorScheme.textSecondary), Gap.w10],
            Text(
              label,
              style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w500, color: isSelected ? context.appColorScheme.cardBackground : context.appColorScheme.textPrimary),
            ),
          ],
        ),
      ),
    );
}
