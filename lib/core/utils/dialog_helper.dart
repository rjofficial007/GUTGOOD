import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/bottom_sheet_helper.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_button.dart';

class DialogHelper {
  const DialogHelper._();

  static Future<bool?> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = AppStrings.confirm,
    String cancelLabel = AppStrings.cancel,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.appColorScheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r24)),
        title: Text(title, style: context.bodyBold.copyWith(fontSize: 18.0.sp)),
        content: Text(message, style: context.body.copyWith(color: context.appColorScheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(cancelLabel, style: context.bodyBold.copyWith(color: context.appColorScheme.textMuted)),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            style: TextButton.styleFrom(foregroundColor: context.appColorScheme.textPrimary),
            child: Text(confirmLabel, style: context.bodyBold),
          ),
        ],
      ),
    );
  }

  static void showActionSheet({
    required BuildContext context,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
    IconData? icon,
    Color? iconColor,
    bool isDestructive = false,
    String? secondaryActionLabel,
    VoidCallback? onSecondaryAction,
  }) {
    final effectiveIconColor = iconColor ?? Theme.of(context).colorScheme.primary;

    BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: title,
      children: [
        if (icon != null) ...[
          Container(
            padding: EdgeInsets.all(AppSizes.p16),
            decoration: BoxDecoration(color: context.appColorScheme.border.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Icon(icon, color: context.appColorScheme.textPrimary, size: 28.0.w),
          ),
          Gap.h24,
        ],
        Text(
          message,
          textAlign: TextAlign.center,
          style: context.body.copyWith(color: context.appColorScheme.textSecondary),
        ),
        Gap.h32,
        if (secondaryActionLabel != null) ...[
          GutButton(
            label: secondaryActionLabel,
            onTap: () {
              context.pop();
              onSecondaryAction?.call();
            },
          ),
          Gap.h12,
        ],
        GutButton(
          label: actionLabel,
          isOutlined: secondaryActionLabel != null,
          onTap: () {
            context.pop();
            onAction();
          },
        ),
        Gap.h12,
        if (secondaryActionLabel == null) GutButton(label: AppStrings.cancel, isOutlined: true, onTap: () => context.pop()),
        Gap.h24,
      ],
    );
  }
}
