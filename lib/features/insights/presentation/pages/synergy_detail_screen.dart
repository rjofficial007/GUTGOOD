import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/pattern_grid.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_theme.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/v2_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// Synergy & Pattern deep dive screen.
///
/// Matches the exact editorial design and compactness language of the Insights tab:
/// standard [GutSliverAppBar], compact v2 bento cards, "What We Observed" banner,
/// "The Evidence" 4-stat metric dashboard, "Involved Foods" horizontal grid,
/// and supporting evidence summaries.
class SynergyDetailScreen extends StatelessWidget {
  const SynergyDetailScreen({super.key, this.insight, this.pattern});

  final AIInsight? insight;
  final BodyPattern? pattern;

  @override
  Widget build(BuildContext context) {
    final v2 = context.v2Theme;
    final activeInsight = insight ?? _getLatestInsight(context);
    final activePattern = pattern ?? activeInsight?.detectedPatterns.firstOrNull;

    final evidenceRef = activeInsight?.evidence?.patternRefs.firstOrNull;
    final evidenceRatio = activePattern != null && (activePattern.evidenceRatio > 0 || activePattern.positiveCount + activePattern.negativeCount > 0)
        ? (activePattern.evidenceRatio.clamp(0.0, 1.0) * 100).round()
        : activeInsight?.topInsight?.evidenceRatio != null
        ? (activeInsight!.topInsight!.evidenceRatio!.clamp(0.0, 1.0) * 100).round()
        : evidenceRef == null
        ? null
        : (evidenceRef.evidenceRatio.clamp(0.0, 1.0) * 100).round();
    final frequencyCount = activePattern?.frequency ?? activeInsight?.topInsight?.frequency ?? (activeInsight?.foodImpacts.isNotEmpty == true ? activeInsight!.foodImpacts.length : null);
    final positiveCount =
        activePattern?.positiveCount ??
        activeInsight?.topInsight?.positiveCount ??
        (activeInsight?.foodImpacts.isNotEmpty == true ? activeInsight!.foodImpacts.where((f) => f.impactType == 'positive').length : null);
    final negativeCount =
        activePattern?.negativeCount ??
        activeInsight?.topInsight?.negativeCount ??
        (activeInsight?.foodImpacts.isNotEmpty == true ? activeInsight!.foodImpacts.where((f) => f.impactType == 'negative').length : null);

    return Scaffold(
      backgroundColor: v2.scaffold,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Standard GutSliverAppBar
          GutSliverAppBar(
            title: activePattern?.type != null ? '${patternName(activePattern!.type).toUpperCase()} PATTERN' : 'GUT INSIGHT',
            centerTitle: true,
            showBrandingIcon: false,
            backgroundColor: v2.scaffold,
          ),

          // --- Body Content --------------------------------------------------
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 4.w, 16.w, 24.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. HERO PATTERN CARD
                _buildHeroCard(context, activePattern, activeInsight),
                Gap.h10,

                // 2. WHAT WE OBSERVED CARD
                _buildWhatWeObservedCard(context, activePattern, activeInsight),
                Gap.h10,

                // 3. THE EVIDENCE DASHBOARD
                _buildTheEvidenceCard(
                  context,
                  patternType: activePattern?.type ?? 'digestion',
                  evidenceRatio: evidenceRatio,
                  frequency: frequencyCount,
                  positive: positiveCount,
                  negative: negativeCount,
                ),
                Gap.h10,

                // 4. INVOLVED FOODS SECTION
                _buildInvolvedFoodsSection(context, activePattern, activeInsight),
                Gap.h10,

                // 5. SPLIT GRID: YOUR NEXT STEPS & SUPPORTING EVIDENCE
                _buildSplitGridSection(context, activeInsight),
                Gap.h12,
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// 1. Top Hero Pattern Card (Ultra-Polished Bento Style)
  Widget _buildHeroCard(BuildContext context, BodyPattern? pattern, AIInsight? activeInsight) {
    final frequencyCount = pattern?.frequency ?? activeInsight?.topInsight?.frequency ?? (activeInsight?.foodImpacts.isNotEmpty == true ? activeInsight!.foodImpacts.length : 0);
    final foodName = pattern?.involvedFoods.isNotEmpty == true
        ? pattern!.involvedFoods.first
        : (activeInsight?.healingFoods.firstOrNull?.name ?? activeInsight?.topInsight?.involvedFoods.firstOrNull ?? 'Whole Foods');
    final imageUrl = V2Kit.foodImageUrl(foodName);
    final style = PatternCardStyle.forType(pattern?.type ?? 'digestion');

    final trigger = pattern?.trigger.trim() ?? '';
    final reaction = pattern?.reaction.trim() ?? '';
    final title = (trigger.isNotEmpty || reaction.isNotEmpty)
        ? ((trigger.isNotEmpty && reaction.isNotEmpty) ? '$trigger → $reaction' : (trigger.isNotEmpty ? trigger : reaction))
        : (activeInsight?.topInsight?.title.isNotEmpty == true ? activeInsight!.topInsight!.title : 'Gut Pattern Detail');

    final sub = pattern?.description.isNotEmpty == true
        ? pattern!.description
        : (activeInsight?.topInsight?.description.isNotEmpty == true
              ? activeInsight!.topInsight!.description
              : (activeInsight?.healingGoal?.isNotEmpty == true ? activeInsight!.healingGoal! : 'Track your daily meals to discover how foods affect your gut.'));

    final v2 = context.v2Theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? v2.card : style.cardBg,
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: isDark ? v2.border : style.borderColor, width: 1.w),
        boxShadow: [BoxShadow(color: style.accentColor.withValues(alpha: 0.06), blurRadius: 10.w, offset: const Offset(0, 3))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Content Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag Row
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.5.w),
                      decoration: BoxDecoration(color: style.tagBg, borderRadius: BorderRadius.circular(14.w)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(style.icon, size: 10.w, color: style.tagFg),
                          Gap.w4,
                          Text(
                            style.label,
                            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w700, color: style.tagFg),
                          ),
                        ],
                      ),
                    ),
                    Gap.w6,
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.5.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(10.w),
                        border: Border.all(color: style.borderColor),
                      ),
                      child: Text(
                        '${pattern?.confidence ?? "High"} Conf.',
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w700, color: style.tagFg),
                      ),
                    ),
                  ],
                ),
                Gap.h8,

                // Title
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: InsightV2Theme.fontFamily,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: context.insightColor(const Color(0xFF0F172A)),
                    height: 1.15,
                    letterSpacing: -0.3,
                  ),
                ),
                Gap.h4,

                // Description
                Text(
                  sub,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w500, color: context.insightColor(const Color(0xFF334155)), height: 1.3),
                ),
                Gap.h10,

                // Verified Shield Badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.w),
                  decoration: BoxDecoration(
                    color: style.accentColor,
                    borderRadius: BorderRadius.circular(16.w),
                    boxShadow: [BoxShadow(color: style.accentColor.withValues(alpha: 0.25), blurRadius: 6.w, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.shieldCheck, size: 11.w, color: Colors.white),
                      Gap.w4,
                      Text(
                        'Pattern Verified',
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Gap.w12,

          // Right Floating Food Photo Card
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 96.w,
                height: 106.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.w),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8.w, offset: const Offset(0, 3))],
                ),
                clipBehavior: Clip.antiAlias,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  placeholder: (_, _) => Container(color: style.tagBg),
                  errorWidget: (_, _, _) => Container(
                    color: style.tagBg,
                    child: Icon(style.icon, color: style.tagFg, size: 28),
                  ),
                ),
              ),
              if (frequencyCount > 0)
                Positioned(
                  right: -4.w,
                  bottom: -4.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.w),
                    decoration: BoxDecoration(
                      color: context.insightColor(const Color(0xFF0F172A)),
                      borderRadius: BorderRadius.circular(10.w),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4.w)],
                    ),
                    child: Text(
                      '${frequencyCount}x seen',
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 2. "What We Observed" Section
  Widget _buildWhatWeObservedCard(BuildContext context, BodyPattern? pattern, AIInsight? activeInsight) {
    final style = PatternCardStyle.forType(pattern?.type ?? 'digestion');
    final observationText =
        activeInsight?.topInsight?.description ??
        (pattern != null
            ? 'Repeated meal logs show a correlation between your intake and recurring gut responses.'
            : 'Your logs suggest a meaningful synergy between recent food choices and your gut scores.');

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.insightColor(Colors.white),
        borderRadius: BorderRadius.circular(18.w),
        border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0)), width: 1.w),
        boxShadow: [BoxShadow(color: const Color(0xFF17171B).withValues(alpha: 0.03), blurRadius: 6.w, offset: Offset(0, 2.w))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(color: style.tagBg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(style.icon, size: 16.w, color: style.tagFg),
          ),
          Gap.w10,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What We Observed',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                ),
                Gap.h3,
                Text(
                  observationText,
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w500, color: context.insightColor(const Color(0xFF475569)), height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3. "The Evidence" Metric Dashboard Card
  Widget _buildTheEvidenceCard(BuildContext context, {required String patternType, required int? evidenceRatio, required int? frequency, required int? positive, required int? negative}) {
    final style = PatternCardStyle.forType(patternType);

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.insightColor(Colors.white),
        borderRadius: BorderRadius.circular(18.w),
        border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0)), width: 1.w),
        boxShadow: [BoxShadow(color: const Color(0xFF17171B).withValues(alpha: 0.03), blurRadius: 6.w, offset: Offset(0, 2.w))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(color: style.tagBg, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(LucideIcons.barChart2, size: 14.w, color: style.tagFg),
              ),
              Gap.w8,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'The Evidence',
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                    ),
                    Text(
                      'Based on the evidence saved with this insight.',
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: context.insightColor(const Color(0xFF64748B))),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Gap.h12,

          // 4 Stat Cards Row
          Row(
            children: [
              _buildMetricTile(context, title: evidenceRatio == null ? '—' : '$evidenceRatio%', label: 'Evidence Ratio', icon: LucideIcons.pieChart, color: style.accentColor, bg: style.tagBg),
              Gap.w6,
              _buildMetricTile(context, title: frequency == null ? '—' : '$frequency×', label: 'Times Logged', icon: LucideIcons.history, color: style.accentColor, bg: style.tagBg),
              Gap.w6,
              _buildMetricTile(
                context,
                title: positive == null ? '—' : '$positive',
                label: 'Positive Logs',
                icon: LucideIcons.thumbsUp,
                color: const Color(0xFF15803D),
                bg: context.insightColor(const Color(0xFFF0FDF4)),
              ),
              Gap.w6,
              _buildMetricTile(
                context,
                title: negative == null ? '—' : '$negative',
                label: 'Symptom Logs',
                icon: LucideIcons.thumbsDown,
                color: const Color(0xFFDC2626),
                bg: context.insightColor(const Color(0xFFFEF2F2)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(BuildContext context, {required String title, required String label, required IconData icon, required Color color, required Color bg}) => Expanded(
    child: Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: context.insightColor(bg),
        borderRadius: BorderRadius.circular(12.w),
        border: Border.all(color: context.insightColor(color).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(color: context.insightColor(color).withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(icon, size: 10.w, color: context.insightColor(color)),
              ),
            ],
          ),
          Gap.h6,
          Text(
            title,
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
          ),
          Gap.h2,
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w600, color: context.insightColor(const Color(0xFF64748B))),
          ),
        ],
      ),
    ),
  );

  /// 4. "Involved Foods" Horizontal Grid Section
  Widget _buildInvolvedFoodsSection(BuildContext context, BodyPattern? pattern, AIInsight? insight) {
    final foods = (pattern?.involvedFoods.isNotEmpty == true
        ? pattern!.involvedFoods.map((f) => _FoodCardData(name: f, imageKeyword: f)).toList()
        : (insight?.healingFoods.isNotEmpty == true ? insight!.healingFoods.map((f) => _FoodCardData(name: f.name, imageKeyword: f.name)).toList() : <_FoodCardData>[]));

    if (foods.isEmpty) {
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
              decoration: BoxDecoration(color: context.insightColor(const Color(0xFFFEF3C7)), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(LucideIcons.utensils, size: 14.w, color: context.insightColor(const Color(0xFFB45309))),
            ),
            Gap.w8,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Involved Foods',
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                  ),
                  Text(
                    'These foods often appear together in your data.',
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: context.insightColor(const Color(0xFF64748B))),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.push(AppRoutes.foodIntelligence),
              child: Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: context.insightColor(const Color(0xFF0F172A))),
                  ),
                  Gap.w2,
                  Icon(Icons.arrow_forward_rounded, size: 11.w, color: context.insightColor(const Color(0xFF0F172A))),
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
              for (final food in foods) ...[_InvolvedFoodCard(food: food), Gap.w8],
            ],
          ),
        ),
      ],
    );
  }

  /// 5. Split Grid Section ("Your Next Steps" & "Supporting Evidence")
  Widget _buildSplitGridSection(BuildContext context, AIInsight? insight) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Column: Your Next Steps
        Expanded(child: _buildYourNextStepsCard(context, insight)),
        Gap.w10,

        // Right Column: Supporting Evidence
        Expanded(child: _buildSupportingEvidenceCard(context, insight)),
      ],
    ),
  );

  Widget _buildYourNextStepsCard(BuildContext context, AIInsight? insight) => Container(
    padding: EdgeInsets.all(10.w),
    decoration: BoxDecoration(
      color: context.insightColor(const Color(0xFFF4FAF5)),
      borderRadius: BorderRadius.circular(16.w),
      border: Border.all(color: context.insightColor(const Color(0xFFDCFCE7)), width: 1.w),
    ),
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
                  width: 24.w,
                  height: 24.w,
                  decoration: BoxDecoration(color: context.insightColor(const Color(0xFFDCFCE7)), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Icon(LucideIcons.leaf, size: 12.w, color: context.insightColor(const Color(0xFF15803D))),
                ),
                Gap.w6,
                Expanded(
                  child: Text(
                    'Your Next Steps',
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                  ),
                ),
              ],
            ),
            Gap.h3,
            Text(
              'Try these simple actions to keep seeing the benefits.',
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: context.insightColor(const Color(0xFF475569)), height: 1.2),
            ),
            Gap.h10,

            if (insight?.actionsList.isNotEmpty == true) ...[
              for (var i = 0; i < insight!.actionsList.take(2).length; i++) ...[
                if (i > 0) Gap.h8,
                _NextStepCheckRow(title: insight.actionsList[i].title, subtitle: insight.actionsList[i].description),
              ],
            ] else ...[
              _NextStepCheckRow(title: insight?.topInsight?.nextSteps.firstOrNull ?? 'Increase prebiotic fiber intake', subtitle: 'Add whole plant foods to support gut flora.'),
            ],
          ],
        ),
      ],
    ),
  );

  Widget _buildSupportingEvidenceCard(BuildContext context, AIInsight? insight) {
    final mealsCount = insight?.evidence?.sampleSizes.meals;
    final symptomsCount = insight?.evidence?.sampleSizes.symptoms;
    final scansCount = insight?.evidence?.sampleSizes.scans;

    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: context.insightColor(const Color(0xFFF0F7FF)),
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0)), width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24.w,
                height: 24.w,
                decoration: BoxDecoration(color: context.insightColor(const Color(0xFFDBEAFE)), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(LucideIcons.fileText, size: 12.w, color: context.insightColor(const Color(0xFF1D4ED8))),
              ),
              Gap.w4,
              Expanded(
                child: Text(
                  'Supporting Evidence',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                ),
              ),
              Icon(LucideIcons.info, size: 13.w, color: context.insightColor(const Color(0xFF94A3B8))),
            ],
          ),
          Gap.h2,
          Text(
            'Based on your logged data.',
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: context.insightColor(const Color(0xFF475569))),
          ),
          Gap.h10,

          // Metric Rows
          _EvidenceMetricRow(icon: LucideIcons.utensils, title: 'Meals', subtitle: 'Total meals analyzed', value: mealsCount?.toString() ?? '—'),
          Gap.h8,

          _EvidenceMetricRow(icon: LucideIcons.clipboardList, title: 'Symptoms', subtitle: 'Symptom logs', value: symptomsCount?.toString() ?? '—'),
          Gap.h8,

          _EvidenceMetricRow(icon: LucideIcons.fileText, title: 'Scans', subtitle: 'Total gut scans', value: scansCount?.toString() ?? '—'),
        ],
      ),
    );
  }

  static AIInsight? _getLatestInsight(BuildContext context) {
    try {
      return context.read<InsightsNotifier>().latestInsight;
    } on ProviderNotFoundException {
      return null;
    }
  }
}

