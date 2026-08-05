import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_assets.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/user_profile.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/services/app_services.dart';
import 'package:gutgood/core/services/app_version_services.dart';
import 'package:gutgood/core/services/config_service.dart';
import 'package:gutgood/core/services/export_service.dart';
import 'package:gutgood/core/services/notification_service.dart';
import 'package:gutgood/core/services/usage_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/theme/theme_provider.dart';
import 'package:gutgood/core/utils/bottom_sheet_helper.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/widgets/profile_header.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/auth/presentation/providers/auth_provider.dart';
import 'package:gutgood/features/auth/presentation/providers/purchase_provider.dart';
import 'package:gutgood/features/auth/presentation/widgets/auth_bottom_sheets.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:gutgood/features/profile/presentation/providers/usage_notifier.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUploadImage(ProfileNotifier profileNotifier) async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image != null) {
        await profileNotifier.uploadProfilePicture(File(image.path));
      }
    } catch (e) {
      AppLogger.error('Error picking image: $e');
    }
  }

  void _showEditProfileBottomSheet(ProfileNotifier profileNotifier) {
    final controller = TextEditingController(text: profileNotifier.profile?.displayName);

    BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: AppStrings.editProfile,
      padding: EdgeInsets.only(
          left: AppSizes.p24,
          right: AppSizes.p24,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.p32),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.whatShouldWeCallYou,
                style: context.bodyBold.copyWith(color: context.appColorScheme.textPrimary)),
            Gap.h12,
            GutTextField(
                controller: controller,
                autofocus: true,
                hintText: AppStrings.enterYourNameHint,
                borderRadius: AppSizes.r16),
            Gap.h32,
            GutButton(
              label: AppStrings.saveChanges,
              onTap: () {
                unawaited(profileNotifier.updateDisplayName(controller.text.trim()));
                context.pop();
              },
            ),
          ],
        ),
      ],
    );
  }

  void _showAppearancePicker(BuildContext context, ThemeNotifier themeNotifier) {
    BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: AppStrings.appearance,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: AppSizes.p24),
          child: Text(AppStrings.selectVisualStyle,
              style: context.bodySm.copyWith(color: context.appColorScheme.textSecondary)),
        ),
        _AppearanceOption(
          icon: AppIcons.sun,
          title: AppStrings.system,
          isSelected: themeNotifier.themeMode == ThemeMode.system,
          onTap: () {
            context.pop();
            unawaited(Future.delayed(
                Duration.zero, () => themeNotifier.setThemeMode(ThemeMode.system)));
          },
        ),
        _AppearanceOption(
          icon: AppIcons.sun,
          title: AppStrings.light,
          isSelected: themeNotifier.themeMode == ThemeMode.light,
          onTap: () {
            context.pop();
            unawaited(Future.delayed(
                Duration.zero, () => themeNotifier.setThemeMode(ThemeMode.light)));
          },
        ),
        _AppearanceOption(
          icon: AppIcons.moon,
          title: AppStrings.dark,
          isSelected: themeNotifier.themeMode == ThemeMode.dark,
          onTap: () {
            context.pop();
            unawaited(Future.delayed(
                Duration.zero, () => themeNotifier.setThemeMode(ThemeMode.dark)));
          },
        ),
        Gap.h12,
      ],
    );
  }

  Future<void> _showLogoutBottomSheet(
      GutAuthNotifier authNotifier, ProfileNotifier profileNotifier) async {
    await BottomSheetHelper.showLogoutSheet(
      context: context,
      isAnonymous: authNotifier.isAnonymous,
      onConfirm: () async {
        await authNotifier.signOut();
        unawaited(profileNotifier.refresh());
      },
    );
  }

  Future<void> _showDeleteAccountConfirmation(GutAuthNotifier authNotifier) async {
    await BottomSheetHelper.showDeleteAccountSheet(
      context: context,
      onConfirm: () async {
        await authNotifier.deleteAccount();
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text(AppStrings.accountDeletionRequested)));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: context.appColorScheme.cardBackground,
      body: _ProfileContent(
        onImageTap: _pickAndUploadImage,
        onEditTap: _showEditProfileBottomSheet,
        onLogoutTap: _showLogoutBottomSheet,
        onDeleteTap: _showDeleteAccountConfirmation,
        onAppearanceTap: (t) => _showAppearancePicker(context, t),
      ),
    );
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.onImageTap,
    required this.onEditTap,
    required this.onLogoutTap,
    required this.onDeleteTap,
    required this.onAppearanceTap,
  });

  final Function(ProfileNotifier) onImageTap;
  final Function(ProfileNotifier) onEditTap;
  final Function(GutAuthNotifier, ProfileNotifier) onLogoutTap;
  final Function(GutAuthNotifier) onDeleteTap;
  final Function(ThemeNotifier) onAppearanceTap;

  @override
  Widget build(BuildContext context) {
    final profileNotifier = context.watch<ProfileNotifier>();
    if (profileNotifier.isLoading) {
      return Center(child: CircularProgressIndicator(color: context.appColorScheme.textPrimary));
    }

    return CustomScrollView(
      slivers: [
        const GutSliverAppBar(title: AppStrings.profile, showBrandingIcon: true),
        SliverPadding(
          padding: EdgeInsets.all(AppSizes.p16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _ProfileHeaderSection(
                  onImageTap: onImageTap, onEditTap: onEditTap, onLogoutTap: onLogoutTap),
              _StreakAndUsageSection(),
              _PersonalizationSection(),
              _AppSettingsSection(onAppearanceTap: onAppearanceTap),
              _BodyRhythmSection(),
              _AccountSection(onLogoutTap: onLogoutTap, onDeleteTap: onDeleteTap),
              _SupportSection(),
              if (kDebugMode) _DebugToolsSection(),
              _AppVersionInfo(),
              Gap.h40,
            ]),
          ),
        ),
      ],
    );
  }
}

