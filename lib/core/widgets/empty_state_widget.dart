import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_button.dart';

/// A branded full-screen or section-level empty state indicator.
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onActionPressed,
    this.compact = false,
  });

  /// Icon to represent the empty category.
  final IconData icon;

  /// Primary heading for the empty state.
  final String title;

  /// Descriptive body text.
  final String description;

  /// Optional action button label.
  final String? actionLabel;

  /// Optional callback when action button is clicked.
  final VoidCallback? onActionPressed;

  /// If true, reduces padding for inline / small card containers.
  final bool compact;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSizes.p16 : AppSizes.p40,
        vertical: compact ? AppSizes.p24 : AppSizes.p64,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(compact ? AppSizes.p16 : AppSizes.p24),
            decoration: BoxDecoration(
              color: context.appColorScheme.elevatedSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: compact ? 32.0.w : 48.0.w,
              color: context.appColorScheme.textMuted,
            ),
          ),
          Gap.h16,
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.headingSm.copyWith(fontWeight: FontWeight.w800),
          ),
          Gap.h8,
          Text(
            description,
            textAlign: TextAlign.center,
            style: context.body.copyWith(
              color: context.appColorScheme.textSecondary,
              height: 1.4,
            ),
          ),
          if (actionLabel != null && onActionPressed != null) ...[
            Gap.h20,
            GutButton(
              label: actionLabel!,
              onTap: onActionPressed!,
            ),
          ],
        ],
      ),
    ),
  );
}
