import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/insight_theme.dart';
import 'package:gutgood/core/utils/responsive.dart';

class FoodImpactSectionHeader extends StatelessWidget {
  const FoodImpactSectionHeader({super.key, required this.title, required this.subtitle, this.trailing, this.icon = AppIcons.chartPie, this.iconColor = const Color(0xFF16A765)});

  final String title;
  final String subtitle;
  final Widget? trailing;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: Icon(icon, size: 20.w, color: iconColor),
      ),
      Gap.w10,
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
            ),
            if (subtitle.isNotEmpty) ...[
              Gap.h2,
              Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, color: context.insightColor(const Color(0xFF64748B)))),
            ],
          ],
        ),
      ),
      if (trailing != null) ...[Gap.w8, trailing!],
    ],
  );
}

class FoodImpactSectionAction extends StatelessWidget {
  const FoodImpactSectionAction({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: context.insightTheme.card,
    borderRadius: BorderRadius.circular(30.w),
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30.w),
      child: Container(
        constraints: BoxConstraints(minHeight: 44.w),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30.w),
          border: Border.all(color: context.insightColor(const Color(0xFFDCE5E1))),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w700, color: context.insightColor(const Color(0xFF334155)))),
            Gap.w3,
            Icon(Icons.arrow_forward_rounded, size: 12.w, color: context.insightColor(const Color(0xFF334155))),
          ],
        ),
      ),
    ),
  );
}
