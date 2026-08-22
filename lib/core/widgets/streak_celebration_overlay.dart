import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gutgood/core/constants/app_assets.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/widgets/gut_button.dart';
import 'package:lottie/lottie.dart';

class StreakCelebrationOverlay extends StatefulWidget {
  const StreakCelebrationOverlay({super.key, required this.streak, required this.onDismiss});
  final int streak;
  final VoidCallback onDismiss;

  @override
  State<StreakCelebrationOverlay> createState() => _StreakCelebrationOverlayState();
}

class _StreakCelebrationOverlayState extends State<StreakCelebrationOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _lottieController;
  Timer? _lottieTimer;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    _lottieController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _lottieController.repeat(min: 0.58, max: 1.0, reverse: false);
      }
    });

    // Match StreakCard's timing for starting the animation
    _lottieTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        _lottieController.forward();
      }
    });
  }

  @override
  void dispose() {
    _lottieController.dispose();
    _lottieTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;

    return Material(
      color: colorScheme.cardBackground,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.p32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Spacer(),
              // Animated Flame Icon - Same logic as StreakCard
              Lottie.asset(
                AppAssets.streakAnimation,
                height: AppSizes.p120,
                width: AppSizes.p120,
                controller: _lottieController,
                onLoaded: (composition) {
                  _lottieController.duration = composition.duration;
                  _lottieController.forward(from: 50 / composition.endFrame);
                },
              ),

              Gap.h32,

              Text(
                AppStrings.streakUp,
                style: context.eyebrow.copyWith(color: AppPalette.orange, fontSize: AppSizes.s20, fontWeight: FontWeight.w900, letterSpacing: 4.0),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

              Gap.h16,

              Text(
                '${widget.streak}',
                style: context.h1.copyWith(color: colorScheme.textPrimary, fontSize: AppSizes.s120, fontWeight: FontWeight.w900, height: 1.0),
              ).animate().scale(delay: 400.ms, duration: 500.ms, curve: Curves.elasticOut),

              Text(
                AppStrings.daysInARow,
                style: context.bodyBold.copyWith(color: colorScheme.textSecondary, fontSize: AppSizes.s16, letterSpacing: 2.0),
              ).animate().fadeIn(delay: 600.ms),

              Gap.h48,

              Text(
                AppStrings.streakQuote,
                textAlign: TextAlign.center,
                style: context.body.copyWith(color: colorScheme.textPrimary, fontSize: AppSizes.s16, height: 1.5),
              ).animate().fadeIn(delay: 800.ms),

              Gap.h48,
              const Spacer(),

              GutButton(label: AppStrings.continueAction, onTap: widget.onDismiss).animate().fadeIn(delay: 1000.ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
            ],
          ),
        ),
      ),
    );
  }
}
