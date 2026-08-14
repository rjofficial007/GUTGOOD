import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/insights/presentation/widgets/analysis_card.dart';

class PatternDetailScreen extends StatelessWidget {
  const PatternDetailScreen({super.key, required this.pattern});
  final BodyPattern pattern;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    return Scaffold(
      backgroundColor: scheme.cardBackground,
      body: CustomScrollView(
        slivers: [
          const GutSliverAppBar(title: 'PATTERN DISCOVERY', showBrandingIcon: false),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p10),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _WhatWeNoticedCard(pattern: pattern),
                Gap.h20,
                _InvolvedFoodsCard(pattern: pattern),
                Gap.h20,
                _PatternStrengthCard(pattern: pattern),
                Gap.h20,
                _NextStepsCard(pattern: pattern),
                Gap.h40,
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _WhatWeNoticedCard extends StatelessWidget {
  const _WhatWeNoticedCard({required this.pattern});
  final BodyPattern pattern;

  @override
  Widget build(BuildContext context) => AnalysisCard(
    metric: 'DISCOVERY',
    label: 'WHAT WE NOTICED',
    icon: AppIcons.brain,
    glowColor: AppPalette.purple,
    items: [
      AnalysisItem(title: pattern.reaction.toUpperCase(), subtitle: 'Appeared ${pattern.frequency} times after ${pattern.trigger}', icon: AppIcons.alertCircle, isDone: true),
      AnalysisItem(title: 'DESCRIPTION', subtitle: pattern.description, icon: AppIcons.info),
    ],
  );
}

class _InvolvedFoodsCard extends StatelessWidget {
  const _InvolvedFoodsCard({required this.pattern});
  final BodyPattern pattern;

  @override
  Widget build(BuildContext context) {
    final foods = pattern.involvedFoods.isNotEmpty ? pattern.involvedFoods : ['Logged meals containing ${pattern.trigger}'];

    return AnalysisCard(
      metric: '${foods.length}',
      label: 'FOODS INVOLVED',
      icon: AppIcons.utensils,
      glowColor: AppPalette.blue,
      items: foods.map((f) => AnalysisItem(title: f, subtitle: 'Associated with ${pattern.reaction}', icon: AppIcons.package, isDone: true)).toList(),
    );
  }
}

class _PatternStrengthCard extends StatelessWidget {
  const _PatternStrengthCard({required this.pattern});
  final BodyPattern pattern;

  @override
  Widget build(BuildContext context) {
    String strengthLabel;
    IconData strengthIcon;

    switch (pattern.confidence.toLowerCase()) {
      case 'high':
        strengthLabel = 'Repeated Pattern';
        strengthIcon = AppIcons.trendingUp;
        break;
      case 'moderate':
        strengthLabel = 'Showing up repeatedly';
        strengthIcon = AppIcons.activity;
        break;
      case 'low':
      default:
        strengthLabel = 'Early Pattern';
        strengthIcon = AppIcons.timer;
        break;
    }

    return AnalysisCard(
      metric: pattern.confidence.toUpperCase(),
      label: 'PATTERN STRENGTH',
      icon: AppIcons.shieldCheck,
      glowColor: AppPalette.green,
      items: [AnalysisItem(title: strengthLabel, subtitle: 'Frequency: ${pattern.frequency} occurrences detected', icon: strengthIcon, isDone: true)],
    );
  }
}

class _NextStepsCard extends StatelessWidget {
  const _NextStepsCard({required this.pattern});
  final BodyPattern pattern;

  @override
  Widget build(BuildContext context) {
    final recommendation = pattern.recommendation ?? 'Keep an eye on how you feel next time you have ${pattern.trigger}.';

    return AnalysisCard(
      metric: 'NEXT',
      label: 'WHAT YOU CAN DO',
      icon: AppIcons.lightbulb,
      glowColor: AppPalette.green,
      items: [
        AnalysisItem(title: 'ACTION STEP', subtitle: recommendation, icon: AppIcons.checkCircle, isDone: true),
        AnalysisItem(title: 'ASK GUTGOOD', subtitle: 'Ask about "${pattern.trigger} and ${pattern.reaction}"', icon: AppIcons.messageSquare),
      ],
    );
  }
}