class _ProfileHeaderSection extends StatelessWidget {
  const _ProfileHeaderSection({
    required this.onImageTap,
    required this.onEditTap,
    required this.onLogoutTap,
  });

  final Function(ProfileNotifier) onImageTap;
  final Function(ProfileNotifier) onEditTap;
  final Function(GutAuthNotifier, ProfileNotifier) onLogoutTap;

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.read<GutAuthNotifier>();
    final profileNotifier = context.read<ProfileNotifier>();

    return Selector<ProfileNotifier, UserProfile?>(
      selector: (_, n) => n.profile,
      builder: (context, p, _) => ProfileHeader(
          name: p?.displayName ??
              (authNotifier.isAnonymous
                  ? AppStrings.guestUser
                  : authNotifier.user?.displayName ?? ''),
          email: p?.email ??
              (authNotifier.isAnonymous
                  ? AppStrings.signInToSyncData
                  : authNotifier.user?.email ?? ''),
          isPremium: p?.isPremium ?? false,
          photoUrl: p?.photoUrl,
          streak: p?.streak ?? 0,
          goalsCount: p?.goals.length ?? 0,
          sensitivitiesCount: p?.sensitivities.length ?? 0,
          lifestyleCount: p?.lifestyle.length ?? 0,
          onImageTap: () {
            SemanticsService.sendAnnouncement(
                View.of(context), AppStrings.uploadingProfilePicture, TextDirection.ltr);
            onImageTap(profileNotifier);
          },
          onEditTap: () => onEditTap(profileNotifier),
          onLogoutTap: () => onLogoutTap(authNotifier, profileNotifier),
        ),
    );
  }
}

class _StreakAndUsageSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
      children: [
        Selector<ProfileNotifier, (int, String?)>(
          selector: (_, n) => (n.profile?.streak ?? 0, n.profile?.lastActivityDate),
          builder: (context, data, _) => Padding(
            padding: EdgeInsets.only(top: AppSizes.p16),
            child: StreakCard(streak: data.$1, lastActivityDate: data.$2),
          ),
        ),
        Selector<ProfileNotifier, bool>(
          selector: (_, n) => n.profile?.isPremium ?? false,
          builder: (context, isPremium, _) {
            if (isPremium) return const SizedBox.shrink();
            return _AIUsageCard(usageNotifier: context.read<UsageNotifier>());
          },
        ),
      ],
    );
}

class _PersonalizationSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Selector<ProfileNotifier, (List<String>, List<String>, List<String>)>(
      selector: (_, n) =>
          (n.profile?.goals ?? [], n.profile?.sensitivities ?? [], n.profile?.lifestyle ?? []),
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

class _AppSettingsSection extends StatelessWidget {
  const _AppSettingsSection({required this.onAppearanceTap});
  final Function(ThemeNotifier) onAppearanceTap;

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.read<ThemeNotifier>();
    return GutSection(
      title: AppStrings.app,
      showCard: true,
      children: [
        AppTile(
            icon: AppIcons.bookmark,
            title: AppStrings.savedFoods,
            onTap: () => unawaited(context.push(AppRoutes.savedFoods))),
        AppTile(
            icon: AppIcons.bell,
            title: AppStrings.notificationPreferences,
            onTap: () => unawaited(context.push(AppRoutes.notifications))),
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
              style: context.caption
                  .copyWith(color: context.appColorScheme.textMuted, fontWeight: FontWeight.w500),
            ),
            onTap: () => onAppearanceTap(themeNotifier),
            showBottomBorder: false,
          ),
        ),
      ],
    );
  }
}

