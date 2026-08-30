import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';

/// A generic, pill-shaped action banner used for primary CTAs like Weekly Recaps or Nutrition Facts.
/// Defaults to the vibrant "Lime" theme as requested in PRD Section 7.
class GutActionBanner extends StatelessWidget {
  const GutActionBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
    this.iconContainerColor,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  /// Background color of the entire banner. Defaults to [AppPalette.lime].
  final Color? backgroundColor;

  /// Color of the leading icon. Defaults to [AppPalette.black].
  final Color? iconColor;

  /// Background color of the leading icon's circular container. Defaults to [AppPalette.white].
  final Color? iconContainerColor;

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? context.appColorScheme.textPrimary;
    final effectiveIconColor =
        iconColor ?? context.appColorScheme.cardBackground;
    final effectiveIconContainer =
        iconContainerColor ??
        context.appColorScheme.cardBackground.withAlpha(26);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(Responsive.w(10.0)),
        decoration: BoxDecoration(
          color: effectiveBg,
          borderRadius: BorderRadius.circular(50.0.r),
          border: Border.all(
            color: context.appColorScheme.borderSubtle,
          ),
          boxShadow: [
            BoxShadow(
              color: AppPalette.black.withAlpha(10),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.0.w),
              decoration: BoxDecoration(
                color: effectiveIconContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: effectiveIconColor, size: 18.0.w),
            ),
            Gap.w14,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.bodyBold.copyWith(
                      color: effectiveIconColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: context.caption.copyWith(
                      color: effectiveIconColor.withAlpha(178),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: EdgeInsets.all(Responsive.w(15.0)),
                decoration: BoxDecoration(
                  color: effectiveIconColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.chevronRight,
                  size: 16.0.w,
                  color: effectiveBg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
