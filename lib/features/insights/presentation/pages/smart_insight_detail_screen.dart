import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/ai_insight_details.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? scheme.cardBackground : AppPalette.gray50,
      body: CustomScrollView(
        slivers: [
          const GutSliverAppBar(title: '', centerTitle: true),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Intelligence Hero (Wallet Identity)
                  DashboardEntrance(
                    delay: 50,
                    child: IntelligencePulseCard(
                      title: insight.title,
                      description: insight.description,
                      index: 1,
                      onTap: () {}, // Already on detail screen
                    ),
                  ),
                  Gap.h16,

                  // 2. Statistical Quick View
                  DashboardEntrance(delay: 100, child: _InsightDetailMetricGrid(insight: insight)),
                  Gap.h16,

                  // 3. Detailed Observation & Action Plan
                  DashboardEntrance(
                    delay: 150,
                    child: PhysicalGoalCard(
                      title: AppStrings.whatWeNoticed.toUpperCase(),
                      subtitle: 'OBSERVATION',
                      label: insight.observation ?? insight.description,
                      icon: AppIcons.brain,
                      color: AppPalette.purple,
                      onTap: () {},
                    ),
                  ),
                  Gap.h16,
                  DashboardEntrance(
                    delay: 180,
                    child: PhysicalGoalCard(
                      title: AppStrings.actionPlan.toUpperCase(),
                      subtitle: 'STRATEGY',
                      label: insight.nextSteps.isNotEmpty ? insight.nextSteps.first : 'Keep monitoring how you feel.',
                      icon: AppIcons.lightbulb,
                      color: AppPalette.green,
                      onTap: () {},
                    ),
                  ),
                  Gap.h16,

                  // 4. Involved Foods
                  if (insight.involvedFoods.isNotEmpty) ...[
                    DashboardEntrance(
                      delay: 200,
                      child: BentoCard(
                        padding: const EdgeInsets.all(12),
                        height: 140.h,
                        backgroundColor: scheme.cardBackground,
                        child: Row(
                          children: [
                            // Left block: Count Identity
                            Container(
                              width: 116.h,
                              height: 116.h,
                              decoration: BoxDecoration(
                                color: scheme.surfaceSubtle,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              child: Stack(
                                children: [
                                  Positioned(top: 10, left: 10, child: Icon(AppIcons.utensils, size: 12, color: scheme.textPrimary)),
                                  Center(
                                    child: Text(
                                      '${insight.involvedFoods.length}',
                                      style: context.displayHero.copyWith(color: scheme.textPrimary, fontSize: 56.sp, letterSpacing: -5),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 10,
                                    left: 10,
                                    right: 10,
                                    child: Text(
                                      'ITEMS',
                                      textAlign: TextAlign.center,
                                      style: context.captionMicro.copyWith(color: scheme.textMuted, fontWeight: FontWeight.w900, fontSize: 8.sp, letterSpacing: 1.1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Gap.w16,
                            // Right info: Vertical Cycler
                            Expanded(
                              child: BentoItemCycler(
                                items: insight.involvedFoods.map((f) => CyclerItemData(name: f, effect: AppStrings.linkedToInsight, emoji: '🍽️')).toList(),
                                title: AppStrings.foodsInvolved,
                                trend: 'Primary factors identified by AI.',
                                isPositive: false,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Gap.h16,
                  ],
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
