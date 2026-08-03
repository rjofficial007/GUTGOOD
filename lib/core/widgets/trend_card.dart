import 'package:flutter/material.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:intl/intl.dart';

import '../constants/app_icons.dart';
import '../constants/app_sizes.dart';
import '../models/ai_insight.dart';

class TrendCard extends StatelessWidget {
  final List<AIInsight> insights;
  final AIInsight? currentInsight; // 🟢 NEW: Pass current insight for guaranteed "today" fill
  final DateTime? referenceDate;
  final String title;
  final String subtitle;

  const TrendCard({super.key, required this.insights, this.currentInsight, this.referenceDate, this.title = 'GUT SCORE TREND', this.subtitle = 'Weekly progress snapshot'});

  @override
  Widget build(BuildContext context) {
    // Merge history and current to ensure no data gaps
    final allInsights = [...insights];
    if (currentInsight != null && !allInsights.any((i) => i.firestoreId == currentInsight!.firestoreId)) {
      allInsights.insert(0, currentInsight!);
    }

    // Extract scores for the badge
    final scores = allInsights.take(2).map((i) => i.gutScore).toList();

    return Container(
      padding: EdgeInsets.all(AppSizes.p20),
      decoration: BoxDecoration(
        color: context.appColorScheme.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.r28),
        border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: AppPalette.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(AppIcons.barChart, color: context.appColorScheme.textPrimary, size: AppSizes.icon24),
                      Gap.w8,
                      Text(
                        title,
                        style: context.eyebrow.copyWith(color: context.appColorScheme.textPrimary, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                      ),
                    ],
                  ),
                  Gap.h4,
                  Text(subtitle, style: context.bodyBold.copyWith(fontSize: AppSizes.s16)),
                ],
              ),
              _TrendDirectionBadge(scores: scores),
            ],
          ),
          Gap.h24,
          _TrendBarChart(insights: allInsights, referenceDate: referenceDate ?? DateTime.now()),
        ],
      ),
    );
  }
}

class _TrendBarChart extends StatelessWidget {
  final List<AIInsight> insights;
  final DateTime referenceDate;

  const _TrendBarChart({required this.insights, required this.referenceDate});

  @override
  Widget build(BuildContext context) {
    final int totalSlots = 7;

    // 🟢 Fix: Normalize all dates to local midnight for accurate calendar day mapping.
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);

    final ref = referenceDate;
    final refMidnight = DateTime(ref.year, ref.month, ref.day);

    // Get Sunday of the reference week (anchor)
    final sunday = refMidnight.subtract(Duration(days: refMidnight.weekday % 7));

    // Map insights to days of this week
    final Map<int, int> dayScores = {};
    for (var insight in insights) {
      final date = insight.updatedAt.toLocal();
      final normalizedDate = DateTime(date.year, date.month, date.day);

      // Calculate day index (0 = Sunday, 6 = Saturday)
      final diff = normalizedDate.difference(sunday).inDays;

      if (diff >= 0 && diff < 7) {
        // If multiple insights on same day, keep the first one found
        // (Assuming insights list is newest first, this is the latest report for that day).
        if (!dayScores.containsKey(diff)) {
          dayScores[diff] = insight.gutScore;
        }
      }
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(totalSlots, (index) {
            final int value = dayScores[index] ?? 0;
            final double targetHeight = (value / 100) * 80.0;
            final bool hasValue = value > 0;

            final day = sunday.add(Duration(days: index));
            final dayName = DateFormat('E').format(day)[0];
            final bool isToday = day.year == now.year && day.month == now.month && day.day == now.day;

            return Column(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: targetHeight),
                  duration: Duration(milliseconds: 600 + (index * 100)),
                  curve: Curves.easeOutQuart,
                  builder: (context, val, _) {
                    return Container(
                      width: 16.0.w,
                      height: 80.0.h,
                      alignment: Alignment.bottomCenter,
                      decoration: BoxDecoration(color: context.appColorScheme.border.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(50.0.r)),
                      child: Container(
                        width: 16.0.w,
                        height: val.h,
                        decoration: BoxDecoration(color: hasValue ? context.appColorScheme.textPrimary : Colors.transparent, borderRadius: BorderRadius.circular(50.0.r)),
                      ),
                    );
                  },
                ),
                Gap.h12,
                Text(
                  dayName,
                  style: context.caption.copyWith(
                    fontSize: 10.0.sp,
                    color: isToday ? context.appColorScheme.textPrimary : context.appColorScheme.textMuted,
                    fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class _TrendDirectionBadge extends StatelessWidget {
  final List<int> scores;
  const _TrendDirectionBadge({required this.scores});

  @override
  Widget build(BuildContext context) {
    if (scores.length < 2) return const SizedBox.shrink();

    // scores are descending (newest first) from insights.take(2)
    final last = scores[0];
    final first = scores[1];
    final diff = last - first;
    final isPositive = diff >= 0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.p10, vertical: AppSizes.p4),
      decoration: BoxDecoration(color: (isPositive ? context.appColorScheme.success : context.appColorScheme.error).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(100)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isPositive ? AppIcons.arrowUp : AppIcons.arrowDown, size: 14.0.w, color: isPositive ? context.appColorScheme.success : context.appColorScheme.error),
          Gap.w4,
          Text(
            '${diff.abs()}',
            style: context.caption.copyWith(color: isPositive ? context.appColorScheme.success : context.appColorScheme.error, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
