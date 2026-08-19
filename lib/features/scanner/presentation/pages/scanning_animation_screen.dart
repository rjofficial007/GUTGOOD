import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/haptic_helper.dart';
import 'package:gutgood/core/widgets/widgets.dart';

class ScanningAnimationScreen extends StatefulWidget {
  const ScanningAnimationScreen({super.key});

  @override
  State<ScanningAnimationScreen> createState() => _ScanningAnimationScreenState();
}

class _ScanningAnimationScreenState extends State<ScanningAnimationScreen> with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _beamController;

  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _beamAnimation;

  int _loadingTextIndex = 0;
  final List<String> _loadingTexts = [
    AppStrings.loadingInitializingVision,
    AppStrings.loadingReadingIngredients,
    AppStrings.loadingIdentifyingTriggers,
    AppStrings.loadingMatchingGoals,
    AppStrings.loadingSynthesizingInsights,
  ];
  Timer? _textTimer;

  @override
  void initState() {
    super.initState();

    // 1. Progress Controller (0 to ~98% for simulated activity)
    _progressController = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _progressAnimation = Tween<double>(begin: 0.0, end: 0.98).animate(CurvedAnimation(parent: _progressController, curve: Curves.easeInOutSine));

    // 2. Pulse Controller (Subtle heartbeat)
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    // 3. Rotation Controller (Mechanical outer ring)
    _rotationController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _rotationAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(_rotationController);

    // 4. Beam Controller (Scanning laser)
    _beamController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _beamAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(CurvedAnimation(parent: _beamController, curve: Curves.easeInOut));

    _progressController.forward();

    // Cycle text every 0.8 seconds
    _textTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (mounted) {
        setState(() {
          _loadingTextIndex = (_loadingTextIndex + 1) % _loadingTexts.length;
        });
        if (_loadingTextIndex == 2) HapticHelper.light();
      }
    });

    _progressController.addListener(() {
      if (_progressController.value > 0.5 && _progressController.value < 0.52) {
        HapticHelper.medium();
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    _beamController.dispose();
    _textTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.appColorScheme.cardBackground,
    appBar: GutAppBar(
      backgroundColor: AppPalette.transparent,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: Icon(AppIcons.x, color: context.appColorScheme.textPrimary),
          onPressed: () => context.pop(),
        ),
      ],
    ),
    body: SafeArea(
      child: Column(
        children: [
          Gap.h20,
          Text(AppStrings.scanning, style: context.headingMd.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const Spacer(),
          _AnimationStack(
            progressAnimation: _progressAnimation,
            rotationAnimation: _rotationAnimation,
            pulseAnimation: _pulseAnimation,
            beamAnimation: _beamAnimation,
            loadingText: _loadingTexts[_loadingTextIndex],
          ),
          const Spacer(),
        ],
      ),
    ),
  );
}

class _AnimationStack extends StatelessWidget {
  const _AnimationStack({required this.progressAnimation, required this.rotationAnimation, required this.pulseAnimation, required this.beamAnimation, required this.loadingText});

  final Animation<double> progressAnimation;
  final Animation<double> rotationAnimation;
  final Animation<double> pulseAnimation;
  final Animation<double> beamAnimation;
  final String loadingText;

  @override
  Widget build(BuildContext context) => Center(
    child: AnimatedBuilder(
      animation: Listenable.merge([progressAnimation, pulseAnimation, rotationAnimation, beamAnimation]),
      builder: (context, child) => Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              _RotatingDecorativeRing(angle: rotationAnimation.value),
              _ProgressRing(value: progressAnimation.value),
              _PulseIcon(animation: pulseAnimation),
              _ScanningBeam(beamOffset: beamAnimation.value),
            ],
          ),
          Gap.h48,
          _PercentageCounter(value: progressAnimation.value),
          Gap.h8,
          _StatusText(text: loadingText),
        ],
      ),
    ),
  );
}

class _RotatingDecorativeRing extends StatelessWidget {
  const _RotatingDecorativeRing({required this.angle});
  final double angle;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: angle,
    child: CustomPaint(
      size: const Size(220, 220),
      painter: _DashedCirclePainter(color: context.appColorScheme.border.withValues(alpha: 0.5)),
    ),
  );
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 180,
    height: 180,
    child: CircularProgressIndicator(
      value: value,
      strokeWidth: 10,
      backgroundColor: context.appColorScheme.border.withValues(alpha: 0.3),
      valueColor: AlwaysStoppedAnimation<Color>(context.appColorScheme.textPrimary),
      strokeCap: StrokeCap.round,
    ),
  );
}

class _PulseIcon extends StatelessWidget {
  const _PulseIcon({required this.animation});
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: animation,
    child: Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(color: context.appColorScheme.border.withValues(alpha: 0.3), shape: BoxShape.circle),
      child: Icon(AppIcons.barcode, size: AppSizes.icon40, color: context.appColorScheme.textPrimary),
    ),
  );
}

class _ScanningBeam extends StatelessWidget {
  const _ScanningBeam({required this.beamOffset});
  final double beamOffset;

  @override
  Widget build(BuildContext context) => Positioned(
    top: 90 + (90 * beamOffset),
    child: Container(
      width: 160,
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [context.appColorScheme.textPrimary.withValues(alpha: 0), context.appColorScheme.textPrimary, context.appColorScheme.textPrimary.withValues(alpha: 0)]),
        boxShadow: [BoxShadow(color: context.appColorScheme.textPrimary.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)],
      ),
    ),
  );
}

class _PercentageCounter extends StatelessWidget {
  const _PercentageCounter({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) => Text(
    '${(value * 100).toInt()}%',
    style: context.headingLg.copyWith(fontSize: AppSizes.s40, fontWeight: FontWeight.w900, color: context.appColorScheme.textPrimary),
  );
}

class _StatusText extends StatelessWidget {
  const _StatusText({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 400),
    child: Text(
      text,
      key: ValueKey(text),
      style: context.body.copyWith(color: context.appColorScheme.textSecondary, fontWeight: FontWeight.w600),
    ),
  );
}

class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const double dashWidth = 5;
    const double dashSpace = 5;
    final radius = size.width / 2;
    final circumference = 2 * math.pi * radius;
    final dashCount = (circumference / (dashWidth + dashSpace)).floor();

    for (var i = 0; i < dashCount; i++) {
      final startAngle = (i * (dashWidth + dashSpace)) / radius;
      canvas.drawArc(Rect.fromCircle(center: Offset(radius, radius), radius: radius), startAngle, dashWidth / radius, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
