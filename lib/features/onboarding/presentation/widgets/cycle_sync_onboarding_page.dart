import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/widgets.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:gutgood/core/constants/app_icons.dart';

class CycleSyncOnboardingPage extends StatelessWidget {
  final bool cycleSyncEnabled;
  final String selectedCyclePhase;
  final List<String> cyclePhases;
  final ValueChanged<bool> onToggleEnabled;
  final ValueChanged<String> onPhaseSelected;

  const CycleSyncOnboardingPage({super.key, required this.cycleSyncEnabled, required this.selectedCyclePhase, required this.cyclePhases, required this.onToggleEnabled, required this.onPhaseSelected});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.p24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Gap.h16,
                  Text(AppStrings.bodyRhythm, style: context.displaySm).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                  Gap.h10,
                  Text(AppStrings.bodyRhythmSubtitle, style: context.bodyLg.copyWith(color: context.appColorScheme.textSecondary)).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),
                  Gap.h32,
                  Container(
                    padding: EdgeInsets.all(AppSizes.p20),
                    decoration: BoxDecoration(
                      color: context.appColorScheme.elevatedSurface,
                      borderRadius: BorderRadius.circular(AppSizes.r18),
                      border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: AppSizes.w42,
                          height: AppSizes.w42,
                          decoration: BoxDecoration(color: context.appColorScheme.border.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(AppSizes.r14)),
                          child: Icon(AppIcons.flower, color: context.appColorScheme.textPrimary, size: AppSizes.icon20),
                        ),
                        Gap.w14,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppStrings.cycleSync, style: context.bodyBold),
                              Text(
                                AppStrings.personalizeInsightsPhase,
                                style: context.bodySm.copyWith(color: context.appColorScheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: cycleSyncEnabled,
                          onChanged: onToggleEnabled,
                          activeThumbColor: context.appColorScheme.cardBackground,
                          activeTrackColor: context.appColorScheme.textPrimary,
                          inactiveThumbColor: context.appColorScheme.cardBackground,
                          inactiveTrackColor: context.appColorScheme.border,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.1, end: 0),
                  if (cycleSyncEnabled) ...[
                    Gap.h32,
                    Text(AppStrings.selectCyclePhase, style: context.bodyBold).animate().fadeIn(duration: 300.ms),
                    Gap.h16,
                    Wrap(
                      spacing: AppSizes.p10,
                      runSpacing: AppSizes.p10,
                      children: cyclePhases.map((phase) {
                        final isSelected = selectedCyclePhase == phase;
                        return GutChip(icon: AppIcons.flower, label: phase, isSelected: isSelected, onTap: () => onPhaseSelected(phase));
                      }).toList(),
                    ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                  ],
                  Spacer(),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSizes.p20),
                    child: Text(AppStrings.cycleSyncHormonalPatterns, style: context.caption.copyWith(color: context.appColorScheme.textMuted)),
                  ).animate().fadeIn(delay: 600.ms),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
