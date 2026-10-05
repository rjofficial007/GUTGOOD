import 'package:flutter/material.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/theme/insight_theme.dart';
import 'package:gutgood/features/insights/presentation/pages/meal_symptom_detail_screen.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_feed/insight_ui_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class OccurrenceTile extends StatelessWidget {
  const OccurrenceTile({super.key, required this.occurrence, this.pattern});

  final PatternOccurrence occurrence;
  final BodyPattern? pattern;

  @override
  Widget build(BuildContext context) {

    final dateStr = occurrence.dateLabel ?? occurrence.date;
    final rawTime = occurrence.mealTime ?? occurrence.timeAfter;
    final timeStr = (rawTime.toLowerCase() == 'n/a' || rawTime.trim().isEmpty) ? '' : rawTime;
    final reactionStr = occurrence.reaction.isNotEmpty ? occurrence.reaction : 'Symptom logged';

    final lowerReaction = reactionStr.toLowerCase();

    final isEnergy = lowerReaction.contains('energy') || lowerReaction.contains('boost') || lowerReaction.contains('focus') || lowerReaction.contains('vitality') || lowerReaction.contains('alert');

    final isPositive =
        isEnergy || lowerReaction.contains('good') || lowerReaction.contains('great') || lowerReaction.contains('productive') || lowerReaction.contains('heal') || lowerReaction.contains('happy');

    final isNegative =
        lowerReaction.contains('bloat') ||
        lowerReaction.contains('pain') ||
        lowerReaction.contains('cramp') ||
        lowerReaction.contains('reflux') ||
        lowerReaction.contains('headache') ||
        lowerReaction.contains('nausea') ||
        lowerReaction.contains('drop') ||
        lowerReaction.contains('tired') ||
        lowerReaction.contains('fog') ||
        lowerReaction.contains('acid') ||
        lowerReaction.contains('distension');

    final Color statusColor;

    if (isEnergy) {
      statusColor = const Color(0xFFD97706); // Energetic amber/gold
    } else if (isPositive) {
      statusColor = const Color(0xFF15803D); // Fresh green
    } else if (isNegative) {
      statusColor = const Color(0xFFDC2626); // Warning red
    } else {
      statusColor = const Color(0xFF475569); // Neutral slate
    }

    return Container(
      decoration: BoxDecoration(
        color: context.insightColor(Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0))),
        boxShadow: [BoxShadow(color: context.insightColor(const Color(0xFF0F172A)).withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
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
                  child: InsightUiKit.foodImage(
                    occurrence.mealName,
                    imageUrl: occurrence.imageUrl,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    placeholder: Container(color: context.insightColor(const Color(0xFFF1F5F9))),
                    errorWidget: Container(
                      color: context.insightColor(const Color(0xFFFEF3C7)),
                      child: Icon(LucideIcons.utensils, color: context.insightColor(const Color(0xFFD97706)), size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // 2. Info Area (Meal Name, Symptom, Date/Time)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Meal Name
                      Text(
                        occurrence.mealName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.insightColor(const Color(0xFF0F172A)), height: 1.2),
                      ),
                      const SizedBox(height: 2),

                      // Reaction / Symptom (Red/Status Color, no icon)
                      Text(
                        reactionStr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: context.insightColor(statusColor), height: 1.1),
                      ),
                      const SizedBox(height: 3),

                      // Date & Time
                      Text(
                        timeStr.isNotEmpty ? '$dateStr • $timeStr' : dateStr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: context.insightColor(const Color(0xFF64748B)), height: 1.1),
                      ),
                    ],
                  ),
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
