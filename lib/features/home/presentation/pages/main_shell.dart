import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/theme/theme_provider.dart';
import 'package:gutgood/core/widgets/streak_celebration_overlay.dart';
import 'package:gutgood/app/theme/app_theme.dart';
import 'package:genz_insights/genz_insights.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell, this.isGenzInsights = false});
  final StatefulNavigationShell navigationShell;
  final bool isGenzInsights;

  @override
  Widget build(BuildContext context) {
    final profileNotifier = context.watch<ProfileNotifier>();
    final themeNotifier = context.watch<ThemeNotifier>();
    final appTheme = Theme.of(context);
    final genzUsesDarkTheme = isGenzInsights &&
        (!themeNotifier.hasExplicitPreference || appTheme.brightness == Brightness.dark);
    final genzBackground = genzUsesDarkTheme
        ? const Color(0xFF0B0B12)
        : const Color(0xFFF3F1EC);
    final genzSurface = genzUsesDarkTheme
        ? const Color(0xFF171722)
        : Colors.white;
    final genzBorder = genzUsesDarkTheme
        ? const Color(0x1CFFFFFF)
        : const Color(0x1C0B0B12);

    final shell = Scaffold(
      backgroundColor: isGenzInsights ? genzBackground : context.appColorScheme.cardBackground,
      body: Stack(
        children: [
          navigationShell,
          if (profileNotifier.showStreakCelebration)
            Positioned.fill(
              child: StreakCelebrationOverlay(
                streak: profileNotifier.profile?.streak ?? 0,
                onDismiss: profileNotifier.dismissStreakCelebration,
              ),
            ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: isGenzInsights ? genzSurface : context.appColorScheme.cardBackground,
          border: Border(
            top: BorderSide(
              color: isGenzInsights ? genzBorder : context.appColorScheme.border,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizes.p8,
              vertical: AppSizes.p4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _TabItem(
                  icon: LucideIcons.messageCircle,
                  label: AppStrings.chat,
                  active: navigationShell.currentIndex == 0,
                  onTap: () => navigationShell.goBranch(0),
                ),
                _TabItem(
                  icon: LucideIcons.barChart,
                  label: AppStrings.insightsTab,
                  active: navigationShell.currentIndex == 1,
                  onTap: () => navigationShell.goBranch(1),
                ),
                _TabItem(
                  icon: LucideIcons.history,
                  label: AppStrings.history,
                  active: navigationShell.currentIndex == 2,
                  onTap: () => navigationShell.goBranch(2),
                ),
                _TabItem(
                  icon: LucideIcons.user,
                  label: AppStrings.profileTab,
                  active: navigationShell.currentIndex == 3,
                  onTap: () => navigationShell.goBranch(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!isGenzInsights) return shell;

    final shellTheme = genzUsesDarkTheme ? AppTheme.darkTheme : AppTheme.lightTheme;
    final brightness = genzUsesDarkTheme ? Brightness.dark : Brightness.light;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: genzUsesDarkTheme ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Theme(
        data: shellTheme.copyWith(
          brightness: brightness,
          scaffoldBackgroundColor: genzBackground,
          colorScheme: shellTheme.colorScheme.copyWith(brightness: brightness),
          textTheme: shellTheme.textTheme.apply(
            fontFamily: GenzFonts.primary,
            fontFamilyFallback: GenzFonts.fallback,
          ),
          primaryTextTheme: shellTheme.primaryTextTheme.apply(
            fontFamily: GenzFonts.primary,
            fontFamilyFallback: GenzFonts.fallback,
          ),
        ),
        child: shell,
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSizes.p8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: active
                  ? Theme.of(context).colorScheme.primary
                  : context.appColorScheme.textMuted,
              size: AppSizes.icon24,
            ),
            Gap.h4,
            Text(
              label,
              style: context.caption.copyWith(
                color: active
                    ? Theme.of(context).colorScheme.primary
                    : context.appColorScheme.textMuted,
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
