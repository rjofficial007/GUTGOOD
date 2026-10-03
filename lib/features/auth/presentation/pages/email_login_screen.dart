import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_assets.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/constants/storage_keys.dart';
import 'package:gutgood/core/di/di_instance.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/extensions.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/core/widgets/gut_button.dart';
import 'package:gutgood/core/widgets/gut_text_field.dart';
import 'package:gutgood/features/auth/data/utils/auth_error_handler.dart';
import 'package:gutgood/features/auth/domain/repositories/auth_repository.dart';
import 'package:gutgood/features/auth/presentation/providers/auth_provider.dart';
import 'package:gutgood/features/auth/presentation/widgets/auth_bottom_sheets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  bool _linkSent = false;
  GutAuthNotifier? _authNotifier;

  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    final appStateService = sl<AppStateService>();
    appStateService.emailLinkError.addListener(_onLinkError);
    appStateService.pendingEmailLink.addListener(_onPendingLinkReceived);
    appStateService.pendingMergeConflict.addListener(_onMergeConflict);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authNotifier = context.read<GutAuthNotifier>();
      _authNotifier?.addListener(_onAuthChanged);
    });
  }

  @override
  void dispose() {
    final appStateService = sl<AppStateService>();
    appStateService.emailLinkError.removeListener(_onLinkError);
    appStateService.pendingEmailLink.removeListener(_onPendingLinkReceived);
    appStateService.pendingMergeConflict.removeListener(_onMergeConflict);
    _authNotifier?.removeListener(_onAuthChanged);
    _emailController.dispose();
    _nameController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _onMergeConflict() async {
    final conflict = sl<AppStateService>().pendingMergeConflict.value;
    if (conflict == null || !mounted) return;

    final appState = sl<AppStateService>();
    if (!appState.claimMergePrompt()) return;
    appState.setPendingMergeConflict(null);

    try {
      final shouldMerge = await showMergeConfirmationSheet(
        context,
        conflict['email'] ?? '',
      );
      if (!mounted) return;
      final authNotifier = context.read<GutAuthNotifier>();
      if (shouldMerge == true) {
        try {
          await authNotifier.confirmMerge(
            conflict['anonymousUid']!,
            conflict['permanentUid']!,
          );
          if (mounted && context.canPop()) {
            // 🟢 Fix: Pop with result to allow the sheet to dismiss itself cleanly.
            context.pop(authNotifier.user);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.authSyncDelayedMessage)),
            );
          }
        }
      } else if (shouldMerge == false) {
        await authNotifier.abandonMerge();
      }
    } finally {
      appState.releaseMergePrompt();
    }
  }

  void _onPendingLinkReceived() {
    if (sl<AppStateService>().pendingEmailLink.value != null && mounted) {
      // If we have a pending link, switch to input state to ask for email
      setState(() {
        _linkSent = false;
      });
    }
  }

  void _onAuthChanged() {
    if (_authNotifier?.isAuthenticated == true &&
        !(_authNotifier?.isAnonymous ?? true) &&
        mounted) {
      context.pop(_authNotifier?.user);
    }
  }

  void _onLinkError() {
    final appStateService = sl<AppStateService>();
    final err = appStateService.emailLinkError.value;
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      setState(() => _linkSent = false);
      appStateService.setEmailLinkError(null);
    }
  }

  void _startCooldown() {
    setState(() => _cooldownSeconds = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds > 0) {
        setState(() => _cooldownSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _sendLink() async {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    final appStateService = sl<AppStateService>();

    if (name.isEmpty && appStateService.pendingEmailLink.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.enterNameContinuePrompt)),
      );
      return;
    }

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.enterEmailToContinue)),
      );
      return;
    }

    if (!email.isValidEmail) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.invalidEmail)));
      return;
    }

    final authNotifier = context.read<GutAuthNotifier>();

    try {
      // If there's a pending link, we just complete the sign-in instead of sending a new link
      final appStateService = sl<AppStateService>();
      final pendingLink = appStateService.pendingEmailLink.value;
      if (pendingLink != null) {
        try {
          await authNotifier.signInWithEmailLink(email, pendingLink);
          appStateService.setPendingEmailLink(null); // Clear it
        } on AuthMergeConflictException catch (e) {
          appStateService.setPendingEmailLink(null);
          if (mounted) {
            final shouldMerge = await showMergeConfirmationSheet(
              context,
              e.email,
            );
            if (shouldMerge == true && mounted) {
              await authNotifier.confirmMerge(e.anonymousUid, e.permanentUid);
            } else if (shouldMerge == false && mounted) {
              await authNotifier.abandonMerge();
            }
          }
        }
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StorageKeys.loginEmail, email);
      if (name.isNotEmpty) {
        await prefs.setString('login_display_name', name);
      }

      await authNotifier.sendSignInLinkToEmail(email);
      setState(() {
        _linkSent = true;
      });
      _startCooldown();
    } on AuthMergeConflictException catch (e) {
      if (mounted) {
        final shouldMerge = await showMergeConfirmationSheet(context, e.email);
        if (shouldMerge == true && mounted) {
          await authNotifier.confirmMerge(e.anonymousUid, e.permanentUid);
          // If successful, _onAuthChanged will handle navigation
        } else if (shouldMerge == false && mounted) {
          await authNotifier.abandonMerge();
        }
      }
    } catch (e) {
      if (mounted) {
        final message = AuthErrorHandler.mapException(e);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    appBar: GutAppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      leading: IconButton(
        icon: Icon(
          AppIcons.chevronLeft,
          color: context.appColorScheme.textPrimary,
        ),
        onPressed: () {
          sl<AppStateService>().setPendingEmailLink(null);
          context.pop();
        },
      ),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: AppSizes.p24,
          vertical: AppSizes.p20,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _linkSent ? _buildSentState() : _buildInputState(),
        ),
      ),
    ),
  );

  Widget _buildInputState() {
    final pendingLink = sl<AppStateService>().pendingEmailLink.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      key: const ValueKey('input'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pendingLink != null
              ? AppStrings.completeSignIn
              : AppStrings.welcomeBack,
          style: context.headingMd.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: AppSizes.s24,
          ),
        ),
        Gap.h8,
        Text(
          pendingLink != null
              ? AppStrings.completeSignInSubtitle
              : AppStrings.signInSubtitle,
          style: context.body.copyWith(
            color: context.appColorScheme.textSecondary,
          ),
        ),
        Gap.h32,
        if (pendingLink == null) ...[
          _buildLabel(AppStrings.labelYourName),
          GutTextField(
            controller: _nameController,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            style: context.bodyBold,
            hintText: AppStrings.enterYourNameHint,
            prefixIcon: AppIcons.user,
          ),
          Gap.h20,
        ],
        _buildLabel(AppStrings.emailAddress),
        GutTextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: context.bodyBold,
          hintText: AppStrings.enterEmail,
          prefixIcon: AppIcons.mail,
        ),
        Gap.h40,
        _LoginButton(onTap: _sendLink, isConfirm: pendingLink != null),
        if (pendingLink == null) ...[
          Gap.h32,
          const _SocialLoginDivider(),
          Gap.h20,
          _SocialLoginButtons(isDark: isDark),
        ],
      ],
    );
  }

  Widget _buildSentState() => Column(
    key: const ValueKey('sent'),
    children: [
      Gap.h40,
      Container(
        padding: EdgeInsets.all(AppSizes.p24),
        decoration: BoxDecoration(
          color: context.appColorScheme.elevatedSurface,
          shape: BoxShape.circle,
        ),
        child: Icon(
          AppIcons.mailCheck,
          size: 48,
          color: context.appColorScheme.textPrimary,
        ),
      ),
      Gap.h32,
      Text(
        AppStrings.checkYourEmail,
        textAlign: TextAlign.center,
        style: context.headingMd.copyWith(fontWeight: FontWeight.w900),
      ),
      Gap.h12,
      Text(
        AppStrings.linkSentSubtitle,
        textAlign: TextAlign.center,
        style: context.body.copyWith(
          color: context.appColorScheme.textSecondary,
        ),
      ),
      Gap.h40,
      _ResendButton(
        cooldownSeconds: _cooldownSeconds,
        onResend: () => setState(() => _linkSent = false),
      ),
      Gap.h16,
      GutButton(
        label: AppStrings.backToSignIn,
        isOutlined: true,
        onTap: () {
          sl<AppStateService>().setPendingEmailLink(null);
          context.pop();
        },
      ),
    ],
  );

  Widget _buildLabel(String text) => Padding(
    padding: EdgeInsets.only(bottom: AppSizes.p8),
    child: Text(text, style: context.bodyBold.copyWith(fontSize: AppSizes.s13)),
  );
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({required this.onTap, required this.isConfirm});
  final VoidCallback onTap;
  final bool isConfirm;

  @override
  Widget build(BuildContext context) => Selector<GutAuthNotifier, bool>(
    selector: (_, n) => n.isLoading,
    builder: (context, isLoading, _) {
      if (isLoading) {
        return Center(
          child: CircularProgressIndicator(
            color: context.appColorScheme.textPrimary,
          ),
        );
      }
      return GutButton(
        label: isConfirm ? AppStrings.confirmEmail : AppStrings.sendLink,
        onTap: onTap,
      );
    },
  );
}

