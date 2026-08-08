import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_assets.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/features/scanner/domain/models/scanner_mode.dart';

class PermissionOverlay extends StatelessWidget {
  const PermissionOverlay({super.key, required this.onRequestPermission});
  final VoidCallback onRequestPermission;

  @override
  Widget build(BuildContext context) => Container(
    color: AppPalette.black.withValues(alpha: 0.8),
    child: Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSizes.p40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.r20),
              child: Image.asset(
                AppAssets.appIcon,
                height: AppSizes.p100,
                width: AppSizes.p100,
              ),
            ),
            Gap.h32,
            Text(
              AppStrings.allowCameraAccess,
              textAlign: TextAlign.center,
              style: AppTextStyles.headingMd.copyWith(
                color: AppPalette.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Gap.h16,
            Text(
              AppStrings.cameraAccessSubtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppPalette.white70,
                height: 1.4,
              ),
            ),
            Gap.h32,
            GestureDetector(
              onTap: onRequestPermission,
              child: Text(
                AppStrings.openSettings,
                style: context.bodyBold.copyWith(
                  color: AppPalette.blueLink,
                  fontSize: AppSizes.s16,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class ModeIntroOverlay extends StatelessWidget {
  const ModeIntroOverlay({
    super.key,
    required this.currentMode,
    required this.modes,
  });
  final ScannerMode currentMode;
  final List<ScannerModeOption> modes;

  @override
  Widget build(BuildContext context) {
    final label = modes
        .firstWhere((m) => m.mode == currentMode)
        .label
        .toUpperCase();

    return Center(
      child: IgnorePointer(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 800),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeInBack,
          transitionBuilder: (child, animation) {
            final rotate = Tween<double>(
              begin: math.pi / 2,
              end: 0.0,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: AnimatedBuilder(
                animation: rotate,
                builder: (context, child) => Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0015)
                    ..rotateX(rotate.value),
                  alignment: Alignment.center,
                  child: child,
                ),
                child: child,
              ),
            );
          },
          child: Text(
            label,
            key: ValueKey<String>('intro-$currentMode-$label'),
            textAlign: TextAlign.center,
            style: context.displayLg.copyWith(
              fontSize: 50.0.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: -2.5,
              height: 1.0,
              color: AppPalette.white,
              shadows: [
                Shadow(
                  color: AppPalette.black.withValues(alpha: 0.6),
                  blurRadius: 30,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
