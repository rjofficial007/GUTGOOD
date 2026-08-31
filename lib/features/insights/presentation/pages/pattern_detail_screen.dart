import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/insight_ui_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_dashboard_sections.dart';
import 'package:gutgood/features/product_details/presentation/widgets/scan_result_widgets.dart';

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
          const GutSliverAppBar(title: '', showBrandingIcon: false),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Discovery Hero (Wallet Identity)
                  DashboardEntrance(delay: 50, child: _PatternHeroCard(pattern: pattern)),
                  Gap.h12,

                  // 2. Statistical Quick View
                  DashboardEntrance(delay: 100, child: _PatternMetricGrid(pattern: pattern)),
                  Gap.h12,

                  // 3. Clinical Observation & Action Plan Row
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
                                      AppStrings.observationsLabel.toUpperCase(),
                                      style: context.captionMicro.copyWith(color: AppPalette.black.withAlpha(153), fontWeight: FontWeight.w900, fontSize: 8.sp),
                                    ),
                                    Icon(AppIcons.brain, color: AppPalette.black.withAlpha(102), size: 12),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  pattern.description,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.bodyBold.copyWith(color: AppPalette.black, height: 1.2, fontWeight: FontWeight.w900, fontSize: 12.sp),
                                ),
                                const Spacer(),
                                Text(
                                  'AI SUMMARY',
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
                                  pattern.recommendation ?? 'Keep monitoring your intake to verify this body reaction.',
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.bodyBold.copyWith(color: AppPalette.black, height: 1.2, fontWeight: FontWeight.w900, fontSize: 12.sp),
                                ),
                                const Spacer(),
                                Text(
                                  'AI ACTION',
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

                  // 4. Involved Foods (Bento Cycler)
                  if (pattern.involvedFoods.isNotEmpty) ...[
                    DashboardEntrance(
                      delay: 200,
                      child: BentoCard(
                        padding: const EdgeInsets.all(12),
                        height: 140.h,
                        backgroundColor: scheme.surfaceSubtle,
                        child: Row(
                          children: [
                            Container(
                              width: 116.h,
                              height: 116.h,
                              decoration: BoxDecoration(color: AppPalette.white.withAlpha(204), borderRadius: BorderRadius.circular(16)),
                              child: Stack(
                                children: [
                                  Positioned(top: 10, left: 10, child: Icon(AppIcons.utensils, size: 12, color: scheme.textPrimary)),
                                  Center(
                                    child: Text(
                                      '${pattern.involvedFoods.length}',
                                      style: context.displayHero.copyWith(color: AppPalette.black, fontSize: 56.sp, letterSpacing: -4),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 10,
                                    left: 10,
                                    right: 10,
                                    child: Text(
                                      'IDENTIFIED',
                                      textAlign: TextAlign.center,
                                      style: context.captionMicro.copyWith(color: AppPalette.black, fontWeight: FontWeight.w900, fontSize: 8.sp),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Gap.w16,
                            Expanded(
                              child: BentoItemCycler(
                                items: pattern.involvedFoods.map((f) => CyclerItemData(name: f, effect: 'Linked to this discovery.', emoji: '🍽️')).toList(),
                                title: AppStrings.involvedFoodsLabel,
                                trend: 'Statistical factors detected.',
                                isPositive: false,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Gap.h12,
                  ],

                  // 5. Timeline Context
                  if (pattern.occurrences.isNotEmpty) ...[
                    DashboardEntrance(
                      delay: 250,
                      child: BentoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(AppStrings.recentTimelineLabel.toUpperCase(), style: context.captionBold.copyWith(color: scheme.textSecondary)),
                                Icon(AppIcons.history, color: scheme.textSecondary, size: 14),
                              ],
                            ),
                            Gap.h20,
                            ImpactTimeline(
                              items: pattern.occurrences.take(5).map((o) => TimelineItem(title: o.mealName, subtitle: '${o.date} • ${o.reaction}', color: scheme.textPrimary)).toList(),
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

class _PatternHeroCard extends StatelessWidget {
  const _PatternHeroCard({required this.pattern});
  final BodyPattern pattern;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final icon = InsightUiUtils.getPatternTypeIcon(pattern.type);
    final themeColor = InsightUiUtils.getPatternPastelColor(pattern.type);
    final accentColor = InsightUiUtils.getPatternColor(pattern.type);

    return BentoCard(
      padding: const EdgeInsets.all(12),
      height: 160.h,
      backgroundColor: themeColor,
      child: Row(
        children: [
          // Left block: Identity
          Container(
            width: 136.h,
            height: 136.h,
            decoration: BoxDecoration(color: scheme.cardBackground.withAlpha(204), borderRadius: BorderRadius.circular(16)),
            child: Stack(
              children: [
                Positioned(
                  top: 10,
                  left: 10,
                  child: Text('DISCOVERY', style: context.captionMicro.copyWith(color: accentColor, fontWeight: FontWeight.w900, fontSize: 8.sp)),
                ),
                Center(child: Icon(icon, size: 48.sp, color: accentColor)),
                Positioned(
                  bottom: 10,
                  left: 10,
                  right: 10,
                  child: Text(
                    '${pattern.confidence.toUpperCase()} CONFIDENCE',
                    textAlign: TextAlign.center,
                    style: context.captionMicro.copyWith(color: accentColor, fontWeight: FontWeight.w900, fontSize: 8.sp),
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
                Text(InsightUiUtils.getPatternName(pattern.type).toUpperCase(), style: context.captionBold.copyWith(color: AppPalette.black.withAlpha(153))),
                Gap.h8,
                Text(
                  pattern.trigger.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.headingSm.copyWith(color: AppPalette.black, fontWeight: FontWeight.w900, height: 1.1),
                ),
                Gap.h4,
                Text(
                  'LINKED TO',
                  style: context.captionMicro.copyWith(color: AppPalette.black.withAlpha(127), fontWeight: FontWeight.w900),
                ),
                Gap.h4,
                Text(
                  pattern.reaction.toUpperCase(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: context.body.copyWith(color: AppPalette.black, fontWeight: FontWeight.w900, height: 1.1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternMetricGrid extends StatelessWidget {
  const _PatternMetricGrid({required this.pattern});
  final BodyPattern pattern;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: SmallInsightMetricCard(label: 'Matches', value: '${pattern.frequency}', unit: 'LOGS', icon: AppIcons.history, accentColor: AppPalette.blue),
      ),
      Gap.w12,
      Expanded(
        child: SmallInsightMetricCard(label: 'Impact', value: '${(pattern.evidenceRatio * 100).toInt()}%', unit: 'PROBABILITY', icon: AppIcons.brain, accentColor: AppPalette.purple),
      ),
      Gap.w12,
      Expanded(
        child: SmallInsightMetricCard(label: 'Severity', value: '${pattern.positiveCount}', unit: 'REACTIONS', icon: AppIcons.activity, accentColor: AppPalette.pink),
      ),
    ],
  );
}
