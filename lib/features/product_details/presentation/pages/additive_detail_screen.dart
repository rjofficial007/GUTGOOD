import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/data/additive_concern_db.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/bento_widgets.dart';
import 'package:gutgood/features/product_details/presentation/pages/additive_level_colors.dart';
import 'package:gutgood/features/product_details/presentation/utils/scan_result_utils.dart';

/// Additive detail screen redesigned to match brand style: header, 2x2 grid,
/// tip, and related list, all within responsive containers.
class AdditiveDetailScreen extends StatelessWidget {
  const AdditiveDetailScreen({super.key, required this.concern});

  final AdditiveConcern concern;

  static BentoTone toneFor(AdditiveConcernLevel level) => switch (level) {
    AdditiveConcernLevel.higher => BentoTone.coral,
    AdditiveConcernLevel.moderate => BentoTone.amber,
    AdditiveConcernLevel.low => BentoTone.mint,
    AdditiveConcernLevel.unknown => BentoTone.white,
  };

  static String _take(AdditiveConcern c) => c.whyFlagged.isNotEmpty ? c.whyFlagged : AppStrings.noConcernsTypicalAmounts;

  static String _carefulFor(AdditiveConcern c) {
    if (c.carefulFor.isNotEmpty) return c.carefulFor;
    return switch (c.level) {
      AdditiveConcernLevel.higher => AppStrings.carefulHighFallback,
      AdditiveConcernLevel.moderate => AppStrings.carefulModerateFallback,
      AdditiveConcernLevel.low => AppStrings.carefulLowFallback,
      AdditiveConcernLevel.unknown => AppStrings.carefulUnknownFallback,
    };
  }

  static String _tip(AdditiveConcern c) {
    if (c.tip.isNotEmpty) return c.tip;
    return switch (c.level) {
      AdditiveConcernLevel.higher => AppStrings.tipHighFallback,
      AdditiveConcernLevel.moderate => AppStrings.tipModerateFallback,
      AdditiveConcernLevel.low => AppStrings.tipLowFallback,
      AdditiveConcernLevel.unknown => AppStrings.tipUnknownFallback,
    };
  }

