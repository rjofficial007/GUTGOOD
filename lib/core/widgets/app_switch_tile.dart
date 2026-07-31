import 'package:flutter/material.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';

import '../constants/app_sizes.dart';

class AppSwitchTile extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String desc;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool showBottomBorder;

  const AppSwitchTile({super.key, this.icon, required this.title, required this.desc, required this.value, this.onChanged, this.showBottomBorder = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: AppSizes.p16),
      decoration: BoxDecoration(
        border: showBottomBorder ? Border(bottom: BorderSide(color: context.appColorScheme.border.withValues(alpha: 0.5))) : null,
      ),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, color: context.appColorScheme.textPrimary, size: AppSizes.icon20), SizedBox(width: AppSizes.p16)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.bodySm.copyWith(fontWeight: FontWeight.w600)),
                Text(desc, style: context.caption.copyWith(color: context.appColorScheme.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: context.appColorScheme.cardBackground,
            activeTrackColor: context.appColorScheme.textPrimary,
            inactiveThumbColor: context.appColorScheme.cardBackground,
            inactiveTrackColor: context.appColorScheme.border,
          ),
        ],
      ),
    );
  }
}
