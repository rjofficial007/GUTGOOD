import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/ai_insight_details.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/extensions.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/product_details/presentation/widgets/scan_result_widgets.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../providers/insights_notifier.dart';

class ModernSmartAlert extends StatelessWidget {
  const ModernSmartAlert({super.key, required this.insight});
  final InsightSummary insight;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    return DashboardEntrance(
      delay: 450,
      child: InkWell(
        onTap: () => context.push(AppRoutes.smartInsightDetail, extra: insight),
        borderRadius: BorderRadius.circular(AppSizes.r24),
        child: BentoCard(
          padding: const EdgeInsets.all(12),
          height: 180.h,
          backgroundColor: scheme.textPrimary,
          child: Row(
            children: [
              // Left block: AI Identity
              Container(
                width: 136.h,
                height: 136.h,
                decoration: BoxDecoration(
                  color: scheme.cardBackground.withAlpha(204),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Text(
                        'AI PULSE',
                        style: context.captionMicro.copyWith(
                          color: scheme.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Center(child: Icon(AppIcons.brain, size: 56.sp, color: scheme.textPrimary)),
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
                    Text(
                      insight.title.toUpperCase(),
                      style: context.captionBold.copyWith(color: scheme.cardBackground.withAlpha(153)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Gap.h8,
                    Text(
                      insight.description,
                      style: context.caption.copyWith(color: scheme.cardBackground, height: 1.3),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Gap.h8,
                    Text(
                      '${insight.type.toUpperCase()}${AppStrings.insightLabelSuffix.toUpperCase()} ➜',
                      style: context.captionMicro.copyWith(
                        color: scheme.cardBackground,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InsightMetricGrid extends StatelessWidget {
  const InsightMetricGrid({super.key, required this.data, this.notifier});
  final AIInsight data;
  final InsightsNotifier? notifier;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: SmallInsightMetricCard(label: 'Score', value: '${data.gutScore}%', unit: 'GUT')),
        Gap.w12,
        Expanded(child: SmallInsightMetricCard(label: 'Logs', value: '${notifier?.totalMeals ?? data.foodImpacts.length}', unit: 'TOTAL')),
        Gap.w12,
        Expanded(child: SmallInsightMetricCard(label: 'Patterns', value: '${data.detectedPatterns.length}', unit: 'ACTIVE')),
        Gap.w12,
        Expanded(child: SmallInsightMetricCard(label: 'Feelings', value: '${notifier?.totalSymptoms ?? 0}', unit: 'LOGGED')),
      ],
    );
  }
}

class SmallInsightMetricCard extends StatelessWidget {
  const SmallInsightMetricCard({required this.label, required this.value, required this.unit});
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return BentoCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      borderRadius: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label.toUpperCase(), style: context.captionBold.copyWith(color: scheme.textSecondary, fontSize: 8.sp)),
          Gap.h8,
          Text(value, style: context.headingSm.copyWith(fontWeight: FontWeight.w900, color: scheme.textPrimary, fontSize: 16.sp)),
          Gap.h2,
          Text(unit, style: context.captionMicro.copyWith(color: scheme.textMuted)),
        ],
      ),
    );
  }
}

class BentoFoodCycler extends StatelessWidget {
  const BentoFoodCycler({super.key, required this.foods, required this.title, required this.trend, required this.isPositive});
  final List<dynamic> foods;
  final String title;
  final String? trend;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    return BentoItemCycler(
      title: title,
      trend: trend,
      isPositive: isPositive,
      items: foods.map((f) => CyclerItemData(
        name: f is HealingFood || f is TriggerFood ? f.name : (f is FoodImpact ? f.food : 'Unknown'),
        effect: f is FoodImpact ? f.effect : (f.effect ?? ''),
        emoji: f.emoji,
      )).toList(),
    );
  }
}

class CyclerItemData {
  final String name;
  final String effect;
  final String emoji;
  CyclerItemData({required this.name, required this.effect, required this.emoji});
}

class BentoItemCycler extends StatefulWidget {
  const BentoItemCycler({super.key, required this.items, required this.title, required this.trend, required this.isPositive});
  final List<CyclerItemData> items;
  final String title;
  final String? trend;
  final bool isPositive;

  @override
  State<BentoItemCycler> createState() => _BentoItemCyclerState();
}

class _BentoItemCyclerState extends State<BentoItemCycler> {
  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final primaryColor = widget.isPositive ? AppPalette.black : scheme.textPrimary;
    final secondaryColor = widget.isPositive ? AppPalette.black.withAlpha(153) : scheme.textSecondary;
    final mutedColor = widget.isPositive ? AppPalette.black.withAlpha(102) : scheme.textMuted;

    final displayItems = widget.items.isEmpty 
        ? [CyclerItemData(name: 'STABLE HABITS', effect: 'Your gut is tracking well.', emoji: '✨')] 
        : widget.items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(widget.title.toUpperCase(), style: context.captionBold.copyWith(color: mutedColor)),
        Gap.h8,
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 80.h,
                child: PageView.builder(
                  controller: _controller,
                  scrollDirection: Axis.vertical,
                  itemCount: displayItems.length,
                  itemBuilder: (context, i) {
                    final item = displayItems[i];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(item.emoji, style: TextStyle(fontSize: 18.sp)),
                            Gap.w8,
                            Expanded(
                              child: Text(
                                item.name.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.bodyBold.copyWith(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 16.sp),
                              ),
                            ),
                          ],
                        ),
                        Gap.h4,
                        Text(
                          item.effect,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.caption.copyWith(color: secondaryColor, height: 1.2),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            if (displayItems.length > 1) ...[
              Gap.w8,
              RotatedBox(
                quarterTurns: 1,
                child: SmoothPageIndicator(
                  controller: _controller,
                  count: displayItems.length,
                  effect: ScrollingDotsEffect(
                    activeDotColor: primaryColor,
                    dotColor: primaryColor.withAlpha(51),
                    dotHeight: 4,
                    dotWidth: 4,
                    spacing: 4,
                  ),
                ),
              ),
            ],
          ],
        ),
        Gap.h8,
        Text(
          widget.trend ?? (widget.isPositive ? 'Body performance is improving.' : 'Tracking body reactions.'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.captionMicro.copyWith(color: mutedColor, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class BentoActivityCard extends StatelessWidget {
  const BentoActivityCard({super.key, required this.impacts});
  final List<FoodImpact> impacts;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return DashboardEntrance(
      delay: 250,
      child: BentoCard(
        padding: const EdgeInsets.all(12),
        height: 180.h,
        backgroundColor: scheme.surfaceSubtle,
        child: Row(
          children: [
            // Left block: History Identity
            Container(
              width: 136.h,
              height: 136.h,
              decoration: BoxDecoration(color: AppPalette.white.withAlpha(204), borderRadius: BorderRadius.circular(16)),
              child: Stack(
                children: [
                  Positioned(
                    top: 12, left: 12,
                    child: Icon(AppIcons.history, size: 14, color: scheme.textPrimary),
                  ),
                  Center(child: Text('${impacts.length}', style: context.displayHero.copyWith(color: AppPalette.black, fontSize: 64.sp, letterSpacing: -4))),
                  Positioned(bottom: 12, left: 12, right: 12, child: Text('RECENT LOGS', textAlign: TextAlign.center, style: context.captionMicro.copyWith(color: AppPalette.black, fontWeight: FontWeight.w900))),
                ],
              ),
            ),
            Gap.w16,
            // Right info: Vertical Cycler
            Expanded(
              child: BentoFoodCycler(
                foods: impacts,
                title: AppStrings.recentActivityTitle,
                trend: 'Last ${impacts.length} encounters recorded.',
                isPositive: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