class _BodyRhythmSection extends StatelessWidget {
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

class _AccountSection extends StatelessWidget {
  const _AccountSection({required this.onLogoutTap, required this.onDeleteTap});
  final Function(GutAuthNotifier, ProfileNotifier) onLogoutTap;
  final Function(GutAuthNotifier) onDeleteTap;

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.read<GutAuthNotifier>();
    final profileNotifier = context.read<ProfileNotifier>();
    final purchaseProvider = context.read<PurchaseProvider>();

    return Selector<ProfileNotifier, (bool, bool)>(
      selector: (_, n) => (n.profile?.isAnonymous ?? true, n.profile?.isPremium ?? false),
      builder: (context, data, _) {
        final isAnon = data.$1;
        final isPremium = data.$2;

        return GutSection(
          title: AppStrings.account,
          showCard: true,
          children: [
            if (isAnon)
              AppTile(
                icon: AppIcons.userPlus,
                title: AppStrings.signInToSync,
                onTap: () => unawaited(showAuthBottomSheet(context,
                    customMessage: AppStrings.chatAuthMessage, onSuccess: profileNotifier.refresh)),
              ),
            AppTile(
              icon: AppIcons.creditCard,
              title: AppStrings.premiumPlanName,
              subtitle: isPremium ? AppStrings.activeStatus : AppStrings.freeTrial,
              onTap: () {
                if (!isPremium) {
                  unawaited(showPaywallBottomSheet(context, onProceedWithLimited: () {}));
                }
              },
            ),
            AppTile(
                icon: AppIcons.refreshCw,
                title: AppStrings.restorePurchases,
                onTap: () => _handleRestorePurchases(context, purchaseProvider)),
            AppTile(
                icon: AppIcons.logOut,
                title: AppStrings.logout,
                iconColor: context.appColorScheme.error,
                onTap: () => onLogoutTap(authNotifier, profileNotifier)),
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

  Future<void> _handleRestorePurchases(
      BuildContext context, PurchaseProvider purchaseProvider) async {
    final success = await purchaseProvider.restorePurchases();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? AppStrings.restoreSuccess : AppStrings.restoreFailed),
          backgroundColor: success ? context.appColorScheme.success : context.appColorScheme.error));
    }
  }
}

class _SupportSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GutSection(
      title: AppStrings.helpAndSupport,
      showCard: true,
      children: [
        AppTile(
            icon: AppIcons.share,
            title: AppStrings.shareWithFriends,
            onTap: () => sl<AppService>().shareWithFriends(context)),
        AppTile(
          icon: AppIcons.messageSquare,
          title: AppStrings.contactUs,
          onTap: () => unawaited(sl<AppService>()
              .sendingMails(mailContent: AppStrings.labelFeedbackSubject, isFromReview: false)),
        ),
        AppTile(
            icon: AppIcons.star,
            title: AppStrings.rateApp,
            onTap: () => unawaited(sl<AppService>().requestReview())),
        AppTile(
            icon: AppIcons.helpCircle,
            title: AppStrings.aboutUs,
            onTap: () => unawaited(
                sl<AppService>().urlLauncher(context, sl<ConfigService>().aboutUsUrl))),
        AppTile(
            icon: AppIcons.clipboardList,
            title: AppStrings.termsAndConditions,
            onTap: () => unawaited(
                sl<AppService>().urlLauncher(context, sl<ConfigService>().termsConditionUrl))),
        AppTile(
            icon: AppIcons.shieldCheck,
            title: AppStrings.privacy,
            onTap: () => unawaited(
                sl<AppService>().urlLauncher(context, sl<ConfigService>().privacyPolicyUrl))),
        AppTile(
            icon: AppIcons.shield,
            title: AppStrings.medicalDisclaimer,
            onTap: () => unawaited(BottomSheetHelper.showMedicalDisclaimer(context))),
        AppTile(
          icon: AppIcons.download,
          title: 'Export Health Data (CSV)',
          onTap: () async {
            unawaited(sl<AnalyticsService>().logEvent(name: 'export_data_requested'));
            unawaited(sl<ExportService>().exportHealthData());
          },
          showBottomBorder: false,
        ),
      ],
    );
}

