import 'package:flutter/gestures.dart';
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
          // 🟢 Fix: GoRouter's redirect handles navigation automatically.
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
    final authNotifier = context.watch<GutAuthNotifier>();

    return Scaffold(
      backgroundColor: context.appColorScheme.cardBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.p24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const Spacer(flex: 2),

                      // Logo
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppSizes.r20),
                        child: Image.asset(AppAssets.appIcon, height: AppSizes.w100, width: AppSizes.w100),
                      ).animate().fadeIn(duration: 600.ms).scale(delay: 0.ms, duration: 600.ms, curve: Curves.easeOutBack),
                      Gap.h40,

                      // Content
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppSizes.p8),
                        child: Column(
                          children: [
                            Text(
                              AppStrings.foodIsMedicine,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.displayLg.copyWith(fontSize: AppSizes.s60, height: 0.95, letterSpacing: -2.0, fontWeight: FontWeight.w900),
                            ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
                            Gap.h24,
                            Text(
                              AppStrings.understandBodyNeeds,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w400, color: context.appColorScheme.textSecondary),
                            ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
                          ],
                        ),
                      ),
                      const Spacer(flex: 3),
                      Text(
                        AppStrings.healthDisclaimer,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(color: context.appColorScheme.textMuted, fontSize: AppSizes.s10),
                      ).animate().fadeIn(delay: 600.ms, duration: 800.ms),
                      Gap.h20,
                      // Buttons
                      Column(
                        children: [
                          GutButton(
                            label: AppStrings.getStarted,
                            suffixIcon: AppIcons.arrowRight,
                            isLoading: authNotifier.isLoading,
                            onTap: authNotifier.isLoading ? null : () => _handleGetStarted(context, authNotifier),
                          ),
                          Gap.h20,
                          RichText(
                            text: TextSpan(
                              style: context.body.copyWith(color: context.appColorScheme.textSecondary),
                              children: [
                                const TextSpan(text: '${AppStrings.alreadyHaveAccount} '),
                                TextSpan(
                                  text: AppStrings.signIn,
                                  style: context.bodyBold.copyWith(color: context.appColorScheme.textPrimary),
                                  recognizer: TapGestureRecognizer()..onTap = () => showAuthBottomSheet(context),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 800.ms, duration: 600.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
                      Gap.h20,
                    ],
                  ),
                ),
              ),
            ),
        ),
      ),
    );
  }
}
