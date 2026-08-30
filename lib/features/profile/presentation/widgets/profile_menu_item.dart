import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';

class ProfileMenuItem extends StatelessWidget {
  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
    this.color,
    this.showArrow = true,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final Color? color;
  final bool showArrow;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.p24,
        vertical: AppSizes.p18,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSizes.p8),
            decoration: BoxDecoration(
              color: (color ?? context.appColorScheme.textPrimary).withAlpha(26),
              borderRadius: BorderRadius.circular(AppSizes.r8),
            ),
            child: Icon(
              icon,
              color: color ?? context.appColorScheme.textPrimary,
              size: AppSizes.icon20,
            ),
          ),
          Gap.w16,
          Expanded(
            child: Text(
              label,
              style: context.labelBold.copyWith(
                color: color ?? context.appColorScheme.textPrimary,
              ),
            ),
          ),
          if (value != null) ...[
            Text(
              value!,
              style: context.body.copyWith(
                color: context.appColorScheme.textSecondary,
              ),
            ),
            Gap.w8,
          ],
          if (showArrow)
            Icon(
              AppIcons.chevronRight,
              color: context.appColorScheme.textMuted,
              size: AppSizes.icon16,
            ),
        ],
      ),
    ),
  );
}

class ProfileMenuSection extends StatelessWidget {
  const ProfileMenuSection({
    super.key,
    required this.title,
    required this.items,
  });
  final String title;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: EdgeInsets.only(
          left: AppSizes.p24,
          top: AppSizes.p32,
          bottom: AppSizes.p8,
        ),
        child: Text(
          title.toUpperCase(),
          style: context.captionBold.copyWith(
            color: context.appColorScheme.textMuted,
          ),
        ),
      ),
      Container(
        margin: EdgeInsets.symmetric(horizontal: AppSizes.p16),
        decoration: BoxDecoration(
          color: context.appColorScheme.cardBackground,
          borderRadius: BorderRadius.circular(AppSizes.r24),
          border: Border.all(
            color: context.appColorScheme.borderSubtle,
          ),
        ),
        child: Column(children: items),
      ),
    ],
  );
}