class _ResendButton extends StatelessWidget {
  const _ResendButton({required this.cooldownSeconds, required this.onResend});
  final int cooldownSeconds;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) => GutButton(
    label: cooldownSeconds > 0
        ? '${AppStrings.resendIn}$cooldownSeconds${AppStrings.secondUnit}'
        : AppStrings.resendLink,
    onTap: cooldownSeconds > 0 ? null : onResend,
  );
}

class _SocialLoginDivider extends StatelessWidget {
  const _SocialLoginDivider();

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      AppStrings.orContinueWith,
      style: context.caption.copyWith(color: context.appColorScheme.textMuted),
    ),
  );
}

class _SocialLoginButtons extends StatelessWidget {
  const _SocialLoginButtons({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.read<GutAuthNotifier>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialIcon(
          assetPath: AppAssets.appleLogo,
          imageColor: isDark ? AppPalette.white : null,
          onTap: authNotifier.signInWithApple,
        ),
        Gap.w16,
        _SocialIcon(
          assetPath: AppAssets.googleLogo,
          onTap: authNotifier.signInWithGoogle,
        ),
      ],
    );
  }
}

class _SocialIcon extends StatelessWidget {
  const _SocialIcon({
    required this.assetPath,
    required this.onTap,
    this.imageColor,
  });
  final String assetPath;
  final VoidCallback onTap;
  final Color? imageColor;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppSizes.r12),
    child: Container(
      padding: EdgeInsets.all(AppSizes.p12),
      decoration: BoxDecoration(
        border: Border.all(color: context.appColorScheme.border),
        borderRadius: BorderRadius.circular(AppSizes.r12),
      ),
      child: Image.asset(
        assetPath,
        width: AppSizes.icon24,
        height: AppSizes.icon24,
        color: imageColor,
      ),
    ),
  );
}
