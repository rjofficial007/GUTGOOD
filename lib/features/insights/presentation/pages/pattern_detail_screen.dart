import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/pattern_grid.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_theme.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/v2_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// Pattern Details — Synergy-style UI/UX presentation.
///
/// Features bento cards: Hero Pattern Card with right angled food image,
/// "What We Observed" banner, "The Evidence" 4-stat metric dashboard,
/// "Involved Foods" horizontal grid, "Occurrences & Factors" timeline, and "Split Grid" section.
class PatternDetailScreen extends StatelessWidget {
  const PatternDetailScreen({super.key, required this.pattern});

  final BodyPattern pattern;

  @override
  Widget build(BuildContext context) {
    final v2 = context.v2Theme;
    final evidenceRatio = (pattern.evidenceRatio * 100).round();
    final frequency = pattern.frequency;
    final symptomLogs = pattern.positiveCount > 0 ? pattern.positiveCount : (pattern.occurrences.isNotEmpty ? pattern.occurrences.length : pattern.frequency);
    final normalLogs = pattern.negativeCount;

    return Scaffold(
      backgroundColor: v2.scaffold,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Standard GutSliverAppBar matching SynergyDetailScreen
          GutSliverAppBar(title: '${patternName(pattern.type).toUpperCase()} PATTERN', centerTitle: true, showBrandingIcon: false, backgroundColor: v2.scaffold),

          // --- Body Content --------------------------------------------------
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 4.w, 16.w, 24.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. HERO PATTERN CARD
                _buildHeroCard(context),
                Gap.h10,

                // 2. WHAT WE OBSERVED CARD
                _buildWhatWeObservedCard(context),
                Gap.h10,

                // 3. THE EVIDENCE DASHBOARD
                _buildTheEvidenceCard(context, evidenceRatio: evidenceRatio, frequency: frequency, symptomLogs: symptomLogs, normalLogs: normalLogs),
                Gap.h10,

                // 4. INVOLVED FOODS SECTION
                _buildInvolvedFoodsSection(context),
                Gap.h10,

                // 5. OCCURRENCES TIMELINE & COMMON FACTORS CARD
                _buildOccurrencesTimelineCard(context),
                Gap.h10,

                // 6. SPLIT GRID: YOUR NEXT STEPS & SUPPORTING EVIDENCE
                _buildSplitGridSection(context),
                Gap.h12,
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// 1. Top Hero Pattern Card (Matching SynergyDetailScreen Hero layout)
  Widget _buildHeroCard(BuildContext context) {
    final foodName = pattern.involvedFoods.isNotEmpty ? pattern.involvedFoods.first : (pattern.trigger.isNotEmpty ? pattern.trigger : 'Whole Foods');
    final imageUrl = V2Kit.foodImageUrl(foodName);
    final style = PatternCardStyle.forType(pattern.type);

    final trigger = pattern.trigger.trim();
    final reaction = pattern.reaction.trim();
    final title = (trigger.isNotEmpty || reaction.isNotEmpty) ? ((trigger.isNotEmpty && reaction.isNotEmpty) ? '$trigger → $reaction' : (trigger.isNotEmpty ? trigger : reaction)) : style.label;

    return Container(
      height: 152.w,
      decoration: BoxDecoration(
        color: style.cardBg,
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: style.borderColor, width: 1.w),
        boxShadow: [BoxShadow(color: const Color(0xFF17171B).withValues(alpha: 0.04), blurRadius: 6.w, offset: Offset(0, 2.w))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Food Photo on Right
          Positioned.fill(
            child: Row(
              children: [
                const Spacer(flex: 4),
                Expanded(
                  flex: 4,
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
              ],
            ),
          ),

          // Angled Background Clipper
          Positioned.fill(
            child: ClipPath(
              clipper: const _HeroAngledClipper(),
              child: Container(color: style.cardBg),
            ),
          ),

          // Left Content Column
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 190.w,
            child: Padding(
              padding: EdgeInsets.fromLTRB(12.w, 10.w, 6.w, 10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tag Pill
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.w),
                        decoration: BoxDecoration(color: style.tagBg, borderRadius: BorderRadius.circular(16.w)),
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
                        pattern.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w500, color: const Color(0xFF334155), height: 1.25),
                      ),
                    ],
                  ),

                  // High Confidence Badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.w),
                    decoration: BoxDecoration(color: style.accentColor, borderRadius: BorderRadius.circular(16.w)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.shieldCheck, size: 11.w, color: Colors.white),
                        Gap.w4,
                        Text(
                          '${pattern.confidence} Confidence',
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        Gap.w3,
                        Icon(Icons.arrow_forward_rounded, size: 10.w, color: Colors.white),
                      ],
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

  /// 2. "What We Observed" Card
  Widget _buildWhatWeObservedCard(BuildContext context) {
    final style = PatternCardStyle.forType(pattern.type);
    final text = pattern.trigger.isNotEmpty
        ? 'Repeated log history shows that eating ${pattern.trigger} is associated with a ${pattern.type.toLowerCase()} reaction within ${pattern.typicalDelay}.'
        : 'Logged evidence indicates a recurring ${pattern.type.toLowerCase()} pattern over the last ${pattern.timeframeDays} days.';

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.w),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
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
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                ),
                Gap.h3,
                Text(
                  text,
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w500, color: const Color(0xFF475569), height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3. "The Evidence" Metric Dashboard Card
  Widget _buildTheEvidenceCard(BuildContext context, {required int evidenceRatio, required int frequency, required int symptomLogs, required int normalLogs}) {
    final style = PatternCardStyle.forType(pattern.type);

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.w),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
        boxShadow: [BoxShadow(color: const Color(0xFF17171B).withValues(alpha: 0.03), blurRadius: 6.w, offset: Offset(0, 2.w))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                    ),
                    Text(
                      'Based on your last ${pattern.timeframeDays} days of data.',
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Gap.h12,
          Row(
            children: [
              _buildMetricTile(title: '$evidenceRatio%', label: 'Evidence Ratio', icon: LucideIcons.pieChart, color: style.accentColor, bg: style.tagBg),
              Gap.w6,
              _buildMetricTile(title: '${frequency}x', label: 'Times Logged', icon: LucideIcons.history, color: style.accentColor, bg: style.tagBg),
              Gap.w6,
              _buildMetricTile(title: '$symptomLogs', label: 'Symptom Logs', icon: LucideIcons.thumbsDown, color: const Color(0xFFDC2626), bg: const Color(0xFFFEF2F2)),
              Gap.w6,
              _buildMetricTile(title: '$normalLogs', label: 'Normal Logs', icon: LucideIcons.thumbsUp, color: const Color(0xFF15803D), bg: const Color(0xFFF0FDF4)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({required String title, required String label, required IconData icon, required Color color, required Color bg}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12.w),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: Icon(icon, size: 10.w, color: color),
                ),
              ],
            ),
            Gap.h6,
            Text(
              title,
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
            ),
            Gap.h2,
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  /// 4. "Involved Foods" Horizontal Grid (Harvests from involvedFoods, trigger, and occurrences)
  Widget _buildInvolvedFoodsSection(BuildContext context) {
    final foods = <String>[];
    final seen = <String>{};

    for (final f in pattern.involvedFoods) {
      final key = f.trim().toLowerCase();
      if (key.isNotEmpty && seen.add(key)) foods.add(f.trim());
    }

    if (pattern.trigger.trim().isNotEmpty) {
      final key = pattern.trigger.trim().toLowerCase();
      if (seen.add(key)) foods.add(pattern.trigger.trim());
    }

    for (final occ in pattern.occurrences) {
      final key = occ.mealName.trim().toLowerCase();
      if (key.isNotEmpty && seen.add(key)) foods.add(occ.mealName.trim());
    }

    if (foods.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28.w,
              height: 28.w,
              decoration: const BoxDecoration(color: Color(0xFFFEF3C7), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(LucideIcons.utensils, size: 14.w, color: const Color(0xFFB45309)),
            ),
            Gap.w8,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Involved Foods',
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                  ),
                  Text(
                    'Foods frequently associated with this pattern.',
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
              for (final food in foods) ...[_InvolvedFoodTile(foodName: food), Gap.w8],
            ],
          ),
        ),
      ],
    );
  }

