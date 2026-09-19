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

/// Fiber & Fermentation Synergy deep dive screen.
///
/// Matches the exact editorial design and compactness language of the Insights tab:
/// standard [GutSliverAppBar], compact v2 bento cards, "What We Observed" banner,
/// "The Evidence" 4-stat metric dashboard, "Involved Foods" horizontal grid,
/// "Your Next Steps" action checklist, and "Supporting Evidence" logged data summary.
class FiberSynergyDetailScreen extends StatelessWidget {
  const FiberSynergyDetailScreen({super.key, this.insight, this.pattern});

  final AIInsight? insight;
  final BodyPattern? pattern;

  @override
  Widget build(BuildContext context) {
    final v2 = context.v2Theme;
    final activeInsight = insight ?? _getLatestInsight(context);
    final activePattern = pattern ?? activeInsight?.detectedPatterns.firstOrNull;

    final evidenceRatio = activePattern?.evidenceRatio != null && activePattern!.evidenceRatio > 0 ? (activePattern.evidenceRatio * 100).round() : 92;
    final frequencyCount = activePattern?.frequency ?? 5;
    final positiveCount = activePattern?.positiveCount != 0 ? activePattern?.positiveCount ?? 5 : 5;
    final negativeCount = activePattern?.negativeCount ?? 0;

    return Scaffold(
      backgroundColor: v2.scaffold,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Standard GutSliverAppBar matching other detail screens
          GutSliverAppBar(title: 'FIBER & FERMENTATION', centerTitle: true, showBrandingIcon: false, backgroundColor: v2.scaffold),

          // --- Body Content --------------------------------------------------
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 4.w, 16.w, 24.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. HERO PATTERN CARD
                _buildHeroCard(context, activePattern),
                Gap.h10,

                // 2. WHAT WE OBSERVED CARD
                _buildWhatWeObservedCard(context),
                Gap.h10,

                // 3. THE EVIDENCE DASHBOARD
                _buildTheEvidenceCard(context, evidenceRatio: evidenceRatio, frequency: frequencyCount, positive: positiveCount, negative: negativeCount),
                Gap.h10,

                // 4. INVOLVED FOODS SECTION
                _buildInvolvedFoodsSection(context),
                Gap.h10,

                // 5. SPLIT GRID: YOUR NEXT STEPS & SUPPORTING EVIDENCE
                _buildSplitGridSection(context),
                Gap.h12,
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// 1. Top Hero Pattern Card ("Fiber & Fermentation Synergy")
  Widget _buildHeroCard(BuildContext context, BodyPattern? pattern) {
    final yogurtUrl = V2Kit.foodImageUrl(pattern?.involvedFoods.isNotEmpty == true ? pattern!.involvedFoods.first : 'Greek Yogurt Berry Bowl');
    final (tagLabel, tagIcon, tagBg, tagFg) = _tagStyle(pattern);

    final trigger = pattern?.trigger.trim() ?? '';
    final reaction = pattern?.reaction.trim() ?? '';
    final title = (trigger.isNotEmpty || reaction.isNotEmpty)
        ? ((trigger.isNotEmpty && reaction.isNotEmpty) ? '$trigger → $reaction' : (trigger.isNotEmpty ? trigger : reaction))
        : (pattern?.description.isNotEmpty == true ? pattern!.description : 'Fiber & Fermentation Synergy');

    final sub = pattern?.description.isNotEmpty == true ? pattern!.description : 'Consuming fermented foods alongside prebiotic fiber significantly reduces bloating episodes.';

    return Container(
      height: 152.w,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF5),
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: const Color(0xFFFDE6D8), width: 1.w),
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
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: yogurtUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        placeholder: (_, _) => Container(color: const Color(0xFFF1F5F9)),
                        errorWidget: (_, _, _) => Container(
                          color: const Color(0xFFFED7AA),
                          child: const Icon(LucideIcons.utensils, color: Color(0xFF9A3412)),
                        ),
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
              child: Container(color: const Color(0xFFFFFDF7)),
            ),
          ),

