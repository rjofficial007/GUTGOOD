import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:shimmer/shimmer.dart';

class ScanHistoryTile extends StatelessWidget {

  const ScanHistoryTile({super.key, required this.scanResult, this.time, this.userImageUrl, required this.onTap});
  final ScanResult scanResult;
  final DateTime? time;
  final String? userImageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayImageUrl = userImageUrl ?? scanResult.userImageUrl ?? scanResult.imageUrl;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: AppSizes.p12),
        padding: EdgeInsets.all(AppSizes.p12),
        decoration: BoxDecoration(
          color: context.appColorScheme.elevatedSurface,
          borderRadius: BorderRadius.circular(AppSizes.r20),
          border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            // 1. Product Image
            Container(
              width: AppSizes.w52,
              height: AppSizes.w52,
              decoration: BoxDecoration(color: context.appColorScheme.cardBackground, borderRadius: BorderRadius.circular(AppSizes.r12)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.r12),
                child: displayImageUrl != null
                    ? Hero(
                        tag: 'scan_image_${scanResult.barcode ?? scanResult.productName}_${time?.millisecondsSinceEpoch}',
                        child: CachedNetworkImage(
                          imageUrl: displayImageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: context.appColorScheme.border.withValues(alpha: 0.2),
                            highlightColor: context.appColorScheme.border.withValues(alpha: 0.1),
                            child: Container(color: AppPalette.white),
                          ),
                          errorWidget: (_, _, _) => Icon(AppIcons.package, size: AppSizes.icon24, color: context.appColorScheme.textMuted),
                        ),
                      )
                    : Icon(AppIcons.package, size: AppSizes.icon24, color: context.appColorScheme.textMuted),
              ),
            ),
            Gap.w16,
            // 2. Info (Name, Brand, Time)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scanResult.productName,
                    style: context.bodyBold.copyWith(fontSize: AppSizes.s15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Gap.h4,
                  Text(
                    '${scanResult.brand} • ${time != null ? _formatTime(time!) : AppStrings.labelSavedItem}',
                    style: context.caption.copyWith(color: context.appColorScheme.textMuted, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Gap.w12,
            // 3. Score Badge (Circular Progress)
            SizedBox(
              width: AppSizes.w52,
              height: AppSizes.w52,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: scanResult.score / 100,
                    strokeWidth: 5,
                    strokeCap: StrokeCap.round,
                    backgroundColor: context.appColorScheme.textPrimary.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(context.appColorScheme.textPrimary),
                  ),
                  Text(
                    '${scanResult.score}',
                    style: context.bodyBold.copyWith(fontSize: AppSizes.s13, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final amPm = time.hour >= 12 ? AppStrings.unitPM : AppStrings.unitAM;
    return '$hour:${time.minute.toString().padLeft(2, '0')} $amPm';
  }
}
