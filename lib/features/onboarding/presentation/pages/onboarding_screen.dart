import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_config_data.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/selection_option.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/services/notification_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/onboarding/presentation/widgets/ai_personalization_onboarding_page.dart';
import 'package:gutgood/features/onboarding/presentation/widgets/cycle_sync_onboarding_page.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:provider/provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  int _page = 0;
  bool _isFinishing = false;

  // ─── USER SELECTIONS ──────────────────────────────────────────
  final Set<String> _selectedGoals = {};
  final Set<String> _selectedSensitivities = {};
  final Set<String> _selectedLifestyle = {};
  bool _cycleSyncEnabled = false;
  String _selectedCyclePhase = AppStrings.phaseLuteal; // 🟢 Default to Luteal Phase when enabled

  final List<SelectionOption> _goalOptions = AppConfigData.goalOptions;
  final List<SelectionOption> _sensitivityOptions = AppConfigData.sensitivityOptions;
  final List<SelectionOption> _lifestyleOptions = AppConfigData.lifestyleOptions;
  final List<String> _cyclePhases = AppConfigData.cyclePhases;

  int get _totalPages => 6;

  bool get _canContinue {
    switch (_page) {
      case 0:
        return _nameController.text.trim().isNotEmpty;
      case 1:
        return _selectedGoals.isNotEmpty;
      case 2:
        return _selectedSensitivities.isNotEmpty;
      case 3:
        return _selectedLifestyle.isNotEmpty;
      default:
        return true;
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    unawaited(sl<AnalyticsService>().logEvent(name: 'onboarding_started'));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (_page < _totalPages - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      unawaited(sl<AnalyticsService>().logEvent(name: 'onboarding_step_complete', parameters: {'step': _page}));
    } else {
      _finish();
    }
  }

  void _back() {
    FocusScope.of(context).unfocus();
    if (_page > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      unawaited(sl<AnalyticsService>().logEvent(name: 'onboarding_step_back', parameters: {'from_step': _page}));
    } else {
      context.pop();
    }
  }

  Future<void> _finish() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);
    AppLogger.info('OnboardingScreen: Starting finish flow...');

    try {
      final profileNotifier = context.read<ProfileNotifier>();

      // 🟢 Guard: Ensure we have a valid session before finishing.
      final currentUser = sl<FirebaseAuth>().currentUser;
      if (currentUser == null) {
        AppLogger.warning('OnboardingScreen: Attempted to finish without active session.');
        setState(() => _isFinishing = false);
        if (mounted) context.go(AppRoutes.welcome);
        return;
      }

      AppLogger.info('OnboardingScreen: Completing onboarding data...');
      await profileNotifier.completeOnboarding(
        displayName: _nameController.text.trim().isEmpty ? 'Guest' : _nameController.text.trim(),
        goals: _selectedGoals.toList(),
        sensitivities: _selectedSensitivities.toList(),
        lifestyle: _selectedLifestyle.toList(),
        cycleSyncEnabled: _cycleSyncEnabled,
        cyclePhase: _cycleSyncEnabled ? _selectedCyclePhase : null,
        markOnboarded: false, // 🟢 Delay onboarded status until after paywall
      );

      AppLogger.info('OnboardingScreen: Setting up reminders...');
      try {
        await sl<NotificationService>().setupDefaultReminders();
      } catch (e) {
        AppLogger.error('OnboardingScreen: Non-critical failure setting up reminders', error: e);
      }

      if (mounted) {
        AppLogger.info('OnboardingScreen: Showing paywall...');
        // 🟢 Show the paywall while STILL on the Onboarding screen context.
        // This works now because the AppRouter hasn't redirected us to /home/chat yet.
        await showPaywallScreen(context, onProceedWithLimited: () {});

        AppLogger.info('OnboardingScreen: Marking onboarding as complete...');
        // 🟢 Finally mark onboarding as officially complete.
        // This will trigger the ProfileNotifier listener in AppRouter and perform the redirect.
        await profileNotifier.markOnboardingComplete();

        if (mounted) {
          AppLogger.info('OnboardingScreen: Navigation fallback triggered.');
          // Fallback navigation in case listener doesn't fire immediately
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && context.mounted) {
              context.go(AppRoutes.chat);
            }
          });
        }
      }
    } catch (e) {
      AppLogger.error('OnboardingScreen: Critical failure during finish', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.errorGeneral)));
        setState(() => _isFinishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    body: SafeArea(
      child: Column(
        children: [
          OnboardingHeader(
            currentStep: _page,
            totalSteps: _totalPages - 1,
            onBack: _back,
            onSkip: _page < _totalPages - 1 ? _next : null,
            showSkip: _page < _totalPages - 1, // Show skip for all except AI Personalization
            showBack: _page > 0, // 🟢 Do not show back button on the first page
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                _OnboardingNamePage(controller: _nameController),
                _OnboardingSelectionPage(
                  title: AppStrings.onboardingGoalsTitle,
                  subtitle: AppStrings.onboardingGoalsSubtitle,
                  options: _goalOptions,
                  selections: _selectedGoals,
                  onToggle: (val) => setState(() => _selectedGoals.contains(val) ? _selectedGoals.remove(val) : _selectedGoals.add(val)),
                ),
                _OnboardingSelectionPage(
                  title: AppStrings.onboardingSensitivitiesTitle,
                  subtitle: AppStrings.onboardingSensitivitiesSubtitle,
                  options: _sensitivityOptions,
                  selections: _selectedSensitivities,
                  onToggle: (val) => setState(() => _selectedSensitivities.contains(val) ? _selectedSensitivities.remove(val) : _selectedSensitivities.add(val)),
                ),
                _OnboardingSelectionPage(
                  title: AppStrings.onboardingLifestyleTitle,
                  subtitle: AppStrings.onboardingLifestyleSubtitle,
                  options: _lifestyleOptions,
                  selections: _selectedLifestyle,
                  onToggle: (val) => setState(() => _selectedLifestyle.contains(val) ? _selectedLifestyle.remove(val) : _selectedLifestyle.add(val)),
                ),
                CycleSyncOnboardingPage(
                  cycleSyncEnabled: _cycleSyncEnabled,
                  selectedCyclePhase: _selectedCyclePhase,
                  cyclePhases: _cyclePhases,
                  onToggleEnabled: (val) => setState(() => _cycleSyncEnabled = val),
                  onPhaseSelected: (val) => setState(() => _selectedCyclePhase = val),
                ),
                AIPersonalizationOnboardingPage(onFinish: _next, isLoading: _isFinishing),
              ],
            ),
          ),
          _OnboardingFooter(page: _page, totalPages: _totalPages, onNext: _next, isFinishing: _isFinishing, canContinue: _canContinue),
        ],
      ),
    ),
  );
}

