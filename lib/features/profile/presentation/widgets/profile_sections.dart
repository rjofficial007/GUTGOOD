import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_assets.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/di_instance.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/services/config_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/theme/theme_provider.dart';
import 'package:gutgood/core/utils/bottom_sheet_helper.dart';
import 'package:gutgood/core/widgets/profile_header.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/auth/data/services/usage_service.dart';
import 'package:gutgood/features/auth/presentation/pages/paywall_screen.dart';
import 'package:gutgood/features/auth/presentation/providers/auth_provider.dart';
import 'package:gutgood/features/auth/presentation/providers/purchase_provider.dart';
import 'package:gutgood/features/auth/presentation/widgets/auth_bottom_sheets.dart';
import 'package:gutgood/features/profile/data/services/debug_mock_data_service.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:gutgood/features/profile/presentation/providers/usage_notifier.dart';
import 'package:gutgood/infrastructure/firebase/notification_service.dart';
import 'package:gutgood/infrastructure/platform/app_service.dart';
import 'package:gutgood/infrastructure/platform/app_version_service.dart';
import 'package:provider/provider.dart';

class ProfileHeaderSection extends StatelessWidget {
  const ProfileHeaderSection({super.key, required this.onImageTap, required this.onEditTap, required this.onLogoutTap});

  final Function(ProfileNotifier) onImageTap;
  final Function(ProfileNotifier) onEditTap;
  final Function(GutAuthNotifier, ProfileNotifier) onLogoutTap;

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.watch<GutAuthNotifier>();
    final profileNotifier = context.read<ProfileNotifier>();

    return Selector<ProfileNotifier, (UserProfile?, int)>(
      selector: (_, n) => (n.profile, n.avgFoodScore),
      builder: (context, data, _) {
        final p = data.$1;
        final avgFoodScore = data.$2;

        return ProfileHeader(
          name: p?.displayName ?? (authNotifier.isAnonymous ? AppStrings.guestUser : authNotifier.user?.displayName ?? ''),
          email: p?.email ?? (authNotifier.isAnonymous ? AppStrings.signInToSyncData : authNotifier.user?.email ?? ''),
          isPremium: p?.isPremium ?? false,
          photoUrl: p?.photoUrl,
          streak: profileNotifier.streak,
          longestStreak: profileNotifier.longestStreak,
          lastActivityDate: profileNotifier.lastActivityDate,
          gutScore: p?.gutScore ?? 0,
          avgFoodScore: avgFoodScore,
          onImageTap: () {
            SemanticsService.sendAnnouncement(View.of(context), AppStrings.uploadingProfilePicture, TextDirection.ltr);
            onImageTap(profileNotifier);
          },
        );
      },
    );
  }
}

class StreakAndUsageSection extends StatelessWidget {
  const StreakAndUsageSection({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Selector<ProfileNotifier, bool>(
        selector: (_, n) => n.profile?.isPremium ?? false,
        builder: (context, isPremium, _) {
          if (isPremium) return const SizedBox.shrink();
          return const AIUsageCard();
        },
      ),
    ],
  );
}

class PersonalizationSection extends StatelessWidget {
  const PersonalizationSection({super.key});

  @override
  Widget build(BuildContext context) => Selector<ProfileNotifier, (List<String>, List<String>, List<String>)>(
    selector: (_, n) => (n.profile?.goals ?? [], n.profile?.sensitivities ?? [], n.profile?.lifestyle ?? []),
    builder: (context, data, _) {
      final goals = data.$1;
      final sensitivities = data.$2;
      final lifestyle = data.$3;

      return GutSection(
        title: AppStrings.sectionPersonalization,
        showCard: true,
        children: [
          AppTile(
            icon: AppIcons.target,
            title: AppStrings.goals,
            subtitle: '${goals.length} ${AppStrings.activeCount}',
            onTap: () => unawaited(context.push(AppRoutes.goals, extra: goals)),
          ),
          AppTile(
            icon: AppIcons.alertTriangle,
            title: AppStrings.foodSensitivities,
            subtitle: '${sensitivities.length} ${AppStrings.flaggedCount}',
            onTap: () => unawaited(context.push(AppRoutes.sensitivities, extra: sensitivities)),
          ),
          AppTile(
            icon: AppIcons.smile,
            title: AppStrings.lifestyleFactors,
            subtitle: '${lifestyle.length} ${AppStrings.selectedCount}',
            onTap: () => unawaited(context.push(AppRoutes.lifestyle, extra: lifestyle)),
            showBottomBorder: false,
          ),
        ],
      );
    },
  );
}

