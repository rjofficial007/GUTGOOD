import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';

class CautionBadge extends StatelessWidget {
  const CautionBadge({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: context.appColorScheme.errorSubtle,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      AppStrings.caution,
      style: context.captionBold.copyWith(
        color: context.appColorScheme.error,
        letterSpacing: 0.5,
      ),
    ),
  );
}
