import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_assets.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/haptic_helper.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

class ProfileHeader extends StatefulWidget {
  const ProfileHeader({
    super.key,
    required this.name,
    required this.email,
    required this.isPremium,
    this.photoUrl,
    required this.onImageTap,
    required this.streak,
    this.lastActivityDate,
    required this.gutScore,
    required this.avgFoodScore,
  });

  final String name;
  final String email;
  final bool isPremium;
  final String? photoUrl;
  final VoidCallback onImageTap;
  final int streak;
  final String? lastActivityDate;
  final int gutScore;
  final int avgFoodScore;

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> with SingleTickerProviderStateMixin {
  late AnimationController _lottieController;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    _lottieController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _lottieController.repeat(min: 0.58, max: 1.0);
      }
    });
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'G';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = widget.photoUrl != null && widget.photoUrl!.isNotEmpty;
    final bannerHeight = 140.0.h;
    final avatarSize = 90.0.w;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppPalette.black,
        borderRadius: BorderRadius.circular(AppSizes.r28),
        border: Border.all(color: AppPalette.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          // Banner + Avatar Stack with correct hit testing bounds
          SizedBox(
            height: bannerHeight + (avatarSize / 2),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // Luxury Banner with Integrated Streak
                Container(
                  height: bannerHeight,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppPalette.gray800, AppPalette.black],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Streak Animation Integrated into Banner
                      Positioned(
                        top: AppSizes.p12,
                        left: AppSizes.p16,
                        child: Row(
                          children: [
                            Lottie.asset(
                              AppAssets.streakAnimation,
                              height: 40.w,
                              width: 40.w,
                              controller: _lottieController,
                              onLoaded: (composition) {
                                _lottieController.duration = composition.duration;
                                _lottieController.forward();
                              },
                            ),
                            Gap.w8,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${widget.streak}',
                                  style: context.headingSm.copyWith(color: AppPalette.white, fontWeight: FontWeight.w900),
                                ),
                                Text(
                                  'DAY STREAK',
                                  style: context.eyebrow.copyWith(color: AppPalette.white.withValues(alpha: 0.4), fontSize: 7.sp, letterSpacing: 1.0),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Gut Score Integrated into Banner
                      Positioned(
                        top: AppSizes.p20,
                        right: AppSizes.p20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${widget.gutScore}',
                                    style: context.headingSm.copyWith(color: AppPalette.white, fontWeight: FontWeight.w900),
                                  ),
                                  TextSpan(
                                    text: '/100',
                                    style: context.caption.copyWith(color: AppPalette.white.withValues(alpha: 0.3), fontSize: 8.sp),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'GUT SCORE',
                              style: context.eyebrow.copyWith(color: AppPalette.white.withValues(alpha: 0.4), fontSize: 7.sp, letterSpacing: 1.0),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Dual-Ring Avatar (Fully inside the SizedBox for hit-testing)
                Positioned(
                  top: bannerHeight - (avatarSize / 2) - 4,
                  child: GestureDetector(
                    onTap: () {
                      HapticHelper.medium();
                      widget.onImageTap();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppPalette.white.withValues(alpha: 0.1), width: 1),
                      ),
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: avatarSize,
                            height: avatarSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppPalette.gray800,
                              border: Border.all(color: AppPalette.black, width: 3),
                              image: hasPhoto ? DecorationImage(image: CachedNetworkImageProvider(widget.photoUrl!), fit: BoxFit.cover) : null,
                              boxShadow: [
                                BoxShadow(color: AppPalette.black.withValues(alpha: 0.8), blurRadius: 20, offset: const Offset(0, 10)),
                              ],
                            ),
                            child: !hasPhoto
                                ? Center(
                                    child: Text(
                                      _getInitials(widget.name),
                                      style: context.displaySm.copyWith(color: AppPalette.white, fontSize: 32.sp, fontWeight: FontWeight.bold),
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            right: 2.w,
                            bottom: 2.w,
                            child: Semantics(
                              label: 'Upload Profile Picture',
                              button: true,
                              child: Container(
                                padding: EdgeInsets.all(AppSizes.p6),
                                decoration: BoxDecoration(
                                  color: AppPalette.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppPalette.black, width: 2),
                                ),
                                child: Icon(AppIcons.camera, size: AppSizes.icon12, color: AppPalette.black),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Gap.h16,
          // Luxury User Info
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.p20),
            child: Column(
              children: [
                if (widget.isPremium) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: AppSizes.p8, vertical: AppSizes.p2),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppPalette.white.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(AppSizes.r4),
                    ),
                    child: Text(
                      'PREMIUM',
                      style: context.eyebrow.copyWith(color: AppPalette.white.withValues(alpha: 0.6), fontSize: AppSizes.s8, letterSpacing: 2.0),
                    ),
                  ),
                  Gap.h8,
                ],
                Text(
                  widget.name,
                  textAlign: TextAlign.center,
                  style: context.headingSm.copyWith(color: AppPalette.white, letterSpacing: 0.5, fontWeight: FontWeight.bold),
                ),
                Gap.h4,
                Text(
                  widget.email.toLowerCase(),
                  textAlign: TextAlign.center,
                  style: context.caption.copyWith(color: AppPalette.gray500, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          Gap.h24,
          // Weekly Rhythm Bubbles Integrated
          Padding(
            padding: EdgeInsets.only(left: AppSizes.p20, right: AppSizes.p20, bottom: AppSizes.p24),
            child: _MinimalWeeklyBubbles(lastActivityDate: widget.lastActivityDate, streak: widget.streak),
          ),
        ],
      ),
    );
  }
}

class _MinimalWeeklyBubbles extends StatelessWidget {
  const _MinimalWeeklyBubbles({this.lastActivityDate, required this.streak});
  final String? lastActivityDate;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final firstDayOfWeek = todayMidnight.subtract(Duration(days: todayMidnight.weekday % 7));

    return Row(
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
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isStreakDay ? AppPalette.white : (isToday ? AppPalette.white.withValues(alpha: 0.1) : AppPalette.transparent),
                border: Border.all(color: isStreakDay ? AppPalette.white : AppPalette.white.withValues(alpha: 0.1), width: 1),
              ),
              child: isStreakDay
                  ? Icon(AppIcons.flame, size: 10, color: AppPalette.black)
                  : (isToday ? Icon(AppIcons.flame, size: 10, color: AppPalette.white) : null),
            ),
            Gap.h8,
            Text(
              dayName,
              style: context.caption.copyWith(
                fontSize: 10.sp,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? AppPalette.white : AppPalette.white.withValues(alpha: 0.3),
              ),
            ),
          ],
        );
      }),
    );
  }
}