class AppSettingsSection extends StatelessWidget {
  const AppSettingsSection({super.key, required this.onAppearanceTap});
  final Function(ThemeNotifier) onAppearanceTap;

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.read<ThemeNotifier>();
    return GutSection(
      title: AppStrings.app,
      showCard: true,
      children: [
        AppTile(icon: AppIcons.bookmark, title: AppStrings.savedFoods, onTap: () => unawaited(context.push(AppRoutes.savedFoods))),
        AppTile(icon: AppIcons.bell, title: AppStrings.notificationPreferences, onTap: () => unawaited(context.push(AppRoutes.notifications))),

        Selector<ThemeNotifier, ThemeMode>(
          selector: (_, n) => n.themeMode,
          builder: (context, mode, _) => AppTile(
            icon: AppIcons.moon,
            title: AppStrings.appearance,
            trailing: Text(
              mode == ThemeMode.system
                  ? AppStrings.system
                  : mode == ThemeMode.dark
                  ? AppStrings.dark
                  : AppStrings.light,
              style: context.caption.copyWith(color: context.appColorScheme.textMuted, fontWeight: FontWeight.w500),
            ),
            onTap: () => onAppearanceTap(themeNotifier),
            showBottomBorder: false,
          ),
        ),
      ],
    );
  }
}

class BodyRhythmSection extends StatelessWidget {
  const BodyRhythmSection({super.key});

  @override
  Widget build(BuildContext context) {
    final profileNotifier = context.read<ProfileNotifier>();

    return Selector<ProfileNotifier, (bool, String?)>(
      selector: (_, n) => (n.profile?.cycleSyncEnabled ?? false, n.profile?.cyclePhase),
      builder: (context, data, _) {
        final enabled = data.$1;
        final phase = data.$2;

        return GutSection(
          title: AppStrings.bodyRhythm,
          showCard: true,
          children: [
            AppSwitchTile(
              icon: AppIcons.flower,
              title: AppStrings.cycleSync,
              desc: AppStrings.cycleSyncSubtitle,
              value: enabled,
              onChanged: (val) => unawaited(profileNotifier.updateCycleSync(val)),
              showBottomBorder: enabled,
            ),
            if (enabled)
              AppTile(
                icon: AppIcons.calendar,
                title: AppStrings.cyclePhase,
                subtitle: phase ?? AppStrings.phaseLuteal,
                onTap: () => unawaited(context.push(AppRoutes.cyclePhase, extra: phase)),
                showBottomBorder: false,
              ),
          ],
        );
      },
    );
  }
}

class AccountSection extends StatelessWidget {
  const AccountSection({super.key, required this.onEditTap, required this.onLogoutTap, required this.onDeleteTap});
  final Function(ProfileNotifier) onEditTap;
  final Function(GutAuthNotifier, ProfileNotifier) onLogoutTap;
  final Function(GutAuthNotifier) onDeleteTap;

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.watch<GutAuthNotifier>();
    final profileNotifier = context.read<ProfileNotifier>();
    final purchaseProvider = context.read<PurchaseProvider>();

