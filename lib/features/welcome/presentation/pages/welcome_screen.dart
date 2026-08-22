import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gutgood/core/constants/app_assets.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/auth/data/utils/auth_error_handler.dart';
import 'package:gutgood/features/auth/presentation/providers/auth_provider.dart';
import 'package:gutgood/features/auth/presentation/widgets/auth_bottom_sheets.dart';
import 'package:provider/provider.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    final appStateService = sl<AppStateService>();
    appStateService.pendingMergeConflict.addListener(_onMergeConflict);
  }

  @override
  void dispose() {
    final appStateService = sl<AppStateService>();
    appStateService.pendingMergeConflict.removeListener(_onMergeConflict);
    super.dispose();
  }

  Future<void> _onMergeConflict() async {
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
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.authSyncDelayedMessage)));
          }
        }
      } else if (shouldMerge == false) {
        await authNotifier.abandonMerge();
      }
    } finally {
      appState.releaseMergePrompt();
    }
  }

  Future<void> _handleGetStarted(BuildContext context, GutAuthNotifier authNotifier) async {
    try {
      await authNotifier.signInAnonymously();
    } catch (e) {
      if (context.mounted) {
        final message = AuthErrorHandler.mapException(e);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;

    return Scaffold(
      backgroundColor: colorScheme.cardBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const _WelcomeLogo(), Gap.h48, const _WelcomeContent()]),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.p24, vertical: AppSizes.p24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _WelcomeDisclaimer(),
                  Gap.h24,
                  _WelcomeActions(onGetStarted: (n) => _handleGetStarted(context, n)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeLogo extends StatelessWidget {
  const _WelcomeLogo();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.r20),
          child: Image.asset(AppAssets.appIcon, height: AppSizes.w100, width: AppSizes.w100, fit: BoxFit.cover),
        ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOutCubic).scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutCubic, duration: 500.ms),
        Gap.h16,
        Text(
          AppStrings.appName,
          style: AppTextStyles.eyebrow.copyWith(color: colorScheme.textPrimary, letterSpacing: 2, fontSize: AppSizes.s12),
        ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
      ],
    );
  }
}

class _WelcomeContent extends StatelessWidget {
  const _WelcomeContent();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.p32),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppStrings.foodIsInformation,
              textAlign: TextAlign.center,
              style: AppTextStyles.displayLg.copyWith(color: colorScheme.textPrimary, fontSize: AppSizes.s120, height: 1.0, letterSpacing: -2.5),
            ),
          ).animate().fadeIn(delay: 250.ms, duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
          Gap.h20,
          Text(
            AppStrings.understandBodyNeeds2,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLg.copyWith(color: colorScheme.textSecondary, fontSize: AppSizes.s18, fontWeight: FontWeight.w400, height: 1.4),
          ).animate().fadeIn(delay: 350.ms, duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }
}

class _WelcomeDisclaimer extends StatelessWidget {
  const _WelcomeDisclaimer();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;

    return Text(
      AppStrings.healthDisclaimer,
      textAlign: TextAlign.center,
      style: AppTextStyles.caption.copyWith(color: colorScheme.textMuted, fontSize: AppSizes.s10, height: 1.5),
    ).animate().fadeIn(delay: 450.ms, duration: 400.ms);
  }
}

class _WelcomeActions extends StatelessWidget {
  const _WelcomeActions({required this.onGetStarted});
  final Function(GutAuthNotifier) onGetStarted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;

    return Selector<GutAuthNotifier, (bool, bool)>(
      selector: (_, n) => (n.isLoading, n.isAuthenticated),
      builder: (context, data, _) {
        final isLoading = data.$1;

        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: GutButton(label: AppStrings.getStarted, suffixIcon: AppIcons.arrowRight, isLoading: isLoading, onTap: isLoading ? null : () => onGetStarted(context.read<GutAuthNotifier>())),
            ),
            Gap.h24,
            GestureDetector(
              onTap: () => showAuthBottomSheet(context),
              child: RichText(
                text: TextSpan(
                  style: AppTextStyles.body.copyWith(color: colorScheme.textSecondary),
                  children: [
                    const TextSpan(text: AppStrings.alreadyHaveAccount),
                    const TextSpan(text: ' '),
                    TextSpan(
                      text: AppStrings.signIn,
                      style: AppTextStyles.bodyBold.copyWith(color: colorScheme.textPrimary, decoration: TextDecoration.underline),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 550.ms, duration: 400.ms).slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
      },
    );
  }
}
