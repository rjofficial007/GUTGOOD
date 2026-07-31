import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';

class ScanHistoryTile extends StatelessWidget {
  final ScanResult scanResult;
  final DateTime? time;
  final String? userImageUrl;
  final VoidCallback onTap;

  const ScanHistoryTile({super.key, required this.scanResult, this.time, this.userImageUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final String? displayImageUrl = userImageUrl ?? scanResult.userImageUrl ?? scanResult.imageUrl;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.0.h),
        padding: EdgeInsets.all(12.0.w),
        decoration: BoxDecoration(
          color: context.appColorScheme.elevatedSurface,
          borderRadius: BorderRadius.circular(20.0.r),
          border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            // 1. Product Image
            Container(
              width: 52.0.w,
              height: 52.0.w,
              decoration: BoxDecoration(color: context.appColorScheme.cardBackground, borderRadius: BorderRadius.circular(12.0.r)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0.r),
                child: displayImageUrl != null
                    ? Hero(
                        tag: 'scan_image_${scanResult.barcode ?? scanResult.productName}_${time?.millisecondsSinceEpoch}',
                        child: CachedNetworkImage(
                          imageUrl: displayImageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(strokeWidth: 2.w, color: context.appColorScheme.textMuted),
                          ),
                          errorWidget: (_, _, _) => Icon(AppIcons.package, size: 24.0.w, color: context.appColorScheme.textMuted),
                        ),
                      )
                    : Icon(AppIcons.package, size: 24.0.w, color: context.appColorScheme.textMuted),
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
                    style: context.bodyBold.copyWith(fontSize: 15.0.sp),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Gap.h4,
                  Text(
                    '${scanResult.brand} • ${time != null ? _formatTime(time!) : 'Saved Item'}',
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
              width: 52.0.w,
              height: 52.0.w,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: scanResult.score / 100,
                    strokeWidth: 5.w,
                    strokeCap: StrokeCap.round,
                    backgroundColor: context.appColorScheme.textPrimary.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(context.appColorScheme.textPrimary),
                  ),
                  Text(
                    '${scanResult.score}',
                    style: context.bodyBold.copyWith(fontSize: 13.0.sp, fontWeight: FontWeight.w900),
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
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $amPm';
  }
}
