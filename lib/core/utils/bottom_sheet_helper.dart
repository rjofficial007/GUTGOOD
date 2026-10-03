import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/widgets.dart';

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
  }) => showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: backgroundColor ?? AppPalette.transparent,
    builder: (context) => GutSheetWrapper(
      footer: footer,
      padding: padding,
      children: [
        GutSheetHeader(title: title),
        ...children,
      ],
    ),
  );

  static Future<TimeOfDay?> showTimePickerSheet({required BuildContext context, required String title, required TimeOfDay initialTime, Color? backgroundColor}) async {
    var selectedTime = initialTime;

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
                dateTimePickerTextStyle: context.bodyBold.copyWith(fontSize: 22.sp, color: context.appColorScheme.textPrimary),
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
        GutButton(label: AppStrings.confirm, onTap: () => context.pop(selectedTime)),
        Gap.h12,
        GutButton(label: AppStrings.cancel, isOutlined: true, onTap: () => context.pop()),
        Gap.h24,
      ],
    );
  }

  static Future<void> showLogoutSheet({required BuildContext context, required bool isAnonymous, required VoidCallback onConfirm}) async {
    await showGutBottomSheet(
      context: context,
      title: AppStrings.logout,
      children: [
        Container(
          padding: EdgeInsets.all(Responsive.w(16.0)),
          decoration: BoxDecoration(color: context.appColorScheme.border.withAlpha(51), shape: BoxShape.circle),
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
        GutButton(label: AppStrings.cancel, isOutlined: true, onTap: () => context.pop()),
        Gap.h24,
      ],
    );
  }

  static Future<void> showDeleteAccountSheet({required BuildContext context, required VoidCallback onConfirm}) async {
    await showGutBottomSheet(
      context: context,
      title: AppStrings.deleteAccountTitle,
      children: [
        Container(
          padding: EdgeInsets.all(Responsive.w(16.0)),
          decoration: BoxDecoration(color: context.appColorScheme.border.withAlpha(51), shape: BoxShape.circle),
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
        GutButton(label: AppStrings.cancel, isOutlined: true, onTap: () => context.pop()),
        Gap.h24,
      ],
    );
  }

  /// Prompts the user to re-authenticate before a destructive operation
  /// (currently: account deletion) that Firebase has rejected with
  /// `requires-recent-login`.
  ///
  /// - When [isPasswordProvider] is true, collects a password and invokes
  ///   [onConfirmPassword] with it.
  /// - Otherwise (Google/Apple), shows a single "Sign In Again" button that
  ///   invokes [onConfirmProvider], which should re-run the native sign-in
  ///   flow for that provider.
  static Future<void> showReauthenticateSheet({
    required BuildContext context,
    required bool isPasswordProvider,
    Future<void> Function(String password)? onConfirmPassword,
    Future<void> Function()? onConfirmProvider,
  }) async {
    final passwordController = TextEditingController();

    await showGutBottomSheet(
      context: context,
      title: AppStrings.reauthenticateTitle,
      children: [
        Container(
          padding: EdgeInsets.all(Responsive.w(16.0)),
          decoration: BoxDecoration(color: context.appColorScheme.border.withAlpha(51), shape: BoxShape.circle),
          child: Icon(AppIcons.alertTriangle, color: context.appColorScheme.textPrimary, size: 32.0.w),
        ),
        Gap.h20,
        Text(
          isPasswordProvider ? AppStrings.reauthenticateMessage : AppStrings.reauthenticateSocialMessage,
          textAlign: TextAlign.center,
          style: context.body.copyWith(color: context.appColorScheme.textSecondary, height: 1.5),
        ),
        Gap.h24,
        if (isPasswordProvider) ...[
          GutTextField(controller: passwordController, hintText: AppStrings.passwordHint, obscureText: true, prefixIcon: AppIcons.lock),
          Gap.h20,
        ],
        GutButton(
          label: isPasswordProvider ? AppStrings.confirmAndDelete : AppStrings.signInAgain,
          onTap: () {
            context.pop();
            if (isPasswordProvider) {
              onConfirmPassword?.call(passwordController.text);
            } else {
              onConfirmProvider?.call();
            }
          },
        ),
        Gap.h12,
        GutButton(label: AppStrings.cancel, isOutlined: true, onTap: () => context.pop()),
        Gap.h24,
      ],
    );
  }

  static Future<void> showMedicalDisclaimer(BuildContext context) async {
    await showGutBottomSheet(
      context: context,
      title: AppStrings.medicalDisclaimer,
      children: [
        Text(AppStrings.medicalDisclaimerContent, style: context.body.copyWith(color: context.appColorScheme.textSecondary, height: 1.5)),
        Gap.h32,
        GutButton(label: AppStrings.gotItThanks, onTap: () => context.pop()),
        Gap.h24,
      ],
    );
  }
}
