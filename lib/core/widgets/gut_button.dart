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
  });

  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final Color? textColor;
  final IconData? suffixIcon;
  final bool isLoading;
  final bool isOutlined;

  @override
  State<GutButton> createState() => _GutButtonState();
}

class _GutButtonState extends State<GutButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.isOutlined
        ? (widget.color ?? context.appColorScheme.cardBackground)
        : (widget.color ?? Theme.of(context).colorScheme.primary);

    final effectiveTextColor = widget.isOutlined
        ? (widget.textColor ?? context.appColorScheme.textPrimary)
        : (widget.textColor ?? Theme.of(context).colorScheme.onPrimary);

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
              vertical: AppSizes.p18,
              horizontal: AppSizes.p24,
            ),
            decoration: BoxDecoration(
              color: widget.isLoading
                  ? effectiveColor.withValues(alpha: 0.7)
                  : (_isFocused ? effectiveColor.withValues(alpha: 0.9) : effectiveColor),
              borderRadius: BorderRadius.circular(AppSizes.r18),
              border: widget.isOutlined
                  ? Border.all(color: _isFocused ? context.appColorScheme.textPrimary : context.appColorScheme.border, width: 2.0)
                  : (_isFocused ? Border.all(color: context.appColorScheme.textPrimary.withValues(alpha: 0.5), width: 3.0) : null),
              boxShadow: _isFocused
                  ? [BoxShadow(color: effectiveColor.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 2)]
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
                          widget.label,
                          textAlign: TextAlign.center,
                          style: context.bodyBold.copyWith(
                            color: effectiveTextColor,
                            fontSize: AppSizes.s16,
                          ),
                        ),
                        if (widget.suffixIcon != null) ...[
                          Gap.w8,
                          Icon(
                            widget.suffixIcon,
                            color: effectiveTextColor,
                            size: AppSizes.icon20,
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
