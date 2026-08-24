import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/date_formatter.dart';
import 'package:shimmer/shimmer.dart';

class MealHistoryTile extends StatelessWidget {
  const MealHistoryTile({super.key, required this.mealLog, required this.onTap});

  final MealLog mealLog;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayImageUrl = mealLog.photoUrl;

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
            // 1. Meal Image / Icon
            Container(
              width: AppSizes.w52,
              height: AppSizes.w52,
              decoration: BoxDecoration(color: context.appColorScheme.cardBackground, borderRadius: BorderRadius.circular(AppSizes.r12)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.r12),
                child: displayImageUrl != null && displayImageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: displayImageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: context.appColorScheme.border.withValues(alpha: 0.2),
                          highlightColor: context.appColorScheme.border.withValues(alpha: 0.1),
                          child: Container(color: AppPalette.white),
                        ),
                        errorWidget: (_, _, _) => Icon(AppIcons.utensils, size: AppSizes.icon24, color: context.appColorScheme.textMuted),
                      )
                    : Icon(AppIcons.utensils, size: AppSizes.icon24, color: context.appColorScheme.textMuted),
              ),
            ),
            Gap.w16,
            // 2. Info (Items, Type, Time)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mealLog.items.join(', '),
                    style: context.bodyBold.copyWith(fontSize: AppSizes.s15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Gap.h4,
                  Text(
                    '${mealLog.mealType ?? AppStrings.mealSnapLabel} • ${DateFormatter.formatTime(mealLog.createdAt)}',
                    style: context.caption.copyWith(color: context.appColorScheme.textMuted, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
