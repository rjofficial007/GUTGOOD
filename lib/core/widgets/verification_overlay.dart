import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_assets.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/utils/responsive.dart';

import '../theme/app_text_styles.dart';

class VerificationOverlay extends StatelessWidget {
  const VerificationOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final appStateService = sl<AppStateService>();
    return ListenableBuilder(
      listenable: Listenable.merge([appStateService.isVerifyingAuth, appStateService.isLoggingOut, appStateService.isRestoringPurchases, appStateService.isMigrating]),
      builder: (context, child) {
        final bool isVerifying = appStateService.isVerifyingAuth.value;
        final bool isLoggingOut = appStateService.isLoggingOut.value;
        final bool isRestoring = appStateService.isRestoringPurchases.value;
        final bool isMigrating = appStateService.isMigrating.value;

        if (!isVerifying && !isLoggingOut && !isRestoring && !isMigrating) return const SizedBox.shrink();

        String title;
        String subtitle;

        if (isLoggingOut) {
          title = AppStrings.loggingOut;
          subtitle = AppStrings.clearingGutData;
        } else if (isMigrating) {
          title = AppStrings.migratingData;
          subtitle = AppStrings.almostThere;
        } else if (isRestoring) {
          title = AppStrings.restoringPurchasesStatus;
          subtitle = AppStrings.restoringPurchasesSubtitle;
        } else {
          title = AppStrings.verifyingSignIn;
          subtitle = AppStrings.spillingGutTea;
        }
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // 1. Backdrop Blur
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: context.appColorScheme.cardBackground.withValues(alpha: 0.8)),
                ),
              ),

              // 2. Content
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated Logo Scale
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.8, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(scale: value, child: child);
                      },
                      child: Container(
                        width: 100.0.w,
                        height: 100.0.w,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppSizes.r24),
                          boxShadow: [BoxShadow(color: context.appColorScheme.textPrimary.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 5)],
                        ),
                        child: ClipRRect(borderRadius: BorderRadius.circular(AppSizes.r24), child: Image.asset(AppAssets.appIcon)),
                      ),
                    ),
                    Gap.h32,

                    // Status Text
                    Text(
                      title,
                      style: context.h1.copyWith(fontSize: 20.0.sp, fontWeight: FontWeight.w900),
                    ),
                    Gap.h12,
                    Text(subtitle, style: context.body.copyWith(color: context.appColorScheme.textSecondary)),
                    Gap.h40,

                    // Spinner
                    SizedBox(
                      width: 24.0.w,
                      height: 24.0.w,
                      child: CircularProgressIndicator(strokeWidth: 3, color: context.appColorScheme.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
