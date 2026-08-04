import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../constants/app_assets.dart';
import '../constants/app_sizes.dart';
import '../utils/responsive.dart';

class StreakCard extends StatelessWidget {
  final int streak;
  final String? lastActivityDate;

  const StreakCard({super.key, required this.streak, this.lastActivityDate});

  @override
  Widget build(BuildContext context) {
    final bool isActiveToday = _checkIsActiveToday();

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
                      Icon(AppIcons.flame, color: isActiveToday ? context.appColorScheme.textPrimary : context.appColorScheme.textMuted, size: AppSizes.icon24),
                      Gap.h8,
                      Text(
                        '$streak ${AppStrings.dayStreakLabel}',
                        style: context.eyebrow.copyWith(color: isActiveToday ? context.appColorScheme.textPrimary : context.appColorScheme.textMuted, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                      ),
                    ],
                  ),
                  Gap.h4,
                  Text(isActiveToday ? AppStrings.streakOnFire : AppStrings.streakKeepAlive, style: context.bodyBold.copyWith(fontSize: AppSizes.s16)),
                ],
              ),
              Lottie.asset(AppAssets.streakAnimation, height: AppSizes.p56),
            ],
          ),
          Gap.h24,
          _WeeklyProgressRow(lastActivityDate: lastActivityDate, streak: streak),
        ],
      ),
    );
  }

  bool _checkIsActiveToday() {
    if (lastActivityDate == null) return false;
    final today = DateTime.now().toIso8601String().split('T')[0];
    return lastActivityDate == today;
  }
}

class _WeeklyProgressRow extends StatelessWidget {
  final String? lastActivityDate;
  final int streak;

  const _WeeklyProgressRow({this.lastActivityDate, required this.streak});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final firstDayOfWeek = todayMidnight.subtract(Duration(days: todayMidnight.weekday % 7));
    final bool activeToday = _isActiveToday();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final day = firstDayOfWeek.add(Duration(days: index));
        final dayName = DateFormat('E').format(day)[0];
        final bool isToday = DateUtils.isSameDay(day, todayMidnight);

        bool isStreakDay = false;
        if (lastActivityDate != null && streak > 0) {
          final lastActive = DateTime.parse(lastActivityDate!);
          final lastActiveMidnight = DateTime(lastActive.year, lastActive.month, lastActive.day);

          final diff = todayMidnight.difference(lastActiveMidnight).inDays;
          if (diff <= 1) {
            final daysSinceThisDay = lastActiveMidnight.difference(day).inDays;
            if (daysSinceThisDay >= 0 && daysSinceThisDay < streak) {
              isStreakDay = true;
            }
          }
        }

        final bool showFlame = isStreakDay || isToday;
        final bool isHighlighted = isStreakDay || (isToday && activeToday);

        return Column(
          children: [
            Text(
              dayName,
              style: context.caption.copyWith(fontWeight: isToday ? FontWeight.w900 : FontWeight.w600, color: isToday ? context.appColorScheme.textPrimary : context.appColorScheme.textMuted),
            ),
            Gap.h10,
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 34.0.w,
              height: 34.0.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isHighlighted ? context.appColorScheme.textPrimary : (isToday ? context.appColorScheme.textPrimary : Colors.transparent),
                border: Border.all(color: showFlame ? context.appColorScheme.textPrimary : context.appColorScheme.border.withValues(alpha: 0.3), width: showFlame ? 2.0 : 1.0),
              ),
              child: Center(
                child: showFlame ? Icon(AppIcons.flame, color: context.appColorScheme.cardBackground, size: 18.0.w) : null,
              ),
            ),
          ],
        );
      }),
    );
  }

  bool _isActiveToday() {
    if (lastActivityDate == null) return false;
    final today = DateTime.now().toIso8601String().split('T')[0];
    return lastActivityDate == today;
  }
}
