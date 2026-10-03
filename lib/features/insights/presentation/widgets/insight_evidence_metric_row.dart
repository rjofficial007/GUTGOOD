import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/insight_theme.dart';
import 'package:gutgood/core/utils/responsive.dart';

/// Shared evidence metric row used by the Insights detail screens.
///
/// Theme-resolved colors are supplied by the caller so the extracted layout
/// preserves the existing screen-specific light/dark palette.
class InsightEvidenceMetricRow extends StatelessWidget {
  const InsightEvidenceMetricRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.iconBackground,
    required this.iconColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.valueColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final Color iconBackground;
  final Color iconColor;
  final Color titleColor;
  final Color subtitleColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 22.w,
        height: 22.w,
        decoration: BoxDecoration(color: iconBackground, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(icon, size: 11.w, color: iconColor),
      ),
      Gap.w6,
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: titleColor, height: 1.1),
            ),
            Text(
              subtitle,
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.sp, color: subtitleColor, height: 1.1),
            ),
          ],
        ),
      ),
      Text(
        value,
        style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: valueColor),
      ),
    ],
  );
}
