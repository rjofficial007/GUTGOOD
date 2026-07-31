import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';

import '../constants/app_sizes.dart';
import '../theme/app_palette.dart';
import 'modern_insight_card.dart';

class ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final bool isPremium;
  final String? photoUrl;
  final int streak;
  final int goalsCount;
  final int sensitivitiesCount;
  final int lifestyleCount;
  final VoidCallback onImageTap;
  final VoidCallback onEditTap;
  final VoidCallback onLogoutTap;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.email,
    required this.isPremium,
    this.photoUrl,
    required this.streak,
    required this.goalsCount,
    required this.sensitivitiesCount,
    required this.lifestyleCount,
    required this.onImageTap,
    required this.onEditTap,
    required this.onLogoutTap,
  });

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
    final bool hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    return ModernInsightCard(
      title: isPremium ? 'PREMIUM MEMBER' : 'FREE MEMBER',
      leading: Container(
        width: 8.0.w,
        height: 8.0.w,
        decoration: const BoxDecoration(color: AppPalette.lime, shape: BoxShape.circle),
      ),
      backgroundColor: AppPalette.black,
      titleColor: Colors.white.withValues(alpha: 0.7),
      action: Text(
        '${streak}D STREAK',
        style: context.caption.copyWith(color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.bold, fontSize: 9.0.sp),
      ),
      footerColor: AppPalette.lime,
      footer: Text(
        '$goalsCount GOALS • $sensitivitiesCount SENSITIVITIES • $lifestyleCount LIFESTYLE',
        style: context.caption.copyWith(color: AppPalette.black, fontWeight: FontWeight.w900, fontSize: 9.0.sp, letterSpacing: 0.5),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Row
          Row(
            children: [
              GestureDetector(
                onTap: onImageTap,
                child: Stack(
                  children: [
                    Container(
                      width: 64.0.w,
                      height: 64.0.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppPalette.gray800,
                        image: hasPhoto ? DecorationImage(image: CachedNetworkImageProvider(photoUrl!), fit: BoxFit.cover) : null,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 2),
                      ),
                      child: !hasPhoto
                          ? Center(
                              child: Text(
                                _getInitials(name),
                                style: context.bodyBold.copyWith(color: Colors.white, fontSize: 20.0.sp),
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: EdgeInsets.all(4.0.w),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(Icons.add_rounded, size: 12.0.w, color: AppPalette.black),
                      ),
                    ),
                  ],
                ),
              ),
              Gap.w16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: context.bodyBold.copyWith(color: Colors.white, fontSize: 18.0.sp),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      email,
                      style: context.caption.copyWith(color: Colors.white.withValues(alpha: 0.5)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Gap.h32,

          // Action Row: Edit & Logout
          Row(
            children: [
              Expanded(
                child: _HeaderButton(label: 'Edit Profile', icon: AppIcons.user, onTap: onEditTap),
              ),
              Gap.w12,
              Expanded(
                child: _HeaderButton(label: 'Logout', icon: AppIcons.logOut, onTap: onLogoutTap),
              ),
            ],
          ),
          Gap.h24,
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16.0.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.0.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14.0.w, color: Colors.white),
              Gap.w8,
              Text(
                label,
                style: context.caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.0.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
