import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_theme.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/v2_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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

  /// Healing / Improving Trend detail screen — matches exact mock layout from screenshot.
  Widget _buildHealingTrendDetail(BuildContext context) {
    final v2 = context.v2Theme;

    final headline = args.title.isNotEmpty ? args.title : 'Your gut barrier score is improving.';
    final bodyText = (args.body ?? '').isNotEmpty ? args.body! : 'Consistent vegetable fiber intake is actively improving your gut barrier score.';

    final series = args.chartValues.isNotEmpty ? args.chartValues : const [74.0, 75.0, 76.0, 77.0, 78.0, 78.0, 78.0];

    return Scaffold(
      backgroundColor: v2.scaffold,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Same GutSliverAppBar as other screens
          GutSliverAppBar(title: 'IMPROVING TREND', centerTitle: true, showBrandingIcon: false, backgroundColor: v2.scaffold),

          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 4.w, 16.w, 24.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Gap.h10,

                // 1. HERO SCORE CARD (Gut Barrier Score)
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4FAF5),
                    borderRadius: BorderRadius.circular(20.w),
                    border: Border.all(color: const Color(0xFFDCFCE7), width: 1.w),
                    boxShadow: [BoxShadow(color: const Color(0xFF17171B).withValues(alpha: 0.03), blurRadius: 6.w, offset: Offset(0, 2.w))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Badge + Timeframe
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.5.w),
                            decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(16.w)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.leaf, size: 10.w, color: const Color(0xFF15803D)),
                                Gap.w4,
                                Text(
                                  'Gut Barrier Score',
                                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w700, color: const Color(0xFF15803D)),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.5.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16.w),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Last 7 days',
                                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                                ),
                                Gap.w4,
                                Icon(LucideIcons.chevronDown, size: 12.w, color: const Color(0xFF0F172A)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Gap.h8,

                      Text(
                        headline,
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 15.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                      ),
                      Gap.h3,
                      Text(
                        bodyText,
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w500, color: const Color(0xFF475569), height: 1.25),
                      ),
                      Gap.h12,

                      // Chart & Badge Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 60.w,
                              child: V2TrendChart(values: series, height: 52, color: const Color(0xFF16A34A), endDot: true),
                            ),
                          ),
                          Gap.w12,

                          Container(
                            padding: EdgeInsets.all(10.w),
                            decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(16.w)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(3.w),
                                      decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
                                      child: Icon(LucideIcons.arrowUp, size: 10.w, color: Colors.white),
                                    ),
                                    Gap.w4,
                                    Text(
                                      '+4',
                                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 18.sp, fontWeight: FontWeight.w800, color: const Color(0xFF15803D)),
                                    ),
                                  ],
                                ),
                                Gap.h2,
                                Text(
                                  'points this week',
                                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: const Color(0xFF15803D), fontWeight: FontWeight.w600),
                                ),
                                Gap.h2,
                                Text(
                                  '74 → 78',
                                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Gap.h8,

                      // Days Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('Mon', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                          Text('Tue', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                          Text('Wed', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                          Text('Thu', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                          Text('Fri', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                          Text('Sat', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                          Text('Sun', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                        ],
                      ),
                      Gap.h10,

                      Text(
                        'Steady progress',
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                      ),
                      Text(
                        'Your score has increased by 4 points (5%) this week.',
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: const Color(0xFF475569)),
                      ),
                    ],
                  ),
                ),
                Gap.h10,

                // 2. WHAT'S CONTRIBUTING? SECTION
                _buildWhatsContributingSection(context),
                Gap.h10,

                // 3. WEEKLY STATS SECTION
                _buildWeeklyStatsSection(context),
                Gap.h10,

                // 4. PROGRESS HIGHLIGHTS SECTION
                _buildProgressHighlightsSection(context),
                Gap.h10,

                // 5. RECOMMENDED NEXT STEPS SECTION
                _buildNextStepsSection(context),
                Gap.h10,

                // 6. BOTTOM ENCOURAGEMENT BANNER ("Keep going!")
                _buildKeepGoingBanner(context),
                Gap.h12,
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// 2. What's Contributing? Section
  Widget _buildWhatsContributingSection(BuildContext context) {
    final insight = _insightOf(context);
    final foods = insight?.healingSummary?.foods.isNotEmpty == true
        ? insight!.healingSummary!.foods
        : (insight?.healingFoods.isNotEmpty == true
              ? insight!.healingFoods
                    .map((f) => InsightFood(foodId: 'f_${f.name}', name: f.name, emoji: f.emoji, imageUrl: f.userImageUrl ?? f.imageUrl, effect: f.effect, impactLevel: 'high'))
                    .toList()
              : const <InsightFood>[]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28.w,
              height: 28.w,
              decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(LucideIcons.sparkles, size: 14.w, color: const Color(0xFF15803D)),
            ),
            Gap.w8,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "What's Contributing?",
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                  ),
                  Text(
                    'These foods and habits are making a real difference.',
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
        Gap.h8,

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              if (foods.isEmpty) ...[
                _ContributingCard(
                  title: 'Vegetable Fiber',
                  subtitle: 'More fiber-rich plants',
                  badgeText: 'High Impact',
                  badgeColor: const Color(0xFFDCFCE7),
                  badgeTextColor: const Color(0xFF15803D),
                  imageKeyword: 'salad',
                  icon: LucideIcons.leaf,
                ),
                Gap.w8,
                _ContributingCard(
                  title: 'Fermented Foods',
                  subtitle: 'Supporting good bacteria',
                  badgeText: 'High Impact',
                  badgeColor: const Color(0xFFDCFCE7),
                  badgeTextColor: const Color(0xFF15803D),
                  imageKeyword: 'yogurt',
                  icon: LucideIcons.leaf,
                ),
              ] else
                for (final f in foods) ...[
                  _ContributingCard(
                    title: f.name,
                    subtitle: f.effect ?? 'Supports gut health',
                    badgeText: '${f.impactLevel.toUpperCase()} Impact',
                    badgeColor: const Color(0xFFDCFCE7),
                    badgeTextColor: const Color(0xFF15803D),
                    imageKeyword: f.name,
                    icon: LucideIcons.leaf,
                  ),
                  Gap.w8,
                ],
            ],
          ),
        ),
      ],
    );
  }

  /// 3. Weekly Stats Section
  Widget _buildWeeklyStatsSection(BuildContext context) {
    final insight = _insightOf(context);
    final avgScore = insight?.gutScore ?? 78;
    final bestDay = insight?.weeklyRecap?.bestDay ?? 'Latest';
    final foodsLogged = insight?.foodImpacts.length ?? insight?.healingFoods.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28.w,
              height: 28.w,
              decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(LucideIcons.barChart2, size: 14.w, color: const Color(0xFF15803D)),
            ),
            Gap.w8,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Stats',
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                  ),
                  Text(
                    'Your progress at a glance.',
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
        Gap.h8,

        Row(
          children: [
            Expanded(
              child: _WeeklyStatTile(
                icon: LucideIcons.trophy,
                iconBg: const Color(0xFFDCFCE7),
                iconColor: const Color(0xFF15803D),
                label: 'Average Score',
                value: '$avgScore',
                subtext: 'Gut health score',
              ),
            ),
            Gap.w6,
            Expanded(
              child: _WeeklyStatTile(icon: LucideIcons.calendarCheck, iconBg: const Color(0xFFDCFCE7), iconColor: const Color(0xFF15803D), label: 'Best Day', value: bestDay, subtext: 'Highest score'),
            ),
            Gap.w6,
            Expanded(
              child: _WeeklyStatTile(
                icon: LucideIcons.utensils,
                iconBg: const Color(0xFFFEF3C7),
                iconColor: const Color(0xFFB45309),
                label: 'Foods Logged',
                value: '$foodsLogged',
                subtext: 'Logged items',
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 4. Progress Highlights Section
  Widget _buildProgressHighlightsSection(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 28.w,
            height: 28.w,
            decoration: const BoxDecoration(color: Color(0xFFFEF3C7), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(LucideIcons.star, size: 14.w, color: const Color(0xFFB45309)),
          ),
          Gap.w8,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progress Highlights',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                ),
                Text(
                  'Real changes, real results.',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
      Gap.h8,

      Row(
        children: [
          Expanded(
            child: _HighlightBox(
              icon: LucideIcons.leaf,
              iconBg: Color(0xFFDCFCE7),
              iconColor: Color(0xFF15803D),
              title: 'Added fermented foods on 5 out of 7 days.',
              subtitle: "That's 71% of the week!",
            ),
          ),
          Gap.w8,
          Expanded(
            child: _HighlightBox(
              icon: LucideIcons.arrowDown,
              iconBg: Color(0xFFDCFCE7),
              iconColor: Color(0xFF15803D),
              title: 'Reduced sugary beverage intake by 50%.',
              subtitle: 'Great progress for your gut!',
            ),
          ),
        ],
      ),
    ],
  );

  /// 5. Recommended Next Steps Section
  Widget _buildNextStepsSection(BuildContext context) {
    final insight = _insightOf(context);
    final actions = insight?.actionsList ?? const [];

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28.w,
              height: 28.w,
              decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(LucideIcons.leaf, size: 14.w, color: const Color(0xFF15803D)),
            ),
            Gap.w8,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recommended Next Steps',
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                  ),
                  Text(
                    'Keep the momentum going.',
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
        Gap.h8,

        Row(
          children: [
            for (var i = 0; i < actions.take(2).length; i++) ...[
              if (i > 0) Gap.w8,
              Expanded(
                child: _NextStepCard(icon: i == 0 ? LucideIcons.leaf : LucideIcons.sprout, title: actions[i].title, body: actions[i].description),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// 6. Bottom Encouragement Quote Card ("Keep going!")
  Widget _buildKeepGoingBanner(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF5),
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: const Color(0xFFDCFCE7), width: 1.w),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '“',
            style: TextStyle(fontFamily: InsightV2Theme.displayFont, fontSize: 28.sp, fontWeight: FontWeight.w800, color: const Color(0xFF15803D), height: 1.0),
          ),
          Gap.w6,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keep going!',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 13.sp, fontWeight: FontWeight.w800, color: const Color(0xFF15803D)),
                ),
                Gap.h2,
                Text(
                  "You're building healthier habits, and your gut thanks you.",
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: const Color(0xFF334155), height: 1.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Trigger / Something to Watch Detail screen
  Widget _buildTriggerDetail(BuildContext context) {
    final v2 = context.v2Theme;
    final insight = _insightOf(context);
    final pattern = insight?.detectedPatterns.where((p) => p.type.toLowerCase().contains('trigger') || p.reaction.isNotEmpty).firstOrNull;

    final title = args.title.isNotEmpty ? args.title : 'Fried Foods → Bloating';
    final bodyText = (args.body ?? '').isNotEmpty ? args.body! : 'Fried and heavily processed foods consistently precede bloating by 2 hours.';

    final occurrences = pattern?.occurrences ?? const <PatternOccurrence>[];

    return Scaffold(
      backgroundColor: v2.scaffold,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Same GutSliverAppBar as other screens
          GutSliverAppBar(title: 'TRIGGER DETAILS', centerTitle: true, showBrandingIcon: false, backgroundColor: v2.scaffold),

          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 4.w, 16.w, 24.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. HERO TRIGGER CARD
                _buildTriggerHeroCard(context, title: title, bodyText: bodyText, pattern: pattern),
                Gap.h10,

                // 2. RECENT OCCURRENCES SECTION
                _buildRecentOccurrencesSection(context, occurrences: occurrences),
                Gap.h10,

                // 3. OUR RECOMMENDATION (SMART SWAP) CARD
                _buildRecommendationCard(context),
                Gap.h10,

                // 4. RELATED TRIGGER FOODS SECTION
                _buildRelatedTriggerFoodsSection(context),
                Gap.h10,

                // 5. GOOD TO KNOW TIP CARD
                _buildGoodToKnowCard(context),
                Gap.h12,
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// 1. Hero Trigger Card ("Something to Watch")
  Widget _buildTriggerHeroCard(BuildContext context, {required String title, required String bodyText, required BodyPattern? pattern}) {
    final foodImageUrl = V2Kit.foodImageUrl(title);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F6),
        borderRadius: BorderRadius.circular(20.w),
        boxShadow: [BoxShadow(color: const Color(0xFF17171B).withValues(alpha: 0.03), blurRadius: 6.w, offset: Offset(0, 2.w))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Stack with angled food image on right
          SizedBox(
            height: 152.w,
            child: Stack(
              children: [
                // Right Food Image
                Positioned.fill(
                  child: Row(
                    children: [
                      const Spacer(flex: 4),
                      Expanded(
                        flex: 4,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: foodImageUrl,
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                              placeholder: (_, _) => Container(color: const Color(0xFFF1F5F9)),
                              errorWidget: (_, _, _) => Container(color: const Color(0xFFFEE2E2)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Left Angled Clipper
                Positioned.fill(
                  child: ClipPath(
                    clipper: const _HeroAngledClipper(),
                    child: Container(color: const Color(0xFFFFFDF7)),
                  ),
                ),

                // Content Left Column
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 195.w,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12.w, 10.w, 6.w, 10.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tag Pill
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.w),
                          decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(16.w)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.alertTriangle, size: 10.w, color: const Color(0xFF991B1B)),
                              Gap.w4,
                              Text(
                                'Something to Watch',
                                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w700, color: const Color(0xFF991B1B)),
                              ),
                            ],
                          ),
                        ),
                        Gap.h6,

                        // Title
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 15.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), height: 1.15, letterSpacing: -0.3),
                        ),
                        Gap.h4,

                        // Description
                        Text(
                          bodyText,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w500, color: const Color(0xFF334155), height: 1.25),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Stats Bar (4 columns)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.w),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF5F2),
              border: Border(top: BorderSide(color: Color(0xFFFEE2E2))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stat 1: High Frequency
                Expanded(
                  child: _TriggerStatCol(
                    icon: LucideIcons.barChart2,
                    iconBg: const Color(0xFFFEE2E2),
                    iconColor: const Color(0xFFDC2626),
                    label: 'High Frequency',
                    value: '${pattern?.frequency ?? 4} occurrences',
                    subtext: 'Last 7 days',
                  ),
                ),
                Gap.w4,

                // Stat 2: Symptom
                Expanded(
                  child: _TriggerStatCol(
                    icon: LucideIcons.activity,
                    iconBg: const Color(0xFFFEE2E2),
                    iconColor: const Color(0xFFDC2626),
                    label: 'Symptom',
                    value: pattern?.reaction.isNotEmpty == true ? pattern!.reaction : 'Mild bloating',
                    subtext: 'Common reaction',
                  ),
                ),
                Gap.w4,

                // Stat 3: Typical Delay
                Expanded(
                  child: const _TriggerStatCol(icon: LucideIcons.clock, iconBg: Color(0xFFFEE2E2), iconColor: Color(0xFFDC2626), label: 'Typical Delay', value: '~ 2 hours', subtext: 'After eating'),
                ),
                Gap.w4,

                // Stat 4: Confidence
                Expanded(
                  child: _TriggerStatCol(
                    icon: LucideIcons.leaf,
                    iconBg: const Color(0xFFDCFCE7),
                    iconColor: const Color(0xFF15803D),
                    label: 'Confidence',
                    value: pattern?.confidence.isNotEmpty == true ? pattern!.confidence : 'High',
                    subtext: 'Based on your data',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Recent Occurrences Section
  Widget _buildRecentOccurrencesSection(BuildContext context, {required List<PatternOccurrence> occurrences}) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.w),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28.w,
                height: 28.w,
                decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(LucideIcons.fileText, size: 14.w, color: const Color(0xFF0F172A)),
              ),
              Gap.w8,
              Expanded(
                child: Text(
                  'Recent Occurrences',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                ),
              ),
              GestureDetector(
                onTap: () => context.push(AppRoutes.allScans),
                child: Row(
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                    ),
                    Gap.w2,
                    Icon(Icons.arrow_forward_rounded, size: 11.w, color: const Color(0xFF0F172A)),
                  ],
                ),
              ),
            ],
          ),
          Gap.h10,

          // Timeline items
          for (final o in occurrences.take(3)) ...[_OccurrenceTile(occurrence: o), Gap.h8],
        ],
      ),
    );
  }

  /// 3. Our Recommendation (Smart Swap) Card
  Widget _buildRecommendationCard(BuildContext context) {
    final veggiesUrl = V2Kit.foodImageUrl('Steamed Vegetables Bowl');

    return Container(
      height: 140.w,
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF5),
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: const Color(0xFFDCFCE7), width: 1.w),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Photo on Right
          Positioned.fill(
            child: Row(
              children: [
                const Spacer(flex: 4),
                Expanded(
                  flex: 4,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: veggiesUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        placeholder: (_, _) => Container(color: const Color(0xFFF1F5F9)),
                        errorWidget: (_, _, _) => Container(color: const Color(0xFFDCFCE7)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Angled Background Clipper
          Positioned.fill(
            child: ClipPath(
              clipper: const _HeroAngledClipper(),
              child: Container(color: const Color(0xFFF4FAF5)),
            ),
          ),

          // Content Left
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 200.w,
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                            child: Icon(LucideIcons.leaf, size: 11.w, color: const Color(0xFF15803D)),
                          ),
                          Gap.w6,
                          Text(
                            'Our Recommendation',
                            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFF15803D)),
                          ),
                        ],
                      ),
                      Gap.h6,
                      Text(
                        'Swap fried sides for roasted or steamed alternatives.',
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A), height: 1.25),
                      ),
                    ],
                  ),

                  GestureDetector(
                    onTap: () => context.push(AppRoutes.swapDetail),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.w),
                      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(16.w)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Plan Better Swaps',
                            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          Gap.w3,
                          Icon(Icons.arrow_forward_rounded, size: 10.w, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 4. Related Trigger Foods Section
  Widget _buildRelatedTriggerFoodsSection(BuildContext context) {
    final relatedFoods = [
      const _RelatedFoodData(title: 'Deep-Fried Foods', subtitle: 'e.g., onion rings, fried chicken, french fries', imageKeyword: 'Deep Fried Foods'),
      const _RelatedFoodData(title: 'Refined Vegetable Oils', subtitle: 'e.g., soybean, corn, canola oil', imageKeyword: 'Vegetable Oil Bottle'),
      const _RelatedFoodData(title: 'Heavily Processed Foods', subtitle: 'e.g., fast food, packaged snacks, fried snacks', imageKeyword: 'Burger Fries Fast Food'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28.w,
              height: 28.w,
              decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(LucideIcons.link, size: 14.w, color: const Color(0xFF1D4ED8)),
            ),
            Gap.w8,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Related Trigger Foods',
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                  ),
                  Text(
                    'These foods often show similar patterns for you.',
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
        Gap.h8,

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (final f in relatedFoods) ...[_RelatedFoodCard(data: f), Gap.w8],
            ],
          ),
        ),
      ],
    );
  }

  /// 5. Good to Know Card
  Widget _buildGoodToKnowCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF5),
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: const Color(0xFFDCFCE7), width: 1.w),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28.w,
            height: 28.w,
            decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(LucideIcons.lightbulb, size: 14.w, color: const Color(0xFF15803D)),
          ),
          Gap.w10,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good to Know',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFF15803D)),
                ),
                Gap.h3,
                Text(
                  'Frying can make foods higher in fat and harder to digest, which may trigger bloating for sensitive guts.',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: const Color(0xFF334155), height: 1.3),
                ),
              ],
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
}

