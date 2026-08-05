import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_config_data.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/selection_option.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:provider/provider.dart';

class LifestyleScreen extends StatefulWidget {
  const LifestyleScreen({super.key, required this.activeLifestyle});
  final List<String> activeLifestyle;

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
  Widget build(BuildContext context) => Scaffold(
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
                  const _SelectionHeader(
                    title: AppStrings.onboardingLifestyleTitle,
                    subtitle: AppStrings.updatePreferencesSubtitle,
                  ),
                  Gap.h32,
                  SelectionWrap(
                    options: _lifestyleOptions,
                    selectedValues: _selectedLifestyle,
                    onToggle: _toggleLifestyle,
                  ),
                ],
              ),
            ),
          ),
          _SelectionFooter(
            isLoading: _isSaving,
            onSave: _save,
          ),
        ],
      ),
    );
}

class _SelectionHeader extends StatelessWidget {
  const _SelectionHeader({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w800, fontSize: 18)),
        Gap.h8,
        Text(subtitle,
            style: AppTextStyles.bodySm.copyWith(color: context.appColorScheme.textSecondary)),
      ],
    );
}

class _SelectionFooter extends StatelessWidget {
  const _SelectionFooter({required this.isLoading, required this.onSave});
  final bool isLoading;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.fromLTRB(AppSizes.p24, AppSizes.p16, AppSizes.p24, AppSizes.p32),
      child: GutButton(label: AppStrings.saveChanges, isLoading: isLoading, onTap: onSave),
    );
}
