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
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/product_details/presentation/widgets/scan_result_widgets.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class ModernSmartAlert extends StatelessWidget {
  const ModernSmartAlert({super.key, required this.insight});
  final InsightSummary insight;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppPalette.purple.withAlpha(26) : AppPalette.purplePastel;
    final contentColor = isDark ? scheme.textPrimary : AppPalette.black;

    return DashboardEntrance(
      delay: 450,
      child: InkWell(
        onTap: () => context.push(AppRoutes.smartInsightDetail, extra: insight),
        borderRadius: BorderRadius.circular(AppSizes.r24),
        child: BentoCard(
          padding: const EdgeInsets.all(12),
          height: 140.h,
          backgroundColor: bgColor,
          borderColor: isDark ? AppPalette.purple.withAlpha(50) : AppPalette.purple.withAlpha(20),
          child: Row(
            children: [
              // Left block: AI Identity
              Container(
                width: 116.h,
                height: 116.h,
                decoration: BoxDecoration(color: scheme.cardBackground.withAlpha(isDark ? 102 : 204), borderRadius: BorderRadius.circular(16)),
                child: Stack(
                  children: [
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Text(
                        'AI PULSE',
                        style: context.captionMicro.copyWith(color: AppPalette.purple, fontWeight: FontWeight.w900, fontSize: 8.sp),
                      ),
                    ),
                    Center(
                      child: Icon(AppIcons.brain, size: 44.sp, color: AppPalette.purple),
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
                    Text(
                      insight.title.toUpperCase(),
                      style: context.captionBold.copyWith(color: contentColor.withAlpha(153)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Gap.h8,
                    Text(
                      insight.description,
                      style: context.caption.copyWith(color: contentColor, height: 1.3),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Gap.h8,
                    Text(
                      '${insight.type.toUpperCase()}${AppStrings.insightLabelSuffix.toUpperCase()} ➜',
                      style: context.captionMicro.copyWith(color: AppPalette.purple, fontWeight: FontWeight.w900, letterSpacing: 0.5),
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
  const InsightMetricGrid({super.key, required this.data, this.notifier, required this.streak});
  final AIInsight data;
  final InsightsNotifier? notifier;
  final int streak;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: SmallInsightMetricCard(label: 'Streak', value: '$streak', unit: 'DAYS', icon: AppIcons.flame, accentColor: AppPalette.orange),
      ),
      Gap.w12,
      Expanded(
        child: SmallInsightMetricCard(label: 'Patterns', value: '${data.detectedPatterns.length}', unit: 'ACTIVE', icon: AppIcons.brain, accentColor: AppPalette.purple),
      ),
      Gap.w12,
      Expanded(
        child: SmallInsightMetricCard(label: 'Feelings', value: '${notifier?.totalSymptoms ?? 0}', unit: 'LOGGED', icon: AppIcons.activity, accentColor: AppPalette.pink),
      ),
    ],
  );
}

class SmallInsightMetricCard extends StatelessWidget {
  const SmallInsightMetricCard({super.key, required this.label, required this.value, required this.unit, required this.icon, required this.accentColor});
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Adaptive Theme Colors (Mirroring PhysicalGoalCard)
    final cardBg = isDark ? AppPalette.darkCard : accentColor.withAlpha(15);
    final cardBorder = isDark ? AppPalette.white.withAlpha(20) : accentColor.withAlpha(30);
    final unitColor = isDark ? AppPalette.white.withAlpha(153) : scheme.textSecondary;
    final labelColor = isDark ? AppPalette.white.withAlpha(102) : scheme.textMuted;

    return BentoCard(
      padding: EdgeInsets.zero,
      height: 120.h,
      backgroundColor: cardBg,
      borderColor: cardBorder,
      borderRadius: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 🌊 Large Icon with Liquid Fill effect
            Positioned(
              right: -10,
              bottom: -15,
              child: Opacity(
                opacity: isDark ? 0.6 : 0.3,
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (rect) => LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [accentColor, accentColor, accentColor.withAlpha(isDark ? 40 : 80), accentColor.withAlpha(isDark ? 40 : 80)],
                    stops: const [0.0, 0.65, 0.65, 1.0],
                  ).createShader(rect),
                  child: Icon(icon, size: 80.h),
                ),
              ),
            ),

            // 📝 Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: context.displayHero.copyWith(color: accentColor, fontSize: 24.sp, letterSpacing: -1, fontWeight: FontWeight.w900, height: 1),
                  ),
                  Text(
                    unit.toUpperCase(),
                    style: context.captionBold.copyWith(color: unitColor, fontSize: 8.sp, letterSpacing: 0.5),
                  ),
                  const Spacer(),
                  Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.captionMicro.copyWith(color: labelColor, fontWeight: FontWeight.w900, fontSize: 7.sp, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
          ],
        ),
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
  Widget build(BuildContext context) => BentoItemCycler(
    title: title,
    trend: trend,
    isPositive: isPositive,
    items: foods
        .map((f) => CyclerItemData(name: f is HealingFood || f is TriggerFood ? f.name : (f is FoodImpact ? f.food : 'Unknown'), effect: f is FoodImpact ? f.effect : (f.effect ?? ''), emoji: f.emoji))
        .toList(),
  );
}

class CyclerItemData {
  CyclerItemData({required this.name, required this.effect, required this.emoji});
  final String name;
  final String effect;
  final String emoji;
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

    final displayItems = widget.items.isEmpty ? [CyclerItemData(name: 'STABLE HABITS', effect: 'Your gut is tracking well.', emoji: '✨')] : widget.items;

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
                height: 70.h,
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
                  effect: ScrollingDotsEffect(activeDotColor: primaryColor, dotColor: primaryColor.withAlpha(51), dotHeight: 4, dotWidth: 4, spacing: 4),
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
        height: 140.h,
        backgroundColor: scheme.surfaceSubtle,
        child: Row(
          children: [
            // Left block: History Identity
            Container(
              width: 116.h,
              height: 116.h,
              decoration: BoxDecoration(color: AppPalette.white.withAlpha(204), borderRadius: BorderRadius.circular(16)),
              child: Stack(
                children: [
                  Positioned(top: 10, left: 10, child: Icon(AppIcons.history, size: 12, color: scheme.textPrimary)),
                  Center(
                    child: Text(
                      '${impacts.length}',
                      style: context.displayHero.copyWith(color: AppPalette.black, fontSize: 56.sp, letterSpacing: -4),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    right: 10,
                    child: Text(
                      'RECENT LOGS',
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
              child: BentoFoodCycler(foods: impacts, title: AppStrings.recentActivityTitle, trend: 'Last ${impacts.length} encounters recorded.', isPositive: false),
            ),
          ],
        ),
      ),
    );
  }
}
