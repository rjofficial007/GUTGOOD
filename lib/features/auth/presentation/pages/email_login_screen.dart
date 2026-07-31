import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_assets.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/extensions.dart';
import 'package:gutgood/features/auth/data/utils/auth_error_handler.dart';
import 'package:gutgood/features/auth/domain/repositories/auth_repository.dart';
import 'package:gutgood/features/auth/presentation/providers/auth_provider.dart';
import 'package:gutgood/features/auth/presentation/widgets/auth_bottom_sheets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/widgets/gut_app_bar.dart';
import '../../../../core/widgets/gut_button.dart';
import '../../../../core/widgets/gut_text_field.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _emailController = TextEditingController();
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
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _onMergeConflict() async {
    final conflict = sl<AppStateService>().pendingMergeConflict.value;
    if (conflict == null || !mounted) return;
    
    final appState = sl<AppStateService>();
    if (!appState.claimMergePrompt()) return;
    appState.setPendingMergeConflict(null);

    try {
      final shouldMerge = await showMergeConfirmationSheet(context, conflict['email'] ?? '');
      if (!mounted) return;
      final authNotifier = context.read<GutAuthNotifier>();
      if (shouldMerge == true) {
        try {
          await authNotifier.confirmMerge(conflict['anonymousUid']!, conflict['permanentUid']!);
          if (mounted && context.canPop()) {
            // 🟢 Fix: Pop with result to allow the sheet to dismiss itself cleanly.
            context.pop(authNotifier.user);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('We signed you in, but couldn\'t restore your previous data yet. It will retry automatically next time you open the app.')));
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
    if (_authNotifier?.isAuthenticated == true && !(_authNotifier?.isAnonymous ?? true) && mounted) {
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

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.enterEmailToContinue)));
      return;
    }

    if (!email.isValidEmail) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.invalidEmail)));
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
            final shouldMerge = await showMergeConfirmationSheet(context, e.email);
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
      await prefs.setString('login_email', email);

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GutAppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(AppIcons.chevronLeft, color: context.appColorScheme.textPrimary),
          onPressed: () {
            // Clear pending link if user goes back
            sl<AppStateService>().setPendingEmailLink(null);
            context.pop();
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.p24, vertical: AppSizes.p20),
          child: AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: _linkSent ? _buildSentState() : _buildInputState()),
        ),
      ),
    );
  }

  Widget _buildInputState() {
    final authNotifier = context.watch<GutAuthNotifier>();
    final pendingLink = sl<AppStateService>().pendingEmailLink.value;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      key: const ValueKey('input'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(pendingLink != null ? AppStrings.completeSignIn : AppStrings.welcomeBack, style: context.headingMd.copyWith(fontWeight: FontWeight.w900, fontSize: 24)),
        SizedBox(height: AppSizes.p8),
        Text(pendingLink != null ? AppStrings.completeSignInSubtitle : AppStrings.signInSubtitle, style: context.body.copyWith(color: context.appColorScheme.textSecondary)),
        SizedBox(height: AppSizes.p32),

        _buildLabel(AppStrings.emailAddress),
        GutTextField(controller: _emailController, keyboardType: TextInputType.emailAddress, style: context.bodyBold, hintText: AppStrings.enterEmail, prefixIcon: AppIcons.mail),

        SizedBox(height: AppSizes.p40),

        authNotifier.isLoading
            ? Center(child: CircularProgressIndicator(color: context.appColorScheme.textPrimary))
            : GutButton(label: pendingLink != null ? AppStrings.confirmEmail : AppStrings.sendLink, onTap: _sendLink),

        if (pendingLink == null) ...[
          SizedBox(height: AppSizes.p32),

          // Social Login Shortcuts
          Center(
            child: Text(AppStrings.orContinueWith, style: context.caption.copyWith(color: context.appColorScheme.textMuted)),
          ),
          SizedBox(height: AppSizes.p20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SocialIcon(assetPath: AppAssets.appleLogo, imageColor: isDark ? Colors.white : null, onTap: authNotifier.isLoading ? () {} : () => authNotifier.signInWithApple()),
              SizedBox(width: AppSizes.p16),
              _SocialIcon(assetPath: AppAssets.googleLogo, onTap: authNotifier.isLoading ? () {} : () => authNotifier.signInWithGoogle()),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSentState() {
    return Column(
      key: const ValueKey('sent'),
      children: [
        SizedBox(height: AppSizes.p40),
        Container(
          padding: EdgeInsets.all(AppSizes.p24),
          decoration: BoxDecoration(color: context.appColorScheme.elevatedSurface, shape: BoxShape.circle),
          child: Icon(AppIcons.mailCheck, size: 48, color: context.appColorScheme.textPrimary),
        ),
        SizedBox(height: AppSizes.p32),
        Text(
          AppStrings.checkYourEmail,
          textAlign: TextAlign.center,
          style: context.headingMd.copyWith(fontWeight: FontWeight.w900),
        ),
        SizedBox(height: AppSizes.p12),
        Text(
          AppStrings.linkSentSubtitle,
          textAlign: TextAlign.center,
          style: context.body.copyWith(color: context.appColorScheme.textSecondary),
        ),
        SizedBox(height: AppSizes.p40),
        GutButton(
          label: _cooldownSeconds > 0 ? '${AppStrings.resendIn}$_cooldownSeconds${AppStrings.secondUnit}' : AppStrings.resendLink,
          onTap: _cooldownSeconds > 0 ? null : () => setState(() => _linkSent = false),
        ),
        SizedBox(height: AppSizes.p16),
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
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.p8),
      child: Text(text, style: context.bodyBold.copyWith(fontSize: 13)),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final String assetPath;
  final VoidCallback onTap;
  final Color? imageColor;
  const _SocialIcon({required this.assetPath, required this.onTap, this.imageColor});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.r12),
      child: Container(
        padding: EdgeInsets.all(AppSizes.p12),
        decoration: BoxDecoration(
          border: Border.all(color: context.appColorScheme.border),
          borderRadius: BorderRadius.circular(AppSizes.r12),
        ),
        child: Image.asset(assetPath, width: AppSizes.icon24, height: AppSizes.icon24, color: imageColor),
      ),
    );
  }
}
