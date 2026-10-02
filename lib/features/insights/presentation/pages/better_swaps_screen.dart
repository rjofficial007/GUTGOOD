import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/insights/presentation/pages/swap_detail_screen.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_theme.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/v2_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// Better Food Swaps — Ultra-Polished, fully dynamic & compact UI/UX matching mockup.
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
    final insight = _insightOf(context);
    final foodName = widget.swap.source.name;
    final imageUrl = widget.swap.source.imageUrl ?? V2Kit.foodImageUrl(foodName);

    // Dynamic pattern matching
    final matchingPattern = insight?.detectedPatterns
        .where((p) => p.involvedFoods.any((f) => f.toLowerCase().trim() == foodName.toLowerCase().trim()) || p.trigger.toLowerCase().trim() == foodName.toLowerCase().trim())
        .firstOrNull;

    // Dynamic trigger matching
    final matchingTrigger = insight?.triggerFoods.where((f) => f.name.toLowerCase().trim() == foodName.toLowerCase().trim()).firstOrNull;

    final hasPersonalEvidence = matchingPattern != null || matchingTrigger != null;
    final heroSubtitle = matchingPattern?.reaction.isNotEmpty == true
        ? 'Linked to ${matchingPattern!.reaction.toLowerCase()} in your logs.'
        : (matchingTrigger?.effect.isNotEmpty == true ? matchingTrigger!.effect : 'No personal association has been established from your logs.');

    final heroTags = <String>[
      if (matchingPattern != null && matchingPattern.frequency > 0) '${matchingPattern.frequency}x Observed',
      if (matchingPattern?.reaction.isNotEmpty == true) matchingPattern!.reaction,
      if (matchingTrigger?.effect.isNotEmpty == true) matchingTrigger!.effect,
    ];

    // Dynamic Why affect you explanation
    final whyExplanation = (matchingPattern?.description.isNotEmpty == true)
        ? matchingPattern!.description
        : (matchingTrigger?.effect.isNotEmpty == true
              ? '$foodName (${matchingTrigger!.effect}) may place additional strain on your digestive system based on your meal logs.'
              : 'This is a general food alternative. Your logs do not yet show enough evidence to explain how the source food affects you.');

    final dynamicCategories = widget.swap.alternatives.map((alt) => alt.category.trim()).where((c) => c.isNotEmpty).toSet().toList();

    final categories = <String>['All Swaps', ...dynamicCategories];

    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = 'All Swaps';
    }

    final filteredAlternatives = widget.swap.alternatives.where((alt) {
      if (_selectedCategory == 'All Swaps') return true;
      return alt.category.toLowerCase() == _selectedCategory.toLowerCase();
    }).toList();

    final scaffoldBg = context.appColorScheme.cardBackground;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          GutSliverAppBar(title: 'BETTER FOOD SWAPS', centerTitle: true, showBrandingIcon: false, backgroundColor: scaffoldBg),

          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 0.w, 16.w, 24.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. TRIGGER FOOD HERO CARD
                _buildTriggerHeroCard(context, foodName, imageUrl, heroSubtitle, heroTags, hasPersonalEvidence: hasPersonalEvidence),
                Gap.h12,

                // 2. WHY THIS MAY AFFECT YOU CARD
                _buildWhyAffectYouCard(context, whyExplanation, hasPersonalEvidence: hasPersonalEvidence),
                Gap.h12,

                // 3. CATEGORY FILTER PILLS (Removed the extra Gap.h12 here)
                if (categories.length > 1) _buildCategoryFilters(context, categories),
                Gap.h12,
                // 4. ALTERNATIVES GRID (2 columns)
                if (filteredAlternatives.isEmpty) _buildEmptyState(context) else _buildAlternativesGrid(context, filteredAlternatives, foodName),

                Gap.h16,

                // 5. GUIDANCE BANNER
                _buildGuidanceBanner(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// 1. Trigger Food Hero Card
  Widget _buildTriggerHeroCard(BuildContext context, String foodName, String imageUrl, String subtitle, List<String> tags, {required bool hasPersonalEvidence}) => Container(
    height: 180.w,
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
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withValues(alpha: 0.2), Colors.black.withValues(alpha: 0.88)]),
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
                          hasPersonalEvidence ? 'OBSERVED IN YOUR LOGS' : 'GENERAL ALTERNATIVE',
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
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 18.sp, fontWeight: FontWeight.w900, color: Colors.white, height: 1.15, letterSpacing: -0.4),
                  ),
                  Gap.h2,
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.9)),
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

  /// 2. "Why this may affect you" Card
  Widget _buildWhyAffectYouCard(BuildContext context, String explanation, {required bool hasPersonalEvidence}) {
    final v2 = context.v2Theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: v2.card,
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: v2.border, width: 1.w),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(color: isDark ? const Color(0xFFD97706).withValues(alpha: 0.20) : const Color(0xFFFEF3C7), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(LucideIcons.lightbulb, size: 16.w, color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706)),
          ),
          Gap.w10,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPersonalEvidence ? 'What your logs show' : 'About this alternative',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 13.sp, fontWeight: FontWeight.w800, color: v2.textPrimary),
                ),
                Gap.h3,
                Text(
                  explanation,
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w500, color: v2.textSecondary, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Category Filter Pills (Matching exact Insights tab bar style)
  Widget _buildCategoryFilters(BuildContext context, List<String> categories) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final v2 = context.v2Theme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (var i = 0; i < categories.length; i++) ...[
            if (i > 0) Gap.w8,
            GestureDetector(
              onTap: () => setState(() => _selectedCategory = categories[i]),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
                decoration: BoxDecoration(
                  color: categories[i] == _selectedCategory ? (isDark ? Colors.white : const Color(0xFF171717)) : Colors.transparent,
                  borderRadius: BorderRadius.circular(100.w),
                  border: Border.all(color: categories[i] == _selectedCategory ? (isDark ? Colors.white : const Color(0xFF171717)) : v2.border, width: 1.w),
                  boxShadow: categories[i] == _selectedCategory
                      ? [BoxShadow(color: (isDark ? Colors.black : const Color(0xFF17171B)).withValues(alpha: 0.15), blurRadius: 4.w, offset: Offset(0, 2.w))]
                      : null,
                ),
                child: Text(
                  categories[i],
                  style: TextStyle(
                    fontFamily: InsightV2Theme.fontFamily,
                    fontSize: 12.sp,
                    fontWeight: categories[i] == _selectedCategory ? FontWeight.w800 : FontWeight.w600,
                    color: categories[i] == _selectedCategory ? (isDark ? const Color(0xFF0F172A) : Colors.white) : v2.textSecondary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 5. Alternatives Grid (2 columns)
  Widget _buildAlternativesGrid(BuildContext context, List<SwapAlternative> alternatives, String foodName) => GridView.builder(
    padding: EdgeInsets.zero, // Added padding zero to kill default GridView margins
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 10.w,
      mainAxisSpacing: 10.w,
      childAspectRatio: 0.8, // Compact ratio eliminating extra whitespace
    ),
    itemCount: alternatives.length,
    itemBuilder: (context, index) {
      final alt = alternatives[index];
      return _SwapCardItem(alt: alt, sourceFoodName: foodName);
    },
  );

  Widget _buildEmptyState(BuildContext context) {
    final v2 = context.v2Theme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: v2.card,
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: v2.border),
      ),
      child: Center(
        child: Text(
          'No alternatives found for this category.',
          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.sp, color: v2.textSecondary),
        ),
      ),
    );
  }

  Widget _buildGuidanceBanner(BuildContext context) {
    final v2 = context.v2Theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: v2.card,
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: v2.border),
      ),
      child: Row(
        children: [
          Container(
            width: 26.w,
            height: 26.w,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFFD97706).withValues(alpha: 0.20) : const Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(LucideIcons.lightbulb, size: 13.w, color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309)),
          ),
          Gap.w10,
          Expanded(
            child: Text(
              'Try one swap at a time to accurately observe how your digestion responds.',
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, color: v2.textSecondary, height: 1.3),
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
    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.w),
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
  const _SwapCardItem({required this.alt, required this.sourceFoodName});
  final SwapAlternative alt;
  final String sourceFoodName;

  IconData _parseIcon(String raw) {
    final lower = raw.toLowerCase().trim();
    if (lower.contains('dumbbell') || lower.contains('protein') || lower.contains('muscle')) {
      return LucideIcons.dumbbell;
    }
    if (lower.contains('sprout') || lower.contains('fiber') || lower.contains('motility')) {
      return LucideIcons.sprout;
    }
    if (lower.contains('flame') || lower.contains('calor') || lower.contains('burn')) {
      return LucideIcons.flame;
    }
    if (lower.contains('sun') || lower.contains('light') || lower.contains('energy')) {
      return LucideIcons.sun;
    }
    if (lower.contains('shield') || lower.contains('prebiotic') || lower.contains('microbiome')) {
      return LucideIcons.shield;
    }
    if (lower.contains('droplet') || lower.contains('water') || lower.contains('hydrat')) {
      return LucideIcons.droplet;
    }
    if (lower.contains('arrow') || lower.contains('down')) {
      return LucideIcons.arrowDown;
    }
    return LucideIcons.leaf;
  }

  List<_BenefitData> _deriveBenefits(SwapAlternative alt) {
    if (alt.benefits.isNotEmpty) {
      return [for (final b in alt.benefits.take(2)) _BenefitData(label: b.title, icon: _parseIcon(b.icon))];
    }

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
    return benefits.take(2).toList();
  }

  @override
  Widget build(BuildContext context) {
    final v2 = context.v2Theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageUrl = alt.imageUrl ?? V2Kit.foodImageUrl(alt.name);
    final benefits = _deriveBenefits(alt);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SwapDetailScreen(alternative: alt, sourceFoodName: sourceFoodName),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: v2.card,
          borderRadius: BorderRadius.circular(16.w),
          border: Border.all(color: v2.border, width: 1.w),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02), blurRadius: 4.w, offset: Offset(0, 2.w))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food Image
            CachedNetworkImage(
              imageUrl: imageUrl,
              height: 90.w,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(color: v2.cardSubtle),
              errorWidget: (_, _, _) => Container(
                color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.2) : const Color(0xFFDCFCE7),
                child: Icon(LucideIcons.utensils, size: 22.w, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)),
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
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: v2.textPrimary, height: 1.15),
                        ),
                        Gap.h2,
                        // Description
                        Text(
                          alt.reason?.trim().isNotEmpty == true ? alt.reason! : 'No comparison details are available for this alternative yet.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.sp, color: v2.textSecondary, height: 1.2),
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

                    // Compact Pill Button (Matching Mockup Image 2)
                    SizedBox(
                      width: double.infinity,
                      child: Material(
                        color: isDark ? const Color(0xFF059669) : const Color(0xFF064E3B),
                        borderRadius: BorderRadius.circular(100.w),
                        child: InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SwapDetailScreen(alternative: alt, sourceFoodName: sourceFoodName),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(100.w),
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 7.w),
                            child: Center(
                              child: Text(
                                '+ Try This Swap',
                                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.1),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitPill extends StatelessWidget {
  const _BenefitPill({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final v2 = context.v2Theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.w),
      decoration: BoxDecoration(color: isDark ? v2.cardSubtle : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6.w)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 8.w, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)),
          Gap.w4,
          Text(
            label,
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.sp, fontWeight: FontWeight.w700, color: v2.textPrimary),
          ),
        ],
      ),
    );
  }
}
