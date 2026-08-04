import 'package:flutter/material.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';

class CautionBadge extends StatelessWidget {
  const CautionBadge({super.key});

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.appColorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'CAUTION',
        style: context.caption.copyWith(
          color: context.appColorScheme.error,
          fontWeight: FontWeight.w900,
          fontSize: 8,
          letterSpacing: 0.5,
        ),
      ),
    );
}
