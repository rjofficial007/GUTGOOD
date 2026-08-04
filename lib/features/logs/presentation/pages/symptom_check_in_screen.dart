import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/selection_option.dart';
import 'package:gutgood/core/models/symptom_log.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/haptic_helper.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/logs/domain/repositories/log_repository.dart';

class SymptomCheckInScreen extends StatefulWidget {
  const SymptomCheckInScreen({super.key});

  @override
  State<SymptomCheckInScreen> createState() => _SymptomCheckInScreenState();
}

class _SymptomCheckInScreenState extends State<SymptomCheckInScreen> {
  final _notesController = TextEditingController();
  String _selectedSymptom = AppStrings.symptomNone;
  double _severity = 5.0;
  String _mood = AppStrings.moodNeutral;
  int _energy = 5;
  String _sleep = AppStrings.sleepGood;
  bool _isSaving = false;

  final List<SelectionOption> _symptomOptions = [
    const SelectionOption(label: AppStrings.symptomNone, icon: AppIcons.checkCircle),
    const SelectionOption(label: AppStrings.lifestyleBloating, icon: AppIcons.wind),
    const SelectionOption(label: AppStrings.symptomGas, icon: AppIcons.wind),
    const SelectionOption(label: AppStrings.symptomFatigue, icon: AppIcons.batteryLow),
    const SelectionOption(label: AppStrings.symptomHeartburn, icon: AppIcons.flame),
    const SelectionOption(label: AppStrings.symptomNausea, icon: AppIcons.activity),
    const SelectionOption(label: AppStrings.symptomCramps, icon: AppIcons.activity),
    const SelectionOption(label: AppStrings.symptomHeadache, icon: AppIcons.brain),
    const SelectionOption(label: AppStrings.symptomSkin, icon: AppIcons.sparkles),
    const SelectionOption(label: AppStrings.symptomCraving, icon: AppIcons.cookie),
    const SelectionOption(label: AppStrings.symptomStool, icon: AppIcons.activity),
  ];

  final List<SelectionOption> _moodOptions = [
    const SelectionOption(label: AppStrings.moodHappy, icon: AppIcons.smile),
    const SelectionOption(label: AppStrings.moodCalm, icon: AppIcons.smile),
    const SelectionOption(label: AppStrings.moodNeutral, icon: AppIcons.smile),
    const SelectionOption(label: AppStrings.moodAnxious, icon: AppIcons.alertTriangle),
    const SelectionOption(label: AppStrings.moodSad, icon: AppIcons.frown),
    const SelectionOption(label: AppStrings.moodIrritable, icon: AppIcons.flame),
  ];

  final List<SelectionOption> _sleepOptions = [
    const SelectionOption(label: AppStrings.sleepExcellent),
    const SelectionOption(label: AppStrings.sleepGood),
    const SelectionOption(label: AppStrings.sleepFair),
    const SelectionOption(label: AppStrings.sleepPoor),
    const SelectionOption(label: AppStrings.sleepInterrupted),
  ];

  @override
  void initState() {
    super.initState();
    unawaited(sl<AnalyticsService>().logEvent(name: 'symptom_check_in_started'));
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final log = SymptomLog(
      symptom: _selectedSymptom,
      severity: _severity.toInt(),
      energyLevel: _energy,
      mood: _mood,
      sleep: _sleep,
      notes: _notesController.text.trim(),
      source: 'manual',
      time: DateTime.now(),
    );

    try {
      await sl<LogRepository>().logSymptom(log);
      await sl<AnalyticsService>().logEvent(name: 'symptom_check_in_completed', parameters: {
        'symptom': _selectedSymptom,
        'severity': _severity.toInt(),
        'energy': _energy,
        'mood': _mood,
        'has_notes': _notesController.text.isNotEmpty,
      });
      sl<AppStateService>().notifyProfileUpdated();
      HapticHelper.success();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.checkInSaved)));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.checkInFailed)));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: context.appColorScheme.cardBackground,
      body: CustomScrollView(
        slivers: [
          const GutSliverAppBar(title: AppStrings.dailyCheckIn),
          SliverPadding(
            padding: EdgeInsets.all(AppSizes.p24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(AppStrings.howAreYouFeeling, style: context.headingMd.copyWith(fontWeight: FontWeight.w900)),
                Gap.h8,
                Text(AppStrings.dailyCheckInDesc, style: context.bodySm.copyWith(color: context.appColorScheme.textSecondary)),

                GutSection(
                  title: AppStrings.symptoms,
                  child: GutSelectionSection(
                    title: '', // Already has title in GutSection
                    options: _symptomOptions,
                    selectedValue: _selectedSymptom,
                    onSelected: (val) => setState(() => _selectedSymptom = val),
                  ),
                ),

                if (_selectedSymptom != AppStrings.symptomNone) ...[
                  GutSection(
                    title: AppStrings.severityLabel,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${AppStrings.labelScorePrefix}${_severity.toInt()}', style: context.bodyBold.copyWith(color: context.appColorScheme.textPrimary)),
                        Slider(
                          value: _severity,
                          min: 1.0,
                          max: 10.0,
                          divisions: 9,
                          activeColor: context.appColorScheme.textPrimary,
                          inactiveColor: context.appColorScheme.border,
                          onChanged: (val) => setState(() => _severity = val),
                        ),
                      ],
                    ),
                  ),
                ],

                GutSection(
                  title: AppStrings.mood,
                  child: GutSelectionSection(title: '', options: _moodOptions, selectedValue: _mood, onSelected: (val) => setState(() => _mood = val)),
                ),

                GutSection(
                  title: AppStrings.energyLevelLabel,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${AppStrings.labelScorePrefix}$_energy', style: context.bodyBold.copyWith(color: context.appColorScheme.textPrimary)),
                      Slider(
                        value: _energy.toDouble(),
                        min: 1.0,
                        max: 10.0,
                        divisions: 9,
                        activeColor: context.appColorScheme.textPrimary,
                        inactiveColor: context.appColorScheme.border,
                        onChanged: (val) => setState(() => _energy = val.toInt()),
                      ),
                    ],
                  ),
                ),

                GutSection(
                  title: AppStrings.lastNightSleep,
                  child: GutSelectionSection(title: '', options: _sleepOptions, selectedValue: _sleep, onSelected: (val) => setState(() => _sleep = val)),
                ),

                GutSection(
                  title: AppStrings.notesLabel,
                  child: GutTextField(controller: _notesController, maxLines: 3, hintText: AppStrings.anythingToNote),
                ),
                Gap.h40,

                GutButton(label: AppStrings.saveDailyCheckIn, isLoading: _isSaving, onTap: _save),
                Gap.h24,
              ]),
            ),
          ),
        ],
      ),
    );
}
