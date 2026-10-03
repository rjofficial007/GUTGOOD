import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/insight_theme.dart';
import 'package:gutgood/core/utils/insight_presentation.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_evidence_metric_row.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_feed/insight_ui_kit.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_feed/insights_copy.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_next_step_check_row.dart';
import 'package:gutgood/features/insights/presentation/widgets/occurrence_tile.dart';
import 'package:gutgood/features/insights/presentation/widgets/pattern_grid.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

// Top Insight Details — Synergy-style UI/UX presentation matching PatternDetailScreen.
//
// Features bento cards: Hero Insight Card with right angled food image,
// "What We Observed" banner, "The Evidence" 4-stat metric dashboard,
// "Involved Foods" horizontal grid, "Occurrences & Factors" timeline,
// "Related Patterns" section, and "Split Grid" section.

part 'smart_insight_detail_sections.dart';
part 'smart_insight_detail_helpers.dart';
part 'smart_insight_involved_food_tile.dart';



class SmartInsightDetailScreen extends StatelessWidget {
  const SmartInsightDetailScreen({super.key, required this.insight});

  final InsightSummary insight;

  List<BodyPattern> _relatedPatterns(BuildContext context) {
    List<BodyPattern> candidates;
    try {
      candidates = context.read<InsightsNotifier>().prioritizedPatterns;
    } on ProviderNotFoundException {
      return const [];
    }

    final foods = {for (final food in insight.involvedFoods) food.trim().toLowerCase()};
    final title = insight.title.trim().toLowerCase();
    return candidates.where((pattern) {
      final relatedNames = [...pattern.involvedFoods, pattern.trigger].map((name) => name.trim().toLowerCase()).where((name) => name.isNotEmpty);
      return relatedNames.any((name) => foods.contains(name) || (title.isNotEmpty && title.contains(name))) || (title.isNotEmpty && title.contains(pattern.type.toLowerCase()));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.insightTheme;

    final evidenceRatio = insight.evidenceRatio?.isFinite == true ? (insight.evidenceRatio!.clamp(0.0, 1.0) * 100).round() : null;
    final frequency = insight.frequency;
    final positiveCount = insight.positiveCount;
    final negativeCount = insight.negativeCount;

    return Scaffold(
      backgroundColor: theme.scaffold,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Standard GutSliverAppBar matching PatternDetailScreen
          GutSliverAppBar(title: 'TOP INSIGHT', centerTitle: true, showBrandingIcon: false, backgroundColor: theme.scaffold),

          // --- Body Content --------------------------------------------------
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 4.w, 16.w, 24.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. HERO PATTERN CARD
                _buildHeroCard(context),
                Gap.h10,

                // 2. WHAT WE OBSERVED CARD
                _buildWhatWeObservedCard(context),
                Gap.h10,

                // 3. THE EVIDENCE DASHBOARD
                _buildTheEvidenceCard(context, evidenceRatio: evidenceRatio, frequency: frequency, symptomLogs: positiveCount, normalLogs: negativeCount),
                Gap.h10,

                // 4. INVOLVED FOODS SECTION
                _buildInvolvedFoodsSection(context),
                Gap.h10,

                // 5. OCCURRENCES TIMELINE & COMMON FACTORS CARD
                _buildOccurrencesTimelineCard(context),
                Gap.h10,

                // 6. RELATED PATTERNS SECTION
                _buildRelatedPatternsSection(context),
                Gap.h10,

                // 7. SPLIT GRID: YOUR NEXT STEPS & SUPPORTING EVIDENCE
                _buildSplitGridSection(context),
                Gap.h12,
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
