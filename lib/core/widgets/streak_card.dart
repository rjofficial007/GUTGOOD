import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_assets.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

class StreakCard extends StatefulWidget {
  const StreakCard({super.key, required this.streak, this.lastActivityDate});
  final int streak;
  final String? lastActivityDate;

  @override
  State<StreakCard> createState() => _StreakCardState();
}

class _StreakCardState extends State<StreakCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _lottieController;
  Timer? _lottieTimer;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    _lottieController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _lottieController.repeat(min: 0.58, max: 1.0, reverse: false);
      }
    });

    // Start Lottie after DelayedDisplay slide-in animation (approx 800ms)
    _lottieTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) {
        _lottieController.forward();
      }
    });
  }

  @override
  void dispose() {
    _lottieController.dispose();
    _lottieTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActiveToday = _checkIsActiveToday();

    return Container(
      padding: EdgeInsets.all(AppSizes.p20),
      decoration: BoxDecoration(
        color: context.appColorScheme.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.r28),
        border: Border.all(
          color: context.appColorScheme.border.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: AppPalette.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
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
                      Icon(
                        AppIcons.flame,
                        color: isActiveToday
                            ? context.appColorScheme.textPrimary
                            : context.appColorScheme.textMuted,
                        size: AppSizes.icon24,
                      ),
                      Gap.h8,
                      Text(
                        '${widget.streak} ${AppStrings.dayStreakLabel}',
                        style: context.eyebrow.copyWith(
                          color: isActiveToday
                              ? context.appColorScheme.textPrimary
                              : context.appColorScheme.textMuted,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  Gap.h4,
                  Text(
                    isActiveToday
                        ? AppStrings.streakOnFire
                        : AppStrings.streakKeepAlive,
                    style: context.bodyBold.copyWith(fontSize: AppSizes.s16),
                  ),
                ],
              ),
              Lottie.asset(
                AppAssets.streakAnimation,
                height: AppSizes.p56,
                width: AppSizes.p56,
                controller: _lottieController,
                onLoaded: (composition) {
                  _lottieController.duration = composition.duration;
                },
              ),
            ],
          ),
          Gap.h24,
          _WeeklyProgressRow(
            lastActivityDate: widget.lastActivityDate,
            streak: widget.streak,
          ),
        ],
      ),
    );
  }

  bool _checkIsActiveToday() {
    if (widget.lastActivityDate == null) return false;
    final today = DateTime.now().toIso8601String().split('T')[0];
    return widget.lastActivityDate == today;
  }
}

class _WeeklyProgressRow extends StatelessWidget {
  const _WeeklyProgressRow({this.lastActivityDate, required this.streak});
  final String? lastActivityDate;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final firstDayOfWeek = todayMidnight.subtract(
      Duration(days: todayMidnight.weekday % 7),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final day = firstDayOfWeek.add(Duration(days: index));
        final dayName = DateFormat('E').format(day)[0];
        final isToday = DateUtils.isSameDay(day, todayMidnight);

        var isStreakDay = false;
        if (lastActivityDate != null && streak > 0) {
          final lastActive = DateTime.parse(lastActivityDate!);
          final lastActiveMidnight = DateTime(
            lastActive.year,
            lastActive.month,
            lastActive.day,
          );

          final diff = todayMidnight.difference(lastActiveMidnight).inDays;
          // If active today or yesterday, the streak is alive.
          if (diff <= 1) {
            final daysSinceThisDay = lastActiveMidnight.difference(day).inDays;
            if (daysSinceThisDay >= 0 && daysSinceThisDay < streak) {
              isStreakDay = true;
            }
          }
        }

        // A day shows a "completed" flame only if it was a streak day.
        final isCompleted = isStreakDay;
        final isMissed = !isStreakDay && day.isBefore(todayMidnight);

        return Column(
          children: [
            Text(
              dayName,
              style: context.caption.copyWith(
                fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                color: isToday
                    ? context.appColorScheme.textPrimary
                    : context.appColorScheme.textMuted,
              ),
            ),
            Gap.h10,
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 34.0.w,
              height: 34.0.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? context.appColorScheme.textPrimary
                    : (isMissed
                          ? context.appColorScheme.border.withValues(alpha: 0.1)
                          : Colors.transparent),
                border: Border.all(
                  color: isToday
                      ? context.appColorScheme.textPrimary
                      : (isCompleted
                            ? context.appColorScheme.textPrimary
                            : (isMissed
                                  ? context.appColorScheme.border.withValues(
                                      alpha: 0.2,
                                    )
                                  : context.appColorScheme.border.withValues(
                                      alpha: 0.3,
                                    ))),
                  width: isToday ? 2.0 : 1.0,
                ),
              ),
              child: Center(
                child: Icon(
                  AppIcons.flame,
                  color: isCompleted
                      ? context.appColorScheme.cardBackground
                      : (isMissed
                            ? context.appColorScheme.textMuted.withValues(
                                alpha: 0.2,
                              )
                            : (isToday
                                  ? context.appColorScheme.textPrimary
                                        .withValues(alpha: 0.4)
                                  : Colors.transparent)),
                  size: 18.0.w,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
