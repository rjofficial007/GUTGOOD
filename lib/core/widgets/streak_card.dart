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
  const StreakCard({super.key, required this.streak, this.lastActivityDate, this.gutScore = 0, this.avgFoodScore = 0, this.logsToday = 0, this.logsGoal = 3});
  final int streak;
  final String? lastActivityDate;
  final int gutScore;
  final int avgFoodScore;
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
    final scheme = context.appColorScheme;
    final textColor = scheme.textPrimary;
    final borderColor = scheme.border.withValues(alpha: 0.5);

    return Container(
      padding: EdgeInsets.all(AppSizes.p20),
      decoration: BoxDecoration(
        color: scheme.elevatedSurface,
        borderRadius: BorderRadius.circular(AppSizes.r28),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Lottie.asset(
                    AppAssets.streakAnimation,
                    height: 52.w,
                    width: 52.w,
                    controller: _lottieController,
                    onLoaded: (composition) {
                      _lottieController.duration = composition.duration;
                    },
                  ),
                  Gap.w12,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.streak} DAYS',
                        style: context.headingMd.copyWith(color: textColor, height: 1.1, fontWeight: FontWeight.w900, fontFeatures: const [FontFeature.tabularFigures()]),
                      ),
                      Text(
                        'DAILY STREAK',
                        style: context.eyebrow.copyWith(color: textColor.withValues(alpha: 0.6), letterSpacing: 1.2, fontSize: 9.sp),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${widget.avgFoodScore}',
                          style: context.headingMd.copyWith(color: textColor, height: 1.1, fontWeight: FontWeight.w900, fontFeatures: const [FontFeature.tabularFigures()]),
                        ),
                        TextSpan(
                          text: ' / 100',
                          style: context.caption.copyWith(color: textColor.withValues(alpha: 0.4), fontWeight: FontWeight.w800, fontSize: 10.sp),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'GUT SCORE',
                    style: context.eyebrow.copyWith(color: textColor.withValues(alpha: 0.6), letterSpacing: 1.2, fontSize: 9.sp),
                  ),
                ],
              ),
            ],
          ),
          Gap.h10,
          _WeeklyBubbles(lastActivityDate: widget.lastActivityDate, streak: widget.streak),
        ],
      ),
    );
  }
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
      padding: EdgeInsets.symmetric(vertical: AppSizes.p12),
      decoration: BoxDecoration(color: scheme.border.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(24)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          final day = firstDayOfWeek.add(Duration(days: index));
          final dayName = DateFormat('E').format(day)[0];
          final isToday = DateUtils.isSameDay(day, todayMidnight);

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

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isStreakDay ? scheme.textPrimary : (isToday ? scheme.textPrimary.withValues(alpha: 0.1) : scheme.border.withValues(alpha: 0.1)),
                  border: isToday && !isStreakDay ? Border.all(color: scheme.textPrimary.withValues(alpha: 0.4), width: 1.5) : null,
                ),
                child: isStreakDay
                    ? Icon(AppIcons.flame, size: 14, color: scheme.cardBackground)
                    : (isToday ? Icon(AppIcons.flame, size: 14, color: scheme.textPrimary) : Icon(AppIcons.flame, size: 14, color: scheme.textPrimary.withValues(alpha: 0.5))),
              ),
              Gap.h8,
              Text(
                dayName,
                style: context.caption.copyWith(
                  fontSize: 12.sp,
                  fontWeight:  FontWeight.w900 ,
                  color: isToday ? scheme.textPrimary : scheme.textPrimary.withValues(alpha: 0.4),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
