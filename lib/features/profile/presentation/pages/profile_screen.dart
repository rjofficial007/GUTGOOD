import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/services/app_services.dart';
import 'package:gutgood/core/services/app_version_services.dart';
import 'package:gutgood/core/services/config_service.dart';
import 'package:gutgood/core/services/usage_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/theme_provider.dart';
import 'package:gutgood/core/utils/bottom_sheet_helper.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/auth/presentation/providers/auth_provider.dart';
import 'package:gutgood/features/auth/presentation/widgets/auth_bottom_sheets.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/presentation/providers/purchase_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUploadImage(ProfileNotifier profileNotifier) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

      if (image != null) {
        await profileNotifier.uploadProfilePicture(File(image.path));
      }
    } catch (e) {
      Log.e('Error picking image: $e');
    }
  }

  void _showEditProfileBottomSheet(ProfileNotifier profileNotifier) {
    final controller = TextEditingController(text: profileNotifier.profile?.displayName);

    BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: AppStrings.editProfile,
      padding: EdgeInsets.only(left: AppSizes.p24, right: AppSizes.p24, bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.p32),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.whatShouldWeCallYou, style: context.bodyBold.copyWith(color: context.appColorScheme.textPrimary)),
            Gap.h12,
            GutTextField(controller: controller, autofocus: true, hintText: AppStrings.enterYourNameHint, borderRadius: 16.0),
            Gap.h32,
            GutButton(
              label: AppStrings.saveChanges,
              onTap: () {
                profileNotifier.updateDisplayName(controller.text.trim());
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
          child: Text(
            "Select your preferred visual style for the app.",
            style: context.bodySm.copyWith(color: context.appColorScheme.textSecondary),
          ),
        ),
        _AppearanceOption(
          icon: AppIcons.sun,
          title: AppStrings.system,
          isSelected: themeNotifier.themeMode == ThemeMode.system,
          onTap: () {
            context.pop();
            Future.delayed(Duration.zero, () => themeNotifier.setThemeMode(ThemeMode.system));
          },
        ),
        _AppearanceOption(
          icon: AppIcons.sun,
          title: AppStrings.light,
          isSelected: themeNotifier.themeMode == ThemeMode.light,
          onTap: () {
            context.pop();
            Future.delayed(Duration.zero, () => themeNotifier.setThemeMode(ThemeMode.light));
          },
        ),
        _AppearanceOption(
          icon: AppIcons.moon,
          title: AppStrings.dark,
          isSelected: themeNotifier.themeMode == ThemeMode.dark,
          onTap: () {
            context.pop();
            Future.delayed(Duration.zero, () => themeNotifier.setThemeMode(ThemeMode.dark));
          },
        ),
        Gap.h12,
      ],
    );
  }

  void _showMedicalDisclaimer(BuildContext context) {
    BottomSheetHelper.showMedicalDisclaimer(context);
  }

  Future<void> _handleRestorePurchases(PurchaseProvider purchaseProvider) async {
    final success = await purchaseProvider.restorePurchases();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(success ? AppStrings.restoreSuccess : AppStrings.restoreFailed), backgroundColor: success ? context.appColorScheme.success : context.appColorScheme.error));
    }
  }

  void _showLogoutBottomSheet(GutAuthNotifier authNotifier, ProfileNotifier profileNotifier) {
    BottomSheetHelper.showLogoutSheet(
      context: context,
      isAnonymous: authNotifier.isAnonymous,
      onConfirm: () async {
        await authNotifier.signOut();
        profileNotifier.refresh();
      },
    );
  }

  void _showDeleteAccountConfirmation(GutAuthNotifier authNotifier) {
    BottomSheetHelper.showDeleteAccountSheet(
      context: context,
      onConfirm: () async {
        await authNotifier.deleteAccount();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.accountDeletionRequested)));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileNotifier = context.watch<ProfileNotifier>();
    final authNotifier = context.watch<GutAuthNotifier>();
    final themeNotifier = context.watch<ThemeNotifier>();
    final purchaseProvider = context.watch<PurchaseProvider>();

    if (profileNotifier.isLoading) {
      return Scaffold(
        backgroundColor: context.appColorScheme.cardBackground,
        body: Center(child: CircularProgressIndicator(color: context.appColorScheme.textPrimary)),
      );
    }

    final p = profileNotifier.profile;

    return Scaffold(
      backgroundColor: context.appColorScheme.cardBackground,
      body: CustomScrollView(
        slivers: [
          const GutSliverAppBar(title: AppStrings.profile, showBrandingIcon: true),
          SliverPadding(
            padding: EdgeInsets.all(AppSizes.p16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. Profile Hero Section
                ProfileHeader(
                  name: p?.displayName ?? AppStrings.guestUser,
                  email: p?.email ?? AppStrings.signInToSyncData,
                  isPremium: p?.isPremium ?? false,
                  photoUrl: p?.photoUrl,
                  streak: p?.streak ?? 0,
                  goalsCount: p?.goals.length ?? 0,
                  sensitivitiesCount: p?.sensitivities.length ?? 0,
                  lifestyleCount: p?.lifestyle.length ?? 0,
                  onImageTap: () {
                    SemanticsService.sendAnnouncement(View.of(context), AppStrings.uploadingProfilePicture, TextDirection.ltr);
                    _pickAndUploadImage(profileNotifier);
                  },
                  onEditTap: () => _showEditProfileBottomSheet(profileNotifier),
                  onLogoutTap: () => _showLogoutBottomSheet(authNotifier, profileNotifier),
                ),

                // 3. Personalization Grid
                GutSection(
                  title: AppStrings.sectionPersonalization,
                  showCard: true,
                  children: [
                    AppTile(
                      icon: AppIcons.target,
                      title: AppStrings.goals,
                      subtitle: '${p?.goals.length ?? 0} ${AppStrings.activeCount}',
                      onTap: () => context.push('/goals', extra: p?.goals ?? []),
                    ),
                    AppTile(
                      icon: AppIcons.alertTriangle,
                      title: AppStrings.foodSensitivities,
                      subtitle: '${p?.sensitivities.length ?? 0} ${AppStrings.flaggedCount}',
                      onTap: () => context.push('/sensitivities', extra: p?.sensitivities ?? []),
                    ),
                    AppTile(
                      icon: AppIcons.smile,
                      title: AppStrings.lifestyleFactors,
                      subtitle: '${p?.lifestyle.length ?? 0} ${AppStrings.selectedCount}',
                      onTap: () => context.push('/lifestyle', extra: p?.lifestyle ?? []),
                      showBottomBorder: false,
                    ),
                  ],
                ),

                // 4. App Preferences
                GutSection(
                  title: AppStrings.app,
                  showCard: true,
                  children: [
                    AppTile(icon: AppIcons.bookmark, title: AppStrings.savedFoods, onTap: () => context.push('/saved-foods')),
                    AppTile(icon: AppIcons.bell, title: AppStrings.notificationPreferences, onTap: () => context.push('/notifications')),
                    AppTile(
                      icon: AppIcons.moon,
                      title: AppStrings.appearance,
                      trailing: Text(
                        themeNotifier.themeMode == ThemeMode.system
                            ? AppStrings.system
                            : themeNotifier.themeMode == ThemeMode.dark
                            ? AppStrings.dark
                            : AppStrings.light,
                        style: context.caption.copyWith(color: context.appColorScheme.textMuted, fontWeight: FontWeight.w500),
                      ),
                      onTap: () => _showAppearancePicker(context, themeNotifier),
                      showBottomBorder: false,
                    ),
                  ],
                ),

                // 5. Body Rhythm & Settings
                GutSection(
                  title: AppStrings.bodyRhythm,
                  showCard: true,
                  children: [
                    AppSwitchTile(
                      icon: AppIcons.flower,
                      title: AppStrings.cycleSync,
                      desc: AppStrings.cycleSyncSubtitle,
                      value: p?.cycleSyncEnabled ?? false,
                      onChanged: profileNotifier.updateCycleSync,
                      showBottomBorder: p?.cycleSyncEnabled ?? false,
                    ),
                    if (p?.cycleSyncEnabled ?? false)
                      AppTile(
                        icon: AppIcons.calendar,
                        title: AppStrings.cyclePhase,
                        subtitle: p?.cyclePhase ?? AppStrings.phaseLuteal,
                        onTap: () => context.push('/cycle-phase', extra: p?.cyclePhase),
                        showBottomBorder: false,
                      ),
                  ],
                ),

                // 6. Account & Subscription
                GutSection(
                  title: AppStrings.account,
                  showCard: true,
                  children: [
                    if (authNotifier.isAnonymous)
                      AppTile(
                        icon: AppIcons.userPlus,
                        title: AppStrings.signInToSync,
                        onTap: () => showAuthBottomSheet(context, customMessage: AppStrings.chatAuthMessage, onSuccess: profileNotifier.refresh),
                      ),
                    AppTile(
                      icon: AppIcons.creditCard,
                      title: AppStrings.premiumPlanName,
                      subtitle: (p?.isPremium ?? false) ? AppStrings.activeStatus : AppStrings.freeTrial,
                      onTap: () {
                        if (!(p?.isPremium ?? false)) {
                          showPaywallBottomSheet(context, onProceedWithLimited: () {});
                        }
                      },
                    ),
                    AppTile(icon: AppIcons.refreshCw, title: AppStrings.restorePurchases, onTap: () => _handleRestorePurchases(purchaseProvider)),
                    AppTile(icon: AppIcons.logOut, title: AppStrings.logout, iconColor: context.appColorScheme.error, onTap: () => _showLogoutBottomSheet(authNotifier, profileNotifier)),
                    AppTile(
                      icon: AppIcons.trash2,
                      title: AppStrings.deleteAccountLabel,
                      iconColor: context.appColorScheme.error,
                      trailing: const CautionBadge(),
                      onTap: () => _showDeleteAccountConfirmation(authNotifier),
                      showBottomBorder: false,
                    ),
                  ],
                ),

                // 7. Support & Legal
                GutSection(
                  title: AppStrings.helpAndSupport,
                  showCard: true,
                  children: [
                    AppTile(icon: AppIcons.share, title: AppStrings.shareWithFriends, onTap: () => sl<AppService>().shareWithFriends(context)),
                    AppTile(
                      icon: AppIcons.messageSquare,
                      title: AppStrings.contactUs,
                      onTap: () => sl<AppService>().sendingMails(mailContent: "I have some feedback regarding GutGood:", isFromReview: false),
                    ),
                    AppTile(icon: AppIcons.star, title: AppStrings.rateApp, onTap: sl<AppService>().requestReview),
                    AppTile(icon: AppIcons.helpCircle, title: AppStrings.aboutUs, onTap: () => sl<AppService>().urlLauncher(context, sl<ConfigService>().aboutUsUrl)),
                    AppTile(icon: AppIcons.clipboardList, title: AppStrings.termsAndConditions, onTap: () => sl<AppService>().urlLauncher(context, sl<ConfigService>().termsConditionUrl)),
                    AppTile(icon: AppIcons.shieldCheck, title: AppStrings.privacy, onTap: () => sl<AppService>().urlLauncher(context, sl<ConfigService>().privacyPolicyUrl)),
                    AppTile(icon: AppIcons.shield, title: AppStrings.medicalDisclaimer, onTap: () => _showMedicalDisclaimer(context), showBottomBorder: false),
                  ],
                ),

                if (kDebugMode) ...[
                  GutSection(
                    title: AppStrings.sectionDebugTools,
                    showCard: true,
                    children: [
                      AppSwitchTile(
                        icon: AppIcons.shieldCheck,
                        title: AppStrings.premiumStatusDebug,
                        desc: AppStrings.premiumStatusDebug,
                        value: p?.isPremium ?? false,
                        onChanged: (val) async {
                          purchaseProvider.setPremiumForDebug(val);
                          await sl<UsageService>().setPremiumForTesting(val);
                          profileNotifier.refresh();
                        },
                      ),
                      AppTile(
                        icon: AppIcons.refreshCcw,
                        title: AppStrings.resetDailyUsage,
                        onTap: () async {
                          await sl<UsageService>().resetLimitsForTesting();
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.limitsReset)));
                        },
                        showBottomBorder: false,
                      ),
                    ],
                  ),
                ],

                GutSection(
                  showCard: true,
                  topPadding: AppSizes.p40,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 18.0.h),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12.0.r),
                            child: Image.asset(AppAssets.appIcon, width: 44.0.w, height: 44.0.w),
                          ),
                          Gap.w16,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppStrings.appName, style: context.bodyBold),
                                Text(
                                  'v${sl<AppVersionService>().appVersion} (${sl<AppVersionService>().buildVersion})',
                                  style: context.caption.copyWith(color: context.appColorScheme.textMuted.withValues(alpha: 0.7)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Gap.h40,
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppearanceOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _AppearanceOption({required this.icon, required this.title, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Select $title appearance',
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
            border: Border.all(
              color: isSelected ? context.appColorScheme.textPrimary : context.appColorScheme.border,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSizes.p8),
                decoration: BoxDecoration(
                  color: isSelected ? context.appColorScheme.cardBackground.withValues(alpha: 0.15) : context.appColorScheme.cardBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? context.appColorScheme.cardBackground : context.appColorScheme.textPrimary,
                  size: 20,
                ),
              ),
              Gap.w16,
              Text(
                title,
                style: context.bodyBold.copyWith(
                  color: isSelected ? context.appColorScheme.cardBackground : context.appColorScheme.textPrimary,
                  fontSize: 15.sp,
                ),
              ),
              const Spacer(),
              if (isSelected)
                Icon(
                  AppIcons.checkCircle2,
                  color: context.appColorScheme.cardBackground,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