class _DebugToolsSection extends StatelessWidget {
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
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text(AppStrings.limitsReset)));
              }
            },
          ),
          AppTile(
            icon: AppIcons.bell,
            title: 'Test Push Notification',
            onTap: () async {
              await sl<NotificationService>().testNotification();
            },
          ),
          AppTile(
            icon: AppIcons.copy,
            title: 'Copy FCM Token',
            subtitle: 'Tap to copy your push token for testing',
            onTap: () async {
              final token = await FirebaseMessaging.instance.getToken();
              if (token != null) {
                await Clipboard.setData(ClipboardData(text: token));
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('FCM Token copied to clipboard!')));
                }
              }
            },
            showBottomBorder: false,
          ),
        ],
      ),
    );
  }
}

class _AppVersionInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GutSection(
      showCard: true,
      topPadding: AppSizes.p40,
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
                    Text(
                      'v${sl<AppVersionService>().appVersion} (${sl<AppVersionService>().buildVersion})',
                      style: context.caption
                          .copyWith(color: context.appColorScheme.textMuted.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
}

class _AIUsageCard extends StatelessWidget {
  const _AIUsageCard({required this.usageNotifier});
  final UsageNotifier usageNotifier;

  @override
  Widget build(BuildContext context) {
    final usage = usageNotifier.usage;
    final maxChats = usageNotifier.maxChats;
    final maxScans = usageNotifier.maxScans;

    final chatCount = usage?.chatCount ?? 0;
    final scanCount = usage?.scanCount ?? 0;

    return Container(
      margin: EdgeInsets.only(top: AppSizes.p16),
      padding: EdgeInsets.all(AppSizes.p20),
      decoration: BoxDecoration(
        color: context.appColorScheme.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.r24),
        border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: AppPalette.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.sparkles, color: context.appColorScheme.textPrimary, size: AppSizes.icon20),
              Gap.w8,
              Text('DAILY AI ACTIVITY',
                  style: context.eyebrow.copyWith(color: context.appColorScheme.textPrimary, letterSpacing: 1.2)),
            ],
          ),
          Gap.h20,
          _UsageRow(
              label: 'AI Chats', current: chatCount, total: maxChats, color: context.appColorScheme.textPrimary),
          Gap.h16,
          _UsageRow(
              label: 'Product Scans',
              current: scanCount,
              total: maxScans,
              color: context.appColorScheme.textPrimary),
          Gap.h20,
          GestureDetector(
            onTap: () => unawaited(showPaywallBottomSheet(context, onProceedWithLimited: () {})),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Upgrade for Unlimited Access',
                  style:
                      context.bodyBold.copyWith(color: context.appColorScheme.textPrimary, fontSize: AppSizes.s13),
                ),
                Gap.w4,
                Icon(AppIcons.chevronRight, size: 14, color: context.appColorScheme.textPrimary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageRow extends StatelessWidget {
  const _UsageRow({required this.label, required this.current, required this.total, required this.color});
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
            Text(
              label,
              style: context.body.copyWith(fontSize: AppSizes.s14, fontWeight: FontWeight.w600),
            ),
            Text('$current / $total', style: context.caption.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        Gap.h8,
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: context.appColorScheme.border.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(progress >= 1.0 ? context.appColorScheme.error : color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _AppearanceOption extends StatelessWidget {
  const _AppearanceOption(
      {required this.icon, required this.title, required this.isSelected, required this.onTap});
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
              color:
                  isSelected ? context.appColorScheme.textPrimary : context.appColorScheme.elevatedSurface,
              borderRadius: BorderRadius.circular(AppSizes.r16),
              border: Border.all(
                  color: isSelected ? context.appColorScheme.textPrimary : context.appColorScheme.border,
                  width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppSizes.p8),
                  decoration: BoxDecoration(
                      color: isSelected
                          ? context.appColorScheme.cardBackground.withValues(alpha: 0.15)
                          : context.appColorScheme.cardBackground,
                      shape: BoxShape.circle),
                  child: Icon(icon,
                      color: isSelected ? context.appColorScheme.cardBackground : context.appColorScheme.textPrimary,
                      size: AppSizes.icon20),
                ),
                Gap.w16,
                Text(
                  title,
                  style: context.bodyBold.copyWith(
                      color: isSelected ? context.appColorScheme.cardBackground : context.appColorScheme.textPrimary,
                      fontSize: AppSizes.s15),
                ),
                const Spacer(),
                if (isSelected)
                  Icon(AppIcons.checkCircle2, color: context.appColorScheme.cardBackground, size: AppSizes.icon20),
              ],
            ),
          ),
        ),
      );
}
