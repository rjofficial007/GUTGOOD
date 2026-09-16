import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/utils/insight_presentation.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_strings.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_theme.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/v2_kit.dart';

/// Pattern Details — v2 "Real Tokens" presentation (mock screen 3).
///
/// White hairline cards on the scaffold: identity badge, "Trigger → Reaction"
/// headline, the frequency/confidence/window stat row, common factors,
/// recent occurrences timeline, and the recommendation strip.
class PatternDetailScreen extends StatelessWidget {
  const PatternDetailScreen({super.key, required this.pattern});

  final BodyPattern pattern;

  @override
  Widget build(BuildContext context) {
    final v2 = context.v2Theme;
    final trigger = pattern.trigger.trim();
    final reaction = pattern.reaction.trim();
    final title = (trigger.isEmpty || reaction.isEmpty)
        ? (trigger.isEmpty ? reaction : trigger)
        : '$trigger → $reaction';

    final occurrences = [...pattern.occurrences];
    final riskTone = pattern.evidenceRatio >= 0.8
        ? V2Tone.error
        : pattern.evidenceRatio >= 0.5
        ? V2Tone.warning
        : V2Tone.success;

    return Scaffold(
      backgroundColor: v2.scaffold,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          GutSliverAppBar(
            title: '${_typeLabel(pattern.type)} pattern'.toUpperCase(),
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
                    V2Badge(
                      _typeLabel(pattern.type),
                      tone: riskTone,
                      size: 8.5,
                    ),
                    Gap.w6,
                    V2Pill(
                      '${_confidenceLabel(pattern.confidence)} confidence',
                      size: 8.5,
                    ),
                  ],
                ),
                Gap.h10,
                Text(
                  title,
                  style: V2Kit.text(
                    context,
                    size: 19,
                    weight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                if (pattern.description.isNotEmpty) ...[
                  Gap.h6,
                  Text(
                    pattern.description,
                    style: V2Kit.text(
                      context,
                      size: 12.5,
                      color: v2.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
                Gap.h14,

                // --- Stats ----------------------------------------------------
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      V2Stat(
                        label: InsightV2Strings.frequencyLabel,
                        value: '${pattern.frequency}×',
                      ),
                      Gap.w8,
                      V2Stat(
                        label: InsightV2Strings.confidenceLabel,
                        value: _confidenceLabel(pattern.confidence),
                      ),
                      Gap.w8,
                      V2Stat(
                        label: InsightV2Strings.timeWindowLabel,
                        value: '${pattern.timeframeDays}d',
                      ),
                    ],
                  ),
                ),
                Gap.h14,

                // --- Common factors -------------------------------------------
                if (pattern.commonFactors.isNotEmpty) ...[
                  const V2SectionLabel(InsightV2Strings.commonFactorsLabel),
                  Gap.h8,
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 6.w,
                    children: [
                      for (final factor in pattern.commonFactors)
                        V2Pill(
                          '${_factorGlyph(factor.icon)}  ${factor.label}',
                          size: 10.5,
                        ),
                    ],
                  ),
                  Gap.h14,
                ],

                // --- Recent occurrences ---------------------------------------
                if (occurrences.isNotEmpty) ...[
                  const V2SectionLabel(InsightV2Strings.occurrencesLabel),
                  Gap.h8,
                  V2Timeline(
                    rows: [
                      for (var i = 0; i < occurrences.take(4).length; i++)
                        V2TimelineRow(
                          title:
                              '${occurrences[i].date} • ${occurrences[i].mealName}',
                          subtitle: occurrences[i].reaction.isEmpty
                              ? null
                              : occurrences[i].reaction,
                          trailing: occurrences[i].timeAfter.isEmpty
                              ? null
                              : occurrences[i].timeAfter,
                          dotColor: v2.textPrimary,
                          dotMuted: i != 0,
                        ),
                    ],
                  ),
                  Gap.h14,
                ],

                // --- Involved foods -------------------------------------------
                if (pattern.involvedFoods.isNotEmpty) ...[
                  const V2SectionLabel('Foods involved'),
                  Gap.h8,
                  V2FoodGrid(
                    items: [
                      for (final food in pattern.involvedFoods.take(3))
                        V2FoodItemData(
                          name: food,
                          emoji: InsightPresentation.emojiForFood(food),
                        ),
                    ],
                  ),
                  Gap.h14,
                ],

                // --- Recommendation -------------------------------------------
                if ((pattern.recommendation ?? '').isNotEmpty)
                  V2RecCard(
                    dark: true,
                    emoji: '💡',
                    richText: TextSpan(
                      children: [
                        TextSpan(
                          text: 'What to do',
                          style: V2Kit.text(
                            context,
                            size: 11.5,
                            weight: FontWeight.w700,
                            color: v2.card,
                          ),
                        ),
                        TextSpan(
                          text: ' — ${pattern.recommendation}',
                          style: V2Kit.text(
                            context,
                            size: 11.5,
                            color: v2.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                Gap.h12,
                Center(
                  child: Text(
                    InsightV2Strings.basedOnLogsFooter,
                    textAlign: TextAlign.center,
                    style: V2Kit.text(
                      context,
                      size: 10.5,
                      color: v2.textTertiary,
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  static String _typeLabel(String type) => switch (type.toLowerCase()) {
    BodyPattern.typeBloating => 'Digestive',
    BodyPattern.typeEnergy => 'Energy',
    BodyPattern.typeHeadache => 'Headache',
    BodyPattern.typeDigestion => 'Digestion',
    BodyPattern.typeFullness => 'Fullness',
    BodyPattern.typeSleep => 'Sleep',
    _ => 'Pattern',
  };

  static String _confidenceLabel(String confidence) =>
      switch (confidence.toLowerCase()) {
        'high' => 'High',
        'medium' || 'moderate' => 'Medium',
        _ => 'Early',
      };

  static String _factorGlyph(String icon) => switch (icon.toLowerCase()) {
    'milk' => '🥛',
    'utensils' => '🍽',
    'leaf' => '🥬',
    'wheat' => '🌾',
    'droplet' => '💧',
    _ => '•',
  };
}
