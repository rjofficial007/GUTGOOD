import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_assets.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

class StreakCard extends StatefulWidget {
  const StreakCard({super.key, required this.streak, this.lastActivityDate, this.gutScore = 0, this.logsToday = 0, this.logsGoal = 3});
  final int streak;
  final String? lastActivityDate;
  final int gutScore;
  final int logsToday;
  final int logsGoal;

  @override
  State<StreakCard> createState() => _StreakCardState();
}

class _StreakCardState extends State<StreakCard> with SingleTickerProviderStateMixin {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = context.appColorScheme;
    final textColor = scheme.textPrimary;
    final borderColor = scheme.border.withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.elevatedSurface,
        borderRadius: BorderRadius.circular(AppSizes.r32),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left Section: Streak Visual
          Container(
            width: 110.w,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            decoration: BoxDecoration(
              color: scheme.border.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  AppAssets.streakAnimation,
                  height: 50.w,
                  width: 50.w,
                  controller: _lottieController,
                  onLoaded: (composition) {
                    _lottieController.duration = composition.duration;
                  },
                ),
                Gap.h4,
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Text(
                      '${widget.streak} Days',
                      style: context.headingSm.copyWith(color: textColor, fontWeight: FontWeight.w900, letterSpacing: -0.5, fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  ),
                ),
                Text(
                  'STREAK',
                  style: context.caption.copyWith(color: textColor.withValues(alpha: 0.5), fontWeight: FontWeight.w700, fontSize: 9.sp),
                ),
              ],
            ),
          ),
          Gap.w12,
          // Right Section: Progress & Weekly
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Gap.h2,
                // Progress Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${widget.gutScore}',
                        style: context.headingMd.copyWith(color: textColor, fontWeight: FontWeight.w900, fontFeatures: const [FontFeature.tabularFigures()]),
                      ),
                      Text(
                        ' / 100',
                        style: context.title.copyWith(color: textColor.withValues(alpha: 0.4), fontWeight: FontWeight.w800, fontFeatures: const [FontFeature.tabularFigures()]),
                      ),
                      const Spacer(),
                      Text('GUT SCORE', style: context.eyebrow.copyWith(color: textColor)),
                    ],
                  ),
                ),
                Gap.h10,
                // Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: _GlowingProgressBar(progress: widget.gutScore / 100, color: scheme.textPrimary),
                ),
                Gap.h16,
                // Weekly Bubbles
                _WeeklyBubbles(lastActivityDate: widget.lastActivityDate, streak: widget.streak),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowingProgressBar extends StatelessWidget {
  const _GlowingProgressBar({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      LinearProgressIndicator(value: progress.clamp(0.0, 1.0), minHeight: 5, backgroundColor: color.withValues(alpha: 0.1), color: color, borderRadius: BorderRadius.circular(10));
}

class _WeeklyBubbles extends StatelessWidget {
  const _WeeklyBubbles({this.lastActivityDate, required this.streak});
  final String? lastActivityDate;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final firstDayOfWeek = todayMidnight.subtract(Duration(days: todayMidnight.weekday % 7));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      decoration: BoxDecoration(color: scheme.border.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          final day = firstDayOfWeek.add(Duration(days: index));
          final dayName = DateFormat('E').format(day)[0];
          final isToday = DateUtils.isSameDay(day, todayMidnight);
          final isFuture = day.isAfter(todayMidnight);

          var isStreakDay = false;
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

          final isMissed = !isStreakDay && day.isBefore(todayMidnight);

          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: AppSizes.icon24,
                  height: AppSizes.icon24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isStreakDay ? scheme.textPrimary : (isToday ? scheme.textPrimary.withValues(alpha: 0.1) : scheme.border.withValues(alpha: 0.1)),
                    border: isToday && !isStreakDay ? Border.all(color: scheme.textPrimary.withValues(alpha: 0.4), width: 1.5) : null,
                  ),
                  child: isStreakDay
                      ? Icon(AppIcons.flame, size: 10, color: scheme.cardBackground)
                      : (isToday ? Icon(AppIcons.flame, size: 10, color: scheme.textPrimary) : (isMissed ? Icon(AppIcons.flame, size: 10, color: scheme.textPrimary.withValues(alpha: 0.5)) : null)),
                ),
                Gap.h6,
                Text(
                  dayName,
                  style: context.caption.copyWith(
                    fontSize: 8.5.sp,
                    fontWeight: isToday ? FontWeight.w900 : FontWeight.w700,
                    color: isToday ? scheme.textPrimary : scheme.textPrimary.withValues(alpha: isFuture ? 0.2 : 0.4),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
