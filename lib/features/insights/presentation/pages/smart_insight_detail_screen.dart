import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/utils/insight_presentation.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_strings.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_theme.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/v2_kit.dart';
import 'package:provider/provider.dart';

/// Top Insight deep-dive — v2 presentation (extends mock screen 1's
/// `.card.top-insight` into a full page).
///
/// The AI's headline discovery: identity badges, the headline, the
/// observation, the evidence stat row (frequency / match / symptomatic),
/// involved foods, the action plan checklist, and related patterns.
class SmartInsightDetailScreen extends StatelessWidget {
  const SmartInsightDetailScreen({super.key, required this.insight});

  final InsightSummary insight;

  @override
  Widget build(BuildContext context) {
    final v2 = context.v2Theme;
    final patterns = context.read<InsightsNotifier>().prioritizedPatterns;

    final match = (insight.evidenceRatio != null && insight.evidenceRatio! > 0)
        ? '${(insight.evidenceRatio!.clamp(0.0, 1.0) * 100).round()}%'
        : '—';

    return Scaffold(
      backgroundColor: v2.scaffold,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          GutSliverAppBar(
            title: 'TOP INSIGHT',
            centerTitle: true,
            showBrandingIcon: false,
            backgroundColor: v2.scaffold,
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 4.w, 16.w, 32.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // --- Identity -------------------------------------------------
                Row(
                  children: [
                    const V2Badge(
                      InsightV2Strings.topInsightBadge,
                      tone: V2Tone.neutral,
                      size: 9,
                    ),
                    Gap.w6,
                    V2Pill(insight.type, size: 8.5),
                  ],
                ),
                Gap.h10,
                Text(
                  insight.title,
                  style: V2Kit.text(
                    context,
                    size: 21,
                    weight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                if (insight.description.isNotEmpty) ...[
                  Gap.h8,
                  Text(
                    insight.description,
                    style: V2Kit.text(
                      context,
                      size: 13,
                      color: v2.textSecondary,
                      height: 1.55,
                    ),
                  ),
                ],
                Gap.h14,

                // --- Evidence -------------------------------------------------
                V2Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const V2SectionLabel(InsightV2Strings.evidenceLabel),
                      Gap.h10,
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            V2Stat(
                              label: InsightV2Strings.frequencyLabel,
                              value: '${insight.frequency ?? 0}×',
                            ),
                            Gap.w8,
                            V2Stat(label: 'Match', value: match),
                            Gap.w8,
                            V2Stat(
                              label: 'Symptomatic',
                              value:
                                  '${insight.positiveCount ?? 0}/${(insight.positiveCount ?? 0) + (insight.negativeCount ?? 0)}',
                            ),
                          ],
                        ),
                      ),
                      if ((insight.observation ?? '').isNotEmpty) ...[
                        Gap.h12,
                        V2RecCard(
                          tone: V2Tone.purple,
                          emoji: '🔍',
                          richText: TextSpan(
                            children: [
                              TextSpan(
                                text: '${InsightV2Strings.observationLabel}: ',
                                style: V2Kit.text(
                                  context,
                                  size: 11.5,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(
                                text: insight.observation,
                                style: V2Kit.text(
                                  context,
                                  size: 11.5,
                                  color: v2.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Gap.h14,

                // --- Involved foods -------------------------------------------
                if (insight.involvedFoods.isNotEmpty) ...[
                  const V2SectionLabel('Foods involved'),
                  Gap.h8,
                  V2FoodGrid(
                    items: [
                      for (final food in insight.involvedFoods.take(3))
                        V2FoodItemData(
                          name: food,
                          emoji: InsightPresentation.emojiForFood(food),
                        ),
                    ],
                  ),
                  Gap.h14,
                ],

                // --- Action plan ----------------------------------------------
                if (insight.nextSteps.isNotEmpty) ...[
                  V2Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const V2SectionLabel(InsightV2Strings.nextStepsLabel),
                        Gap.h10,
                        V2WhyList(
                          points: insight.nextSteps,
                          tone: V2Tone.success,
                        ),
                      ],
                    ),
                  ),
                  Gap.h14,
                ],

                // --- Related patterns ------------------------------------------
                if (patterns.isNotEmpty) ...[
                  const V2SectionLabel(InsightV2Strings.relatedPatternsLabel),
                  Gap.h8,
                  for (final pattern in patterns.take(3)) ...[
                    V2PatternPill(
                      title: '${pattern.trigger} → ${pattern.reaction}',
                      subtitle:
                          '${pattern.frequency}× • ${pattern.confidence} confidence',
                      emoji: pattern.involvedFoods.isEmpty
                          ? null
                          : InsightPresentation.emojiForFood(
                              pattern.involvedFoods.first,
                            ),
                      onTap: () =>
                          context.push(AppRoutes.patternDetail, extra: pattern),
                    ),
                    Gap.h8,
                  ],
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
