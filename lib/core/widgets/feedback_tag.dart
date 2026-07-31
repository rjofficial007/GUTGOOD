import 'package:flutter/material.dart';

import '../theme/app_color_scheme.dart';
import '../theme/app_text_styles.dart';

class FeedbackTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  const FeedbackTag({super.key, required this.icon, required this.label, required this.onTap, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? context.appColorScheme.textPrimary : context.appColorScheme.cardBackground,
          border: Border.all(color: isSelected ? context.appColorScheme.textPrimary : context.appColorScheme.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: isSelected ? context.appColorScheme.cardBackground : context.appColorScheme.textPrimary),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(color: isSelected ? context.appColorScheme.cardBackground : context.appColorScheme.textPrimary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
