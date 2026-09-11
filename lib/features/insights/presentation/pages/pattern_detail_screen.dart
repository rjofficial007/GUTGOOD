import 'package:flutter/material.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/utils/insight_ui_utils.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/insight_bento_screens.dart';

/// Pattern anatomy screen (v4 bento screen 05).
///
/// Keeps the standard [GutSliverAppBar]; the body is the bento grid: a
/// repeating-episode hero, the three tick-fan metrics, the biological root,
/// and the swap pair.
class PatternDetailScreen extends StatelessWidget {
  const PatternDetailScreen({super.key, required this.pattern});
  final BodyPattern pattern;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.appColorScheme.cardBackground,
    body: CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        GutSliverAppBar(
          title: InsightUiUtils.getPatternName(pattern.type).toUpperCase(),
          centerTitle: true,
          showBrandingIcon: false,
        ),
        InsightBentoPattern(pattern: pattern),
      ],
    ),
  );
}
