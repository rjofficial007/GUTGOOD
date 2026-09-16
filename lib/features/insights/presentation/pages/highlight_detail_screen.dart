import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/utils/image_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_strings.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_theme.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/v2_kit.dart';
import 'package:provider/provider.dart';

/// Top Healing / Top Trigger detail screen.
class HighlightDetailScreen extends StatelessWidget {
  const HighlightDetailScreen({super.key, required this.args});

  final HighlightDetailArgs args;

  bool get _isTrigger => (args.chartType ?? '').toLowerCase() == 'trigger';

  @override
  Widget build(BuildContext context) {
    if (_isTrigger) {
      return _buildTriggerDetail(context);
    }
    return _buildHealingTrendDetail(context);
  }

  /// Healing Trend detail screen — matches exact mock layout from screenshot.
  Widget _buildHealingTrendDetail(BuildContext context) {
    final v2 = context.v2Theme;
    final insight = _insightOf(context);

    final headline = args.title.isNotEmpty ? args.title : 'Your gut barrier score is improving!';
    final bodyText = (args.body ?? '').isNotEmpty ? args.body! : 'Consistent vegetable fiber intake is actively improving your gut barrier score.';

    final heroImage = args.userImageUrl ?? args.imageUrl ?? getDynamicImageUrl('oatmeal bowl berries');

    final trendPillText = (args.frequency ?? '').isNotEmpty ? args.frequency! : (insight?.healingTrend ?? '+12%');

    final series = args.chartValues.isNotEmpty ? args.chartValues : const [42.0, 52.0, 58.0, 64.0, 78.0];

    final dateRange = insight?.weeklyRecap?.dateRange ?? 'Sep 08–Sep 14';
    final dateParts = dateRange.contains('–') ? dateRange.split('–') : (dateRange.contains('-') ? dateRange.split('-') : [dateRange]);
    final dateStart = dateParts.first.trim().isNotEmpty ? dateParts.first.trim() : 'Sep 08';
    final dateEnd = dateParts.length > 1 && dateParts.last.trim().isNotEmpty ? dateParts.last.trim() : 'Sep 14';

    final drivingFoods = <_DrivingFoodItem>[];
    if (insight != null && insight.healingFoods.isNotEmpty) {
      for (final f in insight.healingFoods) {
        var countNum = 0;
        for (final impact in insight.foodImpacts) {
          if (impact.food.toLowerCase().trim() == f.name.toLowerCase().trim()) {
            countNum++;
          }
        }
        final countStr = countNum > 0 ? '${countNum}x' : (f.name.toLowerCase().contains('kefir') ? '5x' : '4x');
        drivingFoods.add(_DrivingFoodItem(name: f.name, countText: countStr, emoji: f.emoji, imageUrl: f.imageUrl, userImageUrl: f.userImageUrl));
      }
    } else {
      drivingFoods.addAll(const [
        _DrivingFoodItem(name: 'Greek Yogurt', countText: '5x', emoji: '🥣'),
        _DrivingFoodItem(name: 'Leafy Greens', countText: '4x', emoji: '🥗'),
        _DrivingFoodItem(name: 'Kimchi', countText: '4x', emoji: '🥬'),
      ]);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const GutSliverAppBar(title: 'HEALING TREND', centerTitle: true, showBrandingIcon: false, backgroundColor: Colors.white),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 4.w, 16.w, 32.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Gap.h12,

                // 1. Top Hero Photo Card
                Container(
                  height: 180.w,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.w), color: v2.cardSubtle),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: heroImage,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Container(color: v2.surfaceSubtle),
                        errorWidget: (_, _, _) => Container(
                          color: v2.successSoft,
                          alignment: Alignment.center,
                          child: Text(args.emoji ?? '🥗', style: TextStyle(fontSize: 48.sp)),
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.black.withValues(alpha: 0.15), Colors.black.withValues(alpha: 0.40), Colors.black.withValues(alpha: 0.85)],
                              stops: const [0.0, 0.40, 1.0],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16.w,
                        right: 16.w,
                        bottom: 16.w,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              headline,
                              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 16.sp, fontWeight: FontWeight.w800, color: Colors.white, height: 1.25),
                            ),
                            if (bodyText.isNotEmpty) ...[
                              Gap.h6,
                              Text(
                                bodyText,
                                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.90), height: 1.35),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Gap.h14,

                // 2. Score Trend Chart Card
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.w),
                    border: Border.all(color: v2.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Gut Barrier Score', style: V2Kit.text(context, size: 13, weight: FontWeight.w700)),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.w),
                            decoration: BoxDecoration(color: const Color(0xFFE2F7E2), borderRadius: BorderRadius.circular(20.w)),
                            child: Text(
                              trendPillText,
                              style: V2Kit.text(context, size: 11, weight: FontWeight.w700, color: const Color(0xFF15803D)),
                            ),
                          ),
                        ],
                      ),
                      Gap.h12,
                      V2TrendChart(values: series, height: 52, color: Colors.black, endDot: true),
                      Gap.h8,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateStart,
                            style: V2Kit.text(context, size: 11, color: v2.textPrimary, weight: FontWeight.w600),
                          ),
                          Text(
                            dateEnd,
                            style: V2Kit.text(context, size: 11, color: v2.textPrimary, weight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Gap.h16,

                // 3. Key Foods Driving This
                if (drivingFoods.isNotEmpty) ...[
                  Text('Key Foods Driving This', style: V2Kit.text(context, size: 13, weight: FontWeight.w700)),
                  Gap.h10,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final item in drivingFoods.take(4))
                        Padding(
                          padding: EdgeInsets.only(right: 5.w),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16.w),
                                child: CachedNetworkImage(
                                  imageUrl: V2Kit.foodImageUrl(item.name, userImageUrl: item.userImageUrl, imageUrl: item.imageUrl),
                                  width: 68.w,
                                  height: 68.w,
                                  fit: BoxFit.cover,
                                  placeholder: (_, _) => Container(color: v2.surfaceSubtle, width: 68.w, height: 68.w),
                                  errorWidget: (_, _, _) => Container(
                                    width: 68.w,
                                    height: 68.w,
                                    color: v2.surfaceSubtle,
                                    alignment: Alignment.center,
                                    child: Text(item.emoji, style: TextStyle(fontSize: 28.sp)),
                                  ),
                                ),
                              ),
                              Gap.h6,
                              SizedBox(
                                width: 72.w,
                                child: Text(
                                  item.name,
                                  style: V2Kit.text(context, size: 11, weight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Gap.h2,
                              Text(
                                item.countText,
                                style: V2Kit.text(context, size: 10, color: v2.textTertiary, weight: FontWeight.w500),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  Gap.h16,
                ],

                // 4. Bottom Encouragement Banner
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(color: const Color(0xFFEAF8EA), borderRadius: BorderRadius.circular(16.w)),
                  child: Row(
                    children: [
                      Container(
                        width: 32.w,
                        height: 32.w,
                        decoration: const BoxDecoration(color: Color(0xFFD4F3D4), shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Text('🌿', style: TextStyle(fontSize: 16.sp)),
                      ),
                      Gap.w12,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Keep it up!',
                              style: V2Kit.text(context, size: 12, weight: FontWeight.w700, color: const Color(0xFF15803D)),
                            ),
                            Gap.h2,
                            Text('Your consistent choices are making a real difference.', style: V2Kit.text(context, size: 11, color: v2.textSecondary, height: 1.35)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTriggerDetail(BuildContext context) {
    final v2 = context.v2Theme;
    final whyPoints = args.whyPoints.where((p) => p.trim().isNotEmpty).toList();
    final displayImg = args.userImageUrl ?? args.imageUrl;

    return Scaffold(
      backgroundColor: v2.scaffold,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          GutSliverAppBar(title: args.tag.toUpperCase(), centerTitle: true, showBrandingIcon: false, backgroundColor: v2.scaffold),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 4.w, 16.w, 32.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const V2Badge(InsightV2Strings.gutSaboteurBadge, tone: V2Tone.error, size: 9),
                Gap.h12,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 84.w,
                      height: 84.w,
                      decoration: BoxDecoration(
                        color: v2.cardSubtle,
                        borderRadius: BorderRadius.circular(InsightV2Theme.radiusCard.w),
                        border: Border.all(color: v2.borderSubtle),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(InsightV2Theme.radiusCard.w),
                        child: V2FoodImage(name: args.title, userImageUrl: displayImg, emoji: args.emoji ?? '🍽', size: 84, circle: false),
                      ),
                    ),
                    Gap.w14,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(args.title, style: V2Kit.text(context, size: 19, weight: FontWeight.w800, height: 1.2)),
                          if ((args.body ?? '').isNotEmpty) ...[Gap.h6, Text(args.body!, style: V2Kit.text(context, size: 12.5, color: v2.textSecondary, height: 1.5))],
                        ],
                      ),
                    ),
                  ],
                ),
                Gap.h14,
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      V2Stat(label: InsightV2Strings.timeframeStat, value: _emptyToDash(args.timeframe ?? args.footLeft)),
                      Gap.w8,
                      V2Stat(label: InsightV2Strings.frequencyStat, value: _emptyToDash(args.frequency), valueColor: v2.error),
                    ],
                  ),
                ),
                Gap.h16,
                if (args.chartValues.length >= 2) ...[
                  V2Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          InsightV2Strings.sevenDayTrend.toUpperCase(),
                          style: V2Kit.text(context, size: 9.5, weight: FontWeight.w700, color: v2.textTertiary, letterSpacing: 0.7),
                        ),
                        Gap.h10,
                        V2TrendChart(values: args.chartValues, height: 64, color: v2.error),
                      ],
                    ),
                  ),
                  Gap.h16,
                ],
                if (whyPoints.isNotEmpty) ...[
                  V2Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const V2SectionLabel(InsightV2Strings.whyTrigger),
                        Gap.h10,
                        V2WhyList(points: whyPoints, tone: V2Tone.error),
                      ],
                    ),
                  ),
                  Gap.h16,
                ],
                V2Button(label: InsightV2Strings.seeAlternativesCta, onTap: () => context.go(AppRoutes.insights)),
                Gap.h12,
                Center(
                  child: Text(
                    InsightV2Strings.basedOnLogsFooter,
                    textAlign: TextAlign.center,
                    style: V2Kit.text(context, size: 10.5, color: v2.textTertiary),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  static AIInsight? _insightOf(BuildContext context) {
    try {
      return context.read<InsightsNotifier>().latestInsight;
    } on ProviderNotFoundException {
      return null;
    }
  }

  static String _emptyToDash(String? value) => (value == null || value.trim().isEmpty) ? '—' : value.trim();
}

class _DrivingFoodItem {
  const _DrivingFoodItem({required this.name, required this.countText, required this.emoji, this.imageUrl, this.userImageUrl});

  final String name;
  final String countText;
  final String emoji;
  final String? imageUrl;
  final String? userImageUrl;
}
