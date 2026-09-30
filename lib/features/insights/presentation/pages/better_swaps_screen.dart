import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_theme.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/v2_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// Better Food Swaps — Ultra-Polished, fully dynamic & compact UI/UX.
class BetterSwapsScreen extends StatefulWidget {
  const BetterSwapsScreen({super.key, required this.swap, this.insight});

  final FoodSwap swap;
  final AIInsight? insight;

  @override
  State<BetterSwapsScreen> createState() => _BetterSwapsScreenState();
}

class _BetterSwapsScreenState extends State<BetterSwapsScreen> {
  String _selectedCategory = 'All Swaps';

  AIInsight? _insightOf(BuildContext context) {
    try {
      return widget.insight ?? context.read<InsightsNotifier>().latestInsight;
    } on ProviderNotFoundException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final v2 = context.v2Theme;
    final insight = _insightOf(context);
    final foodName = widget.swap.source.name;
    final imageUrl = widget.swap.source.imageUrl ?? V2Kit.foodImageUrl(foodName);

    // Dynamic pattern matching
    final matchingPattern = insight?.detectedPatterns.firstWhereOrNull(
      (p) => p.involvedFoods.any((f) => f.toLowerCase().trim() == foodName.toLowerCase().trim()) || p.trigger.toLowerCase().trim() == foodName.toLowerCase().trim(),
    );

    // Dynamic trigger matching
    final matchingTrigger = insight?.triggerFoods.firstWhereOrNull((f) => f.name.toLowerCase().trim() == foodName.toLowerCase().trim());

    // Dynamic Hero Subtitle
    final heroSubtitle = matchingPattern?.reaction.isNotEmpty == true
        ? 'Linked to ${matchingPattern!.reaction.toLowerCase()} in your logs.'
        : (matchingTrigger?.effect.isNotEmpty == true ? matchingTrigger!.effect : 'You\'ve noticed this is often linked to digestive discomfort.');

    // Dynamic Hero Tags
    final heroTags = <String>[
      if (matchingPattern != null && matchingPattern.frequency > 0) '${matchingPattern.frequency}x Observed' else 'Trigger Food',
      if (matchingTrigger?.effect.isNotEmpty == true) matchingTrigger!.effect else (matchingPattern?.reaction.isNotEmpty == true ? matchingPattern!.reaction : 'High Impact'),
      if (matchingPattern?.timeframeDays != null && matchingPattern!.timeframeDays > 0) '${matchingPattern.timeframeDays}d Window' else 'Sensitivity',
    ];

    // Dynamic Why affect you explanation
    final whyExplanation = (matchingPattern?.description.isNotEmpty == true)
        ? matchingPattern!.description
        : (matchingTrigger?.effect.isNotEmpty == true
              ? '$foodName (${matchingTrigger!.effect}) may place additional strain on your digestive system based on your meal logs.'
              : (insight?.topTrigger?.effects.isNotEmpty == true && insight!.topTrigger!.food.toLowerCase() == foodName.toLowerCase())
              ? insight.topTrigger!.effects
              : '$foodName can increase fermentation load or digestive strain, contributing to temporary bloating or symptoms.');

    final categories = <String>['All Swaps'];

    return Scaffold(
      backgroundColor: v2.scaffold,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          GutSliverAppBar(
            title: 'BETTER FOOD SWAPS',
            centerTitle: true,
            showBrandingIcon: false,
            backgroundColor: v2.scaffold,
            actions: [
              IconButton(
                icon: Icon(LucideIcons.bookmark, size: 18.w, color: context.insightColor(const Color(0xFF0F172A))),
                onPressed: () {},
              ),
            ],
          ),

          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 0.w, 16.w, 16.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. TRIGGER FOOD HERO CARD
                _buildTriggerHeroCard(context, foodName, imageUrl, heroSubtitle, heroTags),
                Gap.h10,

                // 2. WHY THIS MAY AFFECT YOU CARD
                _buildWhyAffectYouCard(context, whyExplanation),
                Gap.h10,

                // 3. CATEGORY FILTER PILLS
                if (categories.length > 1) ...[_buildCategoryFilters(context, categories), Gap.h10],

                // 4. SECTION HEADER ("Better Food Swaps")
                Row(
                  children: [
                    Container(
                      width: 26.w,
                      height: 26.w,
                      decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Icon(LucideIcons.leaf, size: 13.w, color: const Color(0xFF15803D)),
                    ),
                    Gap.w8,
                    Text(
                      'Better Food Swaps',
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 15.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                    ),
                  ],
                ),
                Gap.h10,

                // 5. ALTERNATIVES GRID (2 columns)
                if (widget.swap.alternatives.isEmpty) _buildEmptyState(context) else _buildAlternativesGrid(context),

                Gap.h10,

                // 6. GUIDANCE BANNER
                _buildGuidanceBanner(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// 1. Trigger Food Hero Card
  Widget _buildTriggerHeroCard(BuildContext context, String foodName, String imageUrl, String subtitle, List<String> tags) {
    return Container(
      height: 150.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.w),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8.w, offset: Offset(0, 3.w))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(color: const Color(0xFF1E293B)),
            errorWidget: (_, _, _) => Container(color: const Color(0xFF1E293B)),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withValues(alpha: 0.25), Colors.black.withValues(alpha: 0.85)]),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.w),
                      decoration: BoxDecoration(color: const Color(0xFFDC2626), borderRadius: BorderRadius.circular(100.w)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.triangleAlert, size: 9.w, color: Colors.white),
                          Gap.w4,
                          Text(
                            'YOUR TRIGGER FOOD',
                            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.sp, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      foodName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 17.sp, fontWeight: FontWeight.w800, color: Colors.white, height: 1.15, letterSpacing: -0.4),
                    ),
                    Gap.h2,
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.9)),
                    ),
                    Gap.h8,
                    Wrap(
                      spacing: 5.w,
                      runSpacing: 4.w,
                      children: [for (final tag in tags) _HeroTagPill(label: tag)],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 2. "Why this may affect you" Card
  Widget _buildWhyAffectYouCard(BuildContext context, String explanation) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.insightColor(Colors.white),
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0)), width: 1.w),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6.w, offset: Offset(0, 2.w))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28.w,
            height: 28.w,
            decoration: const BoxDecoration(color: Color(0xFFFEF3C7), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(LucideIcons.lightbulb, size: 14.w, color: const Color(0xFFB45309)),
          ),
          Gap.w8,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why this may affect you',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                ),
                Gap.h2,
                Text(
                  explanation,
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w500, color: context.insightColor(const Color(0xFF475569)), height: 1.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Category Filter Pills
  Widget _buildCategoryFilters(BuildContext context, List<String> categories) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final cat in categories) ...[
            GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.w),
                decoration: BoxDecoration(
                  color: _selectedCategory == cat ? const Color(0xFF0F172A) : context.insightColor(Colors.white),
                  borderRadius: BorderRadius.circular(100.w),
                  border: Border.all(color: _selectedCategory == cat ? const Color(0xFF0F172A) : context.insightColor(const Color(0xFFE2E8F0)), width: 1.w),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    fontFamily: InsightV2Theme.fontFamily,
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w700,
                    color: _selectedCategory == cat ? Colors.white : context.insightColor(const Color(0xFF0F172A)),
                  ),
                ),
              ),
            ),
            Gap.w6,
          ],
        ],
      ),
    );
  }

  /// 5. Alternatives Grid (2 columns)
  Widget _buildAlternativesGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 8.w, mainAxisSpacing: 8.w, childAspectRatio: 0.70),
      itemCount: widget.swap.alternatives.length,
      itemBuilder: (context, index) {
        final alt = widget.swap.alternatives[index];
        return _SwapCardItem(alt: alt);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final v2 = context.v2Theme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: v2.card,
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0))),
      ),
      child: Center(
        child: Text(
          'No alternatives listed for this item.',
          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, color: v2.textSecondary),
        ),
      ),
    );
  }

  Widget _buildGuidanceBanner(BuildContext context) {
    final v2 = context.v2Theme;
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: v2.card,
        borderRadius: BorderRadius.circular(14.w),
        border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Container(
            width: 22.w,
            height: 22.w,
            decoration: const BoxDecoration(color: Color(0xFFFEF3C7), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(LucideIcons.lightbulb, size: 11.w, color: const Color(0xFFB45309)),
          ),
          Gap.w8,
          Expanded(
            child: Text(
              'Try one swap at a time to accurately observe how your digestion responds.',
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: v2.textSecondary, height: 1.25),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroTagPill extends StatelessWidget {
  const _HeroTagPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.5.w),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(100.w)),
    child: Text(
      label,
      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w700, color: Colors.white),
    ),
  );
}

