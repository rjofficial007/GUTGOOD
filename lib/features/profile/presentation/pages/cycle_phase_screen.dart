import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:provider/provider.dart';

class CyclePhaseScreen extends StatefulWidget {
  const CyclePhaseScreen({super.key, this.currentPhase});
  final String? currentPhase;

  @override
  State<CyclePhaseScreen> createState() => _CyclePhaseScreenState();
}

class _CyclePhaseScreenState extends State<CyclePhaseScreen> {
  final Set<String> _selectedPhase = {};
  bool _isSaving = false;

  final List<SelectionOption> _phaseOptions = const [
    SelectionOption(label: AppStrings.phaseMenstrual, icon: AppIcons.droplet),
    SelectionOption(label: AppStrings.phaseFollicular, icon: AppIcons.flower),
    SelectionOption(label: AppStrings.phaseOvulatory, icon: AppIcons.sparkles),
    SelectionOption(label: AppStrings.phaseLuteal, icon: AppIcons.moon),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.currentPhase != null) {
      _selectedPhase.add(widget.currentPhase!);
    }
  }

  Future<void> _save() async {
    if (_selectedPhase.isEmpty) return;

    setState(() => _isSaving = true);
    final phase = _selectedPhase.first;

    final notifier = context.read<ProfileNotifier>();
    if (notifier.profile != null) {
      final updatedProfile = notifier.profile!.copyWith(cyclePhase: phase, updatedAt: DateTime.now());
      await notifier.updateUserProfile(updatedProfile);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      context.pop();
    }
  }

  void _togglePhase(String label) {
    setState(() {
      _selectedPhase
        ..clear()
        ..add(label);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const GutAppBar(title: AppStrings.cyclePhase, centerTitle: true),
    body: Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppSizes.p24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PhaseHeader(),
                Gap.h32,
                SelectionWrap(options: _phaseOptions, selectedValues: _selectedPhase, onToggle: _togglePhase),
              ],
            ),
          ),
        ),
        _PhaseFooter(isLoading: _isSaving, isEnabled: _selectedPhase.isNotEmpty, onSave: _save),
      ],
    ),
  );
}

class _PhaseHeader extends StatelessWidget {
  const _PhaseHeader();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(AppStrings.selectCyclePhase, style: context.title.copyWith(fontWeight: FontWeight.w800, fontSize: 18)),
      Gap.h8,
      Text(AppStrings.cycleSyncDesc, style: context.bodySm.copyWith(color: context.appColorScheme.textSecondary)),
    ],
  );
}

class _PhaseFooter extends StatelessWidget {
  const _PhaseFooter({required this.isLoading, required this.isEnabled, required this.onSave});

  final bool isLoading;
  final bool isEnabled;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(AppSizes.p24, AppSizes.p16, AppSizes.p24, AppSizes.p32),
    child: GutButton(label: AppStrings.saveChanges, isLoading: isLoading, onTap: isEnabled ? onSave : null),
  );
}
