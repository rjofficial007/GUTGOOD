import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/widgets.dart';

import '../constants/app_sizes.dart';

class BottomSheetHelper {
  const BottomSheetHelper._();

  static Future<T?> showGutBottomSheet<T>({
    required BuildContext context,
    required String title,
    required List<Widget> children,
    EdgeInsets? padding,
    Widget? footer,
    bool isScrollControlled = true,
    Color? backgroundColor,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: backgroundColor ?? Colors.transparent,
      builder: (context) => GutSheetWrapper(
        footer: footer,
        padding: padding,
        children: [
          GutSheetHeader(title: title),
          ...children,
        ],
      ),
    );
  }

  static Future<TimeOfDay?> showTimePickerSheet({
    required BuildContext context,
    required String title,
    required TimeOfDay initialTime,
    Color? backgroundColor,
  }) async {
    TimeOfDay selectedTime = initialTime;

    return showGutBottomSheet<TimeOfDay>(
      context: context,
      title: title,
      backgroundColor: backgroundColor,
      children: [
        SizedBox(
          height: 200,
          child: CupertinoTheme(
            data: CupertinoThemeData(
              textTheme: CupertinoTextThemeData(
                dateTimePickerTextStyle: context.bodyBold.copyWith(
                  fontSize: 22.sp,
                  color: context.appColorScheme.textPrimary,
                ),
              ),
            ),
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              initialDateTime: DateTime(2026, 1, 1, initialTime.hour, initialTime.minute),
              onDateTimeChanged: (DateTime newDateTime) {
                selectedTime = TimeOfDay(hour: newDateTime.hour, minute: newDateTime.minute);
              },
            ),
          ),
        ),
        Gap.h32,
        GutButton(
          label: AppStrings.confirm,
          onTap: () => context.pop(selectedTime),
        ),
        Gap.h12,
        GutButton(
          label: AppStrings.cancel,
          isOutlined: true,
          onTap: () => context.pop(),
        ),
        Gap.h24,
      ],
    );
  }

  static void showInfoSheet({
    required BuildContext context,
    required String title,
    required String message,
    String? headerLabel,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appColorScheme.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GutSheetHeader(title: title),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.p24),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(Responsive.w(16.0)),
                  decoration: BoxDecoration(color: context.appColorScheme.border.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: Icon(AppIcons.info, color: context.appColorScheme.textPrimary, size: 32.0.w),
                ),
                Gap.h24,
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: context.body.copyWith(color: context.appColorScheme.textSecondary, height: 1.5),
                ),
                Gap.h40,
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 16.0.h),
            decoration: BoxDecoration(color: context.appColorScheme.textPrimary),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(AppIcons.sparkles, size: 14, color: context.appColorScheme.cardBackground),
                Gap.w8,
                Text(
                  headerLabel ?? AppStrings.gutgoodHealthIntelligence,
                  style: context.caption.copyWith(color: context.appColorScheme.cardBackground, fontWeight: FontWeight.w900, fontSize: 10.0.sp, letterSpacing: 1.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void showLogoutSheet({
    required BuildContext context,
    required bool isAnonymous,
    required VoidCallback onConfirm,
  }) {
    showGutBottomSheet(
      context: context,
      title: AppStrings.logout,
      children: [
        Container(
          padding: EdgeInsets.all(Responsive.w(16.0)),
          decoration: BoxDecoration(color: context.appColorScheme.border.withValues(alpha: 0.2), shape: BoxShape.circle),
          child: Icon(AppIcons.alertTriangle, color: context.appColorScheme.textPrimary, size: 32.0.w),
        ),
        Gap.h20,
        Text(
          isAnonymous ? AppStrings.logoutGuestWarning : AppStrings.logoutConfirmMessage,
          textAlign: TextAlign.center,
          style: context.body.copyWith(color: context.appColorScheme.textSecondary, height: 1.5),
        ),
        Gap.h32,
        GutButton(
          label: AppStrings.logoutAnyway,
          onTap: () {
            context.pop();
            onConfirm();
          },
        ),
        Gap.h12,
        GutButton(
          label: AppStrings.cancel,
          isOutlined: true,
          onTap: () => context.pop(),
        ),
        Gap.h24,
      ],
    );
  }

  static void showDeleteAccountSheet({
    required BuildContext context,
    required VoidCallback onConfirm,
  }) {
    showGutBottomSheet(
      context: context,
      title: AppStrings.deleteAccountTitle,
      children: [
        Container(
          padding: EdgeInsets.all(Responsive.w(16.0)),
          decoration: BoxDecoration(color: context.appColorScheme.border.withValues(alpha: 0.2), shape: BoxShape.circle),
          child: Icon(AppIcons.trash2, color: context.appColorScheme.textPrimary, size: 32.0.w),
        ),
        Gap.h20,
        Text(
          AppStrings.deleteAccountConfirm,
          textAlign: TextAlign.center,
          style: context.body.copyWith(color: context.appColorScheme.textSecondary, height: 1.5),
        ),
        Gap.h32,
        GutButton(
          label: AppStrings.deletePermanently,
          onTap: () {
            context.pop();
            onConfirm();
          },
        ),
        Gap.h12,
        GutButton(
          label: AppStrings.cancel,
          isOutlined: true,
          onTap: () => context.pop(),
        ),
        Gap.h24,
      ],
    );
  }

  static void showMedicalDisclaimer(BuildContext context) {
    showGutBottomSheet(
      context: context,
      title: AppStrings.medicalDisclaimer,
      children: [
        Text(
          AppStrings.medicalDisclaimerContent,
          style: context.body.copyWith(color: context.appColorScheme.textSecondary, height: 1.5),
        ),
        Gap.h32,
        GutButton(label: AppStrings.gotItThanks, onTap: () => context.pop()),
        Gap.h24,
      ],
    );
  }
}
