import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:intl/intl.dart';

class TrendCard extends StatelessWidget {

  const TrendCard({super.key, required this.insights, this.currentInsight, this.referenceDate, this.title = AppStrings.scoreTrend, this.subtitle = AppStrings.weeklySnapshot});
  final List<AIInsight> insights;
  final AIInsight? currentInsight; // 🟢 NEW: Pass current insight for guaranteed "today" fill
  final DateTime? referenceDate;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    // Merge history and current to ensure no data gaps
    final allInsights = [...insights];
    if (currentInsight != null && !allInsights.any((i) => i.firestoreId == currentInsight!.firestoreId)) {
      allInsights.insert(0, currentInsight!);
    }

    // Extract scores for the badge
    final scores = allInsights.take(2).map((i) => i.gutScore).toList();

    return GutDashboardSection(
      title: title,
      subtitle: subtitle,
      visualization: _TrendBarChart(insights: allInsights, referenceDate: referenceDate ?? DateTime.now()),
      items: [
        _TrendDirectionTile(scores: scores),
        if (allInsights.isNotEmpty) ...[
          Gap.h12,
          DashboardDetailItem(title: '${allInsights.first.gutScore} ${AppStrings.pointsUnit}', subtitle: AppStrings.gutGoodScore, icon: AppIcons.activity, color: context.appColorScheme.textPrimary),
        ],
      ],
    );
  }
}

class _TrendBarChart extends StatelessWidget {

  const _TrendBarChart({required this.insights, required this.referenceDate});
  final List<AIInsight> insights;
  final DateTime referenceDate;

  @override
  Widget build(BuildContext context) {
    const totalSlots = 7;

    // 🟡 Fix: Use local time for trend mapping so bars align with the user's local day.
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);

    // Get Sunday of the reference week (anchor) in local time
    final sunday = todayMidnight.subtract(Duration(days: todayMidnight.weekday % 7));

    // Map insights to days of this week
    final dayScores = <int, int>{};
    for (var insight in insights) {
      final date = insight.updatedAt;
      final normalizedDate = DateTime(date.year, date.month, date.day);

      // Calculate day index (0 = Sunday, 6 = Saturday)
      final diff = normalizedDate.difference(sunday).inDays;

      if (diff >= 0 && diff < 7) {
        // If multiple insights on same day, keep the newest one
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
            final value = dayScores[index] ?? 0;
            final targetHeight = (value / 100) * 50.0;
            final hasValue = value > 0;

            final day = sunday.add(Duration(days: index));
            final dayName = DateFormat('E').format(day)[0];
            final isToday = DateUtils.isSameDay(day, todayMidnight);

            return Column(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: targetHeight),
                  duration: Duration(milliseconds: 600 + (index * 100)),
                  curve: Curves.easeOutQuart,
                  builder: (context, val, _) => Container(
                      width: 8.0.w,
                      height: 50.0.h,
                      alignment: Alignment.bottomCenter,
                      decoration: BoxDecoration(color: context.appColorScheme.border.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(50.0.r)),
                      child: Container(
                        width: 8.0.w,
                        height: val.h,
                        decoration: BoxDecoration(color: hasValue ? context.appColorScheme.textPrimary : Colors.transparent, borderRadius: BorderRadius.circular(50.0.r)),
                      ),
                    ),
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

class _TrendDirectionTile extends StatelessWidget {
  const _TrendDirectionTile({required this.scores});
  final List<int> scores;

  @override
  Widget build(BuildContext context) {
    if (scores.length < 2) return const SizedBox.shrink();

    // scores are descending (newest first) from insights.take(2)
    final last = scores[0];
    final first = scores[1];
    final diff = last - first;
    final isPositive = diff >= 0;

    return DashboardDetailItem(
      title: '${isPositive ? '+' : '-'}${diff.abs()} ${AppStrings.pointsUnit}',
      subtitle: isPositive ? 'Improving' : 'Declining',
      icon: isPositive ? AppIcons.arrowUp : AppIcons.arrowDown,
      color: isPositive ? context.appColorScheme.success : context.appColorScheme.error,
    );
  }
}
