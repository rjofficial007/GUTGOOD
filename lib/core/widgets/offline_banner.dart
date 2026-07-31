import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/services/internet_connection_checker.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/utils/responsive.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: sl<InternetConnectionChecker>().isInternetAvailable,
      builder: (context, isAvailable, child) {
        if (isAvailable) return const SizedBox.shrink();

        return Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            color: context.appColorScheme.error,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + AppSizes.p4, bottom: AppSizes.p4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off_rounded, color: Colors.white, size: 14.0.w),
                Gap.w8,
                Text(
                  AppStrings.noInternetConnection.toUpperCase(),
                  style: TextStyle(color: Colors.white, fontSize: 10.0.sp, fontWeight: FontWeight.w900, letterSpacing: 1.0, decoration: TextDecoration.none),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
