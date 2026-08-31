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
          const GutSliverAppBar(title: AppStrings.intelligenceDetail, showBrandingIcon: false),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Intelligence Hero (Wallet Identity)
                  DashboardEntrance(delay: 50, child: _InsightHeroCard(insight: insight)),
                  Gap.h12,

                  // 2. Statistical Quick View
                  DashboardEntrance(delay: 100, child: _InsightDetailMetricGrid(insight: insight)),
                  Gap.h12,

                  // 3. Detailed Observation & Action Plan Row
                  DashboardEntrance(
                    delay: 150,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: BentoCard(
                            height: 160.h,
                            backgroundColor: AppPalette.purplePastel,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppStrings.whatWeNoticed.toUpperCase(),
                                      style: context.captionMicro.copyWith(color: AppPalette.black.withAlpha(153), fontWeight: FontWeight.w900, fontSize: 8.sp),
                                    ),
                                    Icon(AppIcons.brain, color: AppPalette.black.withAlpha(102), size: 12),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  insight.observation ?? insight.description,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.bodyBold.copyWith(color: AppPalette.black, height: 1.2, fontWeight: FontWeight.w900, fontSize: 12.sp),
                                ),
                                const Spacer(),
                                Text(
                                  AppStrings.detailedObservation.toUpperCase(),
                                  style: context.captionMicro.copyWith(color: AppPalette.black.withAlpha(153), fontWeight: FontWeight.w900, fontSize: 7.sp),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Gap.w12,
                        Expanded(
                          child: BentoCard(
                            height: 160.h,
                            backgroundColor: AppPalette.greenPastel,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppStrings.actionPlan.toUpperCase(),
                                      style: context.captionMicro.copyWith(color: AppPalette.black.withAlpha(153), fontWeight: FontWeight.w900, fontSize: 8.sp),
                                    ),
                                    Icon(AppIcons.lightbulb, color: AppPalette.black.withAlpha(102), size: 12),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  insight.nextSteps.isNotEmpty ? insight.nextSteps.first : 'Keep monitoring how you feel.',
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.bodyBold.copyWith(color: AppPalette.black, height: 1.2, fontWeight: FontWeight.w900, fontSize: 12.sp),
                                ),
                                const Spacer(),
                                Text(
                                  AppStrings.whatYouCanDo.toUpperCase(),
                                  style: context.captionMicro.copyWith(color: AppPalette.black.withAlpha(153), fontWeight: FontWeight.w900, fontSize: 7.sp),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Gap.h12,

                  // 4. Involved Foods
                  if (insight.involvedFoods.isNotEmpty) ...[
                    DashboardEntrance(
                      delay: 200,
                      child: BentoCard(
                        padding: const EdgeInsets.all(12),
                        height: 140.h,
                        backgroundColor: scheme.surfaceSubtle,
                        child: Row(
                          children: [
                            // Left block: Count Identity
                            Container(
                              width: 116.h,
                              height: 116.h,
                              decoration: BoxDecoration(color: AppPalette.white.withAlpha(204), borderRadius: BorderRadius.circular(16)),
                              child: Stack(
                                children: [
                                  Positioned(top: 10, left: 10, child: Icon(AppIcons.utensils, size: 12, color: scheme.textPrimary)),
                                  Center(
                                    child: Text(
                                      '${insight.involvedFoods.length}',
                                      style: context.displayHero.copyWith(color: AppPalette.black, fontSize: 56.sp, letterSpacing: -5),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 10,
                                    left: 10,
                                    right: 10,
                                    child: Text(
                                      'ITEMS',
                                      textAlign: TextAlign.center,
                                      style: context.captionMicro.copyWith(color: AppPalette.black, fontWeight: FontWeight.w900, fontSize: 8.sp),
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
                    Gap.h12,
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

class _InsightHeroCard extends StatelessWidget {
  const _InsightHeroCard({required this.insight});
  final InsightSummary insight;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    return BentoCard(
      padding: const EdgeInsets.all(12),
      height: 160.h,
      backgroundColor: scheme.textPrimary,
      child: Row(
        children: [
          // Left block: Focus Identity
          Container(
            width: 136.h,
            height: 136.h,
            decoration: BoxDecoration(color: scheme.cardBackground.withAlpha(204), borderRadius: BorderRadius.circular(16)),
            child: Stack(
              children: [
                Positioned(
                  top: 10,
                  left: 10,
                  child: Text(
                    'AI PULSE',
                    style: context.captionMicro.copyWith(color: scheme.textPrimary, fontWeight: FontWeight.w900, fontSize: 8.sp),
                  ),
                ),
                Center(
                  child: Icon(AppIcons.brain, size: 48.sp, color: scheme.textPrimary),
                ),
                Positioned(
                  bottom: 10,
                  left: 10,
                  right: 10,
                  child: Text(
                    insight.strength?.toUpperCase() ?? 'MODERATE',
                    textAlign: TextAlign.center,
                    style: context.captionMicro.copyWith(color: scheme.textPrimary, fontWeight: FontWeight.w900, fontSize: 8.sp),
                  ),
                ),
              ],
            ),
          ),
          Gap.w16,
          // Right info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(insight.type.toUpperCase(), style: context.captionBold.copyWith(color: scheme.cardBackground.withAlpha(153))),
                Gap.h8,
                Text(
                  insight.title.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.headingSm.copyWith(color: scheme.cardBackground, fontWeight: FontWeight.w900, fontSize: 18.sp, height: 1.1),
                ),
                Gap.h8,
                Text(
                  insight.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: context.caption.copyWith(color: scheme.cardBackground.withAlpha(204), height: 1.3),
                ),
              ],
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
