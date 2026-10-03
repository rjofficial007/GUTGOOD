import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/insight_theme.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Shared next-step row used by the Insights detail screens.
///
/// The detail screens provide their existing theme-resolved colors so this
/// extraction preserves each screen's light/dark palette while centralizing
/// the identical layout and interaction-free presentation structure.
class InsightNextStepCheckRow extends StatelessWidget {
  const InsightNextStepCheckRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.titleColor,
    required this.subtitleColor,
  });

  final String title;
  final String subtitle;
  final Color accentColor;
  final Color titleColor;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 16.w,
        height: 16.w,
        margin: EdgeInsets.only(top: 1.w),
        decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(LucideIcons.check, size: 10.w, color: Colors.white),
      ),
      Gap.w6,
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: titleColor, height: 1.2),
            ),
            Gap.h2,
            Text(
              subtitle,
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, color: subtitleColor, height: 1.2),
            ),
          ],
        ),
      ),
    ],
  );
}
