import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/insight_theme.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_evidence_metric_row.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_feed/insight_ui_kit.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_next_step_check_row.dart';
import 'package:gutgood/features/insights/presentation/widgets/pattern_grid.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// Synergy & Pattern deep dive screen.
///
/// Matches the exact editorial design and compactness language of the Insights tab:
/// standard [GutSliverAppBar], compact theme bento cards, "What We Observed" banner,
/// "The Evidence" 4-stat metric dashboard, "Involved Foods" horizontal grid,
/// and supporting evidence summaries.

part 'synergy_detail_sections.dart';
part 'synergy_detail_helpers.dart';
part 'synergy_food_card.dart';



class SynergyDetailScreen extends StatelessWidget {
  const SynergyDetailScreen({super.key, this.insight, this.pattern});

  final AIInsight? insight;
  final BodyPattern? pattern;

  @override
  Widget build(BuildContext context) {
    final theme = context.insightTheme;
    final activeInsight = insight ?? _synergyLatestInsight(context);
    final activePattern = pattern ?? activeInsight?.detectedPatterns.firstOrNull;

    final evidenceRef = activeInsight?.evidence?.patternRefs.firstOrNull;
    final evidenceRatio = activePattern != null && (activePattern.evidenceRatio > 0 || activePattern.positiveCount + activePattern.negativeCount > 0)
        ? (activePattern.evidenceRatio.clamp(0.0, 1.0) * 100).round()
        : activeInsight?.topInsight?.evidenceRatio != null
        ? (activeInsight!.topInsight!.evidenceRatio!.clamp(0.0, 1.0) * 100).round()
        : evidenceRef == null
        ? null
        : (evidenceRef.evidenceRatio.clamp(0.0, 1.0) * 100).round();
    final frequencyCount = activePattern?.frequency ?? activeInsight?.topInsight?.frequency;
    final positiveCount =
        activePattern?.positiveCount ??
        activeInsight?.topInsight?.positiveCount;
    final negativeCount =
        activePattern?.negativeCount ??
        activeInsight?.topInsight?.negativeCount;

    return Scaffold(
      backgroundColor: theme.scaffold,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Standard GutSliverAppBar
          GutSliverAppBar(
            title: activePattern?.type != null ? '${patternName(activePattern!.type).toUpperCase()} PATTERN' : 'GUT INSIGHT',
            centerTitle: true,
            showBrandingIcon: false,
            backgroundColor: theme.scaffold,
          ),

          // --- Body Content --------------------------------------------------
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 4.w, 16.w, 24.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. HERO PATTERN CARD
                _buildHeroCard(context, activePattern, activeInsight),
                Gap.h10,

                // 2. WHAT WE OBSERVED CARD
                _buildWhatWeObservedCard(context, activePattern, activeInsight),
                Gap.h10,

                // 3. THE EVIDENCE DASHBOARD
                _buildTheEvidenceCard(
                  context,
                  patternType: activePattern?.type ?? 'digestion',
                  evidenceRatio: evidenceRatio,
                  frequency: frequencyCount,
                  positive: positiveCount,
                  negative: negativeCount,
                ),
                Gap.h10,

                // 4. INVOLVED FOODS SECTION
                _buildInvolvedFoodsSection(context, activePattern, activeInsight),
                Gap.h10,

                // 5. SPLIT GRID: YOUR NEXT STEPS & SUPPORTING EVIDENCE
                _buildSplitGridSection(context, activeInsight),
                Gap.h12,
              ]),
            ),
          ),
        ],
      ),
    );
  }

}
