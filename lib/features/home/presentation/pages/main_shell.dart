import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/streak_celebration_overlay.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final profileNotifier = context.watch<ProfileNotifier>();

    return Scaffold(
      backgroundColor: context.appColorScheme.cardBackground,
      body: Stack(
        children: [
          navigationShell,
          if (profileNotifier.showStreakCelebration)
            Positioned.fill(
              child: StreakCelebrationOverlay(streak: profileNotifier.profile?.streak ?? 0, onDismiss: profileNotifier.dismissStreakCelebration),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.appColorScheme.cardBackground,
          border: Border(top: BorderSide(color: context.appColorScheme.border, width: 0.5)),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.p8, vertical: AppSizes.p4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _TabItem(icon: LucideIcons.messageCircle, label: AppStrings.chat, active: navigationShell.currentIndex == 0, onTap: () => navigationShell.goBranch(0)),
                _TabItem(icon: LucideIcons.barChart, label: AppStrings.insightsTab, active: navigationShell.currentIndex == 1, onTap: () => navigationShell.goBranch(1)),
                _TabItem(icon: LucideIcons.history, label: AppStrings.history, active: navigationShell.currentIndex == 2, onTap: () => navigationShell.goBranch(2)),
                _TabItem(icon: LucideIcons.user, label: AppStrings.profileTab, active: navigationShell.currentIndex == 3, onTap: () => navigationShell.goBranch(3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabItem({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSizes.p8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: active ? Theme.of(context).colorScheme.primary : context.appColorScheme.textMuted, size: AppSizes.icon24),
              Gap.h4,
              Text(
                label,
                style: context.caption.copyWith(
                  color: active ? Theme.of(context).colorScheme.primary : context.appColorScheme.textMuted,
                  fontSize: AppSizes.s10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
