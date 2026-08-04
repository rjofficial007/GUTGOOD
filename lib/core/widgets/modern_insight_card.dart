import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';

/// A stylized container designed for "Premium" AI insights.
///
/// Features a distinctive header with an icon, optional action button,
/// and a footer for metadata (like confidence levels or timestamps).
class ModernInsightCard extends StatelessWidget {

  const ModernInsightCard({
    super.key,
    required this.title,
    this.leading,
    this.icon,
    required this.child,
    this.backgroundColor,
    this.titleColor,
    this.iconColor,
    this.borderRadius,
    this.padding,
    this.footer,
    this.footerColor,
    this.action,
    this.onTap,
  });
  /// Primary title for the card.
  final String title;

  /// Optional leading widget (overrides [icon] if provided).
  final Widget? leading;

  /// Leading icon for the header.
  final IconData? icon;

  /// The core content widget.
  final Widget child;

  /// Optional background color (defaults to [context.appColorScheme.elevatedSurface]).
  final Color? backgroundColor;

  /// Optional color for the [title].
  final Color? titleColor;

  /// Optional color for the [icon].
  final Color? iconColor;

  /// Optional corner radius.
  final double? borderRadius;

  /// Padding around the content.
  final EdgeInsetsGeometry? padding;

  /// Optional footer widget.
  final Widget? footer;

  /// Optional background color for the [footer] section.
  final Color? footerColor;

  /// Optional widget to display on the top-right (e.g., a status badge).
  final Widget? action;

  /// Optional tap handler for the entire card.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final footerWidget = footer;
    final actionWidget = action;
    final radius = borderRadius ?? 32.0.r;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Base Layer (The Lip)
          if (footerWidget != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: Responsive.h(120.0),
                padding: EdgeInsets.only(bottom: 12.0.h, left: 16.0.w, right: 16.0.w),
                decoration: BoxDecoration(color: footerColor ?? context.appColorScheme.textPrimary, borderRadius: BorderRadius.circular(radius)),
                alignment: Alignment.bottomCenter,
                child: footerWidget,
              ),
            ),

          // Top Layer (Main Card)
          Padding(
            padding: EdgeInsets.only(bottom: footerWidget != null ? 40.0.h : 0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: backgroundColor ?? context.appColorScheme.elevatedSurface,
                borderRadius: BorderRadius.circular(radius),
                boxShadow: [BoxShadow(color: AppPalette.black.withValues(alpha: 0.1), blurRadius: 24, offset: const Offset(0, 8))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.0.w, 20.0.h, 20.0.w, 12.0.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              if (leading != null) leading! else if (icon != null) Icon(icon, color: iconColor ?? context.appColorScheme.textPrimary, size: 20.0.w),
                              if (leading != null || icon != null) Gap.w12,
                              Text(title.toUpperCase(), style: context.eyebrow.copyWith(color: titleColor ?? context.appColorScheme.textPrimary, letterSpacing: 1.2)),
                            ],
                          ),
                          ?actionWidget,
                        ],
                      ),
                    ),

                    // Content
                    Padding(
                      padding: padding ?? EdgeInsets.symmetric(horizontal: 20.0.w),
                      child: child,
                    ),

                    if (footerWidget == null) Gap.h20,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
