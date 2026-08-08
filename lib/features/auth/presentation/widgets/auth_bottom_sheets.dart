import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_assets.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/bottom_sheet_helper.dart';
import 'package:gutgood/core/utils/haptic_helper.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/auth/data/utils/auth_error_handler.dart';
import 'package:gutgood/features/auth/domain/entities/auth_user.dart';
import 'package:gutgood/features/auth/domain/repositories/auth_repository.dart';
import 'package:gutgood/features/auth/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart';

/// Shows a unified authentication bottom sheet.
/// [customMessage] can be used to provide context (e.g., "Sign in to save your results").
/// [onSuccess] is called after a successful authentication.
Future<AuthUser?> showAuthBottomSheet(
  BuildContext context, {
  String? customMessage,
  VoidCallback? onSuccess,
}) => showModalBottomSheet<AuthUser?>(
  context: context,
  isScrollControlled: true,
  // 🟢 Fix: Ensure the sheet is on the same navigator as the login screen.
  useRootNavigator: true,
  backgroundColor: Colors.transparent,
  builder: (context) =>
      _LoginSheet(customMessage: customMessage, onSuccess: onSuccess),
);

/// Shows a prompt to encourage guest users to create an account.
Future<bool?> showRegistrationPrompt(BuildContext context) =>
    BottomSheetHelper.showGutBottomSheet<bool>(
      context: context,
      title: AppStrings.saveProfileTitle,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: context.appColorScheme.cardBackground,
            border: Border.all(color: context.appColorScheme.border),
            shape: BoxShape.circle,
          ),
          child: Icon(
            AppIcons.shieldCheck,
            color: context.appColorScheme.textPrimary,
            size: AppSizes.icon32,
          ),
        ),
        Gap.h24,
        Text(
          AppStrings.saveProfileSubtitle,
          textAlign: TextAlign.center,
          style: context.body.copyWith(
            color: context.appColorScheme.textSecondary,
          ),
        ),
        Gap.h32,
        GutButton(
          label: AppStrings.createAccountPrimary,
          onTap: () => context.pop(true),
        ),
        Gap.h16,
        GutButton(
          label: AppStrings.skipForNow,
          isOutlined: true,
          onTap: () => context.pop(false),
        ),
        Gap.h12,
      ],
    );

/// Shows a confirmation sheet when an existing account is found.
Future<bool?> showMergeConfirmationSheet(
  BuildContext context,
  String email,
) => BottomSheetHelper.showGutBottomSheet<bool>(
  context: context,
  title: AppStrings.accountFound,
  children: [
    Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: context.appColorScheme.cardBackground,
        border: Border.all(color: context.appColorScheme.border),
        shape: BoxShape.circle,
      ),
      child: Icon(
        AppIcons.info,
        color: context.appColorScheme.textPrimary,
        size: AppSizes.icon32,
      ),
    ),
    Gap.h24,
    Text(
      '${AppStrings.accountFoundMergeMessage}$email${AppStrings.mergeConfirmationQuestion}',
      textAlign: TextAlign.center,
      style: context.body.copyWith(color: context.appColorScheme.textSecondary),
    ),
    Gap.h32,
    GutButton(label: AppStrings.mergeProgress, onTap: () => context.pop(true)),
    Gap.h16,
    GutButton(
      label: AppStrings.justLogIn,
      isOutlined: true,
      onTap: () => context.pop(false),
    ),
    Gap.h12,
  ],
);

class _LoginSheet extends StatefulWidget {
  const _LoginSheet({this.customMessage, this.onSuccess});
  final String? customMessage;
  final VoidCallback? onSuccess;

