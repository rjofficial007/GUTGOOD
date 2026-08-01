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

class LifestyleScreen extends StatefulWidget {
  final List<String> activeLifestyle;
  const LifestyleScreen({super.key, required this.activeLifestyle});

  @override
  State<LifestyleScreen> createState() => _LifestyleScreenState();
}

class _LifestyleScreenState extends State<LifestyleScreen> {
  final Set<String> _selectedLifestyle = {};
  bool _isSaving = false;

  final List<SelectionOption> _lifestyleOptions = AppConfigData.lifestyleOptions;

  @override
  void initState() {
    super.initState();
    _selectedLifestyle.addAll(widget.activeLifestyle);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final lifestyleList = _selectedLifestyle.toList();

    final notifier = context.read<ProfileNotifier>();
    if (notifier.profile != null) {
      final updatedProfile = notifier.profile!.copyWith(lifestyle: lifestyleList, updatedAt: DateTime.now());
      await notifier.updateUserProfile(updatedProfile);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      context.pop();
    }
  }

  void _toggleLifestyle(String label) {
    setState(() {
      if (_selectedLifestyle.contains(label)) {
        _selectedLifestyle.remove(label);
      } else {
        _selectedLifestyle.add(label);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const GutAppBar(title: AppStrings.lifestyle),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppSizes.p24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.onboardingLifestyleTitle, style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w800, fontSize: 18)),
                  Gap.h8,
                  Text(AppStrings.updatePreferencesSubtitle, style: AppTextStyles.bodySm.copyWith(color: context.appColorScheme.textSecondary)),
                  Gap.h32,
                  SelectionWrap(options: _lifestyleOptions, selectedValues: _selectedLifestyle, onToggle: _toggleLifestyle),
                ],
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
