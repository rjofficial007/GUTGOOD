import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/features/insights/presentation/pages/meal_symptom_detail_screen.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_theme.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/v2_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class OccurrenceTile extends StatelessWidget {
  const OccurrenceTile({super.key, required this.occurrence, this.pattern});

  final PatternOccurrence occurrence;
  final BodyPattern? pattern;

  @override
  Widget build(BuildContext context) {
    final imgUrl = V2Kit.foodImageUrl(occurrence.mealName, imageUrl: occurrence.imageUrl);

    final dateStr = occurrence.dateLabel ?? occurrence.date;
    final timeStr = occurrence.mealTime ?? occurrence.timeAfter;
    final reactionStr = occurrence.reaction.isNotEmpty ? occurrence.reaction : 'Symptom logged';

    return Container(
      decoration: BoxDecoration(
        color: context.insightColor(Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: context.insightColor(const Color(0xFF0F172A)).withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: pattern == null
              ? null
              : () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MealSymptomDetailScreen(occurrence: occurrence, pattern: pattern!),
                    ),
                  );
                },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                // 1. Food Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: imgUrl,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(color: context.insightColor(const Color(0xFFF1F5F9))),
                    errorWidget: (_, _, _) => Container(
                      color: context.insightColor(const Color(0xFFFEF3C7)),
                      child: Icon(LucideIcons.utensils, color: context.insightColor(const Color(0xFFD97706)), size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // 2. Info Area (Meal Name & Symptom)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Meal Name
                      Text(
                        occurrence.mealName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: context.insightColor(const Color(0xFF0F172A)), height: 1.2),
                      ),
                      const SizedBox(height: 3),

                      // Reaction / Symptom Subtitle
                      Row(
                        children: [
                          Icon(LucideIcons.triangleAlert, size: 10, color: context.insightColor(const Color(0xFFDC2626))),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              reactionStr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: context.insightColor(const Color(0xFFDC2626)), height: 1.1),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // 3. Right Metadata (Date & Time)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Date Badge Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: context.insightColor(const Color(0xFFF1F5F9)), borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        dateStr,
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: context.insightColor(const Color(0xFF0F172A))),
                      ),
                    ),
                    if (timeStr.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        timeStr,
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w500, color: context.insightColor(const Color(0xFF64748B))),
                      ),
                    ],
                  ],
                ),

                // Trailing Chevron (if interactive)
                if (pattern != null) ...[const SizedBox(width: 4), Icon(LucideIcons.chevronRight, size: 16, color: context.insightColor(const Color(0xFF94A3B8)))],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
