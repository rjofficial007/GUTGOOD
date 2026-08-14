import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/theme/theme_provider.dart';
import 'package:gutgood/core/utils/bottom_sheet_helper.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/auth/data/utils/auth_error_handler.dart';
import 'package:gutgood/features/auth/presentation/providers/auth_provider.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:gutgood/features/profile/presentation/widgets/profile_sections.dart';
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
      padding: EdgeInsets.only(left: AppSizes.p24, right: AppSizes.p24, bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.p32),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.whatShouldWeCallYou, style: context.bodyBold.copyWith(color: context.appColorScheme.textPrimary)),
            Gap.h12,
            GutTextField(controller: controller, autofocus: true, hintText: AppStrings.enterYourNameHint, borderRadius: AppSizes.r16),
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
          child: Text(AppStrings.selectVisualStyle, style: context.bodySm.copyWith(color: context.appColorScheme.textSecondary)),
        ),
        AppearanceOption(
          icon: AppIcons.sun,
          title: AppStrings.system,
          isSelected: themeNotifier.themeMode == ThemeMode.system,
          onTap: () {
            context.pop();
            unawaited(Future.delayed(Duration.zero, () => themeNotifier.setThemeMode(ThemeMode.system)));
          },
        ),
        AppearanceOption(
          icon: AppIcons.sun,
          title: AppStrings.light,
          isSelected: themeNotifier.themeMode == ThemeMode.light,
          onTap: () {
            context.pop();
            unawaited(Future.delayed(Duration.zero, () => themeNotifier.setThemeMode(ThemeMode.light)));
          },
        ),
        AppearanceOption(
          icon: AppIcons.moon,
          title: AppStrings.dark,
          isSelected: themeNotifier.themeMode == ThemeMode.dark,
          onTap: () {
            context.pop();
            unawaited(Future.delayed(Duration.zero, () => themeNotifier.setThemeMode(ThemeMode.dark)));
          },
        ),
        Gap.h12,
      ],
    );
  }

  Future<void> _showLogoutBottomSheet(GutAuthNotifier authNotifier, ProfileNotifier profileNotifier) async {
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
    final profileNotifier = context.read<ProfileNotifier>();
    await BottomSheetHelper.showDeleteAccountSheet(
      context: context,
      onConfirm: () async {
        try {
          await authNotifier.deleteAccount();
        } catch (e) {
          if (mounted) {
            final message = AuthErrorHandler.mapException(e);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating, backgroundColor: context.appColorScheme.error));

            unawaited(profileNotifier.refresh());
          }
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
  const _ProfileContent({required this.onImageTap, required this.onEditTap, required this.onLogoutTap, required this.onDeleteTap, required this.onAppearanceTap});

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
        const GutSliverAppBar(title: AppStrings.profile),
        SliverPadding(
          padding: EdgeInsets.all(AppSizes.p16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              ProfileHeaderSection(onImageTap: onImageTap, onEditTap: onEditTap, onLogoutTap: onLogoutTap),
              const StreakAndUsageSection(),
              const PersonalizationSection(),
              AppSettingsSection(onAppearanceTap: onAppearanceTap),
              const BodyRhythmSection(),
              AccountSection(onEditTap: onEditTap, onLogoutTap: onLogoutTap, onDeleteTap: onDeleteTap),
              const SupportSection(),
              if (kDebugMode) const DebugToolsSection(),
              const AppVersionInfo(),
              Gap.h10,
            ]),
          ),
        ),
      ],
    );
  }
}
