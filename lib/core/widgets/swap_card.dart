import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/image_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';

class SwapCard extends StatelessWidget {
  const SwapCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageKeyword,
    this.imageUrl,
    required this.tag,
    this.badge,
    this.isBlackBadge = false,
    this.width,
  });
  final String title;
  final String subtitle;
  final String imageKeyword;
  final String? imageUrl;
  final String tag;
  final String? badge;
  final bool isBlackBadge;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final cardWidth = width ?? 160.0.w;

    return Container(
      width: cardWidth,
      decoration: BoxDecoration(
        color: context.appColorScheme.cardBackground,
        borderRadius: BorderRadius.circular(20.0.r),
        border: Border.all(color: context.appColorScheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Area
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20.0.r),
                ),
                child: CachedNetworkImage(
                  imageUrl: imageUrl ?? getDynamicImageUrl(imageKeyword),
                  height: 120.0.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 120.0.h,
                    color: context.appColorScheme.elevatedSurface,
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 120.0.h,
                    color: context.appColorScheme.elevatedSurface,
                  ),
                ),
              ),
              if (badge != null)
                Positioned(
                  top: 10.0.h,
                  left: 10.0.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.0.w,
                      vertical: 4.0.h,
                    ),
                    decoration: BoxDecoration(
                      color: context.appColorScheme.textPrimary,
                      borderRadius: BorderRadius.circular(6.0.r),
                    ),
                    child: Text(
                      badge!,
                      style: context.overline.copyWith(
                        color: context.appColorScheme.cardBackground,
                        fontSize: 9.0.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(14.0.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.bodyBold.copyWith(fontSize: 14.0.sp),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Gap.h4,
                Text(
                  subtitle,
                  style: context.caption.copyWith(
                    fontSize: 12.0.sp,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Gap.h14,
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.0.w,
                    vertical: 6.0.h,
                  ),
                  decoration: BoxDecoration(
                    color: context.appColorScheme.cardBackground,
                    border: Border.all(color: context.appColorScheme.border),
                    borderRadius: BorderRadius.circular(20.0.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        AppIcons.checkCircle,
                        size: 12.0.w,
                        color: context.appColorScheme.textPrimary,
                      ),
                      Expanded(
                        child: Text(
                          tag.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: context.overline.copyWith(
                            color: context.appColorScheme.textPrimary,
                            fontSize: 9.0.sp,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 12.0.w),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
