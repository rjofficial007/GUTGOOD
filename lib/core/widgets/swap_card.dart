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
    final colorScheme = context.appColorScheme;
    final cardWidth = width ?? 160.0.w;

    return Container(
      width: cardWidth,
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.r20),
        border: Border.all(color: colorScheme.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: colorScheme.surfaceSubtle,
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Area with Technical Badge
          Stack(
            children: [
              Container(
                height: 110.0.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.elevatedSurface,
                  border: Border(bottom: BorderSide(color: colorScheme.border.withAlpha(77))),
                ),
                child: CachedNetworkImage(
                  imageUrl: imageUrl ?? getDynamicImageUrl(imageKeyword),
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Center(child: Icon(AppIcons.image, color: colorScheme.textMuted, size: 20)),
                  errorWidget: (context, url, error) => Center(child: Icon(AppIcons.image, color: colorScheme.textMuted, size: 20)),
                ),
              ),
              if (badge != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.textPrimary,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      badge!.toUpperCase(),
                      style: context.captionTiny.copyWith(
                        color: colorScheme.cardBackground,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          Padding(
            padding: EdgeInsets.all(AppSizes.p14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.labelBold.copyWith(height: 1.1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Gap.h6,
                Text(
                  subtitle,
                  style: context.label.copyWith(
                    color: colorScheme.textSecondary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Gap.h16,
                // Technical Tag - Colored with Border
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color:colorScheme.border,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        AppIcons.checkCircle, 
                        size: 10, 
                        color:colorScheme.textPrimary,
                      ),
                      Gap.w8,
                      Flexible(
                        child: Text(
                          tag.toUpperCase(),
                          style: context.captionBold.copyWith(
                            color:  colorScheme.textPrimary,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
