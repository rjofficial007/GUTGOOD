import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/dialog_helper.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/auth/presentation/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_color_scheme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  Future<void> _confirmAndDeleteAccount(BuildContext context) async {
    final confirmed = await DialogHelper.showConfirmDialog(
      context: context,
      title: AppStrings.deleteAccountTitle,
      message: AppStrings.deleteAccountConfirm,
      confirmLabel: AppStrings.deletePermanently,
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      final authNotifier = context.read<GutAuthNotifier>();
      try {
        await authNotifier.deleteAccount();
        if (context.mounted) {
          context.go('/welcome');
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login' && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.signOutToDeleteAccount)));
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.errorAnalyzingProduct)));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.errorOccurred)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const GutAppBar(title: AppStrings.privacy),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.p24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AlertCard(text: AppStrings.privacyPolicyNote),
            Gap.h32,
            Text(
              AppStrings.dataAndPrivacy.toUpperCase(),
              style: AppTextStyles.caption.copyWith(color: context.appColorScheme.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1.0.w),
            ),
            Gap.h16,
            AppTile(
              icon: AppIcons.download,
              title: AppStrings.dataExport,
              subtitle: AppStrings.downloadData,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.comingSoon)));
              },
            ),
            AppTile(icon: AppIcons.trash2, title: AppStrings.deleteAccountLabel, subtitle: AppStrings.permanentlyDeleteAccount, onTap: () => _confirmAndDeleteAccount(context)),
            AppTile(
              icon: AppIcons.shieldCheck,
              title: AppStrings.dataUsage,
              subtitle: AppStrings.manageDataUsage,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.comingSoon)));
              },
            ),
            AppTile(
              icon: AppIcons.link,
              title: AppStrings.thirdPartyAccess,
              subtitle: AppStrings.manageConnectedServices,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.comingSoon)));
              },
              showBottomBorder: false,
            ),
          ],
        ),
      ),
    );
  }
}
