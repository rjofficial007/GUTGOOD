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
import 'package:gutgood/core/widgets/widgets.dart';

import '../../../../core/utils/haptic_helper.dart';

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
    _progressController = AnimationController(vsync: this, duration: const Duration(seconds: 4));
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

    // Cycle text every 1.2 seconds
    _textTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
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
  Widget build(BuildContext context) {
    return Scaffold(
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
            Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_progressAnimation, _pulseAnimation, _rotationAnimation, _beamAnimation]),
                builder: (context, child) {
                  return Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // 1. Rotating Outer Decorative Ring
                          Transform.rotate(
                            angle: _rotationAnimation.value,
                            child: CustomPaint(
                              size: const Size(220, 220),
                              painter: _DashedCirclePainter(color: context.appColorScheme.border.withValues(alpha: 0.5)),
                            ),
                          ),

                          // 2. Primary Progress Ring
                          SizedBox(
                            width: 180,
                            height: 180,
                            child: CircularProgressIndicator(
                              value: _progressAnimation.value,
                              strokeWidth: 10,
                              backgroundColor: context.appColorScheme.border.withValues(alpha: 0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(context.appColorScheme.textPrimary),
                              strokeCap: StrokeCap.round,
                            ),
                          ),

                          // 3. Central Pulse Area
                          ScaleTransition(
                            scale: _pulseAnimation,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(color: context.appColorScheme.border.withValues(alpha: 0.3), shape: BoxShape.circle),
                              child: Icon(AppIcons.barcode, size: AppSizes.icon40, color: context.appColorScheme.textPrimary),
                            ),
                          ),

                          // 4. Scanning Beam Effect
                          Positioned(
                            top: 90 + (90 * _beamAnimation.value),
                            child: Container(
                              width: 160,
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [context.appColorScheme.textPrimary.withValues(alpha: 0), context.appColorScheme.textPrimary, context.appColorScheme.textPrimary.withValues(alpha: 0)],
                                ),
                                boxShadow: [BoxShadow(color: context.appColorScheme.textPrimary.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Gap.h48,
                      // Percentage Counter
                      Text(
                        '${(_progressAnimation.value * 100).toInt()}%',
                        style: context.headingLg.copyWith(fontSize: AppSizes.s40, fontWeight: FontWeight.w900, color: context.appColorScheme.textPrimary),
                      ),
                      Gap.h8,
                      // Narrative Loading Text
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Text(
                          _loadingTexts[_loadingTextIndex],
                          key: ValueKey(_loadingTextIndex),
                          style: context.body.copyWith(color: context.appColorScheme.textSecondary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const Spacer(),
            // Tip Container
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.p24, vertical: AppSizes.p40),
              child: Container(
                padding: EdgeInsets.all(AppSizes.p20),
                decoration: BoxDecoration(
                  color: context.appColorScheme.elevatedSurface,
                  border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(AppSizes.r24),
                  boxShadow: [BoxShadow(color: AppPalette.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: context.appColorScheme.border.withValues(alpha: 0.3), shape: BoxShape.circle),
                      child: Icon(AppIcons.lightbulb, color: context.appColorScheme.textPrimary, size: AppSizes.icon20),
                    ),
                    Gap.w16,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppStrings.tip, style: context.title.copyWith(fontSize: AppSizes.s15, fontWeight: FontWeight.w800)),
                          Gap.h4,
                          Text(AppStrings.barcodeTip, style: context.bodySm.copyWith(color: context.appColorScheme.textSecondary, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const double dashWidth = 5;
    const double dashSpace = 5;
    final double radius = size.width / 2;
    final double circumference = 2 * math.pi * radius;
    final int dashCount = (circumference / (dashWidth + dashSpace)).floor();

    for (int i = 0; i < dashCount; i++) {
      final double startAngle = (i * (dashWidth + dashSpace)) / radius;
      canvas.drawArc(Rect.fromCircle(center: Offset(radius, radius), radius: radius), startAngle, dashWidth / radius, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
