import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/theme/app_palette.dart';
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
      title: isPremium ? AppStrings.premiumMember : AppStrings.freeMember,
      leading: Container(
        width: AppSizes.p8,
        height: AppSizes.p8,
        decoration: const BoxDecoration(color: AppPalette.white, shape: BoxShape.circle),
      ),
      backgroundColor: AppPalette.black,
      titleColor: AppPalette.white.withValues(alpha: 0.7),
      action: Text(
        '$streak${AppStrings.dayStreak}',
        style: context.caption.copyWith(color: AppPalette.white.withValues(alpha: 0.5), fontWeight: FontWeight.bold, fontSize: AppSizes.s9),
      ),
      footerColor:AppPalette.gray100,
      footer: Text(
        '$goalsCount ${AppStrings.goals.toUpperCase()} • $sensitivitiesCount ${AppStrings.sensitivities.toUpperCase()} • $lifestyleCount ${AppStrings.lifestyle.toUpperCase()}',
        style: context.caption.copyWith(color: AppPalette.black, fontWeight: FontWeight.w900, fontSize: AppSizes.s9, letterSpacing: 0.5),
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
                        border: Border.all(color: AppPalette.white.withValues(alpha: 0.1), width: 2),
                      ),
                      child: !hasPhoto
                          ? Center(
                              child: Text(
                                _getInitials(name),
                                style: context.bodyBold.copyWith(color: AppPalette.white, fontSize: AppSizes.s20),
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: EdgeInsets.all(AppSizes.p4),
                        decoration: const BoxDecoration(color: AppPalette.white, shape: BoxShape.circle),
                        child: Icon(Icons.add_rounded, size: AppSizes.icon12, color: AppPalette.black),
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
                      style: context.bodyBold.copyWith(color: AppPalette.white, fontSize: AppSizes.s18),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      email,
                      style: context.caption.copyWith(color: AppPalette.white.withValues(alpha: 0.5)),
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
                child: _HeaderButton(label: AppStrings.editProfile, icon: AppIcons.user, onTap: onEditTap),
              ),
              Gap.w12,
              Expanded(
                child: _HeaderButton(label: AppStrings.logout, icon: AppIcons.logOut, onTap: onLogoutTap),
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
      color: AppPalette.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppSizes.r16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.r16),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: AppSizes.p12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: AppSizes.icon14, color: AppPalette.white),
              Gap.w8,
              Text(
                label,
                style: context.caption.copyWith(color: AppPalette.white, fontWeight: FontWeight.bold, fontSize: AppSizes.s11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