    return Selector<ProfileNotifier, bool>(
      selector: (_, n) => n.profile?.isPremium ?? false,
      builder: (context, isPremium, _) {
        final isAnon = authNotifier.isAnonymous;

        return GutSection(
          title: AppStrings.account,
          showCard: true,
          children: [
            if (isAnon)
              AppTile(
                icon: AppIcons.userPlus,
                title: AppStrings.signInToSync,
                onTap: () => unawaited(showAuthBottomSheet(context, onSuccess: profileNotifier.refresh)),
              ),
            AppTile(icon: AppIcons.user, title: AppStrings.editProfile, onTap: () => onEditTap(profileNotifier)),
            AppTile(
              icon: AppIcons.creditCard,
              title: AppStrings.premiumPlanName,
              subtitle: isPremium ? AppStrings.activeStatus : AppStrings.freeTrial,
              onTap: () {
                if (!isPremium) {
                  unawaited(showPaywallScreen(context, onProceedWithLimited: () {}));
                }
              },
            ),
            AppTile(icon: AppIcons.refreshCw, title: AppStrings.restorePurchases, onTap: () => _handleRestorePurchases(context, purchaseProvider)),
            AppTile(icon: AppIcons.logOut, title: AppStrings.logout, iconColor: context.appColorScheme.error, onTap: () => onLogoutTap(authNotifier, profileNotifier)),
            AppTile(
              icon: AppIcons.trash2,
              title: AppStrings.deleteAccountLabel,
              iconColor: context.appColorScheme.error,
              trailing: const CautionBadge(),
              onTap: () => onDeleteTap(authNotifier),
              showBottomBorder: false,
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleRestorePurchases(BuildContext context, PurchaseProvider purchaseProvider) async {
    final success = await purchaseProvider.restorePurchases();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(success ? AppStrings.restoreSuccess : AppStrings.restoreFailed), backgroundColor: success ? context.appColorScheme.success : context.appColorScheme.error));
    }
  }
}

class SupportSection extends StatelessWidget {
  const SupportSection({super.key});

  @override
  Widget build(BuildContext context) => GutSection(
    title: AppStrings.helpAndSupport,
    showCard: true,
    children: [
      AppTile(icon: AppIcons.share, title: AppStrings.shareWithFriends, onTap: () => sl<AppService>().shareWithFriends(context)),
      AppTile(
        icon: AppIcons.messageSquare,
        title: AppStrings.contactUs,
        onTap: () => unawaited(sl<AppService>().sendingMails(mailContent: AppStrings.labelFeedbackSubject, isFromReview: false)),
      ),
      AppTile(icon: AppIcons.star, title: AppStrings.rateApp, onTap: () => unawaited(sl<AppService>().requestReview())),
      AppTile(icon: AppIcons.helpCircle, title: AppStrings.aboutUs, onTap: () => unawaited(sl<AppService>().urlLauncher(context, sl<ConfigService>().aboutUsUrl))),
      AppTile(icon: AppIcons.clipboardList, title: AppStrings.termsAndConditions, onTap: () => unawaited(sl<AppService>().urlLauncher(context, sl<ConfigService>().termsConditionUrl))),
      AppTile(icon: AppIcons.shieldCheck, title: AppStrings.privacy, onTap: () => unawaited(sl<AppService>().urlLauncher(context, sl<ConfigService>().privacyPolicyUrl))),
      AppTile(icon: AppIcons.shield, title: AppStrings.medicalDisclaimer, onTap: () => unawaited(BottomSheetHelper.showMedicalDisclaimer(context)), showBottomBorder: false),
    ],
  );
}

class DebugToolsSection extends StatelessWidget {
  const DebugToolsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final profileNotifier = context.read<ProfileNotifier>();
    final purchaseProvider = context.read<PurchaseProvider>();

    return Selector<ProfileNotifier, bool>(
      selector: (_, n) => n.profile?.isPremium ?? false,
      builder: (context, isPremium, _) => GutSection(
        title: AppStrings.sectionDebugTools,
        showCard: true,
        children: [
          AppSwitchTile(
            icon: AppIcons.shieldCheck,
            title: AppStrings.premiumStatusDebug,
            desc: AppStrings.premiumStatusDebug,
            value: isPremium,
            onChanged: (val) async {
              purchaseProvider.setPremiumForDebug(val);
              await sl<UsageService>().setPremiumForTesting(val);
              unawaited(profileNotifier.refresh());
            },
          ),
          AppTile(
            icon: AppIcons.refreshCcw,
            title: AppStrings.resetDailyUsage,
            onTap: () async {
              await sl<UsageService>().resetLimitsForTesting();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.limitsReset)));
              }
            },
          ),
          AppTile(
            icon: AppIcons.bell,
            title: AppStrings.testPushNotification,
            onTap: () async {
              await sl<NotificationService>().testNotification();
            },
          ),
          AppTile(
            icon: AppIcons.copy,
            title: AppStrings.copyFcmToken,
            subtitle: AppStrings.copyFcmTokenSubtitle,
            onTap: () async {
              final token = await FirebaseMessaging.instance.getToken();
              if (token != null) {
                await Clipboard.setData(ClipboardData(text: token));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.fcmTokenCopied)));
                }
              }
            },
          ),
          AppTile(
            icon: Icons.data_array,
            title: AppStrings.generateMockData,
            subtitle: AppStrings.generateMockDataSubtitle,
            onTap: () async {
              await sl<DebugMockDataService>().generateThirtyDaysData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.mockDataGenerated)));
              }
            },
            showBottomBorder: false,
          ),
        ],
      ),
    );
  }
}

