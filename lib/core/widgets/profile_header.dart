import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_assets.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
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
    this.longestStreak = 0,
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
  final int longestStreak;
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
    final bannerHeight = 80.0.h;
    final avatarSize = 80.0.w;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppPalette.black,
        borderRadius: BorderRadius.circular(AppSizes.r28),
        border: Border.all(color: AppPalette.white.withAlpha(31)),
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
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.gray800, AppPalette.black]),
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
                        border: Border.all(color: AppPalette.white.withAlpha(26), width: 1),
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
                              boxShadow: [BoxShadow(color: AppPalette.black.withAlpha(204), blurRadius: 20, offset: const Offset(0, 10))],
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
                      border: Border.all(color: AppPalette.white.withAlpha(51)),
                      borderRadius: BorderRadius.circular(AppSizes.r4),
                    ),
                    child: Text(
                      AppStrings.premium,
                      style: context.eyebrow.copyWith(color: AppPalette.white.withAlpha(153), fontSize: AppSizes.s8, letterSpacing: 2.0),
                    ),
                  ),
                  Gap.h8,
                ],
                Text(
                  widget.name,
                  textAlign: TextAlign.center,
                  style: context.headingLg.copyWith(color: AppPalette.white, letterSpacing: 0.5, fontWeight: FontWeight.bold),
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
            padding: EdgeInsets.symmetric(horizontal: AppSizes.p20),
            child: _MinimalWeeklyBubbles(lastActivityDate: widget.lastActivityDate, streak: widget.streak),
          ),
          Gap.h32,
          // Relocated Stats Section
          Padding(
            padding: EdgeInsets.only(left: AppSizes.p10, right: AppSizes.p20, bottom: AppSizes.p32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Streak Row
                Row(
                  children: [
                    Lottie.asset(
                      AppAssets.streakAnimation,
                      height: 50.w,
                      width: 50.w,
                      controller: _lottieController,
                      onLoaded: (composition) {
                        _lottieController.duration = composition.duration;
                        _lottieController.forward(from: 50 / composition.endFrame);
                      },
                    ),
                    Gap.w8,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${widget.streak}',
                              style: context.headingMd.copyWith(color: AppPalette.white, fontWeight: FontWeight.w900),
                            ),
                            if (widget.longestStreak > 0) ...[
                              Gap.w6,
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  '${AppStrings.bestScore}: ${widget.longestStreak}',
                                  style: context.captionBold.copyWith(color: AppPalette.white.withAlpha(77)),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          AppStrings.dayStreakLabel.toUpperCase(),
                          style: context.captionBold.copyWith(color: AppPalette.white.withAlpha(102)),
                        ),
                      ],
                    ),
                  ],
                ),
                // Gut Score Column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${widget.avgFoodScore}',
                            style: context.headingMd.copyWith(color: AppPalette.white, fontWeight: FontWeight.w900),
                          ),
                          TextSpan(
                            text: '/100',
                            style: context.caption.copyWith(color: AppPalette.white.withAlpha(77)),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      AppStrings.gutGoodScore.toUpperCase(),
                      style: context.captionBold.copyWith(color: AppPalette.white.withAlpha(102)),
                    ),
                  ],
                ),
              ],
            ),
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
          
          final daysSinceThisDay = lastActiveMidnight.difference(day).inDays;
          if (daysSinceThisDay >= 0 && daysSinceThisDay < streak) {
            isStreakDay = true;
          }
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isStreakDay ? AppPalette.white : (isToday ? AppPalette.white.withAlpha(26) : AppPalette.transparent),
                border: Border.all(color: isStreakDay ? AppPalette.white : AppPalette.white.withAlpha(26), width: 1),
              ),
              child: isStreakDay ? const Icon(AppIcons.flame, size: 10, color: AppPalette.black) : (isToday ? const Icon(AppIcons.flame, size: 10, color: AppPalette.white) : null),
            ),
            Gap.h8,
            Text(
              dayName,
              style: context.caption.copyWith(fontSize: 12.sp, fontWeight: isToday ? FontWeight.bold : FontWeight.normal, color: isToday ? AppPalette.white : AppPalette.white.withAlpha(77)),
            ),
          ],
        );
      }),
    );
  }
}