class _FoodCardData {
  const _FoodCardData({required this.name, required this.imageKeyword});
  final String name;
  final String imageKeyword;
}

class _InvolvedFoodCard extends StatelessWidget {
  const _InvolvedFoodCard({required this.food});

  final _FoodCardData food;

  @override
  Widget build(BuildContext context) {
    final imageUrl = V2Kit.foodImageUrl(food.imageKeyword);

    return Container(
      width: 108.w,
      padding: EdgeInsets.all(7.w),
      decoration: BoxDecoration(
        color: context.insightColor(const Color(0xFFFFFDF7)),
        borderRadius: BorderRadius.circular(14.w),
        border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0)), width: 1.w),
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
              placeholder: (_, _) => Container(color: context.insightColor(const Color(0xFFF1F5F9))),
              errorWidget: (_, _, _) => Container(
                color: context.insightColor(const Color(0xFFFEF3C7)),
                alignment: Alignment.center,
                child: Icon(LucideIcons.utensils, size: 20.w, color: context.insightColor(const Color(0xFFD97706))),
              ),
            ),
          ),
          Gap.h4,
          Text(
            food.name,
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w700, color: context.insightColor(const Color(0xFF0F172A))),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Gap.h3,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.w),
            decoration: BoxDecoration(color: context.insightColor(const Color(0xFFDCFCE7)), borderRadius: BorderRadius.circular(10.w)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.leaf, size: 8.5.w, color: context.insightColor(const Color(0xFF15803D))),
                Gap.w2,
                Text(
                  'High Impact',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w700, color: context.insightColor(const Color(0xFF15803D))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NextStepCheckRow extends StatelessWidget {
  const _NextStepCheckRow({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 16.w,
        height: 16.w,
        margin: EdgeInsets.only(top: 1.w),
        decoration: BoxDecoration(color: context.insightColor(const Color(0xFF16A34A)), shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(LucideIcons.check, size: 10.w, color: Colors.white),
      ),
      Gap.w6,
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: context.insightColor(const Color(0xFF0F172A)), height: 1.2),
            ),
            Gap.h2,
            Text(
              subtitle,
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: context.insightColor(const Color(0xFF475569)), height: 1.2),
            ),
          ],
        ),
      ),
    ],
  );
}

class _EvidenceMetricRow extends StatelessWidget {
  const _EvidenceMetricRow({required this.icon, required this.title, required this.subtitle, required this.value});

  final IconData icon;
  final String title;
  final String subtitle;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 22.w,
        height: 22.w,
        decoration: BoxDecoration(color: context.insightColor(const Color(0xFFDBEAFE)), shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(icon, size: 11.w, color: context.insightColor(const Color(0xFF1D4ED8))),
      ),
      Gap.w6,
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: context.insightColor(const Color(0xFF0F172A)), height: 1.1),
            ),
            Text(
              subtitle,
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.sp, color: context.insightColor(const Color(0xFF64748B)), height: 1.1),
            ),
          ],
        ),
      ),
      Text(
        value,
        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
      ),
    ],
  );
}