class AppVersionInfo extends StatelessWidget {
  const AppVersionInfo({super.key});

  @override
  Widget build(BuildContext context) => GutSection(
    showCard: true,
    topPadding: AppSizes.p20,
    children: [
      Padding(
        padding: EdgeInsets.symmetric(vertical: AppSizes.p18),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.r12),
              child: Image.asset(AppAssets.appIcon, width: AppSizes.icon44, height: AppSizes.icon44),
            ),
            Gap.w16,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.appName, style: AppTextStyles.bodyBold),
                  Text('v${sl<AppVersionService>().appVersion} (${sl<AppVersionService>().buildVersion})', style: context.captionBold.copyWith(color: context.appColorScheme.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class AIUsageCard extends StatelessWidget {
  const AIUsageCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final textColor = scheme.textPrimary;
    final borderColor = scheme.borderSubtle;

    final usageNotifier = context.watch<UsageNotifier>();
    final usage = usageNotifier.usage;
    final maxChats = usageNotifier.maxChats;
    final maxScans = usageNotifier.maxScans;
    final isAnon = context.select<GutAuthNotifier, bool>((n) => n.isAnonymous);

    final chatCount = usage?.chatCount ?? 0;
    final scanCount = usage?.scanCount ?? 0;

    return Container(
      margin: EdgeInsets.only(top: AppSizes.p16),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.limits.toUpperCase(), style: context.captionBold.copyWith(color: textColor.withAlpha(153))),
                  Text(isAnon ? AppStrings.guestAccount : AppStrings.freePlan, style: context.bodyBold.copyWith(color: textColor, height: 1.1)),
                ],
              ),
              GestureDetector(
                onTap: () => unawaited(showPaywallScreen(context, onProceedWithLimited: () {})),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: textColor, borderRadius: BorderRadius.circular(100)),
                  child: Text(AppStrings.upgrade.toUpperCase(), style: context.captionBold.copyWith(color: scheme.cardBackground)),
                ),
              ),
            ],
          ),
          Gap.h24,
          UsageRow(label: AppStrings.aiChats, current: chatCount, total: maxChats, color: textColor),
          Gap.h16,
          UsageRow(label: AppStrings.productScans, current: scanCount, total: maxScans, color: textColor),
        ],
      ),
    );
  }
}

class UsageRow extends StatelessWidget {
  const UsageRow({super.key, required this.label, required this.current, required this.total, required this.color});
  final String label;
  final int current;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = (current / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label.toUpperCase(), style: context.captionBold.copyWith(color: context.appColorScheme.textSecondary)),
            Text('$current / $total', style: context.captionBold.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
          ],
        ),
        Gap.h6,
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(value: progress, backgroundColor: context.appColorScheme.borderSubtle, valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 5),
        ),
      ],
    );
  }
}

class AppearanceOption extends StatelessWidget {
  const AppearanceOption({super.key, required this.icon, required this.title, required this.isSelected, required this.onTap});
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${AppStrings.semanticsAppearancePrefix}$title${AppStrings.semanticsAppearanceSuffix}',
    button: true,
    selected: isSelected,
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: AppSizes.p12),
        padding: EdgeInsets.all(AppSizes.p16),
        decoration: BoxDecoration(
          color: isSelected ? context.appColorScheme.textPrimary : context.appColorScheme.elevatedSurface,
          borderRadius: BorderRadius.circular(AppSizes.r16),
          border: Border.all(color: isSelected ? context.appColorScheme.textPrimary : context.appColorScheme.border, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppSizes.p8),
              decoration: BoxDecoration(color: isSelected ? context.appColorScheme.cardBackground.withAlpha(38) : context.appColorScheme.cardBackground, shape: BoxShape.circle),
              child: Icon(icon, color: isSelected ? context.appColorScheme.cardBackground : context.appColorScheme.textPrimary, size: AppSizes.icon20),
            ),
            Gap.w16,
            Text(title, style: context.labelBold.copyWith(color: isSelected ? context.appColorScheme.cardBackground : context.appColorScheme.textPrimary)),
            const Spacer(),
            if (isSelected) Icon(AppIcons.checkCircle2, color: context.appColorScheme.cardBackground, size: AppSizes.icon20),
          ],
        ),
      ),
    ),
  );
}
