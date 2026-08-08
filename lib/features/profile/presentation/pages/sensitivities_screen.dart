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

class SensitivitiesScreen extends StatefulWidget {
  const SensitivitiesScreen({super.key, required this.activeSensitivities});
  final List<String> activeSensitivities;

  @override
  State<SensitivitiesScreen> createState() => _SensitivitiesScreenState();
}

class _SensitivitiesScreenState extends State<SensitivitiesScreen> {
  final Set<String> _selectedSensitivities = {};
  bool _isSaving = false;

  final List<SelectionOption> _sensitivityOptions =
      AppConfigData.sensitivityOptions;

  @override
  void initState() {
    super.initState();
    _selectedSensitivities.addAll(widget.activeSensitivities);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final sensitivitiesList = _selectedSensitivities.toList();

    final notifier = context.read<ProfileNotifier>();
    if (notifier.profile != null) {
      final updatedProfile = notifier.profile!.copyWith(
        sensitivities: sensitivitiesList,
        updatedAt: DateTime.now(),
      );
      await notifier.updateUserProfile(updatedProfile);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      context.pop();
    }
  }

  void _toggleSensitivity(String label) {
    setState(() {
      if (_selectedSensitivities.contains(label)) {
        _selectedSensitivities.remove(label);
      } else {
        _selectedSensitivities.add(label);
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    appBar: const GutAppBar(title: AppStrings.sensitivities),
    body: Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppSizes.p24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SelectionHeader(
                  title: AppStrings.onboardingSensitivitiesTitle,
                  subtitle: AppStrings.updatePreferencesSubtitle,
                ),
                Gap.h32,
                SelectionWrap(
                  options: _sensitivityOptions,
                  selectedValues: _selectedSensitivities,
                  onToggle: _toggleSensitivity,
                ),
              ],
            ),
          ),
        ),
        _SelectionFooter(isLoading: _isSaving, onSave: _save),
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
      Text(
        title,
        style: AppTextStyles.title.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
      Gap.h8,
      Text(
        subtitle,
        style: AppTextStyles.bodySm.copyWith(
          color: context.appColorScheme.textSecondary,
        ),
      ),
    ],
  );
}

class _SelectionFooter extends StatelessWidget {
  const _SelectionFooter({required this.isLoading, required this.onSave});
  final bool isLoading;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      AppSizes.p24,
      AppSizes.p16,
      AppSizes.p24,
      AppSizes.p32,
    ),
    child: GutButton(
      label: AppStrings.saveChanges,
      isLoading: isLoading,
      onTap: onSave,
    ),
  );
}
