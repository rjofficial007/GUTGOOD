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

                // 3. WHY THIS HAPPENS (PATTERN EXPLANATION)
                if (pattern != null) ...[_buildPatternExplanationCard(context), Gap.h10],

                // 4. YOUR NOTE CARD
                if (occurrence.notes != null && occurrence.notes!.isNotEmpty) ...[_buildNoteCard(context), Gap.h10],

                Gap.h6,
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// 1. Top Hero Meal Card (Solid Black card layout with dynamic food blending & domain accent)
  Widget _buildHeroCard(BuildContext context) {
    final style = pattern != null ? PatternCardStyle.forPattern(pattern!) : PatternCardStyle.forType('digestion');
    final imageUrl = V2Kit.foodImageUrl(occurrence.mealName, imageUrl: occurrence.imageUrl);
    final accentColor = style.accentColor;
    const cardBgColor = Color(0xFF0F1015);

    final dateStr = occurrence.dateLabel ?? occurrence.date;
    final timeStr = occurrence.mealTime ?? 'Logged meal';
    final subtitle = '$dateStr • $timeStr';

    final reactionText = occurrence.reaction.isNotEmpty ? occurrence.reaction : 'Observation logged';
    final timeAfterStr = occurrence.timeAfterLabel ?? occurrence.timeAfter;
    final metaText = timeAfterStr.isNotEmpty ? '$reactionText • Observed $timeAfterStr after eating' : reactionText;

    final rawTypeLabel = style.label;
    final severityLabel = (occurrence.symptomSeverity ?? 'Observed').toUpperCase();

    return Container(
      height: 160.w,
      decoration: BoxDecoration(color: cardBgColor, borderRadius: BorderRadius.circular(24.w)),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // 1. Left Content Section
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 14.w, 12.w, 14.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Texts
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Domain Category Tag Pill
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.w),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(100.w),
                          border: Border.all(color: accentColor.withValues(alpha: 0.40), width: 0.8.w),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(style.icon, size: 10.w, color: accentColor),
                            Gap.w4,
                            Text(
                              rawTypeLabel.toUpperCase(),
                              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w800, color: accentColor, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                      Gap.h6,

                      // Line 1: Bold Title
                      Text(
                        occurrence.mealName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 16.sp, fontWeight: FontWeight.w800, color: Colors.white, height: 1.15, letterSpacing: -0.3),
                      ),
                      Gap.h2,

                      // Line 2: Subtitle
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w600, color: accentColor, height: 1.2, letterSpacing: -0.1),
                      ),
                      Gap.h4,

                      // Line 3: Meta bullet points
                      Text(
                        metaText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w400, color: const Color(0xFF94A3B8), height: 1.25),
                      ),
                    ],
                  ),

                  // Bottom Badge Tag Row
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.w),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(100.w),
                      border: Border.all(color: accentColor.withValues(alpha: 0.40), width: 0.8.w),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5.w,
                          height: 5.w,
                          decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                        ),
                        Gap.w5,
                        Text(
                          '$severityLabel SEVERITY',
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.sp, fontWeight: FontWeight.w800, color: accentColor, letterSpacing: 0.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Right Side Image (Blended with black background)
          SizedBox(
            width: 130.w,
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
                        color: Colors.white.withValues(alpha: 0.05),
                        child: Center(
                          child: Icon(style.icon, color: accentColor.withValues(alpha: 0.5), size: 28.w),
                        ),
                      ),
                      errorWidget: (_, _, _) => Container(
                        color: Colors.white.withValues(alpha: 0.05),
                        child: Center(
                          child: Icon(style.icon, color: accentColor.withValues(alpha: 0.7), size: 28.w),
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
                        colors: [cardBgColor, cardBgColor.withValues(alpha: 0.2), cardBgColor.withValues(alpha: 0.0)],
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

  /// 3. Pattern Observation Card
  Widget _buildPatternExplanationCard(BuildContext context) {
    final v2 = context.v2Theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final explanationText = pattern!.description.isNotEmpty ? pattern!.description : 'Your logs show this association, but they do not establish why it happened.';

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
                'Pattern Observation',
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
}
