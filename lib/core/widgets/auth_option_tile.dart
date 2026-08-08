import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';

class AuthOptionTile extends StatelessWidget {
  const AuthOptionTile({
    super.key,
    this.icon,
    this.imagePath,
    required this.label,
    required this.onTap,
    this.color,
    this.textColor,
    this.imageColor,
  });
  final IconData? icon;
  final String? imagePath;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Color? textColor;
  final Color? imageColor;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppSizes.r16),
    child: Container(
      padding: EdgeInsets.symmetric(
        vertical: AppSizes.p16,
        horizontal: AppSizes.p20,
      ),
      decoration: BoxDecoration(
        color: color ?? context.appColorScheme.cardBackground,
        border: color == null
            ? Border.all(color: context.appColorScheme.border)
            : null,
        borderRadius: BorderRadius.circular(AppSizes.r16),
        boxShadow: color != null
            ? [
                BoxShadow(
                  color: color!.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (imagePath != null)
            Image.asset(imagePath!, width: 20, height: 20, color: imageColor)
          else if (icon != null)
            Icon(
              icon,
              size: 20,
              color: textColor ?? context.appColorScheme.textPrimary,
            ),
          Gap.w12,
          Text(
            label,
            style: AppTextStyles.bodyBold.copyWith(
              color: textColor ?? context.appColorScheme.textPrimary,
            ),
          ),
        ],
      ),
    ),
  );
}
