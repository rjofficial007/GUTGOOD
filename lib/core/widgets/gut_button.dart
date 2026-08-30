import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/haptic_helper.dart';

/// The primary action button used across the GutGood application.
///
/// Supports both filled and outlined styles, loading states, and haptic feedback.
/// Automatically expands to fill the available horizontal width.
/// Enhanced with TV/Desktop focus support.
class GutButton extends StatefulWidget {
  const GutButton({
    super.key,
    required this.label,
    this.onTap,
    this.color,
    this.textColor,
    this.suffixIcon,
    this.isLoading = false,
    this.isOutlined = false,
    this.isSmall = false,
    this.borderRadius,
  });

  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final Color? textColor;
  final IconData? suffixIcon;
  final bool isLoading;
  final bool isOutlined;
  final bool isSmall;
  final double? borderRadius;

  @override
  State<GutButton> createState() => _GutButtonState();
}

class _GutButtonState extends State<GutButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;
    
    final effectiveColor = widget.isOutlined
        ? (widget.color ?? colorScheme.cardBackground)
        : (widget.color ?? colorScheme.textPrimary);

    final effectiveTextColor = widget.isOutlined
        ? (widget.textColor ?? colorScheme.textPrimary)
        : (widget.textColor ?? colorScheme.cardBackground);

    return Semantics(
      label: widget.label,
      button: true,
      enabled: !widget.isLoading && widget.onTap != null,
      child: FocusableActionDetector(
        onFocusChange: (focus) => setState(() => _isFocused = focus),
        mouseCursor: SystemMouseCursors.click,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap?.call()),
        },
        child: GestureDetector(
          onTap: widget.isLoading
              ? null
              : () {
                  HapticHelper.light();
                  widget.onTap?.call();
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: widget.isSmall ? AppSizes.p12 : AppSizes.p18,
              horizontal: AppSizes.p24,
            ),
            decoration: BoxDecoration(
              color: widget.isLoading
                  ? effectiveColor.withAlpha(178)
                  : (_isFocused ? effectiveColor.withAlpha(229) : effectiveColor),
              borderRadius: BorderRadius.circular(widget.borderRadius ?? AppSizes.r12),
              border: widget.isOutlined
                  ? Border.all(color: _isFocused ? colorScheme.textPrimary : colorScheme.border, width: 1.5)
                  : (_isFocused ? Border.all(color: colorScheme.textPrimary.withAlpha(127), width: 2.0) : null),
              boxShadow: _isFocused
                  ? [BoxShadow(color: effectiveColor.withAlpha(51), blurRadius: 12, spreadRadius: 2)]
                  : null,
            ),
            child: Center(
              child: widget.isLoading
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
                          widget.label.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: context.eyebrow.copyWith(
                            color: effectiveTextColor,
                            fontSize: widget.isSmall ? 10 : 12,
                          ),
                        ),
                        if (widget.suffixIcon != null) ...[
                          const SizedBox(width: 10),
                          Icon(
                            widget.suffixIcon,
                            color: effectiveTextColor,
                            size: widget.isSmall ? 14 : 18,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
