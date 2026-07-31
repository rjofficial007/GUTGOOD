import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/widgets.dart';

import '../../../../core/constants/app_icons.dart';

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
                  Text(AppStrings.bodyRhythm, style: context.displaySm),
                  Gap.h10,
                  Text(AppStrings.bodyRhythmSubtitle, style: context.bodyLg.copyWith(color: context.appColorScheme.textSecondary)),
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
                          width: 42.0.w,
                          height: 42.0.w,
                          decoration: BoxDecoration(color: AppPalette.pink.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppSizes.r14)),
                          child: Icon(AppIcons.flower, color: AppPalette.pink, size: 20.0.w),
                        ),
                        Gap.w14,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppStrings.cycleSync, style: context.bodyBold),
                              Text(
                                "Personalize insights based on your cycle phase",
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
                  ),
                  if (cycleSyncEnabled) ...[
                    Gap.h32,
                    Text(AppStrings.selectCyclePhase, style: context.bodyBold),
                    Gap.h16,
                    Wrap(
                      spacing: 10.0.w,
                      runSpacing: 10.0.h,
                      children: cyclePhases.map((phase) {
                        final isSelected = selectedCyclePhase == phase;
                        return GutChip(icon: AppIcons.flower, label: phase, isSelected: isSelected, onTap: () => onPhaseSelected(phase));
                      }).toList(),
                    ),
                  ],
                  Spacer(),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSizes.p20),
                    child: Text(AppStrings.cycleSyncHormonalPatterns, style: context.caption.copyWith(color: context.appColorScheme.textMuted)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