class _OnboardingNamePage extends StatelessWidget {
  const _OnboardingNamePage({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: AppSizes.p24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Gap.h16,
        Text(AppStrings.whatShouldWeCallYou, style: AppTextStyles.displaySm).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
        Gap.h10,
        Text(
          AppStrings.enterNameContinuePrompt,
          style: AppTextStyles.bodyLg.copyWith(color: context.appColorScheme.textSecondary),
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),
        Gap.h32,
        GutTextField(controller: controller, hintText: AppStrings.enterYourNameHint, autofocus: true, textCapitalization: TextCapitalization.words).animate().fadeIn(delay: 200.ms, duration: 500.ms),
      ],
    ),
  );
}

class _OnboardingSelectionPage extends StatelessWidget {
  const _OnboardingSelectionPage({required this.title, required this.subtitle, required this.options, required this.selections, required this.onToggle});

  final String title;
  final String subtitle;
  final List<SelectionOption> options;
  final Set<String> selections;
  final Function(String) onToggle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: AppSizes.p24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Gap.h16,
        Text(title, style: AppTextStyles.displaySm).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
        Gap.h10,
        Text(subtitle, style: AppTextStyles.bodyLg.copyWith(color: context.appColorScheme.textSecondary)).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),
        Gap.h32,
        Expanded(
          child: SingleChildScrollView(
            child: SelectionWrap(options: options, selectedValues: selections, onToggle: onToggle).animate().fadeIn(delay: 200.ms, duration: 500.ms),
          ),
        ),
      ],
    ),
  );
}

class _OnboardingFooter extends StatelessWidget {
  const _OnboardingFooter({required this.page, required this.totalPages, required this.onNext, required this.isFinishing, required this.canContinue});

  final int page;
  final int totalPages;
  final VoidCallback onNext;
  final bool isFinishing;
  final bool canContinue;

  @override
  Widget build(BuildContext context) {
    if (page >= totalPages - 1) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSizes.p24, AppSizes.p16, AppSizes.p24, AppSizes.p24),
      child: isFinishing
          ? const Center(child: CircularProgressIndicator())
          : GutButton(
              label: AppStrings.continueButton,
              suffixIcon: AppIcons.arrowRight,
              onTap: canContinue ? onNext : null,
              color: canContinue ? null : context.appColorScheme.border,
              textColor: canContinue ? null : context.appColorScheme.textMuted,
            ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);
  }
}
