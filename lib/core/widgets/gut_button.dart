import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/haptic_helper.dart';

/// The primary action button used across the GutGood application.
///
/// Supports both filled and outlined styles, loading states, and haptic feedback.
/// Automatically expands to fill the available horizontal width.
class GutButton extends StatelessWidget {
  const GutButton({
    super.key,
    required this.label,
    this.onTap,
    this.color,
    this.textColor,
    this.suffixIcon,
    this.isLoading = false,
    this.isOutlined = false,
  });

  /// The text to display on the button.
  final String label;

  /// Callback function when the button is tapped.
  final VoidCallback? onTap;

  /// Background color (filled) or surface color (outlined).
  final Color? color;

  /// Text and icon color.
  final Color? textColor;

  /// Optional icon to display after the [label].
  final IconData? suffixIcon;

  /// Whether to show a [CircularProgressIndicator] instead of text.
  final bool isLoading;

  /// Whether to use the outlined border style.
  final bool isOutlined;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isOutlined
        ? (color ?? context.appColorScheme.cardBackground)
        : (color ?? Theme.of(context).colorScheme.primary);

    final effectiveTextColor = isOutlined
        ? (textColor ?? context.appColorScheme.textPrimary)
        : (textColor ?? Theme.of(context).colorScheme.onPrimary);

    return Semantics(
      label: label,
      button: true,
      enabled: !isLoading && onTap != null,
      child: GestureDetector(
        onTap: isLoading
            ? null
            : () {
                HapticHelper.light();
                onTap?.call();
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: AppSizes.p18,
            horizontal: AppSizes.p24,
          ),
          decoration: BoxDecoration(
            color: isLoading
                ? effectiveColor.withValues(alpha: 0.7)
                : effectiveColor,
            borderRadius: BorderRadius.circular(AppSizes.r18),
            border: isOutlined
                ? Border.all(color: context.appColorScheme.border, width: 1.5)
                : null,
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    height: AppSizes.icon20,
                    width: AppSizes.icon20,
                    child: CircularProgressIndicator(
                      color: effectiveTextColor,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: context.bodyBold.copyWith(
                          color: effectiveTextColor,
                          fontSize: AppSizes.s16,
                        ),
                      ),
                      if (suffixIcon != null) ...[
                        Gap.w8,
                        Icon(
                          suffixIcon,
                          color: effectiveTextColor,
                          size: AppSizes.icon20,
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