class _BenefitData {
  const _BenefitData({required this.label, required this.icon});
  final String label;
  final IconData icon;
}

class _SwapCardItem extends StatelessWidget {
  const _SwapCardItem({required this.alt});
  final SwapAlternative alt;

  List<_BenefitData> _deriveBenefits(SwapAlternative alt) {
    final benefits = <_BenefitData>[];
    final reasonLower = (alt.reason ?? '').toLowerCase();
    if (reasonLower.contains('protein')) {
      benefits.add(const _BenefitData(label: 'Higher protein', icon: LucideIcons.dumbbell));
    }
    if (reasonLower.contains('fat') || reasonLower.contains('saturat')) {
      benefits.add(const _BenefitData(label: 'Lower in fat', icon: LucideIcons.leaf));
    }
    if (reasonLower.contains('fiber') || reasonLower.contains('plant')) {
      benefits.add(const _BenefitData(label: 'High fiber', icon: LucideIcons.sprout));
    }
    if (reasonLower.contains('calor') || reasonLower.contains('light')) {
      benefits.add(const _BenefitData(label: 'Lower calories', icon: LucideIcons.flame));
    }
    if (reasonLower.contains('process') || reasonLower.contains('whole') || reasonLower.contains('natural')) {
      benefits.add(const _BenefitData(label: 'Less processed', icon: LucideIcons.sparkles));
    }
    if (benefits.isEmpty) {
      benefits.add(const _BenefitData(label: 'Gut Friendly', icon: LucideIcons.leaf));
      if (alt.impactLevel.isNotEmpty && alt.impactLevel.toLowerCase() != 'high') {
        benefits.add(_BenefitData(label: '${alt.impactLevel.toUpperCase()} Impact', icon: LucideIcons.zap));
      }
    }
    return benefits.take(2).toList();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = alt.imageUrl ?? V2Kit.foodImageUrl(alt.name);
    final benefits = _deriveBenefits(alt);

    return Container(
      decoration: BoxDecoration(
        color: context.insightColor(Colors.white),
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0)), width: 1.w),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4.w, offset: Offset(0, 2.w))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food Image
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.w)),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              height: 95.w,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(color: context.insightColor(const Color(0xFFF1F5F9))),
              errorWidget: (_, _, _) => Container(
                color: context.insightColor(const Color(0xFFDCFCE7)),
                child: Icon(LucideIcons.utensils, size: 22.w, color: const Color(0xFF15803D)),
              ),
            ),
          ),

          // Content Area
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(8.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        alt.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A)), height: 1.15),
                      ),
                      Gap.h2,
                      // Description
                      Text(
                        alt.reason ?? 'A gentler alternative to support your gut health.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.sp, color: context.insightColor(const Color(0xFF64748B)), height: 1.2),
                      ),
                      Gap.h4,
                      // Benefit pills row
                      Wrap(
                        spacing: 4.w,
                        runSpacing: 3.w,
                        children: [for (final b in benefits) _BenefitPill(label: b.label, icon: b.icon)],
                      ),
                    ],
                  ),

                  // Try This Swap Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Swapped to ${alt.name}!'), duration: const Duration(seconds: 2)));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF064E3B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 6.w),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.w)),
                      ),
                      child: Text(
                        '+ Try This Swap',
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w700, color: Colors.white),
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
}

class _BenefitPill extends StatelessWidget {
  const _BenefitPill({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.5.w),
    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6.w)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 8.5.w, color: const Color(0xFF15803D)),
        Gap.w3,
        Text(
          label,
          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w700, color: context.insightColor(const Color(0xFF0F172A))),
        ),
      ],
    ),
  );
}
