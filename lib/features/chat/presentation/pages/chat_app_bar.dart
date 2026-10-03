part of 'chat_screen.dart';

/// Chat app-bar presentation component.

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ChatAppBar();

  @override
  Widget build(BuildContext context) => Selector2<ProfileNotifier, InsightsNotifier, (int?, bool)>(
    selector: (_, p, i) => (p.profile?.streak, i.healthAlerts.any((a) => !a.isRead)),
    builder: (context, data, _) {
      final streak = data.$1;
      final hasUnreadAlerts = data.$2;

      return GutAppBar(
        title: AppStrings.gutgood,
        streak: streak,
        actions: [
          GestureDetector(
            onTap: () => showPaywallScreen(context, onProceedWithLimited: () {}),
            child: const Tooltip(message: AppStrings.viewPremiumBenefits, child: PremiumBadge()),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(AppIcons.bell, color: context.appColorScheme.textPrimary, size: AppSizes.icon20),
                onPressed: () => context.push(AppRoutes.notificationArchive),
              ),
              if (hasUnreadAlerts)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: context.appColorScheme.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.appColorScheme.cardBackground, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          Gap.w4,
        ],
      );
    },
  );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// =============================================================================
// MESSAGE LIST
// =============================================================================

