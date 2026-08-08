import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';

class GutTextField extends StatelessWidget {
  const GutTextField({
    super.key,
    this.controller,
    this.hintText,
    this.prefixIcon,
    this.keyboardType,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.style,
    this.borderless = false,
    this.borderRadius = 12.0,
    this.contentPadding,
    this.textCapitalization = TextCapitalization.none,
  });
  final TextEditingController? controller;
  final String? hintText;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final TextStyle? style;
  final bool borderless;
  final double borderRadius;
  final EdgeInsetsGeometry? contentPadding;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final inputStyle = style ?? context.body;

    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      minLines: minLines,
      enabled: enabled,
      onChanged: onChanged,
      onSubmitted: (_) => onSubmitted?.call(),
      style: inputStyle,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: inputStyle.copyWith(
          color: context.appColorScheme.textMuted.withValues(alpha: 0.5),
        ),
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                size: AppSizes.icon18,
                color: context.appColorScheme.textMuted,
              )
            : null,
        filled: !borderless,
        fillColor: borderless
            ? AppPalette.transparent
            : context.appColorScheme.elevatedSurface,
        contentPadding:
            contentPadding ??
            EdgeInsets.symmetric(
              vertical: AppSizes.p16,
              horizontal: AppSizes.p16,
            ),
        border: _buildBorder(context, AppPalette.transparent),
        enabledBorder: _buildBorder(context, context.appColorScheme.border),
        focusedBorder: _buildBorder(
          context,
          context.appColorScheme.textPrimary,
          width: 1.5,
        ),
        disabledBorder: _buildBorder(
          context,
          context.appColorScheme.border.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  InputBorder _buildBorder(
    BuildContext context,
    Color color, {
    double width = 1.0,
  }) {
    if (borderless) return InputBorder.none;

    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius.r),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
