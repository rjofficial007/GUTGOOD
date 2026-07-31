import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_config_data.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/selection_option.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/notification_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/onboarding/presentation/widgets/ai_personalization_onboarding_page.dart';
import 'package:gutgood/features/onboarding/presentation/widgets/cycle_sync_onboarding_page.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:provider/provider.dart';

import '../../../../core/di/injection_container.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;
  bool _isFinishing = false;

  // ─── USER SELECTIONS ──────────────────────────────────────────
  final Set<String> _selectedGoals = {};
  final Set<String> _selectedSensitivities = {};
  final Set<String> _selectedLifestyle = {};
  bool _cycleSyncEnabled = false;
  String _selectedCyclePhase = AppStrings.notSpecified; // 🟢 PRD Alignment: Default to Not Specified

  final List<SelectionOption> _goalOptions = AppConfigData.goalOptions;
  final List<SelectionOption> _sensitivityOptions = AppConfigData.sensitivityOptions;
  final List<SelectionOption> _lifestyleOptions = AppConfigData.lifestyleOptions;
  final List<String> _cyclePhases = AppConfigData.cyclePhases;

  int get _totalPages => 5;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (_page < _totalPages - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      _finish();
    }
  }

  void _back() {
    FocusScope.of(context).unfocus();
    if (_page > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      context.pop();
    }
  }

  Future<void> _finish() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);

    final profileNotifier = context.read<ProfileNotifier>();

    // 🟢 Guard: Ensure we have a valid session before finishing.
    final currentUser = sl<FirebaseAuth>().currentUser;
    if (currentUser == null) {
      Log.w('OnboardingScreen: Attempted to finish without active session.');
      setState(() => _isFinishing = false);
      if (mounted) context.go('/welcome');
      return;
    }

    await profileNotifier.completeOnboarding(
      displayName: 'Guest',
      goals: _selectedGoals.toList(),
      sensitivities: _selectedSensitivities.toList(),
      lifestyle: _selectedLifestyle.toList(),
      cycleSyncEnabled: _cycleSyncEnabled,
      cyclePhase: _selectedCyclePhase,
    );

    await sl<NotificationService>().setupDefaultReminders();
    sl<AppStateService>().notifyProfileUpdated();

    if (mounted) {
      await showPaywallBottomSheet(context, onProceedWithLimited: () {});
      if (mounted) {
        context.go('/home/chat');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            OnboardingHeader(currentStep: _page, totalSteps: _totalPages - 1, onBack: _back, onSkip: _next),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _buildSelectionPage(
                    title: AppStrings.onboardingGoalsTitle,
                    subtitle: AppStrings.onboardingGoalsSubtitle,
                    options: _goalOptions,
                    selections: _selectedGoals,
                    onToggle: (val) => setState(() => _selectedGoals.contains(val) ? _selectedGoals.remove(val) : _selectedGoals.add(val)),
                  ),
                  _buildSelectionPage(
                    title: AppStrings.onboardingSensitivitiesTitle,
                    subtitle: AppStrings.onboardingSensitivitiesSubtitle,
                    options: _sensitivityOptions,
                    selections: _selectedSensitivities,
                    onToggle: (val) => setState(() => _selectedSensitivities.contains(val) ? _selectedSensitivities.remove(val) : _selectedSensitivities.add(val)),
                  ),
                  _buildSelectionPage(
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
                  AIPersonalizationOnboardingPage(onFinish: _next),
                ],
              ),
            ),
            if (_page < _totalPages - 1 && _page != 4)
              Padding(
                padding: EdgeInsets.fromLTRB(AppSizes.p24, AppSizes.p16, AppSizes.p24, AppSizes.p36),
                child: GutButton(label: AppStrings.continueButton, suffixIcon: AppIcons.arrowRight, onTap: _next),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionPage({required String title, required String subtitle, required List<SelectionOption> options, required Set<String> selections, required Function(String) onToggle}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.p24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Gap.h16,
          Text(title, style: AppTextStyles.displaySm),
          Gap.h10,
          Text(subtitle, style: AppTextStyles.bodyLg.copyWith(color: context.appColorScheme.textSecondary)),
          Gap.h32,
          Expanded(
            child: SingleChildScrollView(
              child: SelectionWrap(options: options, selectedValues: selections, onToggle: onToggle),
            ),
          ),
        ],
      ),
    );
  }
}