  /// 5. Occurrences Timeline & Common Factors Card
  Widget _buildOccurrencesTimelineCard(BuildContext context) {
    final style = PatternCardStyle.forType(pattern.type);

    if (pattern.commonFactors.isEmpty && pattern.occurrences.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.w),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
        boxShadow: [BoxShadow(color: const Color(0xFF17171B).withValues(alpha: 0.03), blurRadius: 6.w, offset: Offset(0, 2.w))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.history, size: 14.w, color: style.accentColor),
              Gap.w6,
              Text(
                'Occurrences & Factors',
                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
              ),
            ],
          ),
          Gap.h8,

          // Common factors
          if (pattern.commonFactors.isNotEmpty) ...[
            Wrap(
              spacing: 6.w,
              runSpacing: 6.w,
              children: [
                for (final factor in pattern.commonFactors)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.w),
                    decoration: BoxDecoration(color: style.tagBg, borderRadius: BorderRadius.circular(10.w)),
                    child: Text(
                      '${_factorGlyph(factor.icon)} ${factor.label}',
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w600, color: style.tagFg),
                    ),
                  ),
              ],
            ),
            Gap.h10,
          ],

          // Recent occurrences list
          if (pattern.occurrences.isNotEmpty) ...[
            Column(
              children: [
                for (var i = 0; i < pattern.occurrences.take(4).length; i++) ...[
                  if (i > 0) Divider(height: 12.w, color: const Color(0xFFF1F5F9)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${pattern.occurrences[i].date} • ${pattern.occurrences[i].mealName}',
                              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                            ),
                            if (pattern.occurrences[i].reaction.isNotEmpty) ...[
                              Gap.h2,
                              Text(
                                pattern.occurrences[i].reaction,
                                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: const Color(0xFF64748B)),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (pattern.occurrences[i].timeAfter.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.w),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6.w)),
                          child: Text(
                            pattern.occurrences[i].timeAfter,
                            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 6. Split Grid Section ("Your Next Steps" & "Supporting Evidence")
  Widget _buildSplitGridSection(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Column: Your Next Steps
        Expanded(child: _buildYourNextStepsCard(context)),
        Gap.w10,

        // Right Column: Supporting Evidence
        Expanded(child: _buildSupportingEvidenceCard(context)),
      ],
    ),
  );

  Widget _buildYourNextStepsCard(BuildContext context) {
    final style = PatternCardStyle.forType(pattern.type);
    final recText = (pattern.recommendation?.isNotEmpty == true) ? pattern.recommendation! : 'Log your meals and symptoms consistently to track this trend.';

    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF5),
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: const Color(0xFFDCFCE7), width: 1.w),
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
                    decoration: BoxDecoration(color: style.tagBg, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Icon(style.icon, size: 12.w, color: style.tagFg),
                  ),
                  Gap.w6,
                  Expanded(
                    child: Text(
                      'Your Next Steps',
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                    ),
                  ),
                ],
              ),
              Gap.h3,
              Text(
                'Recommended actions for this pattern:',
                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: const Color(0xFF475569), height: 1.2),
              ),
              Gap.h10,

              _NextStepCheckRow(title: 'Recommendation', subtitle: recText),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupportingEvidenceCard(BuildContext context) {
    AIInsight? latestInsight;
    try {
      latestInsight = context.read<InsightsNotifier>().latestInsight;
    } on ProviderNotFoundException {
      latestInsight = null;
    }

    final mealsCount = latestInsight?.evidence?.sampleSizes.meals ?? pattern.totalSimilarMeals;
    final symptomsCount = latestInsight?.evidence?.sampleSizes.symptoms ?? pattern.occurrences.length;
    final scansCount = latestInsight?.evidence?.sampleSizes.scans ?? 0;

    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24.w,
                height: 24.w,
                decoration: const BoxDecoration(color: Color(0xFFDBEAFE), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(LucideIcons.fileText, size: 12.w, color: const Color(0xFF1D4ED8)),
              ),
              Gap.w4,
              Expanded(
                child: Text(
                  'Supporting Evidence',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
          Gap.h2,
          Text(
            'Based on your logged data.',
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: const Color(0xFF475569)),
          ),
          Gap.h10,

          _EvidenceMetricRow(icon: LucideIcons.utensils, title: 'Meals', subtitle: 'Similar meals analyzed', value: '$mealsCount'),
          Gap.h8,

          _EvidenceMetricRow(icon: LucideIcons.clipboardList, title: 'Symptoms', subtitle: 'Pattern occurrences', value: '$symptomsCount'),
          Gap.h8,

          _EvidenceMetricRow(icon: LucideIcons.fileText, title: 'Scans', subtitle: 'Total scans', value: '$scansCount'),
        ],
      ),
    );
  }

  static String _factorGlyph(String icon) => switch (icon.toLowerCase()) {
    'milk' => '🥛',
    'utensils' => '🍽',
    'leaf' => '🥬',
    'wheat' => '🌾',
    'droplet' => '💧',
    _ => '•',
  };
}

