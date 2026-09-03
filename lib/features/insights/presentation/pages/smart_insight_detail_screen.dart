import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/ai_insight_details.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/super_card.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_dashboard_sections.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_dashboard_view.dart';
import 'package:gutgood/features/product_details/presentation/widgets/scan_result_widgets.dart';

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
          const GutSliverAppBar(title: 'DETAILED INSIGHT', centerTitle: true),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. WHAT IS HAPPENING (Intelligence Hero)
                  DashboardEntrance(
                    delay: 50,
                    child: IntelligencePulseCard(title: insight.title, description: insight.description, index: 1, onTap: () {}),
                  ),
                  Gap.h16,

                  // 2. HOW IT IS CHANGING (Statistical Metrics)
                  DashboardEntrance(delay: 100, child: _InsightDetailMetricGrid(insight: insight)),
                  Gap.h16,

                  // 3. WHAT IS CONTRIBUTING (Involved Foods & Observation)
                  DashboardEntrance(
                    delay: 150,
                    child: SuperPhysicalGoalCard(
                      title: AppStrings.whatWeNoticed.toUpperCase(),
                      subtitle: 'WHAT IS HAPPENING',
                      label: insight.observation ?? insight.description,
                      icon: AppIcons.brain,
                      color: AppPalette.purple,
                      onTap: () {},
                    ),
                  ),
                  Gap.h16,

                  // CONTRIBUTING FACTORS (BentoFoodCard)
                  if (insight.involvedFoods.isNotEmpty) ...[
                    DashboardEntrance(
                      delay: 180,
                      child: BentoFoodCard(
                        title: 'CONTRIBUTING FACTORS',
                        trend: 'Primary foods identified by AI.',
                        isPositive: insight.type.toLowerCase().contains('healing') || insight.type.toLowerCase().contains('positive'),
                        icon: AppIcons.utensils,
                        foods: insight.involvedFoods.map((f) => HealingFood(name: f, effect: AppStrings.linkedToInsight, emoji: '🍽️')).toList(),
                      ),
                    ),
                    Gap.h16,
                  ],

                  // 4. WHAT TO DO NEXT (Action Strategy)
                  DashboardEntrance(
                    delay: 210,
                    child: SuperPhysicalGoalCard(
                      title: AppStrings.actionPlan.toUpperCase(),
                      subtitle: 'WHAT TO DO NEXT',
                      label: insight.nextSteps.isNotEmpty ? insight.nextSteps.first : 'Keep monitoring how you feel after meals.',
                      icon: AppIcons.lightbulb,
                      color: AppPalette.green,
                      onTap: () {},
                    ),
                  ),
                  Gap.h40,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightDetailMetricGrid extends StatelessWidget {
  const _InsightDetailMetricGrid({required this.insight});
  final InsightSummary insight;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: SmallInsightMetricCard(label: 'Strength', value: insight.strength?.toUpperCase() ?? 'MOD', unit: 'STRENGTH', icon: AppIcons.zap, accentColor: AppPalette.orange),
      ),
      Gap.w12,
      Expanded(
        child: SmallInsightMetricCard(label: 'Matches', value: '${insight.frequency ?? 1}', unit: 'OCCURRENCES', icon: AppIcons.history, accentColor: AppPalette.blue),
      ),
      if (insight.evidenceRatio != null) ...[
        Gap.w12,
        Expanded(
          child: SmallInsightMetricCard(label: 'Impact', value: '${(insight.evidenceRatio! * 100).toInt()}%', unit: 'PROBABILITY', icon: AppIcons.brain, accentColor: AppPalette.purple),
        ),
      ],
    ],
  );
}
