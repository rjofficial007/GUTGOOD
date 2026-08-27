import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';

class FooterActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isEmbedded;
  final IconData? icon;

  const FooterActionButton({
    super.key,
    required this.label,
    this.onTap,
    this.isEmbedded = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return const SizedBox.shrink();
    final colorScheme = context.appColorScheme;

    return Padding(
      padding: EdgeInsets.all(isEmbedded ? 0 : AppSizes.p20),
      child: Column(
        children: [
          if (isEmbedded) Gap.h12,
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppSizes.r24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.r24),
                  border: Border.all(color: colorScheme.border.withValues(alpha: 1.0), width: 1),
                  color: isEmbedded ? colorScheme.elevatedSurface.withValues(alpha: 0.3) : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon ?? AppIcons.arrowRight, size: isEmbedded ? 11.sp : 12, color: colorScheme.textPrimary),
                    Gap.w8,
                    Text(
                      label.toUpperCase(),
                      style: context.eyebrow.copyWith(
                        color: colorScheme.textPrimary,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Gap.h12,
        ],
      ),
    );
  }
}
