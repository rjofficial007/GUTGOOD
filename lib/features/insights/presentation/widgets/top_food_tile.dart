import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/insight_theme.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TopFoodItemData {
  const TopFoodItemData({required this.title, required this.frequency, required this.badge, required this.imageUrl, this.description, this.isPositive = true, this.category = 'good'});

  final String title;
  final String frequency;
  final String badge;
  final String imageUrl;
  final String? description;
  final bool isPositive;
  final String category;
}

class TopFoodTile extends StatelessWidget {
  const TopFoodTile({super.key, required this.item, this.onTap});

  final TopFoodItemData item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = context.insightTheme;

    final (badgeBg, badgeFg, badgeIcon) = item.isPositive
        ? (context.insightColor(const Color(0xFFDCFCE7)), context.insightColor(const Color(0xFF15803D)), LucideIcons.leaf)
        : (context.insightColor(const Color(0xFFFEE2E2)), context.insightColor(const Color(0xFF991B1B)), LucideIcons.triangleAlert);

    final countStr = item.frequency.isEmpty ? '' : (item.frequency.contains('logged') ? item.frequency : (item.frequency.endsWith('x') ? '${item.frequency} logged' : item.frequency));

    // Red-shade border for trigger / watch items; emerald for positive
    final borderColor = item.isPositive
        ? (isDark ? const Color(0xFF22C55E).withValues(alpha: 0.28) : const Color(0xFFBBF7D0))
        : (isDark ? const Color(0xFFEF4444).withValues(alpha: 0.45) : const Color(0xFFFCA5A5));

    // Dark mode surface tint: deep red for triggers, deep green for healing
    final cardBg = item.isPositive
        ? (isDark ? const Color(0xFF102319) : theme.card)
        : (isDark ? const Color(0xFF231416) : theme.card);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18.w),
        border: Border.all(color: borderColor, width: 1.2.w),
        boxShadow: [
          if (!item.isPositive && isDark)
            BoxShadow(color: const Color(0xFFEF4444).withValues(alpha: 0.08), blurRadius: 10.w, offset: const Offset(0, 2)),
          BoxShadow(color: context.insightColor(const Color(0xFF0F172A)).withValues(alpha: 0.03), blurRadius: 8.w, offset: const Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18.w),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Food Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(14.w),
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    width: 56.w,
                    height: 56.w,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(color: badgeBg),
                    errorWidget: (_, _, _) => Container(
                      color: badgeBg,
                      child: Icon(badgeIcon, color: badgeFg, size: 24.w),
                    ),
                  ),
                ),
                Gap.w12,

                // 2. Info Area
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Badge + Count Tag
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.5.w),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(10.w),
                              border: !item.isPositive && isDark
                                  ? Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.30), width: 0.8.w)
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(badgeIcon, size: 9.5.w, color: badgeFg),
                                Gap.w3,
                                Text(
                                  item.badge,
                                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w700, color: badgeFg),
                                ),
                              ],
                            ),
                          ),
                          if (countStr.isNotEmpty) ...[
                            Gap.w6,
                            Text(
                              countStr,
                              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w600, color: context.insightColor(const Color(0xFF64748B))),
                            ),
                          ],
                        ],
                      ),
                      Gap.h5,

                      // Food Name
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: InsightTheme.fontFamily,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: !item.isPositive && isDark
                              ? const Color(0xFFF87171)
                              : (item.isPositive && isDark ? const Color(0xFF4ADE80) : context.insightColor(const Color(0xFF0F172A))),
                          height: 1.15,
                          letterSpacing: -0.2,
                        ),
                      ),

                      // Description / Effect (if provided)
                      if (item.description != null && item.description!.isNotEmpty) ...[
                        Gap.h3,
                        Text(
                          item.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, color: context.insightColor(const Color(0xFF475569)), height: 1.3),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