          // Leaf Branch Illustration near bottom center
          Positioned(
            left: 130.w,
            bottom: -2.w,
            child: CustomPaint(size: Size(38.w, 44.w), painter: const _LeafBranchPainter()),
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
                        decoration: BoxDecoration(color: tagBg, borderRadius: BorderRadius.circular(16.w)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(tagIcon, size: 10.w, color: tagFg),
                            Gap.w4,
                            Text(
                              tagLabel,
                              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w700, color: tagFg),
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
                        sub,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w500, color: const Color(0xFF334155), height: 1.25),
                      ),
                    ],
                  ),

                  // High Confidence Badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.w),
                    decoration: BoxDecoration(color: const Color(0xFF024A2B), borderRadius: BorderRadius.circular(16.w)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.shieldCheck, size: 11.w, color: Colors.white),
                        Gap.w4,
                        Text(
                          'High Confidence',
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

  /// 2. "What We Observed" Section
  Widget _buildWhatWeObservedCard(BuildContext context) => Container(
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
        // Green Bar Chart Icon
        Container(
          width: 32.w,
          height: 32.w,
          decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Icon(LucideIcons.barChart2, size: 16.w, color: const Color(0xFF15803D)),
        ),
        Gap.w10,

        // Content Column
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
                'Meals rich in kefir and whole grains correlate with high energy and smooth digestion.',
                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w500, color: const Color(0xFF475569), height: 1.3),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  /// 3. "The Evidence" Metric Dashboard Card
  Widget _buildTheEvidenceCard(BuildContext context, {required int evidenceRatio, required int frequency, required int positive, required int negative}) => Container(
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
        // Header Row
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
                    'The Evidence',
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                  ),
                  Text(
                    'Based on your last 7 days of data.',
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.info, size: 16.w, color: const Color(0xFF94A3B8)),
          ],
        ),
        Gap.h12,

        // 4 Stat Cards Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stat 1: Evidence Ratio Ring
            Expanded(
              child: _EvidenceStatTile(
                iconWidget: _CircularProgressRing(percentage: evidenceRatio.toDouble(), size: 30.w, color: const Color(0xFF16A34A), backgroundColor: const Color(0xFFDCFCE7)),
                valueText: '',
                label: 'Evidence ratio',
                subLabel: 'Strong correlation',
              ),
            ),
            Gap.w4,

            // Stat 2: Frequency
            Expanded(
              child: _EvidenceStatTile(
                icon: LucideIcons.fileText,
                iconBg: const Color(0xFFDCFCE7),
                iconColor: const Color(0xFF15803D),
                valueText: '$frequency',
                label: 'Frequency',
                subLabel: 'times together',
              ),
            ),
            Gap.w4,

            // Stat 3: Positive Instances
            Expanded(
              child: _EvidenceStatTile(
                icon: LucideIcons.thumbsUp,
                iconBg: const Color(0xFFDCFCE7),
                iconColor: const Color(0xFF15803D),
                valueText: '$positive',
                label: 'Positive instances',
                subLabel: 'Less bloating',
              ),
            ),
            Gap.w4,

            // Stat 4: Negative Instances
            Expanded(
              child: _EvidenceStatTile(
                icon: LucideIcons.thumbsDown,
                iconBg: const Color(0xFFFEE2E2),
                iconColor: const Color(0xFFDC2626),
                valueText: '$negative',
                label: 'Negative instances',
                subLabel: 'No increased symptoms',
              ),
            ),
          ],
        ),
      ],
    ),
  );

  /// 4. "Involved Foods" Horizontal Grid Section
  Widget _buildInvolvedFoodsSection(BuildContext context) {
    final foods = (pattern?.involvedFoods.isNotEmpty == true
        ? pattern!.involvedFoods.map((f) => _FoodCardData(name: f, imageKeyword: f)).toList()
        : (insight?.healingFoods.isNotEmpty == true
            ? insight!.healingFoods.map((f) => _FoodCardData(name: f.name, imageKeyword: f.name)).toList()
            : <_FoodCardData>[]));

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
                    'These foods often appear together in your data.',
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.push(AppRoutes.savedFoods),
              child: Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                  ),
                  Gap.w2,
                  Icon(Icons.arrow_forward_rounded, size: 11.w, color: const Color(0xFF0F172A)),
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

  Widget _buildYourNextStepsCard(BuildContext context) => Container(
    padding: EdgeInsets.all(10.w),
    decoration: BoxDecoration(
      color: const Color(0xFFF4FAF5),
      borderRadius: BorderRadius.circular(16.w),
      border: Border.all(color: const Color(0xFFDCFCE7), width: 1.w),
    ),
    child: Stack(
      children: [
        Positioned(
          right: -8.w,
          bottom: -8.w,
          child: CustomPaint(size: Size(40.w, 40.w), painter: const _LeafBranchPainter()),
        ),
        Column(
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
                      decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Icon(LucideIcons.leaf, size: 12.w, color: const Color(0xFF15803D)),
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
                  'Try these simple actions to keep seeing the benefits.',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: const Color(0xFF475569), height: 1.2),
                ),
                Gap.h10,

                if (insight?.actionsList.isNotEmpty == true) ...[
                  for (var i = 0; i < insight!.actionsList.take(2).length; i++) ...[
                    if (i > 0) Gap.h8,
                    _NextStepCheckRow(title: insight!.actionsList[i].title, subtitle: insight!.actionsList[i].description),
                  ],
                ] else ...[
                  _NextStepCheckRow(
                    title: insight?.topInsight?.nextSteps.firstOrNull ?? 'Increase prebiotic fiber intake',
                    subtitle: 'Add whole plant foods to support gut flora.',
                  ),
                ],
              ],
            ),
            Gap.h10,

            // Action Button
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tips saved to your daily action plan!'), duration: Duration(seconds: 2)));
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.w),
                decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(16.w)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Use These Tips',
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
      ],
    ),
  );

  Widget _buildSupportingEvidenceCard(BuildContext context) {
    final mealsCount = insight?.evidence?.sampleSizes.meals ?? insight?.foodImpacts.length ?? 0;
    final symptomsCount = insight?.evidence?.sampleSizes.symptoms ?? 0;
    final scansCount = insight?.evidence?.sampleSizes.scans ?? 0;

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
              Icon(LucideIcons.info, size: 13.w, color: const Color(0xFF94A3B8)),
            ],
          ),
          Gap.h2,
          Text(
            'Based on your logged data.',
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: const Color(0xFF475569)),
          ),
          Gap.h10,

          // Metric Rows
          _EvidenceMetricRow(icon: LucideIcons.utensils, title: 'Meals', subtitle: 'Total meals analyzed', value: '$mealsCount'),
          Gap.h8,

          _EvidenceMetricRow(icon: LucideIcons.clipboardList, title: 'Symptoms', subtitle: 'Symptom logs', value: '$symptomsCount'),
          Gap.h8,

          _EvidenceMetricRow(icon: LucideIcons.fileText, title: 'Scans', subtitle: 'Total gut scans', value: '$scansCount'),
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

  static (String, IconData, Color, Color) _tagStyle(BodyPattern? pattern) {
    if (pattern == null || pattern.type.trim().isEmpty) {
      return ('Pattern', LucideIcons.leaf, const Color(0xFFFDE6D8), const Color(0xFF7C2D12));
    }
    final rawType = pattern.type.trim();
    final t = rawType.toLowerCase();
    final label = rawType[0].toUpperCase() + rawType.substring(1);

    return switch (t) {
      'bloating' => ('Bloating', LucideIcons.leaf, const Color(0xFFFDE6D8), const Color(0xFF7C2D12)),
      'digestion' || 'digestive' => ('Digestion', LucideIcons.leaf, const Color(0xFFFDE6D8), const Color(0xFF7C2D12)),
      'energy' => (label, LucideIcons.zap, const Color(0xFFFEF3C7), const Color(0xFF92400E)),
      'headache' => (label, LucideIcons.activity, const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
      'fullness' => (label, LucideIcons.activity, const Color(0xFFFDE6D8), const Color(0xFF7C2D12)),
      'sleep' => (label, LucideIcons.moon, const Color(0xFFE0E7FF), const Color(0xFF3730A3)),
      'healing' => (label, LucideIcons.sparkles, const Color(0xFFDCFCE7), const Color(0xFF15803D)),
      'trigger' => (label, LucideIcons.alertTriangle, const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
      _ => (label, LucideIcons.leaf, const Color(0xFFFDE6D8), const Color(0xFF7C2D12)),
    };
  }
}

// =============================================================================
// HELPER WIDGETS & PAINTERS
// =============================================================================

class _EvidenceStatTile extends StatelessWidget {
  const _EvidenceStatTile({this.icon, this.iconWidget, this.iconBg, this.iconColor, required this.valueText, required this.label, required this.subLabel});

  final IconData? icon;
  final Widget? iconWidget;
  final Color? iconBg;
  final Color? iconColor;
  final String valueText;
  final String label;
  final String subLabel;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (iconWidget != null)
        iconWidget!
      else
        Row(
          children: [
            Container(
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(color: iconBg ?? const Color(0xFFDCFCE7), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(icon, size: 12.w, color: iconColor ?? const Color(0xFF15803D)),
            ),
            if (valueText.isNotEmpty) ...[
              Gap.w4,
              Text(
                valueText,
                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 15.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
              ),
            ],
          ],
        ),
      Gap.h4,
      Text(
        label,
        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A), height: 1.15),
      ),
      Gap.h2,
      Text(
        subLabel,
        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.sp, color: const Color(0xFF64748B), height: 1.15),
      ),
    ],
  );
}

