import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/insights/presentation/pages/better_swaps_screen.dart';
import 'package:gutgood/features/insights/presentation/widgets/pattern_grid.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_theme.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/v2_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Meal & Symptom Breakdown — Synergy-style UI/UX presentation.
class MealSymptomDetailScreen extends StatelessWidget {
  const MealSymptomDetailScreen({super.key, required this.occurrence, this.pattern, this.swap});

  final PatternOccurrence occurrence;
  final BodyPattern? pattern;
  final FoodSwap? swap;

  @override
  Widget build(BuildContext context) {
    final v2 = context.v2Theme;

    return Scaffold(
      backgroundColor: v2.scaffold,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Standard GutSliverAppBar
          GutSliverAppBar(title: 'MEAL & SYMPTOM', centerTitle: true, showBrandingIcon: false, backgroundColor: v2.scaffold),

          // --- Body Content --------------------------------------------------
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 4.w, 16.w, 24.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. HERO MEAL CARD
                _buildHeroCard(context),
                Gap.h10,

                // 2. MATCHED SYMPTOM CARD
                _buildMatchedSymptomCard(context),
                Gap.h10,

                // 3. WHY THIS HAPPENS (PATTERN EXPLANATION)
                if (pattern != null) ...[_buildPatternExplanationCard(context), Gap.h10],

                // 4. YOUR NOTE CARD
                if (occurrence.notes != null && occurrence.notes!.isNotEmpty) ...[_buildNoteCard(context), Gap.h10],

                Gap.h6,

                // 5. PLAN A BETTER SWAP CTA
                _buildBetterSwapCTA(context),
                Gap.h12,
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// 1. Top Hero Meal Card (Matching PatternCard hero layout with dynamic food color blending)
  Widget _buildHeroCard(BuildContext context) {
    final style = pattern != null ? PatternCardStyle.forPattern(pattern!) : PatternCardStyle.forType('digestion');
    final imageUrl = V2Kit.foodImageUrl(occurrence.mealName, imageUrl: occurrence.imageUrl);
    final heroColor = PatternCardStyle.foodHeroColor(occurrence.mealName, style.heroBg);

    final dateStr = occurrence.dateLabel ?? occurrence.date;
    final timeStr = occurrence.mealTime ?? 'Logged meal';
    final subtitle = '$dateStr • $timeStr';

    final reactionText = occurrence.reaction.isNotEmpty ? occurrence.reaction : 'Symptom logged';
    final timeAfterStr = occurrence.timeAfterLabel ?? occurrence.timeAfter;
    final metaText = timeAfterStr.isNotEmpty ? '$reactionText • Observed $timeAfterStr after eating' : reactionText;

    final severityLabel = (occurrence.symptomSeverity ?? 'Observed').toUpperCase();

    return Container(
      height: 154.w,
      decoration: BoxDecoration(color: heroColor, borderRadius: BorderRadius.circular(24.w)),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // 1. Left Content Section
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(18.w, 16.w, 12.w, 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Texts
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Line 1: Bold Title
                      Text(
                        occurrence.mealName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 18.sp, fontWeight: FontWeight.w800, color: Colors.white, height: 1.15, letterSpacing: -0.4),
                      ),
                      Gap.h2,

                      // Line 2: Subtitle
                      Text(
                        subtitle,
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

                      // Line 3: Meta bullet points
                      Text(
                        metaText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha: 0.90), height: 1.25),
                      ),
                    ],
                  ),

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
                          '$severityLabel SEVERITY',
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
                          child: Icon(LucideIcons.utensils, color: Colors.white.withValues(alpha: 0.5), size: 28.w),
                        ),
                      ),
                      errorWidget: (_, _, _) => Container(
                        color: Colors.white.withValues(alpha: 0.15),
                        child: Center(
                          child: Icon(LucideIcons.utensils, color: Colors.white.withValues(alpha: 0.7), size: 28.w),
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

  /// 2. Matched Reaction / Symptom Card
  Widget _buildMatchedSymptomCard(BuildContext context) {
    final v2 = context.v2Theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final reactionText = occurrence.reaction.isNotEmpty ? occurrence.reaction : 'Symptom logged';
    final timeAfterText = occurrence.timeAfterLabel ?? occurrence.timeAfter;

    final lower = reactionText.toLowerCase();
    final isEnergy = lower.contains('energy') || lower.contains('boost') || lower.contains('focus') || lower.contains('vitality') || lower.contains('alert');

    final isPositive = isEnergy || lower.contains('good') || lower.contains('great') || lower.contains('productive') || lower.contains('heal') || lower.contains('happy');

    final headerText = isEnergy ? 'ENERGY BOOST' : (isPositive ? 'LOGGED EFFECT' : 'MATCHED SYMPTOM');
    final headerIcon = isEnergy ? LucideIcons.zap : (isPositive ? LucideIcons.sparkles : LucideIcons.triangleAlert);

    final cardBg = isEnergy
        ? (isDark ? const Color(0xFF261D0B) : const Color(0xFFFEFCE8))
        : (isPositive ? (isDark ? v2.successSoft : const Color(0xFFF0FDF4)) : (isDark ? v2.errorSoft : const Color(0xFFFEF2F2)));

    final borderColor = isEnergy
        ? (isDark ? const Color(0xFFFBBF24).withValues(alpha: 0.35) : const Color(0xFFFEF08A))
        : (isPositive ? (isDark ? const Color(0xFF22C55E).withValues(alpha: 0.35) : const Color(0xFFDCFCE7)) : (isDark ? const Color(0xFFEF4444).withValues(alpha: 0.35) : const Color(0xFFFECACA)));

    final iconBg = isEnergy
        ? (isDark ? const Color(0xFFFBBF24).withValues(alpha: 0.20) : const Color(0xFFFEF3C7))
        : (isPositive ? (isDark ? const Color(0xFF22C55E).withValues(alpha: 0.20) : const Color(0xFFDCFCE7)) : (isDark ? const Color(0xFFEF4444).withValues(alpha: 0.20) : const Color(0xFFFEE2E2)));

    final accentColor = isEnergy
        ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706))
        : (isPositive ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)) : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626)));

    final titleColor = isEnergy
        ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309))
        : (isPositive ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF14532D)) : (isDark ? const Color(0xFFF87171) : const Color(0xFF991B1B)));

    final subColor = isEnergy
        ? (isDark ? const Color(0xFFFDE047) : const Color(0xFFA16207))
        : (isPositive ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534)) : (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C)));

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18.w),
        border: Border.all(color: borderColor, width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(headerIcon, size: 14.w, color: accentColor),
              ),
              Gap.w8,
              Expanded(
                child: Text(
                  headerText,
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: accentColor),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.w),
                decoration: BoxDecoration(
                  color: isDark ? v2.card : Colors.white,
                  borderRadius: BorderRadius.circular(8.w),
                  border: Border.all(color: borderColor, width: 0.8.w),
                ),
                child: Text(
                  occurrence.symptomSeverity ?? (isPositive ? 'Positive' : 'Observed'),
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w800, color: accentColor),
                ),
              ),
            ],
          ),
          Gap.h10,
          Text(
            reactionText,
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 15.sp, fontWeight: FontWeight.w800, color: titleColor),
          ),
          if (timeAfterText.isNotEmpty) ...[
            Gap.h3,
            Text(
              'Observed $timeAfterText after eating',
              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: subColor, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }

  /// 3. Why This Happens (Pattern Explanation Card)
  Widget _buildPatternExplanationCard(BuildContext context) {
    final v2 = context.v2Theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final explanationText = pattern!.description.isNotEmpty ? pattern!.description : 'Logged evidence shows this meal triggers a reaction based on your body data.';

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
                decoration: BoxDecoration(color: isDark ? const Color(0xFF7C3AED).withValues(alpha: 0.20) : const Color(0xFFEDE9FE), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(LucideIcons.lightbulb, size: 14.w, color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED)),
              ),
              Gap.w8,
              Text(
                'Why This Happens',
                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: v2.textPrimary),
              ),
            ],
          ),
          Gap.h8,
          Text(
            explanationText,
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w500, color: v2.textSecondary, height: 1.35),
          ),
        ],
      ),
    );
  }

  /// 4. Your Note Card
  Widget _buildNoteCard(BuildContext context) {
    final v2 = context.v2Theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? v2.card : Colors.white,
        borderRadius: BorderRadius.circular(18.w),
        border: Border.all(color: isDark ? v2.border : const Color(0xFFE2E8F0), width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24.w,
                height: 24.w,
                decoration: BoxDecoration(color: isDark ? v2.cardSubtle : const Color(0xFFF1F5F9), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(LucideIcons.stickyNote, size: 12.w, color: v2.textSecondary),
              ),
              Gap.w6,
              Text(
                'Your Note',
                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: v2.textSecondary),
              ),
            ],
          ),
          Gap.h6,
          Text(
            '"${occurrence.notes}"',
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.5.sp, fontStyle: FontStyle.italic, color: v2.textPrimary, height: 1.3),
          ),
        ],
      ),
    );
  }

  /// 5. Plan a Better Swap CTA
  Widget _buildBetterSwapCTA(BuildContext context) {
    final v2 = context.v2Theme;

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: v2.textPrimary,
        borderRadius: BorderRadius.circular(16.w),
        child: InkWell(
          onTap: () {
            final defaultSwap =
                swap ??
                FoodSwap(
                  id: 'swap_default',
                  source: SwapSource(foodId: 'food_trigger', name: occurrence.mealName),
                  alternatives: const [SwapAlternative(foodId: 'food_alt_01', name: 'Grilled or Roasted Alternative', reason: 'Lower in added oils and easier to digest.')],
                );
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => BetterSwapsScreen(swap: defaultSwap)));
          },
          borderRadius: BorderRadius.circular(16.w),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 14.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.repeat, size: 16.w, color: v2.card),
                Gap.w8,
                Text(
                  'Plan a Better Swap',
                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 13.sp, fontWeight: FontWeight.w800, color: v2.card),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
