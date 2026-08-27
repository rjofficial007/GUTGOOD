import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/ai_insight_details.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/core/widgets/modern_insight_card.dart';
import 'package:gutgood/features/insights/presentation/widgets/analysis_card.dart';

class SmartInsightDetailScreen extends StatelessWidget {
  const SmartInsightDetailScreen({super.key, required this.insight});
  final InsightSummary insight;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    return Scaffold(
      backgroundColor: scheme.cardBackground,
      body: CustomScrollView(
        slivers: [
          const GutSliverAppBar(title: 'INTELLIGENCE DETAIL', showBrandingIcon: false),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p10),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                DashboardEntrance(delay: 50, child: _InsightHeroCard(insight: insight)),
                Gap.h20,
                DashboardEntrance(delay: 100, child: _ObservationCard(insight: insight)),
                Gap.h20,
                if (insight.involvedFoods.isNotEmpty) ...[DashboardEntrance(delay: 150, child: _FoodsInvolvedCard(foods: insight.involvedFoods)), Gap.h20],
                DashboardEntrance(delay: 200, child: _NextStepsCard(insight: insight)),
                Gap.h40,
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightHeroCard extends StatelessWidget {
  const _InsightHeroCard({required this.insight});
  final InsightSummary insight;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final color = scheme.textPrimary;

    final footerText = insight.evidenceRatio != null 
        ? '${(insight.evidenceRatio! * 100).toInt()}% PROBABILITY • ${insight.frequency ?? 1} OCCURRENCES'
        : '${insight.strength?.toUpperCase() ?? 'MODERATE'} STRENGTH • ${insight.frequency ?? 1} OCCURRENCES';

    return ModernInsightCard(
      title: 'SMART ALERT',
      icon: AppIcons.salad,
      iconColor: color,
      backgroundColor: scheme.cardBackground,
      footer: Text(
        footerText,
        style: context.caption.copyWith(color: scheme.cardBackground, fontWeight: FontWeight.w900, fontSize: 9.sp, letterSpacing: 1.2),
      ),
      footerColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Gap.h24,
          Text(
            insight.title.toUpperCase(),
            style: context.bodyBold.copyWith(fontSize: 28.sp, fontWeight: FontWeight.w900, letterSpacing: -1.2, height: 1.0),
            textAlign: TextAlign.center,
          ),
          Gap.h12,
          Text(
            insight.description,
            style: context.bodySm.copyWith(color: scheme.textSecondary, height: 1.4),
            textAlign: TextAlign.center,
          ),
          Gap.h32,
        ],
      ),
    );
  }
}

class _ObservationCard extends StatelessWidget {
  const _ObservationCard({required this.insight});
  final InsightSummary insight;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return AnalysisCard(
      metric: (insight.frequency ?? 1).toString(),
      label: 'WHAT WE NOTICED',
      icon: AppIcons.brain,
      glowColor: scheme.textPrimary,
      items: [
        AnalysisItem(title: 'DETAILED OBSERVATION', subtitle: insight.observation ?? insight.description, icon: AppIcons.info),
        if (insight.evidenceRatio != null)
          AnalysisItem(
            title: 'STATISTICAL EVIDENCE',
            subtitle: '${(insight.evidenceRatio! * 100).toInt()}% Impact Probability: Symptomatic in ${insight.positiveCount} logs, asymptomatic in ${insight.negativeCount}.',
            icon: AppIcons.activity,
          ),
      ],
    );
  }
}

class _FoodsInvolvedCard extends StatelessWidget {
  const _FoodsInvolvedCard({required this.foods});
  final List<String> foods;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return AnalysisCard(
      metric: foods.length.toString(),
      label: 'FOODS INVOLVED',
      icon: AppIcons.utensils,
      glowColor: scheme.textPrimary,
      items: foods.map((f) => AnalysisItem(title: f.toUpperCase(), subtitle: 'Linked to this insight', icon: AppIcons.package, isDone: true, color: scheme.textPrimary)).toList(),
    );
  }
}

class _NextStepsCard extends StatelessWidget {
  const _NextStepsCard({required this.insight});
  final InsightSummary insight;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final nextStep = insight.nextSteps.isNotEmpty ? insight.nextSteps.first : 'Keep monitoring how you feel after these meals.';

    return AnalysisCard(
      metric: 'NEXT',
      label: 'ACTION PLAN',
      icon: AppIcons.lightbulb,
      glowColor: scheme.success,
      items: [
        AnalysisItem(title: 'WHAT YOU CAN DO', subtitle: nextStep, icon: AppIcons.checkCircle, isDone: true, color: scheme.textPrimary),
        AnalysisItem(title: 'ASK GUTGOOD', subtitle: 'Ask about "${insight.title}"', icon: AppIcons.messageSquare, color: scheme.textPrimary),
      ],
    );
  }
}
