import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/widgets.dart';

class AIPersonalizationOnboardingPage extends StatefulWidget {
  const AIPersonalizationOnboardingPage({super.key, required this.onFinish, this.isLoading = false});
  final VoidCallback onFinish;
  final bool isLoading;

  @override
  State<AIPersonalizationOnboardingPage> createState() => _AIPersonalizationOnboardingPageState();
}

class _AIPersonalizationOnboardingPageState extends State<AIPersonalizationOnboardingPage> {
  bool _isAnalyzing = true;
  bool _isSuccess = false;
  int _statusIndex = 0;

  final List<String> _statusMessages = [
    AppStrings.statusScanningGoals,
    AppStrings.statusCheckingSensitivities,
    AppStrings.statusAnalyzingLifestyle,
    AppStrings.statusOptimizing,
    AppStrings.statusPersonalizingGutGood,
    AppStrings.statusAlmostReady,
  ];

  @override
  void initState() {
    super.initState();
    _startAnalysis();
  }

  void _startAnalysis() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted && _isAnalyzing) {
        setState(() {
          _statusIndex = (_statusIndex + 1) % _statusMessages.length;
        });
        return true;
      }
      return false;
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _isSuccess = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: AppSizes.p24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Gap.h16,
        // Persistent Header
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isSuccess ? AppStrings.analysisComplete : AppStrings.builtAroundYou, style: context.displaySm),
            Gap.h10,
            Text(_isSuccess ? AppStrings.gutTeaReady : AppStrings.aiPersonalizationDesc, style: context.bodyLg.copyWith(color: context.appColorScheme.textSecondary)),
          ],
        ).animate().fadeIn(duration: 400.ms),

        // Main Center Area
        Expanded(child: Center(child: _isAnalyzing ? _buildHeroFlipText() : _buildMinimalSuccessIcon())),

        // Bottom Button
        if (_isSuccess)
          Padding(
            padding: EdgeInsets.only(bottom: AppSizes.p20),
            child: GutButton(label: AppStrings.continueButton, suffixIcon: AppIcons.arrowRight, onTap: widget.onFinish, isLoading: widget.isLoading),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0)
        else
          Gap.h32, // Reserved space for button
      ],
    ),
  );

  Widget _buildHeroFlipText() => Padding(
    padding: EdgeInsets.only(bottom: AppSizes.p100),
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeInBack,
      transitionBuilder: (child, animation) {
        final rotate = Tween<double>(begin: math.pi / 2, end: 0.0).animate(animation);
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
        _statusMessages[_statusIndex],
        key: ValueKey<int>(_statusIndex),
        textAlign: TextAlign.center,
        style: context.displayLg.copyWith(fontSize: 50.0.sp, fontWeight: FontWeight.w900, letterSpacing: -2.5, height: 1.0, color: context.appColorScheme.textPrimary),
      ),
    ),
  );

  Widget _buildMinimalSuccessIcon() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: AppSizes.p120,
        height: AppSizes.p120,
        decoration: BoxDecoration(shape: BoxShape.circle, color: context.appColorScheme.textPrimary),
        child: Icon(AppIcons.check, color: context.appColorScheme.cardBackground, size: AppSizes.icon60),
      ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
      Gap.h32,
      Text(AppStrings.labelReady, style: context.displayMd.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1)).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
    ],
  );
}
