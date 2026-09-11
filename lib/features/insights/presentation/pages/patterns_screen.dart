import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/bento_widgets.dart';
import 'package:gutgood/features/insights/presentation/widgets/pattern_grid.dart';
import 'package:provider/provider.dart';

/// The patterns gallery (phone adaptation from patterns.html).
///
/// A home for every detected [BodyPattern], each card deep-linking to the
/// [PatternDetailScreen].
class PatternsScreen extends StatelessWidget {
  const PatternsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6FA),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFDF6FA), Color(0xFFF4EDFA), Color(0xFFEFE6F6)],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: Consumer<InsightsNotifier>(
          builder: (context, notifier, _) {
            final patterns = notifier.prioritizedPatterns;
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _AppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 4.w, 16.w, 20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // _Header(),
                        // Gap.h14,
                        // _InfoPill(isSufficient: patterns.length >= 3),
                        Gap.h16,
                        PatternGrid(patterns: patterns),
                        const _PrivacyFooter(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GutSliverAppBar(
        title: AppStrings.observedPatterns,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF171A2E),
        showBrandingIcon: false,
        actions: [
          IconButton(
            icon: const Icon(AppIcons.more),
            onPressed: () {},
            color: const Color(0xFF5C6070),
          ),
          Gap.w8,
        ],
      );
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6),
              borderRadius: BorderRadius.circular(14.w),
            ),
            child: const Center(
              child: Icon(AppIcons.sparkles, color: Colors.white, size: 22),
            ),
          ),
          Gap.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.bentoPatternsHeadline,
                  style: TextStyle(
                    fontFamily: InsightBentoTheme.fontFamily,
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF171A2E),
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  AppStrings.bentoPatternsSub,
                  style: TextStyle(
                    fontFamily: InsightBentoTheme.fontFamily,
                    fontSize: 12.sp,
                    color: const Color(0xFF5C6070),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.isSufficient});
  final bool isSufficient;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.w),
        decoration: BoxDecoration(
          color: const Color(0xFFFBF7FD),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: const Color(0xFFF0E6F7)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(AppIcons.sparkles, size: 15, color: Color(0xFF8B5CF6)),
            Gap.w8,
            Text(
              isSufficient ? AppStrings.bentoPatternsAppear : AppStrings.bentoPatternsLearning,
              style: TextStyle(
                fontFamily: InsightBentoTheme.fontFamily,
                fontSize: 12.sp,
                color: const Color(0xFF4A4E5E),
              ),
            ),
          ],
        ),
      );
}

class _PrivacyFooter extends StatelessWidget {
  const _PrivacyFooter();

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: 24.w, bottom: 16.w),
        child: Center(
          child: Text(
            AppStrings.bentoPrivacyNote,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: InsightBentoTheme.fontFamily,
              fontSize: 11.sp,
              color: const Color(0xFF8A8E9E),
            ),
          ),
        ),
      );
}