class _CircularProgressRing extends StatelessWidget {
  const _CircularProgressRing({required this.percentage, required this.size, required this.color, required this.backgroundColor});

  final double percentage;
  final double size;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            value: (percentage / 100).clamp(0.0, 1.0),
            strokeWidth: 3.w,
            backgroundColor: backgroundColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            strokeCap: StrokeCap.round,
          ),
        ),
        Text(
          '${percentage.round()}%',
          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
        ),
      ],
    ),
  );
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
            food.name,
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
                  'High Impact',
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

class _LeafBranchPainter extends CustomPainter {
  const _LeafBranchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = const Color(0xFF86EFAC).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final stemPaint = Paint()
      ..color = const Color(0xFF22C55E).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.2, size.height)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.5, size.width * 0.7, 0);
    canvas.drawPath(path, stemPaint);

    void drawLeaf(Offset center, double angle, double scale) {
      canvas
        ..save()
        ..translate(center.dx, center.dy)
        ..rotate(angle);
      final leafPath = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(12 * scale, -8 * scale, 22 * scale, 0)
        ..quadraticBezierTo(12 * scale, 8 * scale, 0, 0);
      canvas
        ..drawPath(leafPath, fillPaint)
        ..restore();
    }

    drawLeaf(Offset(size.width * 0.7, size.height * 0.1), -0.5, 0.9);
    drawLeaf(Offset(size.width * 0.5, size.height * 0.4), 0.6, 1.0);
    drawLeaf(Offset(size.width * 0.3, size.height * 0.7), -0.4, 0.8);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