  @override
  State<_LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends State<_LoginSheet> {
  late final GutAuthNotifier _authNotifier;

  @override
  void initState() {
    super.initState();
    _authNotifier = context.read<GutAuthNotifier>()
      ..addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _authNotifier.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (_authNotifier.isAuthenticated &&
        !_authNotifier.isAnonymous &&
        mounted) {
      AppLogger.info(
        'AuthSheet: Authentication detected in background. Dismissing sheet.',
      );
      // 🟢 Fix: If auth becomes permanent while the sheet is open (e.g. Magic Link resolve),
      // automatically close the sheet.
      _onAuthSuccess(context);
    }
  }

  Future<void> _handleSocialSignIn(
    BuildContext context,
    GutAuthNotifier authNotifier,
    Future<AuthUser?> Function() signInMethod,
  ) async {
    try {
      final user = await signInMethod();
      if (user != null && context.mounted) {
        await _onAuthSuccess(context);
      }
    } on AuthMergeConflictException catch (e) {
      if (context.mounted) {
        final appState = sl<AppStateService>();
        if (!appState.claimMergePrompt()) return;

        try {
          if (e.attemptedProvider == 'apple.com') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(AppStrings.confirmingIdentity),
                duration: Duration(seconds: 2),
              ),
            );
          }
          final shouldMerge = await showMergeConfirmationSheet(
            context,
            e.email,
          );
          if (shouldMerge == true && context.mounted) {
            try {
              await authNotifier.confirmMerge(e.anonymousUid, e.permanentUid);
              // 🟢 Fix: Rely on GoRouter's redirect rather than manual context.go()
            } catch (err) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(AppStrings.authSyncDelayedMessage),
                  ),
                );
                await _onAuthSuccess(context);
              }
            }
          } else if (shouldMerge == false && context.mounted) {
            // User chose "Just Log In" - finalize without merging
            await authNotifier.abandonMerge();
            if (context.mounted) await _onAuthSuccess(context);
          }
        } finally {
          appState.releaseMergePrompt();
        }
      }
    } catch (e) {
      if (context.mounted) {
        final message = AuthErrorHandler.mapException(e);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _onAuthSuccess(BuildContext context) async {
    // Trigger verification overlay for consistent premium experience
    final appStateService = sl<AppStateService>()..setVerifyingAuth(true);
    AppLogger.info(
      'Auth: Authentication success. Showing verification overlay.',
    );

    HapticHelper.success();

    // Close the bottom sheet immediately so the user sees the verification overlay on the main screen
    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    widget.onSuccess?.call();

    // Give it a moment to show the success state/overlay before letting the global stack reset take over
    await Future.delayed(const Duration(milliseconds: 1000));
    appStateService.setVerifyingAuth(false);
  }

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.watch<GutAuthNotifier>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GutSheetWrapper(
      children: [
        const GutSheetHeader(title: AppStrings.signIn),
        Text(
          widget.customMessage ?? AppStrings.signInSubtitleGeneral,
          textAlign: TextAlign.center,
          style: context.body.copyWith(
            color: context.appColorScheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Gap.h32,

        AuthOptionTile(
          imagePath: AppAssets.appleLogo,
          label: AppStrings.signInWithApple,
          imageColor: isDark ? AppPalette.white : null,
          onTap: authNotifier.isLoading
              ? () {}
              : () => _handleSocialSignIn(
                  context,
                  authNotifier,
                  authNotifier.signInWithApple,
                ),
        ),
        Gap.h12,
        AuthOptionTile(
          imagePath: AppAssets.googleLogo,
          label: AppStrings.signInWithGoogle,
          onTap: authNotifier.isLoading
              ? () {}
              : () => _handleSocialSignIn(
                  context,
                  authNotifier,
                  authNotifier.signInWithGoogle,
                ),
        ),
        Gap.h12,
        AuthOptionTile(
          icon: AppIcons.mail,
          label: AppStrings.continueWithEmail,
          onTap: () async {
            final user = await context.push<AuthUser?>('/login');
            if (context.mounted && user != null) {
              await _onAuthSuccess(context);
            }
          },
        ),
        if (authNotifier.isLoading) ...[
          Gap.h24,
          CircularProgressIndicator(color: context.appColorScheme.textPrimary),
        ],
        Gap.h32,
        Text(
          AppStrings.termsAndPrivacyNotice,
          textAlign: TextAlign.center,
          style: context.caption.copyWith(
            color: context.appColorScheme.textMuted,
            height: 1.4,
            fontSize: AppSizes.s11,
          ),
        ),
        Gap.h24,
      ],
    );
  }
}
