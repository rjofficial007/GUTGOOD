import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/utils/haptic_helper.dart';

class ChatActionIcon extends StatelessWidget {
  const ChatActionIcon({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: () {
            HapticHelper.light();
            onTap();
          },
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: context.appColorScheme.elevatedSurface,
              borderRadius: BorderRadius.circular(AppSizes.r10),
              border: Border.all(color: context.appColorScheme.border),
            ),
            child: Icon(
              icon,
              size: 15,
              color: context.appColorScheme.textSecondary,
            ),
          ),
        ),
      );
}
