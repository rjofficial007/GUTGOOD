import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/models/pattern_occurrence.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/insight_ui_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/insights/presentation/widgets/analysis_card.dart';
import 'package:shimmer/shimmer.dart';

class PatternDetailScreen extends StatelessWidget {
  const PatternDetailScreen({super.key, required this.pattern});
  final BodyPattern pattern;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    return Scaffold(
      backgroundColor: scheme.cardBackground,
      body: CustomScrollView(
        slivers: [
          const GutSliverAppBar(title: '', showBrandingIcon: false),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p10),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                DashboardEntrance(delay: 50, child: _PatternHeroCard(pattern: pattern)),
                Gap.h20,
                DashboardEntrance(delay: 100, child: _ObservationsCard(pattern: pattern)),
                Gap.h20,
                if (pattern.occurrences.isNotEmpty) ...[
                  DashboardEntrance(
                    delay: 150,
                    child: _OccurrenceTimeline(occurrences: pattern.occurrences, patternType: pattern.type),
                  ),
                  Gap.h20,
                ],
                if (pattern.involvedFoods.isNotEmpty) ...[DashboardEntrance(delay: 175, child: _InvolvedFoodsCard(foods: pattern.involvedFoods)), Gap.h20],
                if (pattern.commonFactors.isNotEmpty) ...[DashboardEntrance(delay: 200, child: _CommonFactorsCard(factors: pattern.commonFactors)), Gap.h20],
                DashboardEntrance(delay: 250, child: _NextStepsCard(pattern: pattern)),
                Gap.h40,
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternHeroCard extends StatelessWidget {
  const _PatternHeroCard({required this.pattern});
  final BodyPattern pattern;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final icon = InsightUiUtils.getPatternTypeIcon(pattern.type);
    final patternName = InsightUiUtils.getPatternName(pattern.type);

    return ModernInsightCard(
      title: patternName.toUpperCase(),
      icon: icon,
      iconColor: scheme.textPrimary,
      backgroundColor: scheme.cardBackground,
      footer: Text(
        '${pattern.confidence.toUpperCase()} CONFIDENCE • ${pattern.frequency} OCCURRENCES',
        style: context.caption.copyWith(color: scheme.cardBackground, fontWeight: FontWeight.w900, fontSize: 10.sp, letterSpacing: 1.2),
      ),
      footerColor: scheme.textPrimary,
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Gap.h24,
            Text(
              pattern.trigger.toUpperCase(),
              style: context.displaySm.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1.5, height: 0.9),
              textAlign: TextAlign.center,
            ),
            Gap.h8,
            Text('linked to'.toUpperCase(), style: context.eyebrow),
            Gap.h8,
            Text(
              pattern.reaction.toUpperCase(),
              style: context.displaySm.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1.5, height: 0.9, color: scheme.textPrimary),
              textAlign: TextAlign.center,
            ),
            Gap.h32,
          ],
        ),
      ),
    );
  }
}

class _ObservationsCard extends StatelessWidget {
  const _ObservationsCard({required this.pattern});
  final BodyPattern pattern;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('OBSERVATIONS', style: context.eyebrow),
      Gap.h16,
      AnalysisCard(
        metric: pattern.frequency.toString(),
        label: 'DETECTED EVENTS',
        icon: AppIcons.brain,
        glowColor: context.appColorScheme.textPrimary,
        items: [
          AnalysisItem(title: 'DESCRIPTION', subtitle: pattern.description, icon: AppIcons.info),
          AnalysisItem(title: 'CONSISTENCY', subtitle: 'Found in ${pattern.frequency} out of ${pattern.totalSimilarMeals} meals containing ${pattern.trigger}.', icon: AppIcons.activity),
        ],
      ),
    ],
  );
}

