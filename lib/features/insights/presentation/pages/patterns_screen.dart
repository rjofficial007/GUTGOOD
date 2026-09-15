import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/arc_pattern_card.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/bento_widgets.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/pattern_style.dart';
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
    final dark = PatternSurface.isDark(context);
    return Scaffold(
      backgroundColor: dark ? const Color(0xFF0B0C0E) : const Color(0xFFFDF6FA),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            // Gallery lavender wash; in dark the same wash over the bento base.
            colors: dark ? const [Color(0xFF1A162A), Color(0xFF14121E), Color(0xFF100F17)] : const [Color(0xFFFDF6FA), Color(0xFFF4EDFA), Color(0xFFEFE6F6)],
            stops: const [0.0, 0.6, 1.0],
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
                        if (patterns.isNotEmpty) ...[PatternCarouselWidget(patterns: patterns), Gap.h20],
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
    foregroundColor: PatternSurface.isDark(context) ? const Color(0xFFF5F7FA) : const Color(0xFF171A2E),
    showBrandingIcon: false,
    actions: [
      IconButton(icon: const Icon(AppIcons.more), onPressed: () {}, color: PatternSurface.muted(context)),
      Gap.w8,
    ],
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
        style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.sp, color: PatternSurface.faint(context)),
      ),
    ),
  );
}
