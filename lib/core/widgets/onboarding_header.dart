import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';

import '../theme/app_color_scheme.dart';

class OnboardingHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  const OnboardingHeader({super.key, required this.currentStep, required this.totalSteps, required this.onBack, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p4),
      child: SizedBox(
        height: 52.0.h,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: onBack,
              icon: Icon(AppIcons.arrowLeft),
              style: IconButton.styleFrom(backgroundColor: AppPalette.transparent, foregroundColor: context.appColorScheme.textPrimary),
            ),
            Row(
              children: List.generate(totalSteps, (index) {
                final isActive = index == currentStep;
                final isCompleted = index < currentStep;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 24.0.w : 6.0.w,
                  height: 6.0.h,
                  decoration: BoxDecoration(
                    color: isActive ? context.appColorScheme.textPrimary : (isCompleted ? context.appColorScheme.textSecondary : context.appColorScheme.border),
                    borderRadius: BorderRadius.circular(3.0.r),
                  ),
                );
              }),
            ),
            TextButton(
              onPressed: onSkip,
              child: Text(AppStrings.skip, style: AppTextStyles.label.copyWith(color: context.appColorScheme.textMuted)),
            ),
          ],
        ),
      ),
    );
  }
}
