import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_config_data.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/selection_option.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_color_scheme.dart';

class GoalsScreen extends StatefulWidget {
  final List<String> activeGoals;
  const GoalsScreen({super.key, required this.activeGoals});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final Set<String> _selectedGoals = {};
  bool _isSaving = false;

  final List<SelectionOption> _goalOptions = AppConfigData.goalOptions;

  @override
  void initState() {
    super.initState();
    _selectedGoals.addAll(widget.activeGoals);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final goalsList = _selectedGoals.toList();

    final notifier = context.read<ProfileNotifier>();
    if (notifier.profile != null) {
      final updatedProfile = notifier.profile!.copyWith(goals: goalsList, updatedAt: DateTime.now());
      await notifier.updateUserProfile(updatedProfile);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      context.pop();
    }
  }

  void _toggleGoal(String label) {
    setState(() {
      if (_selectedGoals.contains(label)) {
        _selectedGoals.remove(label);
      } else {
        _selectedGoals.add(label);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const GutAppBar(title: AppStrings.goals),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.p24),
              child: GutSection(
                title: AppStrings.onboardingGoalsTitle,
                topPadding: AppSizes.p24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.updatePreferencesSubtitle, style: AppTextStyles.bodySm.copyWith(color: context.appColorScheme.textSecondary)),
                    Gap.h32,
                    SelectionWrap(options: _goalOptions, selectedValues: _selectedGoals, onToggle: _toggleGoal),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(AppSizes.p24, AppSizes.p16, AppSizes.p24, AppSizes.p32),
            child: GutButton(label: AppStrings.saveChanges, isLoading: _isSaving, onTap: _save),
          ),
        ],
      ),
    );
  }
}
