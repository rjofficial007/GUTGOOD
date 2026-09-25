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
///
/// Features premium bento cards matching the PatternCard style exactly.
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
          GutSliverAppBar(
            title: 'BETTER FOOD SWAPS',
            centerTitle: true,
            showBrandingIcon: false,
            backgroundColor: v2.scaffold,
          ),

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
                Gap.h20,

                // 3. SECTION LABEL
                Row(
                  children: [
                    Icon(
                      LucideIcons.sparkles,
                      size: 14.w,
                      color: context.insightColor(const Color(0xFF0F172A)),
                    ),
                    Gap.w6,
                    Text(
                      'Recommended Alternatives',
                      style: TextStyle(
                        fontFamily: InsightV2Theme.fontFamily,
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w800,
                        color: context.insightColor(const Color(0xFF0F172A)),
                      ),
                    ),
                  ],
                ),
                Gap.h10,

                // 4. ALTERNATIVES LIST (PatternCard Style)
                if (swap.alternatives.isEmpty)
                  _buildEmptyState(context)
                else
                  for (final alt in swap.alternatives) ...[
                    _AlternativePatternStyleCard(alt: alt),
                    Gap.h10,
                  ],

                Gap.h20,

                // 5. GUIDANCE BANNER
                _buildGuidanceBanner(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// 1. Trigger Food Hero Card (Matches PatternCard Layout)
  Widget _buildTriggerHeroCard(BuildContext context) {
    final foodName = swap.source.name;
    final imageUrl = swap.source.imageUrl ?? V2Kit.foodImageUrl(foodName);
    final style = PatternCardStyle.forType('headache'); // Use Red/Trigger style

    return Container(
      height: 128.w,
      decoration: BoxDecoration(
        color: style.cardBg,
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: style.borderColor, width: 1.w),
        boxShadow: [
          BoxShadow(
            color: style.accentColor.withValues(alpha: 0.05),
            blurRadius: 8.w,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Left Content Area
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            right: 120.w,
            child: Padding(
              padding: EdgeInsets.fromLTRB(12.w, 10.w, 6.w, 10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Tag Pill
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 3.w,
                        ),
                        decoration: BoxDecoration(
                          color: style.tagBg,
                          borderRadius: BorderRadius.circular(14.w),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.alertTriangle,
                              size: 10.w,
                              color: style.tagFg,
                            ),
                            Gap.w4,
                            Text(
                              'TRIGGER FOOD',
                              style: TextStyle(
                                fontFamily: InsightV2Theme.fontFamily,
                                fontSize: 8.5.sp,
                                fontWeight: FontWeight.w800,
                                color: style.tagFg,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Gap.h6,

                      // Title
                      Text(
                        foodName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: InsightV2Theme.fontFamily,
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w800,
                          color: context.insightColor(const Color(0xFF0F172A)),
                          height: 1.15,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Gap.h2,

                      // Subtitle
                      Text(
                        'Associated with recurring digestive discomfort and bloating.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: InsightV2Theme.fontFamily,
                          fontSize: 9.5.sp,
                          fontWeight: FontWeight.w500,
                          color: context.insightColor(const Color(0xFF334155)),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Right Angled Food Photo
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 115.w,
            child: ClipPath(
              clipper: const _RightAngledSwapClipper(),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                placeholder: (_, _) => Container(color: style.tagBg),
                errorWidget: (_, _, _) => Container(
                  color: style.tagBg,
                  child: Icon(LucideIcons.flame, color: style.tagFg, size: 24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 2. "Why Swap?" Observation Card
  Widget _buildWhySwapCard(BuildContext context) => Container(
    padding: EdgeInsets.all(12.w),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18.w),
      border: Border.all(
        color: context.insightColor(const Color(0xFFE2E8F0)),
        width: 1.w,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF17171B).withValues(alpha: 0.03),
          blurRadius: 6.w,
          offset: Offset(0, 2.w),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32.w,
          height: 32.w,
          decoration: const BoxDecoration(
            color: Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            LucideIcons.info,
            size: 16.w,
            color: context.insightColor(const Color(0xFF475569)),
          ),
        ),
        Gap.w10,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Why the swap?',
                style: TextStyle(
                  fontFamily: InsightV2Theme.fontFamily,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  color: context.insightColor(const Color(0xFF0F172A)),
                ),
              ),
              Gap.h3,
              Text(
                'Replacing ${swap.source.name} with gentler alternatives can reduce the fermentation load in your gut and prevent inflammatory flare-ups.',
                style: TextStyle(
                  fontFamily: InsightV2Theme.fontFamily,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  color: context.insightColor(const Color(0xFF475569)),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildEmptyState(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(20.w),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20.w),
      border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0))),
    ),
    child: Center(
      child: Text(
        'No alternatives listed for this item.',
        style: TextStyle(
          fontFamily: InsightV2Theme.fontFamily,
          fontSize: 11.5.sp,
          color: context.insightColor(const Color(0xFF64748B)),
        ),
      ),
    ),
  );

  Widget _buildGuidanceBanner(BuildContext context) => Container(
    padding: EdgeInsets.all(12.w),
    decoration: BoxDecoration(
      color: context.insightColor(const Color(0xFFF8FAFC)),
      borderRadius: BorderRadius.circular(16.w),
      border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0))),
    ),
    child: Row(
      children: [
        Icon(
          LucideIcons.lightbulb,
          size: 16.w,
          color: context.insightColor(const Color(0xFF94A3B8)),
        ),
        Gap.w10,
        Expanded(
          child: Text(
            'Try one swap at a time to accurately observe how your digestion responds.',
            style: TextStyle(
              fontFamily: InsightV2Theme.fontFamily,
              fontSize: 10.sp,
              color: context.insightColor(const Color(0xFF64748B)),
              height: 1.3,
            ),
          ),
        ),
      ],
    ),
  );
}

/// A bento-style card for alternatives that matches the PatternCard layout exactly.
class _AlternativePatternStyleCard extends StatelessWidget {
  const _AlternativePatternStyleCard({required this.alt});

  final SwapAlternative alt;

  @override
  Widget build(BuildContext context) {
    final imageUrl = alt.imageUrl ?? V2Kit.foodImageUrl(alt.name);
    // Use the "Digestion/Green" style from PatternCard for recommended items
    final style = PatternCardStyle.forType('digestion');

    return Container(
      height: 128.w,
      decoration: BoxDecoration(
        color: style.cardBg,
        borderRadius: BorderRadius.circular(18.w),
        border: Border.all(color: style.borderColor, width: 1.w),
        boxShadow: [
          BoxShadow(
            color: style.accentColor.withValues(alpha: 0.04),
            blurRadius: 8.w,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 1. Left Content Area
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            right: 120.w,
            child: Padding(
              padding: EdgeInsets.fromLTRB(12.w, 10.w, 6.w, 10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Tag Pill
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 3.w,
                        ),
                        decoration: BoxDecoration(
                          color: style.tagBg,
                          borderRadius: BorderRadius.circular(14.w),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.leaf,
                              size: 10.w,
                              color: style.tagFg,
                            ),
                            Gap.w4,
                            Text(
                              'RECOMMENDED',
                              style: TextStyle(
                                fontFamily: InsightV2Theme.fontFamily,
                                fontSize: 8.5.sp,
                                fontWeight: FontWeight.w800,
                                color: style.tagFg,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Gap.h6,

                      // Title
                      Text(
                        alt.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: InsightV2Theme.fontFamily,
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w800,
                          color: context.insightColor(const Color(0xFF0F172A)),
                          height: 1.15,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Gap.h2,

                      // Description / Reason
                      Text(
                        alt.reason ??
                            'A gut-friendly alternative to support your balance.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: InsightV2Theme.fontFamily,
                          fontSize: 9.5.sp,
                          fontWeight: FontWeight.w500,
                          color: context.insightColor(const Color(0xFF334155)),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 2. Right Angled Food Photo (Matches PatternCard exactly)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 115.w,
            child: ClipPath(
              clipper: const _RightAngledSwapClipper(),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                placeholder: (_, _) => Container(color: style.tagBg),
                errorWidget: (_, _, _) => Container(
                  color: style.tagBg,
                  child: Icon(LucideIcons.leaf, color: style.tagFg, size: 24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RightAngledSwapClipper extends CustomClipper<Path> {
  const _RightAngledSwapClipper();

  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width * 0.18, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
