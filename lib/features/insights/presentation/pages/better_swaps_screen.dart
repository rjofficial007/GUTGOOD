import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/insights/presentation/widgets/pattern_grid.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_theme.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/v2_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Better Food Swaps — Ultra-Polished Synergy-style UI/UX.
class BetterSwapsScreen extends StatelessWidget {
  const BetterSwapsScreen({super.key, required this.swap});

  final FoodSwap swap;

  @override
  Widget build(BuildContext context) {
    final v2 = context.v2Theme;

    return Scaffold(
      backgroundColor: v2.scaffold,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Standard GutSliverAppBar
          GutSliverAppBar(title: 'BETTER FOOD SWAPS', centerTitle: true, showBrandingIcon: false, backgroundColor: v2.scaffold),

          // --- Body Content --------------------------------------------------
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 4.w, 16.w, 24.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. TRIGGER FOOD HERO CARD (PatternCard Style)
                _buildTriggerHeroCard(context),
                Gap.h10,

                // 2. WHY SWAP? OBSERVATION CARD
                _buildWhySwapCard(context),
                Gap.h16,

                // 4. ALTERNATIVES LIST (PatternCard Style)
                if (swap.alternatives.isEmpty) _buildEmptyState(context) else for (final alt in swap.alternatives) ...[_AlternativePatternStyleCard(alt: alt), Gap.h10],

                Gap.h10,

                // 5. GUIDANCE BANNER
                _buildGuidanceBanner(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// 1. Trigger Food Hero Card (Matches PatternCard Hero Style)
  Widget _buildTriggerHeroCard(BuildContext context) {
    final foodName = swap.source.name;
    final imageUrl = swap.source.imageUrl ?? V2Kit.foodImageUrl(foodName);
    final heroColor = PatternCardStyle.foodHeroColor(foodName, const Color(0xFF991B1B));

    return Container(
      height: 154.w,
      decoration: BoxDecoration(color: heroColor, borderRadius: BorderRadius.circular(24.w)),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // Left Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(18.w, 16.w, 12.w, 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Food Name Title
                      Text(
                        foodName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 18.sp, fontWeight: FontWeight.w800, color: Colors.white, height: 1.15, letterSpacing: -0.4),
                      ),
                      Gap.h2,

                      // Subtitle
                      Text(
                        'Trigger Food Item',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: InsightV2Theme.fontFamily,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.88),
                          height: 1.2,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Gap.h8,

                      // Meta details
                      Text(
                        'Associated with recurring digestive discomfort and sensitivities.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha: 0.90), height: 1.25),
                      ),
                    ],
                  ),

                  // Trigger Badge Pill
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.w),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.20), borderRadius: BorderRadius.circular(100.w)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.triangleAlert, size: 10.w, color: Colors.white),
                        Gap.w4,
                        Text(
                          'TRIGGER FOOD',
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.sp, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right Side Image with ShaderMask blend
          SizedBox(
            width: 148.w,
            height: double.infinity,
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
                          child: Icon(LucideIcons.flame, color: Colors.white.withValues(alpha: 0.5), size: 28.w),
                        ),
                      ),
                      errorWidget: (_, _, _) => Container(
                        color: Colors.white.withValues(alpha: 0.15),
                        child: Center(
                          child: Icon(LucideIcons.flame, color: Colors.white.withValues(alpha: 0.7), size: 28.w),
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
    );
  }

  /// 2. "Why Swap?" Observation Card
  Widget _buildWhySwapCard(BuildContext context) {
    final v2 = context.v2Theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? v2.card : Colors.white,
        borderRadius: BorderRadius.circular(18.w),
        border: Border.all(color: isDark ? v2.border : const Color(0xFFE2E8F0), width: 1.w),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.20) : const Color(0xFFDBEAFE), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(LucideIcons.info, size: 16.w, color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8)),
          ),
          Gap.w10,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why the swap?',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: v2.textPrimary),
                ),
                Gap.h3,
                Text(
                  'Replacing ${swap.source.name} with gentler alternatives can reduce the fermentation load in your gut and prevent inflammatory flare-ups.',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w500, color: v2.textSecondary, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final v2 = context.v2Theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? v2.card : Colors.white,
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: isDark ? v2.border : const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Text(
          'No alternatives listed for this item.',
          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.5.sp, color: v2.textSecondary),
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
        color: isDark ? v2.card : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: isDark ? v2.border : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 24.w,
            height: 24.w,
            decoration: BoxDecoration(color: isDark ? const Color(0xFFFBBF24).withValues(alpha: 0.20) : const Color(0xFFFEF3C7), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(LucideIcons.lightbulb, size: 12.w, color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309)),
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

/// A bento-style card for alternatives that matches the PatternCard layout exactly.
class _AlternativePatternStyleCard extends StatelessWidget {
  const _AlternativePatternStyleCard({required this.alt});

  final SwapAlternative alt;

  @override
  Widget build(BuildContext context) {
    final imageUrl = alt.imageUrl ?? V2Kit.foodImageUrl(alt.name);
    final heroColor = PatternCardStyle.foodHeroColor(alt.name, const Color(0xFF059669));

    return Container(
      height: 154.w,
      decoration: BoxDecoration(color: heroColor, borderRadius: BorderRadius.circular(24.w)),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // 1. Left Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(18.w, 16.w, 12.w, 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Food Name Title
                      Text(
                        alt.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 18.sp, fontWeight: FontWeight.w800, color: Colors.white, height: 1.15, letterSpacing: -0.4),
                      ),
                      Gap.h2,

                      // Subtitle
                      Text(
                        'Gut-Friendly Alternative',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: InsightV2Theme.fontFamily,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.88),
                          height: 1.2,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Gap.h8,

                      // Reason / Description
                      Text(
                        alt.reason ?? 'A gentler alternative to support your gut balance.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha: 0.90), height: 1.25),
                      ),
                    ],
                  ),

                  // Recommended Badge Pill
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.w),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.20), borderRadius: BorderRadius.circular(100.w)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.leaf, size: 10.w, color: Colors.white),
                        Gap.w4,
                        Text(
                          'RECOMMENDED',
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.sp, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Right Side Image with ShaderMask blend
          SizedBox(
            width: 148.w,
            height: double.infinity,
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
                          child: Icon(LucideIcons.leaf, color: Colors.white.withValues(alpha: 0.5), size: 28.w),
                        ),
                      ),
                      errorWidget: (_, _, _) => Container(
                        color: Colors.white.withValues(alpha: 0.15),
                        child: Center(
                          child: Icon(LucideIcons.leaf, color: Colors.white.withValues(alpha: 0.7), size: 28.w),
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
    );
  }
}