// =============================================================================
// HELPER WIDGETS
// =============================================================================

class _InvolvedFoodTile extends StatelessWidget {
  const _InvolvedFoodTile({required this.foodName});

  final String foodName;

  @override
  Widget build(BuildContext context) {
    final imageUrl = V2Kit.foodImageUrl(foodName);

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
                color: const Color(0xFFFEF3C7),
                alignment: Alignment.center,
                child: Icon(LucideIcons.utensils, size: 20.w, color: const Color(0xFFD97706)),
              ),
            ),
          ),
          Gap.h4,
          Text(
            foodName,
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Gap.h3,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.w),
            decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(10.w)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.leaf, size: 8.5.w, color: const Color(0xFF15803D)),
                Gap.w2,
                Text(
                  'Involved',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w700, color: const Color(0xFF15803D)),
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
        decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
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
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A), height: 1.2),
            ),
            Gap.h2,
            Text(
              subtitle,
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: const Color(0xFF475569), height: 1.2),
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
        decoration: const BoxDecoration(color: Color(0xFFDBEAFE), shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(icon, size: 11.w, color: const Color(0xFF1D4ED8)),
      ),
      Gap.w6,
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A), height: 1.1),
            ),
            Text(
              subtitle,
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.sp, color: const Color(0xFF64748B), height: 1.1),
            ),
          ],
        ),
      ),
      Text(
        value,
        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
      ),
    ],
  );
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
