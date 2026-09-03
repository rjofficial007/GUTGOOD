import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';

/// A standardized list tile displaying a leading image or icon,
/// title and subtitle metadata, and a trailing circular score progress gauge.
class GutScoreListTile extends StatelessWidget {
  const GutScoreListTile({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.score,
    required this.onTap,
    this.scoreColor,
    this.trackColor,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final int score;
  final VoidCallback onTap;
  final Color? scoreColor;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final effectiveScoreColor = scoreColor ?? context.appColorScheme.textPrimary;
    final effectiveTrackColor = trackColor ?? context.appColorScheme.borderSubtle;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: AppSizes.p12),
        padding: EdgeInsets.all(AppSizes.p12),
        decoration: BoxDecoration(
          color: context.appColorScheme.elevatedSurface,
          borderRadius: BorderRadius.circular(AppSizes.r20),
          border: Border.all(color: context.appColorScheme.borderSubtle),
        ),
        child: Row(
          children: [
            // 1. Leading Image / Icon Widget
            SizedBox(
              width: AppSizes.w52,
              height: AppSizes.w52,
              child: leading,
            ),
            Gap.w16,
            // 2. Info (Title & Subtitle)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.labelBold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Gap.h4,
                  Text(
                    subtitle,
                    style: context.captionBold.copyWith(color: context.appColorScheme.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Gap.w12,
            // 3. Score Badge (Circular Progress Gauge)
            SizedBox(
              width: AppSizes.w52,
              height: AppSizes.w52,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: (score / 100).clamp(0.0, 1.0),
                    strokeWidth: 5,
                    strokeCap: StrokeCap.round,
                    backgroundColor: effectiveTrackColor,
                    valueColor: AlwaysStoppedAnimation<Color>(effectiveScoreColor),
                  ),
                  Text(
                    '$score',
                    style: context.labelBold,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
