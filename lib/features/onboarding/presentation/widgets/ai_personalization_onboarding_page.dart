import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/widgets.dart';

class AIPersonalizationOnboardingPage extends StatefulWidget {
  final VoidCallback onFinish;

  const AIPersonalizationOnboardingPage({super.key, required this.onFinish});

  @override
  State<AIPersonalizationOnboardingPage> createState() => _AIPersonalizationOnboardingPageState();
}

class _AIPersonalizationOnboardingPageState extends State<AIPersonalizationOnboardingPage> with TickerProviderStateMixin {
  late AnimationController _aiController;
  late AnimationController _pulseController;

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
    _aiController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();

    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);

    _startAnalysis();
  }

  @override
  void dispose() {
    _aiController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startAnalysis() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 800));
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
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(AppSizes.p32),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - AppSizes.p64),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isAnalyzing) ...[
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _aiController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _aiController.value * 2 * 3.14159,
                              child: Container(
                                width: 140.0.w,
                                height: 140.0.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppPalette.black.withValues(alpha: 0.05), width: 1.0.w),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      top: 0,
                                      left: 60.0.w,
                                      child: Container(
                                        width: 8.0.w,
                                        height: 8.0.w,
                                        decoration: const BoxDecoration(color: AppPalette.black, shape: BoxShape.circle),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        ScaleTransition(
                          scale: Tween(begin: 1.0, end: 1.1).animate(_pulseController),
                          child: Container(
                            width: 80.0.w,
                            height: 80.0.w,
                            decoration: BoxDecoration(
                              color: AppPalette.black,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: AppPalette.black.withValues(alpha: 0.2), blurRadius: 20.0.w, spreadRadius: 5.0.w)],
                            ),
                            child: Icon(AppIcons.sparkles, color: AppPalette.white, size: 32.0.w),
                          ),
                        ),
                      ],
                    ),
                    Gap.h48,
                    Text(AppStrings.aiPersonalization, style: AppTextStyles.displaySm, textAlign: TextAlign.center),
                    Gap.h24,
                    Text(
                      AppStrings.aiPersonalizationDesc,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyLg.copyWith(color: context.appColorScheme.textSecondary, height: 1.4),
                    ),
                    Gap.h32,
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _statusMessages[_statusIndex],
                        key: ValueKey(_statusIndex),
                        style: AppTextStyles.bodyBold.copyWith(color: AppPalette.purple, fontSize: 16.0.sp),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ] else if (_isSuccess) ...[
                    const Spacer(),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        ScaleTransition(
                          scale: Tween(begin: 1.0, end: 1.05).animate(_pulseController),
                          child: Container(
                            width: 80.0.w,
                            height: 80.0.w,
                            decoration: BoxDecoration(
                              color: AppPalette.black,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: AppPalette.black.withValues(alpha: 0.3), blurRadius: 25.0.w, spreadRadius: 5.0.w)],
                            ),
                            child: Icon(AppIcons.check, color: AppPalette.white, size: 40.0.w),
                          ),
                        ),
                      ],
                    ),
                    Gap.h48,
                    Text(AppStrings.analysisComplete, style: AppTextStyles.displaySm, textAlign: TextAlign.center),
                    Gap.h16,
                    Text(
                      AppStrings.gutTeaReady,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyLg.copyWith(color: AppPalette.gray500),
                    ),
                    const Spacer(),
                    GutButton(label: AppStrings.continueButton, suffixIcon: AppIcons.arrowRight, onTap: widget.onFinish),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
