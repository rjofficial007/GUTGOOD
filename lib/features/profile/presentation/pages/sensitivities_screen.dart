import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_config_data.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:gutgood/features/profile/presentation/widgets/profile_selection_widgets.dart';
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

  final List<SelectionOption> _sensitivityOptions = AppConfigData.sensitivityOptions;

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
      final updatedProfile = notifier.profile!.copyWith(sensitivities: sensitivitiesList, updatedAt: DateTime.now());
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
    appBar: const GutAppBar(title: AppStrings.sensitivities, centerTitle: true),
    body: Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppSizes.p24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ProfileSelectionHeader(title: AppStrings.onboardingSensitivitiesTitle, subtitle: AppStrings.updatePreferencesSubtitle),
                Gap.h32,
                SelectionWrap(options: _sensitivityOptions, selectedValues: _selectedSensitivities, onToggle: _toggleSensitivity),
              ],
            ),
          ),
        ),
        ProfileSelectionFooter(isLoading: _isSaving, onSave: _save),
      ],
    ),
  );
}