  static String _impactBody(AdditiveConcernLevel level) => switch (level) {
    AdditiveConcernLevel.higher => AppStrings.impactHighBody,
    AdditiveConcernLevel.moderate => AppStrings.impactModerateBody,
    AdditiveConcernLevel.low => AppStrings.impactLowBody,
    AdditiveConcernLevel.unknown => AppStrings.impactUnknownBody,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final related = AdditiveConcernDb.relatedTo(concern);
    final relatedAll = AdditiveConcernDb.relatedTo(concern, limit: 100);
    final description = '${concern.whatItIs} ${concern.whyUsed}';
    final tone = toneFor(concern.level);
    final palette = context.bentoTheme.bento(tone);

    return Scaffold(
      backgroundColor: scheme.cardBackground,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const GutSliverAppBar(),
            SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = constraints.maxWidth < 400 ? AppSizes.p12 : AppSizes.p16;

                  return Padding(
                    padding: EdgeInsets.fromLTRB(horizontalPadding, AppSizes.p8, horizontalPadding, AppSizes.p20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DashboardEntrance(delay: 40, child: _buildMainCard(context, palette, description, constraints.maxWidth)),
                        Gap.h12,
                        DashboardEntrance(delay: 240, child: _buildTipCard(context, constraints.maxWidth)),
                        if (related.isNotEmpty) ...[Gap.h24, DashboardEntrance(delay: 300, child: _buildRelatedSection(context, related, relatedAll, constraints.maxWidth))],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard(BuildContext context, BentoPalette palette, String description, double width) {
    final scheme = context.appColorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(BentoMetrics.padding.w),
      decoration: BoxDecoration(gradient: palette.gradient, borderRadius: BorderRadius.circular(BentoMetrics.heroRadius.w)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _iconCircle(icon: AdditiveLevelColors.iconFor(concern.level), iconColor: palette.tagForeground, background: palette.tagBackground, size: 38.w),
              Gap.w12,
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        concern.name,
                        style: TextStyle(color: scheme.textPrimary, fontFamily: InsightBentoTheme.fontFamily, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.4, height: 1.1),
                      ),
                      Row(
                        children: [
                          _BentoRiskPill(label: concern.riskLabel, palette: palette),
                          if (concern.category.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Text(
                                concern.category,
                                style: TextStyle(color: scheme.textSecondary, fontFamily: InsightBentoTheme.fontFamily, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Description
          Text(
            description,
            style: TextStyle(color: scheme.textPrimary.withValues(alpha: 0.8), fontFamily: InsightBentoTheme.fontFamily, fontSize: width < 380 ? 13 : 13.5, height: 1.35, fontWeight: FontWeight.w400),
          ),
          Gap.h10,
          // Grid
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: _insightCard(context, title: AppStrings.whyItsUsed, text: concern.whyUsed, icon: AppIcons.leaf, tone: BentoTone.mint),
                      ),
                      Gap.h8,
                      Expanded(
                        child: _insightCard(context, title: AppStrings.whoToBeCareful, text: _carefulFor(concern), icon: AppIcons.user, tone: BentoTone.coral),
                      ),
                    ],
                  ),
                ),
                Gap.w8,
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: _insightCard(context, title: AppStrings.gutGoodTake, text: _take(concern), icon: AppIcons.alertCircle, tone: BentoTone.amber),
                      ),
                      Gap.h8,
                      Expanded(child: _scoreCard(context)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _insightCard(BuildContext context, {required String title, required String text, required IconData icon, required BentoTone tone}) {
    final scheme = context.appColorScheme;
    final palette = context.bentoTheme.bento(tone);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(BentoMetrics.padding.w),
      decoration: BoxDecoration(gradient: palette.gradient, borderRadius: BorderRadius.circular(BentoMetrics.radius.w)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: palette.tagForeground, size: 18.w),
          Gap.h10,
          Text(
            title,
            style: TextStyle(color: scheme.textPrimary, fontFamily: InsightBentoTheme.fontFamily, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: -0.3, height: 1.1),
          ),
          Gap.h6,
          Text(
            text,
            style: TextStyle(color: scheme.textSecondary, fontFamily: InsightBentoTheme.fontFamily, fontSize: 12, height: 1.3, fontWeight: FontWeight.w400),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _scoreCard(BuildContext context) {
    final scheme = context.appColorScheme;
    final palette = context.bentoTheme.bento(BentoTone.white);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(BentoMetrics.padding.w),
      decoration: BoxDecoration(gradient: palette.gradient, borderRadius: BorderRadius.circular(BentoMetrics.radius.w)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(AppIcons.barChart, color: palette.tagForeground, size: 18.w),
              const Spacer(),
              _BentoRiskPill(label: AppStrings.scorePointsShort(concern.scoreImpactPts), palette: context.bentoTheme.bento(toneFor(concern.level))),
            ],
          ),
          Gap.h10,
          Text(
            AppStrings.impactOnYourScore,
            style: TextStyle(color: scheme.textPrimary, fontFamily: InsightBentoTheme.fontFamily, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: -0.3, height: 1.1),
          ),
          Gap.h6,
          Text(
            _impactBody(concern.level),
            style: TextStyle(color: scheme.textSecondary, fontFamily: InsightBentoTheme.fontFamily, fontSize: 12, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(BuildContext context, double width) {
    final t = context.bentoTheme;
    return InkWell(
      onTap: () => context.push(AppRoutes.chat),
      borderRadius: BorderRadius.circular(BentoMetrics.radius.w),
      child: Container(
        padding: EdgeInsets.all(BentoMetrics.padding.w),
        decoration: BoxDecoration(
          color: t.mint.withAlpha(16),
          borderRadius: BorderRadius.circular(BentoMetrics.radius.w),
          // border: Border.all(color: t.mint.withAlpha(40)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(color: t.mint.withAlpha(26), shape: BoxShape.circle),
              child: Icon(AppIcons.lightbulb, size: 18.w, color: t.mint),
            ),
            Gap.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.tipTitle,
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 15.sp, fontWeight: FontWeight.w700, color: t.mint),
                  ),
                  Gap.h2,
                  Text(
                    _tip(concern),
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w400, color: t.textTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedSection(BuildContext context, List<AdditiveConcern> related, List<AdditiveConcern> relatedAll, double width) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                AppStrings.relatedAdditives.toUpperCase(),
                style: TextStyle(color: context.bentoTheme.textTertiary, fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w700, letterSpacing: 1.2),
              ),
            ),
            if (relatedAll.length > related.length)
              InkWell(
                onTap: () => context.push(
                  AppRoutes.additivesList,
                  extra: AdditiveListArgs(items: relatedAll, title: AppStrings.relatedAdditives),
                ),
                child: Row(
                  children: [
                    Text(
                      AppStrings.seeAll,
                      style: TextStyle(color: context.bentoTheme.positive, fontSize: 13.sp, fontWeight: FontWeight.w700, fontFamily: InsightBentoTheme.fontFamily),
                    ),
                    Gap.w2,
                    Icon(Icons.chevron_right_rounded, color: context.bentoTheme.positive, size: 18.w),
                  ],
                ),
              ),
          ],
        ),
      ),
      Gap.h12,
      Column(children: List.generate(related.length, (index) => _relatedAdditiveRow(context, related[index], width: width))),
    ],
  );

  Widget _relatedAdditiveRow(BuildContext context, AdditiveConcern additive, {required double width}) {
    final t = context.bentoTheme;
    final levelColors = AdditiveLevelColors.of(context, additive.level);
    final dotColor = additiveConcernColor(context, additive.level);

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(AppRoutes.additiveDetail, extra: additive),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(color: levelColors.background, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(color: levelColors.iconBackground, shape: BoxShape.circle),
                  child: Icon(AdditiveLevelColors.iconFor(additive.level), size: 18.sp, color: levelColors.accent),
                ),
                Gap.w12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        additive.displayTitle,
                        maxLines: 1,
                        style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.titleSize.sp, fontWeight: FontWeight.w600, color: t.textPrimary),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        additive.whyFlagged.isNotEmpty ? additive.whyFlagged : additive.whatItIs,
                        style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.footSize.sp, fontWeight: FontWeight.w400, color: t.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Gap.w8,
                Container(
                  width: 8.sp,
                  height: 8.sp,
                  decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
                Gap.w8,
                Icon(AppIcons.chevronRight, size: 16.sp, color: levelColors.accent.withAlpha(150)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconCircle({required IconData icon, required Color iconColor, required Color background, required double size}) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: background, shape: BoxShape.circle),
    alignment: Alignment.center,
    child: Icon(icon, color: iconColor, size: size * 0.52),
  );
}

class _BentoRiskPill extends StatelessWidget {
  const _BentoRiskPill({required this.label, required this.palette});
  final String label;
  final BentoPalette palette;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: palette.tagForeground, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(
        label.toUpperCase(),
        style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 10, fontWeight: FontWeight.w800, color: palette.tagForeground),
      ),
    ],
  );
}
