import 'package:flutter/material.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/constants/app_sizes.dart';

/// A vertical tile used for displaying rich, card-based insights in a grid.
/// 
/// Commonly used in the [InsightsScreen] and [InsightDetailSheet].
/// Supports background highlighting for high-priority ("vibrant") patterns.
class GutGridTile extends StatelessWidget {
  /// Primary category or type of the insight.
  final String title;
  
  /// The main value or finding.
  final String value;
  
  /// Descriptive context or supporting details.
  final String subtitle;
  
  /// Leading icon or illustration.
  final Widget icon;
  
  /// Optional background color. Defaults to [context.appColorScheme.elevatedSurface].
  final Color? backgroundColor;
  
  /// Optional accent color for the status indicator and icon border.
  final Color? statusColor;
  
  /// Optional tap handler.
  final VoidCallback? onTap;
  
  /// Optional custom text color.
  final Color? textColor;
  
  /// Optional custom background for the icon container.
  final Color? iconContainerColor;

  const GutGridTile({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.backgroundColor,
    this.statusColor,
    this.onTap,
    this.textColor,
    this.iconContainerColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFullVibrant = backgroundColor != null && 
        (backgroundColor == AppPalette.softBlue || backgroundColor == AppPalette.lime || backgroundColor == AppPalette.black);
    
    final Color effectiveTextColor = textColor ?? (isFullVibrant 
        ? (backgroundColor == AppPalette.lime ? AppPalette.black : Colors.white)
        : context.appColorScheme.textPrimary);

    final Color mutedTextColor = isFullVibrant 
        ? effectiveTextColor.withValues(alpha: 0.7)
        : context.appColorScheme.textMuted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: Responsive.h(140.0),
        padding: EdgeInsets.all(Responsive.w(16.0)),
        decoration: BoxDecoration(
          color: backgroundColor ?? context.appColorScheme.elevatedSurface,
          borderRadius: BorderRadius.circular(Responsive.r(24.0)),
          border: !isFullVibrant ? Border.all(color: context.appColorScheme.border.withValues(alpha: 0.5)) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Stack(
                  children: [
                    Container(
                      padding: EdgeInsets.all(Responsive.w(6.0)),
                      decoration: BoxDecoration(
                        color: iconContainerColor ?? (isFullVibrant ? Colors.white.withValues(alpha: 0.2) : context.appColorScheme.cardBackground),
                        shape: BoxShape.circle,
                        border: statusColor != null 
                            ? Border.all(color: statusColor!.withValues(alpha: 0.3), width: 1.5)
                            : null,
                      ),
                      child: icon,
                    ),
                    if (statusColor != null)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8.0.w,
                          height: 8.0.w,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: backgroundColor ?? context.appColorScheme.elevatedSurface, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor!.withValues(alpha: 0.5),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                Icon(
                  Icons.more_horiz_rounded, 
                  size: 16.0.w, 
                  color: mutedTextColor,
                ),
              ],
            ),
            const Spacer(),
            Text(
              title.toUpperCase(),
              style: context.caption.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 8.0.sp,
                letterSpacing: 1.2,
                color: mutedTextColor,
              ),
            ),
            Gap.h4,
            Text(
              value,
              style: context.bodyBold.copyWith(
                fontSize: 13.0.sp,
                color: effectiveTextColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: context.caption.copyWith(
                fontSize: 9.0.sp,
                color: mutedTextColor,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
