import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';

/// A vertical tile used for displaying rich, card-based insights in a grid.
///
/// Commonly used in the [InsightsScreen] and [InsightDetailSheet].
/// Supports background highlighting for high-priority ("vibrant") patterns.
class GutGridTile extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final isFullVibrant =
        backgroundColor != null &&
        backgroundColor == context.appColorScheme.textPrimary;

    final effectiveTextColor =
        textColor ??
        (isFullVibrant
            ? context.appColorScheme.cardBackground
            : context.appColorScheme.textPrimary);

    final mutedTextColor = isFullVibrant
        ? effectiveTextColor.withAlpha(178)
        : context.appColorScheme.textMuted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: Responsive.h(140.0),
        padding: EdgeInsets.all(Responsive.w(16.0)),
        decoration: BoxDecoration(
          color: backgroundColor ?? context.appColorScheme.elevatedSurface,
          borderRadius: BorderRadius.circular(AppSizes.r24),
          border: !isFullVibrant
              ? Border.all(
                  color: context.appColorScheme.borderSubtle,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: AppPalette.black.withAlpha(5),
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
                        color:
                            iconContainerColor ??
                            (isFullVibrant
                                ? context.appColorScheme.cardBackground.withAlpha(51)
                                : context.appColorScheme.cardBackground),
                        shape: BoxShape.circle,
                        border: !isFullVibrant
                            ? Border.all(
                                color: context.appColorScheme.borderSubtle,
                                width: 1.5,
                              )
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
                            color: context.appColorScheme.textPrimary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  backgroundColor ??
                                  context.appColorScheme.elevatedSurface,
                              width: 1.5,
                            ),
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
              style: context.captionBold.copyWith(
                color: mutedTextColor,
              ),
            ),
            Gap.h4,
            Text(
              value,
              style: context.labelBold.copyWith(
                color: effectiveTextColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: context.captionBold.copyWith(
                color: mutedTextColor,
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