class _OccurrenceTimeline extends StatelessWidget {
  const _OccurrenceTimeline({required this.occurrences, required this.patternType});
  final List<PatternOccurrence> occurrences;
  final String patternType;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RECENT TIMELINE', style: context.eyebrow),
        Gap.h20,
        ...List.generate(occurrences.length, (i) {
          final o = occurrences[i];
          final isLast = i == occurrences.length - 1;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Timeline Line & Dot
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Column(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(top: 26),
                        decoration: BoxDecoration(color: scheme.textPrimary, shape: BoxShape.circle),
                      ),
                      if (!isLast) Expanded(child: Container(width: 2, color: scheme.border.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
                Gap.w20,
                // 2. Content Card
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : AppSizes.p12),
                    child: _HistoryListTile(
                      title: o.mealName,
                      subtitle: '${o.date} • ${o.reaction} • ${o.timeAfter}',
                      imageUrl: o.imageUrl,
                      iconColor: scheme.textPrimary,
                      margin: EdgeInsets.zero,

                      onTap: () {},
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _HistoryListTile extends StatelessWidget {
  const _HistoryListTile({required this.title, required this.subtitle, this.imageUrl, required this.iconColor, this.trailing, required this.onTap, this.margin});

  final String title;
  final String subtitle;
  final String? imageUrl;
  final Color iconColor;
  final Widget? trailing;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin ?? EdgeInsets.only(bottom: AppSizes.p12),
        padding: EdgeInsets.all(AppSizes.p12),
        decoration: BoxDecoration(
          color: scheme.elevatedSurface,
          borderRadius: BorderRadius.circular(AppSizes.r20),
          border: Border.all(color: scheme.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: AppSizes.w52,
              height: AppSizes.w52,
              decoration: BoxDecoration(color: scheme.border.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(AppSizes.r12)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.r12),
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: context.appColorScheme.border.withValues(alpha: 0.2),
                          highlightColor: context.appColorScheme.border.withValues(alpha: 0.1),
                          child: Container(color: AppPalette.white),
                        ),
                        errorWidget: (_, _, _) => Icon(AppIcons.salad, size: AppSizes.icon24, color: context.appColorScheme.textMuted),
                      )
                    : Icon(AppIcons.salad, color: iconColor, size: AppSizes.icon24),
              ),
            ),
            Gap.w16,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.bodyBold.copyWith(fontSize: AppSizes.s15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Gap.h4,
                  Text(
                    subtitle,
                    style: context.caption.copyWith(color: scheme.textMuted, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[Gap.w12, trailing!],
          ],
        ),
      ),
    );
  }
}

class _InvolvedFoodsCard extends StatelessWidget {
  const _InvolvedFoodsCard({required this.foods});
  final List<String> foods;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('INVOLVED FOODS', style: context.eyebrow),
        Gap.h16,
        AnalysisCard(
          metric: foods.length.toString(),
          label: 'DETECTED INGREDIENTS',
          icon: AppIcons.utensils,
          glowColor: scheme.textPrimary,
          items: foods.map((f) => AnalysisItem(title: f.toUpperCase(), subtitle: 'Linked to this pattern', icon: AppIcons.package, color: scheme.textPrimary)).toList(),
        ),
      ],
    );
  }
}

class _CommonFactorsCard extends StatelessWidget {
  const _CommonFactorsCard({required this.factors});
  final List<CommonFactor> factors;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('COMMON FACTORS', style: context.eyebrow),
      Gap.h16,
      AnalysisCard(
        metric: factors.length.toString(),
        label: 'IMPACTING ELEMENTS',
        icon: AppIcons.database,
        glowColor: context.appColorScheme.textPrimary,
        items: factors.map((f) => AnalysisItem(title: f.label.toUpperCase(), subtitle: 'Potential contributing factor', icon: InsightUiUtils.getReactionIcon(f.icon))).toList(),
      ),
    ],
  );
}

class _NextStepsCard extends StatelessWidget {
  const _NextStepsCard({required this.pattern});
  final BodyPattern pattern;

  @override
  Widget build(BuildContext context) {
    final recommendation = pattern.recommendation ?? 'Keep logging to verify this pattern.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('WHAT TO DO NEXT', style: context.eyebrow),
        Gap.h16,
        AnalysisCard(
          metric: 'NEXT',
          label: 'ACTION PLAN',
          icon: AppIcons.lightbulb,
          glowColor: context.appColorScheme.textPrimary,
          items: [
            AnalysisItem(title: 'RECOMMENDATION', subtitle: recommendation, icon: AppIcons.checkCircle, isDone: true, color: context.appColorScheme.textPrimary),
            AnalysisItem(title: 'VERIFICATION', subtitle: 'Log your next 3 meals containing ${pattern.trigger} to confirm.', icon: AppIcons.target, color: context.appColorScheme.textPrimary),
          ],
        ),
      ],
    );
  }
}
