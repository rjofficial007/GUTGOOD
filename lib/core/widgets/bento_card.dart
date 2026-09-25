import 'package:flutter/material.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';

class BentoCard extends StatelessWidget {
  const BentoCard({super.key, required this.child, this.backgroundColor, this.borderColor, this.padding, this.borderRadius, this.height, this.width, this.showShadow = false});

  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final double? height;
  final double? width;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? scheme.cardBackground,
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

class BentoCardHeader extends StatelessWidget {
  const BentoCardHeader({super.key, required this.title, this.icon, this.textColor, this.iconColor});

  final String title;
  final IconData? icon;
  final Color? textColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final color = textColor ?? scheme.textSecondary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(title.toUpperCase(), style: context.eyebrow.copyWith(color: color)),
        ),
        if (icon != null) Icon(icon, color: iconColor ?? scheme.textMuted, size: 14),
      ],
    );
  }
}
