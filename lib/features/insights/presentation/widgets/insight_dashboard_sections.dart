import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:gutgood/core/utils/image_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/product_details/presentation/widgets/scan_result_widgets.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class ModernSmartAlert extends StatelessWidget {
  const ModernSmartAlert({super.key, required this.insight});
  final InsightSummary insight;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppPalette.purple.withAlpha(26) : scheme.cardBackground;
    final contentColor = isDark ? scheme.textPrimary : AppPalette.black;

    return DashboardEntrance(
      delay: 450,
      child: InkWell(
        onTap: () => context.push(AppRoutes.smartInsightDetail, extra: insight),
        borderRadius: BorderRadius.circular(AppSizes.r24),
        child: BentoCard(
          padding: const EdgeInsets.all(12),
          height: 160.h,
          backgroundColor: bgColor,
          borderColor: isDark ? AppPalette.purple.withAlpha(50) : AppPalette.purple.withAlpha(20),
          child: Row(
            children: [
              // Left block: AI Identity
              Container(
                width: 136.h,
                height: 136.h,
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
    final cardBg = isDark ? AppPalette.darkCard : scheme.cardBackground;
    final cardBorder = isDark ? AppPalette.white.withAlpha(20) : scheme.borderSubtle;
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

class BentoFoodCard extends StatefulWidget {
  const BentoFoodCard({super.key, required this.foods, required this.title, required this.trend, required this.isPositive, required this.icon});
  final List<dynamic> foods;
  final String title;
  final String? trend;
  final bool isPositive;
  final IconData icon;

  @override
  State<BentoFoodCard> createState() => _BentoFoodCardState();
}

class _BentoFoodCardState extends State<BentoFoodCard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final color = widget.isPositive ? AppPalette.green : AppPalette.red;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = widget.foods.map((f) {
      if (f is HealingFood || f is TriggerFood) {
        final dynamic food = f;
        return CyclerItemData(name: food.name, effect: food.effect, emoji: food.emoji, imageUrl: food.imageUrl);
      } else if (f is FoodImpact) {
        return CyclerItemData(name: f.food, effect: f.effect, emoji: f.emoji, imageUrl: f.imageUrl, dateLabel: f.dateLabel);
      } else if (f is RecapHighlight) {
        return CyclerItemData(name: f.text, effect: '', emoji: '💡');
      }
      return CyclerItemData(name: 'Unknown', effect: '', emoji: '🍽️');
    }).toList();

    final displayItems = items.isEmpty ? [CyclerItemData(name: 'STABLE HABITS', effect: 'Your gut is tracking well.', emoji: '✨')] : items;

    return DashboardEntrance(
      delay: 200,
      child: BentoCard(
        padding: const EdgeInsets.all(12),
        height: 160.h,
        backgroundColor: scheme.cardBackground,
        child: Row(
          children: [
            // Left block: Visual Identity (Synced with scroll)
            Container(
              width: 136.h,
              height: 136.h,
              decoration: BoxDecoration(color: widget.isPositive ? AppPalette.green.withAlpha(20) : AppPalette.red.withAlpha(20), borderRadius: BorderRadius.circular(16)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    if (displayItems.isNotEmpty && _currentIndex < displayItems.length)
                      Positioned.fill(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                            return Stack(
                              children: <Widget>[
                                ...previousChildren.map((child) => Positioned.fill(child: child)),
                                if (currentChild != null) Positioned.fill(child: currentChild),
                              ],
                            );
                          },
                          child: CachedNetworkImage(
                            key: ValueKey('${widget.title}_image_$_currentIndex'),
                            imageUrl: displayItems[_currentIndex].imageUrl ?? getDynamicImageUrl(displayItems[_currentIndex].name),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: AppPalette.shimmerBase(context),
                              highlightColor: AppPalette.shimmerHighlight(context),
                              child: Container(color: AppPalette.white),
                            ),
                            errorWidget: (_, __, ___) => Center(
                              child: Icon(widget.icon, size: 40.sp, color: color.withAlpha(153)),
                            ),
                          ),
                        ),
                      ),
                    Positioned(top: 10, left: 10, child: Icon(widget.icon, size: 14, color: displayItems.isNotEmpty ? AppPalette.white : color)),
                  ],
                ),
              ),
            ),
            Gap.w16,
            // Right info: Cycler
            Expanded(
              child: BentoItemCycler(items: displayItems, title: widget.title, trend: widget.trend, isPositive: widget.isPositive, onPageChanged: (index) => setState(() => _currentIndex = index)),
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
    items: foods.map((f) {
      if (f is HealingFood || f is TriggerFood) {
        final dynamic food = f;
        return CyclerItemData(name: food.name, effect: food.effect, emoji: food.emoji, imageUrl: food.imageUrl);
      } else if (f is FoodImpact) {
        return CyclerItemData(name: f.food, effect: f.effect, emoji: f.emoji, imageUrl: f.imageUrl);
      } else if (f is RecapHighlight) {
        return CyclerItemData(name: f.text, effect: '', emoji: '💡');
      }
      return CyclerItemData(name: 'Unknown', effect: '', emoji: '🍽️');
    }).toList(),
  );
}

class CyclerItemData {
  CyclerItemData({required this.name, required this.effect, required this.emoji, this.imageUrl, this.dateLabel});
  final String name;
  final String effect;
  final String emoji;
  final String? imageUrl;
  final String? dateLabel;
}

class BentoItemCycler extends StatefulWidget {
  const BentoItemCycler({super.key, required this.items, required this.title, required this.trend, required this.isPositive, this.onPageChanged});
  final List<CyclerItemData> items;
  final String title;
  final String? trend;
  final bool isPositive;
  final ValueChanged<int>? onPageChanged;

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
    final primaryColor = scheme.textPrimary;
    final secondaryColor = scheme.textSecondary;
    final mutedColor = scheme.textMuted;

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
                height: 90.h,
                child: PageView.builder(
                  controller: _controller,
                  scrollDirection: Axis.vertical,
                  itemCount: displayItems.length,
                  onPageChanged: widget.onPageChanged,
                  itemBuilder: (context, i) {
                    final item = displayItems[i];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.name.toUpperCase(),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: context.bodyBold.copyWith(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 12.sp),
                        ),
                        Gap.h4,
                        Text(
                          item.effect,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.caption.copyWith(color: secondaryColor, height: 1.2),
                        ),
                        if (item.dateLabel != null) ...[
                          Gap.h2,
                          Text(
                            item.dateLabel!,
                            style: context.captionTiny.copyWith(color: mutedColor, fontSize: 9.sp),
                          ),
                        ],
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
    return BentoFoodCard(
      foods: impacts,
      title: 'RECENT LOGS',
      trend: null, // Trend not needed for activity card
      isPositive: true, // Defaulting to positive style for history
      icon: AppIcons.history,
    );
  }
}
