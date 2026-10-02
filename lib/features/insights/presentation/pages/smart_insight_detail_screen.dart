import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/utils/insight_presentation.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/occurrence_tile.dart';
import 'package:gutgood/features/insights/presentation/widgets/pattern_grid.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_strings.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_theme.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/v2_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// Top Insight Details — Synergy-style UI/UX presentation matching PatternDetailScreen.
///
/// Features bento cards: Hero Insight Card with right angled food image,
/// "What We Observed" banner, "The Evidence" 4-stat metric dashboard,
/// "Involved Foods" horizontal grid, "Occurrences & Factors" timeline,
/// "Related Patterns" section, and "Split Grid" section.
class SmartInsightDetailScreen extends StatelessWidget {
  const SmartInsightDetailScreen({super.key, required this.insight});

  final InsightSummary insight;

  List<BodyPattern> _relatedPatterns(BuildContext context) {
    List<BodyPattern> candidates;
    try {
      candidates = context.read<InsightsNotifier>().prioritizedPatterns;
    } on ProviderNotFoundException {
      return const [];
    }

    final foods = {for (final food in insight.involvedFoods) food.trim().toLowerCase()};
    final title = insight.title.trim().toLowerCase();
    return candidates.where((pattern) {
      final relatedNames = [...pattern.involvedFoods, pattern.trigger].map((name) => name.trim().toLowerCase()).where((name) => name.isNotEmpty);
      return relatedNames.any((name) => foods.contains(name) || (title.isNotEmpty && title.contains(name))) || (title.isNotEmpty && title.contains(pattern.type.toLowerCase()));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final v2 = context.v2Theme;

    final evidenceRatio = insight.evidenceRatio?.isFinite == true ? (insight.evidenceRatio!.clamp(0.0, 1.0) * 100).round() : null;
    final frequency = insight.frequency;
    final positiveCount = insight.positiveCount;
    final negativeCount = insight.negativeCount;

    return Scaffold(
      backgroundColor: v2.scaffold,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Standard GutSliverAppBar matching PatternDetailScreen
          GutSliverAppBar(title: 'TOP INSIGHT', centerTitle: true, showBrandingIcon: false, backgroundColor: v2.scaffold),

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
                _buildTheEvidenceCard(context, evidenceRatio: evidenceRatio, frequency: frequency, symptomLogs: positiveCount, normalLogs: negativeCount),
                Gap.h10,

                // 4. INVOLVED FOODS SECTION
                _buildInvolvedFoodsSection(context),
                Gap.h10,

                // 5. OCCURRENCES TIMELINE & COMMON FACTORS CARD
                _buildOccurrencesTimelineCard(context),
                Gap.h10,

                // 6. RELATED PATTERNS SECTION
                _buildRelatedPatternsSection(context),
                Gap.h10,

                // 7. SPLIT GRID: YOUR NEXT STEPS & SUPPORTING EVIDENCE
                _buildSplitGridSection(context),
                Gap.h12,
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// 1. Top Hero Insight Card (Matching PatternCard hero layout with dynamic food color blending)
  Widget _buildHeroCard(BuildContext context) {
    final foodName = insight.involvedFoods.firstOrNull;
    final imageUrl = foodName == null ? null : V2Kit.foodImageUrl(foodName);
    final style = PatternCardStyle.forType(insight.type);

    final title = insight.title.isNotEmpty ? insight.title : 'Top Insight Discovery';
    final descStr = insight.description.trim();

    final confidenceLabel = (insight.strength?.trim().isNotEmpty == true ? insight.strength! : 'LIMITED DATA').toUpperCase();
    const heroColor = Color(0xFF6F67DD);

    return Container(
      constraints: BoxConstraints(minHeight: 140.w),
      decoration: BoxDecoration(color: heroColor, borderRadius: BorderRadius.circular(24.w)),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Left Content Section
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(18.w, 16.w, 12.w, 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Line 1: Bold Title
                    Text(
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 18.sp, fontWeight: FontWeight.w800, color: Colors.white, height: 1.15, letterSpacing: -0.4),
                    ),
                    if (descStr.isNotEmpty) ...[
                      Gap.h6,
                      // Line 2: Description
                      Text(
                        descStr,
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha: 0.90), height: 1.25),
                      ),
                    ],
                    Gap.h12,

                    // Bottom Badge Tag Row
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.w),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.20), borderRadius: BorderRadius.circular(100.w)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5.w,
                            height: 5.w,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          ),
                          Gap.w5,
                          Text(
                            '$confidenceLabel CONFIDENCE',
                            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.sp, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Right Side Image (Seamlessly blended with dynamic food background)
                if (imageUrl != null) SizedBox(
                  width: 138.w,
              child: Stack(
                children: [
                Positioned.fill(
                  child: ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Colors.transparent, Colors.white24, Colors.white],
                      stops: [0.0, 0.28, 0.65],
                    ).createShader(rect),
                    blendMode: BlendMode.dstIn,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      placeholder: (_, _) => Container(
                        color: Colors.white.withValues(alpha: 0.15),
                        child: Center(
                          child: Icon(style.icon, color: Colors.white.withValues(alpha: 0.5), size: 28.w),
                        ),
                      ),
                      errorWidget: (_, _, _) => Container(
                        color: Colors.white.withValues(alpha: 0.15),
                        child: Center(
                          child: Icon(style.icon, color: Colors.white.withValues(alpha: 0.7), size: 28.w),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [heroColor, heroColor.withValues(alpha: 0.55), heroColor.withValues(alpha: 0.0)],
                        stops: const [0.0, 0.35, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  }

  /// 2. "What We Observed" Card
  Widget _buildWhatWeObservedCard(BuildContext context) {
    final v2 = context.v2Theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = PatternCardStyle.forType(insight.type);
    final text = (insight.observation != null && insight.observation!.isNotEmpty)
        ? insight.observation!
        : (insight.description.isNotEmpty ? insight.description : 'No observation details are available for this insight.');

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? v2.card : Colors.white,
        borderRadius: BorderRadius.circular(18.w),
        border: Border.all(color: isDark ? v2.border : const Color(0xFFE2E8F0), width: 1.w),
        boxShadow: [BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.15) : const Color(0xFF17171B).withValues(alpha: 0.03), blurRadius: 6.w, offset: Offset(0, 2.w))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(color: isDark ? v2.cardSubtle : context.insightColor(style.tagBg), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(style.icon, size: 16.w, color: isDark ? v2.textPrimary : context.insightColor(style.tagFg)),
          ),
          Gap.w10,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What We Observed',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: v2.textPrimary),
                ),
                Gap.h3,
                Text(
                  text,
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w500, color: v2.textSecondary, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3. "The Evidence" Metric Dashboard Card
  Widget _buildTheEvidenceCard(BuildContext context, {required int? evidenceRatio, required int? frequency, required int? symptomLogs, required int? normalLogs}) {
    final v2 = context.v2Theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = PatternCardStyle.forType(insight.type);

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? v2.card : Colors.white,
        borderRadius: BorderRadius.circular(18.w),
        border: Border.all(color: isDark ? v2.border : const Color(0xFFE2E8F0), width: 1.w),
        boxShadow: [BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.15) : const Color(0xFF17171B).withValues(alpha: 0.03), blurRadius: 6.w, offset: Offset(0, 2.w))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(color: isDark ? v2.cardSubtle : context.insightColor(style.tagBg), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(LucideIcons.barChart2, size: 14.w, color: isDark ? v2.textPrimary : context.insightColor(style.tagFg)),
              ),
              Gap.w8,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'The Evidence',
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: v2.textPrimary),
                    ),
                    Text(
                      'Based on your logged historical data.',
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: v2.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Gap.h12,
          Row(
            children: [
              _buildMetricTile(
                context,
                title: evidenceRatio == null ? '—' : '$evidenceRatio%',
                label: 'Evidence Ratio',
                icon: LucideIcons.pieChart,
                color: isDark ? v2.purple : style.accentColor,
                bg: isDark ? v2.cardSubtle : style.tagBg,
              ),
              Gap.w6,
              _buildMetricTile(
                context,
                title: frequency == null ? '—' : '$frequency×',
                label: 'Times Logged',
                icon: LucideIcons.history,
                color: isDark ? v2.purple : style.accentColor,
                bg: isDark ? v2.cardSubtle : style.tagBg,
              ),
              Gap.w6,
              _buildMetricTile(
                context,
                title: symptomLogs == null ? '—' : '$symptomLogs',
                label: 'Symptom Logs',
                icon: LucideIcons.thumbsDown,
                color: isDark ? v2.error : const Color(0xFFDC2626),
                bg: isDark ? v2.errorSoft : const Color(0xFFFEF2F2),
              ),
              Gap.w6,
              _buildMetricTile(
                context,
                title: normalLogs == null ? '—' : '$normalLogs',
                label: 'Normal Logs',
                icon: LucideIcons.thumbsUp,
                color: isDark ? v2.success : const Color(0xFF15803D),
                bg: isDark ? v2.successSoft : const Color(0xFFF0FDF4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(BuildContext context, {required String title, required String label, required IconData icon, required Color color, required Color bg}) {
    final v2 = context.v2Theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final resolvedBg = isDark ? v2.cardSubtle : context.insightColor(bg);
    final resolvedColor = isDark ? color : context.insightColor(color);

    return Expanded(
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: resolvedBg,
          borderRadius: BorderRadius.circular(12.w),
          border: Border.all(color: isDark ? v2.border : resolvedColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(color: isDark ? resolvedColor.withValues(alpha: 0.18) : resolvedColor.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: Icon(icon, size: 10.w, color: resolvedColor),
                ),
              ],
            ),
            Gap.h6,
            Text(
              title,
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: v2.textPrimary),
            ),
            Gap.h2,
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w600, color: v2.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  /// 4. "Involved Foods" Horizontal Grid
  Widget _buildInvolvedFoodsSection(BuildContext context) {
    final foods = <String>[];
    final seen = <String>{};

    for (final f in insight.involvedFoods) {
      final key = f.trim().toLowerCase();
      if (key.isNotEmpty && seen.add(key)) foods.add(f.trim());
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
                    'Foods mentioned in this insight.',
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: context.insightColor(const Color(0xFF64748B))),
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
    final style = PatternCardStyle.forType(insight.type);
    final matchingPattern = _relatedPatterns(context).firstOrNull;

    if (matchingPattern == null || (matchingPattern.commonFactors.isEmpty && matchingPattern.occurrences.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(color: context.insightColor(style.accentColor).withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(LucideIcons.history, size: 12.w, color: context.insightColor(style.accentColor)),
            ),
            Gap.w8,
            Text(
              'Occurrences & Factors',
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
            ),
          ],
        ),
        Gap.h10,

        // Common Factors Card (if available)
        if (matchingPattern.commonFactors.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: context.v2Theme.card,
              borderRadius: BorderRadius.circular(18.w),
              border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0)), width: 1.w),
              boxShadow: [BoxShadow(color: context.insightColor(const Color(0xFF0F172A)).withValues(alpha: 0.03), blurRadius: 8.w, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Associated Factors',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w700, color: context.insightColor(const Color(0xFF64748B))),
                ),
                Gap.h8,
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.w,
                  children: [
                    for (final factor in matchingPattern.commonFactors)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.w),
                        decoration: BoxDecoration(
                          color: context.insightColor(style.tagBg).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(100.w),
                          border: Border.all(color: context.insightColor(style.tagFg).withValues(alpha: 0.15), width: 0.7.w),
                        ),
                        child: Text(
                          '${_factorGlyph(factor.icon)} ${factor.label}',
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w600, color: context.insightColor(style.tagFg), height: 1.1),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Gap.h10,
        ],

        // Recent Occurrences List (Separate Item Cards)
        if (matchingPattern.occurrences.isNotEmpty) ...[
          for (final occ in matchingPattern.occurrences.take(4)) ...[OccurrenceTile(occurrence: occ, pattern: matchingPattern), Gap.h10],
        ],
      ],
    );
  }

  /// 6. Related Patterns Section
  Widget _buildRelatedPatternsSection(BuildContext context) {
    final patterns = _relatedPatterns(context);

    if (patterns.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(color: context.insightColor(const Color(0xFFEDE9FE)), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(LucideIcons.gitFork, size: 14.w, color: context.insightColor(const Color(0xFF7C3AED))),
            ),
            Gap.w8,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    InsightV2Strings.relatedPatternsLabel,
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                  ),
                  Text(
                    'Detected patterns related to this insight.',
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: context.insightColor(const Color(0xFF64748B))),
                  ),
                ],
              ),
            ),
          ],
        ),
        Gap.h8,
        for (final p in patterns.take(3)) ...[
          V2PatternPill(
            title: '${p.trigger} → ${p.reaction}',
            subtitle: '${p.frequency}× • ${p.confidence} confidence',
            emoji: p.involvedFoods.isEmpty ? null : InsightPresentation.emojiForFood(p.involvedFoods.first),
            onTap: () => context.push(AppRoutes.patternDetail, extra: p),
          ),
          Gap.h8,
        ],
      ],
    );
  }

  /// 7. Split Grid Section ("Your Next Steps" & "Supporting Evidence")
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
    final v2 = context.v2Theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = PatternCardStyle.forType(insight.type);
    final steps = insight.nextSteps;

    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF102319) : const Color(0xFFF4FAF5),
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.28) : const Color(0xFFDCFCE7), width: 1.w),
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
                    decoration: BoxDecoration(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.20) : context.insightColor(style.tagBg), shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Icon(style.icon, size: 12.w, color: isDark ? const Color(0xFF4ADE80) : context.insightColor(style.tagFg)),
                  ),
                  Gap.w6,
                  Expanded(
                    child: Text(
                      'Your Next Steps',
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: v2.textPrimary),
                    ),
                  ),
                ],
              ),
              Gap.h3,
              Text(
                steps.isEmpty ? 'No personalized next steps are available yet.' : 'Recommended actions for this insight:',
                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: v2.textSecondary, height: 1.2),
              ),
              Gap.h10,

              if (steps.isEmpty)
                Text('Log meals and symptoms to help build a useful insight.', style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, color: v2.textSecondary))
              else
                for (var i = 0; i < steps.take(3).length; i++) ...[if (i > 0) Gap.h8, _NextStepCheckRow(title: 'Action ${i + 1}', subtitle: steps[i])],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupportingEvidenceCard(BuildContext context) {
    final v2 = context.v2Theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    AIInsight? latestInsight;
    try {
      latestInsight = context.read<InsightsNotifier>().latestInsight;
    } on ProviderNotFoundException {
      latestInsight = null;
    }

    final mealsCount = latestInsight?.evidence?.sampleSizes.meals;
    final symptomsCount = latestInsight?.evidence?.sampleSizes.symptoms ?? insight.positiveCount;
    final scansCount = latestInsight?.evidence?.sampleSizes.scans;

    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111C2E) : const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.28) : const Color(0xFFE2E8F0), width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24.w,
                height: 24.w,
                decoration: BoxDecoration(color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.20) : const Color(0xFFDBEAFE), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(LucideIcons.fileText, size: 12.w, color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8)),
              ),
              Gap.w4,
              Expanded(
                child: Text(
                  'Supporting Evidence',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: v2.textPrimary),
                ),
              ),
            ],
          ),
          Gap.h2,
          Text(
            'Based on your logged data.',
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: v2.textSecondary),
          ),
          Gap.h10,

          _EvidenceMetricRow(icon: LucideIcons.utensils, title: 'Meals', subtitle: 'Similar meals analyzed', value: mealsCount?.toString() ?? '—'),
          Gap.h8,

          _EvidenceMetricRow(icon: LucideIcons.clipboardList, title: 'Symptoms', subtitle: 'Pattern occurrences', value: symptomsCount?.toString() ?? '—'),
          Gap.h8,

          _EvidenceMetricRow(icon: LucideIcons.fileText, title: 'Scans', subtitle: 'Total scans', value: scansCount?.toString() ?? '—'),
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
            foodName,
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w700, color: context.insightColor(const Color(0xFF0F172A))),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Gap.h3,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.w),
            decoration: BoxDecoration(
              color: context.insightColor(const Color(0xFFF0FDF4)),
              borderRadius: BorderRadius.circular(100.w),
              border: Border.all(color: context.insightColor(const Color(0xFF15803D)).withValues(alpha: 0.2), width: 0.7.w),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.leaf, size: 7.5.w, color: context.insightColor(const Color(0xFF15803D))),
                Gap.w2,
                Text(
                  'Involved',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.sp, fontWeight: FontWeight.w700, color: context.insightColor(const Color(0xFF15803D)), height: 1.1),
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
  Widget build(BuildContext context) {
    final v2 = context.v2Theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 16.w,
          height: 16.w,
          margin: EdgeInsets.only(top: 1.w),
          decoration: BoxDecoration(color: isDark ? const Color(0xFF22C55E) : const Color(0xFF16A34A), shape: BoxShape.circle),
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
                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: v2.textPrimary, height: 1.2),
              ),
              Gap.h2,
              Text(
                subtitle,
                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: v2.textSecondary, height: 1.2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EvidenceMetricRow extends StatelessWidget {
  const _EvidenceMetricRow({required this.icon, required this.title, required this.subtitle, required this.value});

  final IconData icon;
  final String title;
  final String subtitle;
  final String value;

  @override
  Widget build(BuildContext context) {
    final v2 = context.v2Theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 22.w,
          height: 22.w,
          decoration: BoxDecoration(color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.20) : const Color(0xFFDBEAFE), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Icon(icon, size: 11.w, color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8)),
        ),
        Gap.w6,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: v2.textPrimary, height: 1.1),
              ),
              Text(
                subtitle,
                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.sp, color: v2.textSecondary, height: 1.1),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: v2.textPrimary),
        ),
      ],
    );
  }
}
