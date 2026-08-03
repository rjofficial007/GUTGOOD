import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_button.dart';
import 'package:lottie/lottie.dart';

class StreakCelebrationOverlay extends StatelessWidget {
  final int streak;
  final VoidCallback onDismiss;

  const StreakCelebrationOverlay({super.key, required this.streak, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.p32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Flame Icon
              Lottie.asset('assets/animations/streak.json', height: 100.0.w),

              // Icon(AppIcons.flame, color: AppPalette.orange, size: 100.0.w)
              //     .animate(onPlay: (controller) => controller.repeat(reverse: true))
              //     .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 600.ms, curve: Curves.easeInOut)
              //     .shimmer(delay: 400.ms, duration: 1800.ms, color: Colors.white.withValues(alpha: 0.5)),
              Gap.h32,

              Text(
                'STREAK UP!',
                style: context.eyebrow.copyWith(color: AppPalette.orange, fontSize: AppSizes.s20, fontWeight: FontWeight.w900, letterSpacing: 4.0),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

              Gap.h16,

              Text(
                '$streak',
                style: context.h1.copyWith(color: Colors.white, fontSize: 120.0.sp, fontWeight: FontWeight.w900, height: 1.0),
              ).animate().scale(delay: 400.ms, duration: 500.ms, curve: Curves.elasticOut),

              Text(
                'DAYS IN A ROW',
                style: context.bodyBold.copyWith(color: Colors.white70, fontSize: AppSizes.s16, letterSpacing: 2.0),
              ).animate().fadeIn(delay: 600.ms),

              Gap.h48,

              Text(
                'You\'re building a healthy habit, one day at a time. Keep it up!',
                textAlign: TextAlign.center,
                style: context.body.copyWith(color: Colors.white, fontSize: AppSizes.s16, height: 1.5),
              ).animate().fadeIn(delay: 800.ms),

              Gap.h48,

              GutButton(label: 'CONTINUE', onTap: onDismiss).animate().fadeIn(delay: 1000.ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
            ],
          ),
        ),
      ),
    );
  }
}
