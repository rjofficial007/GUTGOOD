import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/services/internet_connection_checker.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: sl<InternetConnectionChecker>().isInternetAvailable,
    builder: (context, isAvailable, child) {
      if (isAvailable) return const SizedBox.shrink();

      return Material(
        color: AppPalette.transparent,
        child: Container(
          width: double.infinity,
          color: context.appColorScheme.error,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + AppSizes.p4,
            bottom: AppSizes.p4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                color: AppPalette.white,
                size: AppSizes.icon14,
              ),
              Gap.w8,
              Text(
                AppStrings.noInternetConnection.toUpperCase(),
                style: context.eyebrow.copyWith(
                  color: AppPalette.white,
                  fontSize: AppSizes.s10,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