// =============================================================================
// SUB-COMPONENTS & PAINTERS
// =============================================================================

class _ContributingCard extends StatelessWidget {
  const _ContributingCard({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.imageKeyword,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String badgeText;
  final Color badgeColor;
  final Color badgeTextColor;
  final String imageKeyword;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final imageUrl = V2Kit.foodImageUrl(imageKeyword);

    return Container(
      width: 108.w,
      padding: EdgeInsets.all(7.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF7),
        borderRadius: BorderRadius.circular(14.w),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.w),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: 94.w,
              height: 60.w,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(color: const Color(0xFFF1F5F9)),
              errorWidget: (_, _, _) => Container(
                color: const Color(0xFFDCFCE7),
                alignment: Alignment.center,
                child: Icon(icon, size: 20.w, color: const Color(0xFF15803D)),
              ),
            ),
          ),
          Gap.h5,
          Text(
            title,
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.sp, color: const Color(0xFF64748B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Gap.h3,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.w),
            decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(10.w)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 8.5.w, color: badgeTextColor),
                Gap.w2,
                Text(
                  badgeText,
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w700, color: badgeTextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyStatTile extends StatelessWidget {
  const _WeeklyStatTile({required this.icon, required this.iconBg, required this.iconColor, required this.label, required this.value, required this.subtext});

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final String subtext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.w),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24.w,
            height: 24.w,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(icon, size: 12.w, color: iconColor),
          ),
          Gap.h6,
          Text(
            label,
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 16.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
          ),
          Text(
            subtext,
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.5.sp, color: const Color(0xFF64748B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _HighlightBox extends StatelessWidget {
  const _HighlightBox({required this.icon, required this.iconBg, required this.iconColor, required this.title, required this.subtitle});

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.w),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22.w,
            height: 22.w,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(icon, size: 11.w, color: iconColor),
          ),
          Gap.w6,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A), height: 1.2),
                ),
                Gap.h2,
                Text(
                  subtitle,
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: const Color(0xFF64748B), height: 1.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NextStepCard extends StatelessWidget {
  const _NextStepCard({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF5),
        borderRadius: BorderRadius.circular(14.w),
        border: Border.all(color: const Color(0xFFDCFCE7), width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 22.w,
                height: 22.w,
                decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(icon, size: 11.w, color: const Color(0xFF15803D)),
              ),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFDCFCE7)),
                ),
                child: Icon(Icons.arrow_forward_rounded, size: 10.w, color: const Color(0xFF15803D)),
              ),
            ],
          ),
          Gap.h6,
          Text(
            title,
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A), height: 1.2),
          ),
          Gap.h2,
          Text(
            body,
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: const Color(0xFF475569), height: 1.2),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TriggerStatCol extends StatelessWidget {
  const _TriggerStatCol({required this.icon, required this.iconBg, required this.iconColor, required this.label, required this.value, required this.subtext});

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final String subtext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22.w,
          height: 22.w,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Icon(icon, size: 11.w, color: iconColor),
        ),
        Gap.h4,
        Text(
          label,
          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.sp, color: const Color(0xFFDC2626), fontWeight: FontWeight.w600),
        ),
        Gap.h2,
        Text(
          value,
          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), height: 1.15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Gap.h2,
        Text(
          subtext,
          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.5.sp, color: const Color(0xFF64748B)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _OccurrenceTile extends StatelessWidget {
  const _OccurrenceTile({required this.occurrence});

  final PatternOccurrence occurrence;

  @override
  Widget build(BuildContext context) {
    final imgUrl = V2Kit.foodImageUrl(occurrence.mealName, imageUrl: occurrence.imageUrl);

    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.w),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.w),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10.w)),
            child: Text(
              occurrence.date.isNotEmpty ? occurrence.date : (occurrence.dateLabel ?? 'Observed'),
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
            ),
          ),
          Gap.w8,
          ClipRRect(
            borderRadius: BorderRadius.circular(8.w),
            child: CachedNetworkImage(
              imageUrl: imgUrl,
              width: 44.w,
              height: 44.w,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(color: const Color(0xFFF1F5F9)),
              errorWidget: (_, _, _) => Container(color: const Color(0xFFFEF3C7)),
            ),
          ),
          Gap.w8,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  occurrence.mealName,
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Gap.h2,
                Text(
                  occurrence.reaction.isNotEmpty ? occurrence.reaction : 'Abdominal bloating',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, color: const Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Gap.w6,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                occurrence.timeAfter.isNotEmpty ? occurrence.timeAfter : '2 hours after',
                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: const Color(0xFF475569)),
              ),
              Gap.w4,
              Icon(Icons.chevron_right_rounded, size: 14.w, color: const Color(0xFF94A3B8)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RelatedFoodData {
  const _RelatedFoodData({required this.title, required this.subtitle, required this.imageKeyword});
  final String title;
  final String subtitle;
  final String imageKeyword;
}

class _RelatedFoodCard extends StatelessWidget {
  const _RelatedFoodCard({required this.data});

  final _RelatedFoodData data;

  @override
  Widget build(BuildContext context) {
    final imgUrl = V2Kit.foodImageUrl(data.imageKeyword);

    return Container(
      width: 118.w,
      padding: EdgeInsets.all(7.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF7),
        borderRadius: BorderRadius.circular(14.w),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.w),
            child: CachedNetworkImage(
              imageUrl: imgUrl,
              width: 104.w,
              height: 64.w,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(color: const Color(0xFFF1F5F9)),
              errorWidget: (_, _, _) => Container(color: const Color(0xFFFEE2E2)),
            ),
          ),
          Gap.h5,
          Text(
            data.title,
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Gap.h2,
          Text(
            data.subtitle,
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.sp, color: const Color(0xFF64748B)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _HeroAngledClipper extends CustomClipper<Path> {
  const _HeroAngledClipper();

  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, 0)
    ..lineTo(size.width * 0.62, 0)
    ..lineTo(size.width * 0.52, size.height)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
