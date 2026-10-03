import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/insight_bento_theme.dart';
import 'package:gutgood/core/utils/responsive.dart';

/// Shared tag treatment used by product and symptom detail headers.
class ProductDetailHeaderTag extends StatelessWidget {
  const ProductDetailHeaderTag({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.uppercaseLabel = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool uppercaseLabel;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6.r),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 10.sp, color: color), Gap.w4],
        Text(
          uppercaseLabel ? label.toUpperCase() : label,
          style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: color),
        ),
      ],
    ),
  );
}
