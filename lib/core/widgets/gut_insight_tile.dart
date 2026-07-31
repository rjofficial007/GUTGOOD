import 'package:flutter/material.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';

import '../constants/app_sizes.dart';

class GutInsightTile extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color statusColor;
  final VoidCallback? onTap;

  const GutInsightTile({super.key, required this.title, required this.value, required this.subtitle, required this.icon, required this.statusColor, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12.0.w, vertical: 12.0.h),
        decoration: BoxDecoration(
          color: context.appColorScheme.cardBackground,
          borderRadius: BorderRadius.circular(20.0.r),
          border: Border.all(color: context.appColorScheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(6.0.w),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.05), shape: BoxShape.circle),
              child: Icon(icon, color: statusColor, size: 16.0.w),
            ),
            Gap.h10,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title.toUpperCase(),
                  style: context.caption.copyWith(color: context.appColorScheme.textMuted, fontSize: 10.0.sp, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                Text(value, style: context.bodyBold.copyWith(fontSize: 13.0.sp, height: 1.2)),
                if (subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: Text(subtitle, style: context.label.copyWith(color: context.appColorScheme.textMuted, height: 1.2)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
