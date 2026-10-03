import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/widgets/gut_button.dart';

/// Shared header used by the profile preference-selection screens.
class ProfileSelectionHeader extends StatelessWidget {
  const ProfileSelectionHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w800, fontSize: 18)),
      Gap.h8,
      Text(subtitle, style: AppTextStyles.bodySm.copyWith(color: context.appColorScheme.textSecondary)),
    ],
  );
}

/// Shared save footer used by the profile preference-selection screens.
class ProfileSelectionFooter extends StatelessWidget {
  const ProfileSelectionFooter({super.key, required this.isLoading, required this.onSave});

  final bool isLoading;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(AppSizes.p24, AppSizes.p16, AppSizes.p24, AppSizes.p32),
    child: GutButton(label: AppStrings.saveChanges, isLoading: isLoading, onTap: onSave),
  );
}
