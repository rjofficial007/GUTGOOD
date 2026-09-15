import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/data/additive_concern_db.dart';
import 'package:gutgood/core/models/navigation/route_arguments.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/bento_widgets.dart';
import 'package:gutgood/features/product_details/presentation/pages/additive_level_colors.dart';

/// Full additives list screen redesigned for compactness and brand style.
class AdditivesListScreen extends StatelessWidget {
  const AdditivesListScreen({super.key, required this.args});

  final AdditiveListArgs args;

  static int _rank(AdditiveConcernLevel level) => switch (level) {
    AdditiveConcernLevel.higher => 3,
    AdditiveConcernLevel.moderate => 2,
    AdditiveConcernLevel.low => 1,
    AdditiveConcernLevel.unknown => 0,
  };

  static BentoTone toneFor(AdditiveConcernLevel level) => switch (level) {
    AdditiveConcernLevel.higher => BentoTone.coral,
    AdditiveConcernLevel.moderate => BentoTone.amber,
    AdditiveConcernLevel.low => BentoTone.mint,
    AdditiveConcernLevel.unknown => BentoTone.white,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final sorted = [...args.items]..sort((a, b) => _rank(b.level).compareTo(_rank(a.level)));
    return Scaffold(
      backgroundColor: scheme.cardBackground,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const GutSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.w, 16.w, 32.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ListHeader(title: args.title, subtitle: args.subtitle, count: sorted.length),
                    Gap.h16,
                    if (sorted.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.w),
                        child: Center(
                          child: Text(
                            AppStrings.noAdditivesFound,
                            style: TextStyle(color: scheme.textSecondary, fontFamily: InsightBentoTheme.fontFamily, fontSize: 13, fontWeight: FontWeight.w400),
                          ),
                        ),
                      )
                    else
                      for (var i = 0; i < sorted.length; i++)
                        Padding(
                          padding: EdgeInsets.only(bottom: BentoMetrics.gridGap.w),
                          child: DashboardEntrance(
                            delay: 60 + i * 40,
                            child: _AdditiveCard(concern: sorted[i]),
                          ),
                        ),
                    Gap.h12,
                    const DashboardEntrance(delay: 320, child: _WhyItMattersCard()),
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

class _ListHeader extends StatelessWidget {
  const _ListHeader({required this.title, required this.subtitle, required this.count});

  final String title;
  final String subtitle;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final palette = context.bentoTheme.bento(BentoTone.white);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: scheme.textPrimary, fontFamily: InsightBentoTheme.fontFamily, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -1.0, height: 1.1),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(color: scheme.textSecondary, fontFamily: InsightBentoTheme.fontFamily, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 82.w,
          padding: EdgeInsets.symmetric(vertical: 10.w),
          decoration: BoxDecoration(gradient: palette.gradient, borderRadius: BorderRadius.circular(BentoMetrics.radiusSm.w)),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(color: scheme.textPrimary, fontFamily: InsightBentoTheme.fontFamily, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
              Text(
                'TOTAL\nADDITIVES',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.textSecondary, fontFamily: InsightBentoTheme.fontFamily, fontSize: 8, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: 1.0),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdditiveCard extends StatelessWidget {
  const _AdditiveCard({required this.concern});

  final AdditiveConcern concern;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final tone = AdditivesListScreen.toneFor(concern.level);
    final palette = context.bentoTheme.bento(tone);
    final title = concern.code.isEmpty ? concern.name : '${concern.name} (${concern.code})';
    final description = concern.whyFlagged.isNotEmpty ? '${concern.whyUsed} ${concern.whyFlagged}.' : concern.whyUsed;

    return InkWell(
      borderRadius: BorderRadius.circular(BentoMetrics.radius.w),
      onTap: () => context.push(AppRoutes.additiveDetail, extra: concern),
      child: Container(
        padding: EdgeInsets.all(BentoMetrics.padding.w),
        decoration: BoxDecoration(gradient: palette.gradient, borderRadius: BorderRadius.circular(BentoMetrics.radius.w)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(color: palette.tagBackground, shape: BoxShape.circle),
              child: Icon(AdditiveLevelColors.iconFor(concern.level), size: 22.w, color: palette.tagForeground),
            ),
            Gap.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: scheme.textPrimary, fontFamily: InsightBentoTheme.fontFamily, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: -0.4),
                  ),
                  Row(
                    children: [
                      _ListRiskBadge(label: concern.concernLabel, color: palette.tagForeground, background: palette.tagBackground),
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
                  Gap.h6,
                  Text(
                    description,
                    style: TextStyle(color: scheme.textSecondary, fontFamily: InsightBentoTheme.fontFamily, fontSize: 12, height: 1.3, fontWeight: FontWeight.w400),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Gap.w6,
            Padding(
              padding: EdgeInsets.only(top: 2.w),
              child: Icon(AppIcons.chevronRight, size: 20.w, color: palette.tagForeground),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListRiskBadge extends StatelessWidget {
  const _ListRiskBadge({required this.label, required this.color, required this.background});
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(
        label.toUpperCase(),
        style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 10, fontWeight: FontWeight.w800, color: color),
      ),
    ],
  );
}

class _WhyItMattersCard extends StatelessWidget {
  const _WhyItMattersCard();

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final palette = context.bentoTheme.bento(BentoTone.mint);
    return Container(
      padding: EdgeInsets.all(BentoMetrics.padding.w),
      decoration: BoxDecoration(gradient: palette.gradient, borderRadius: BorderRadius.circular(BentoMetrics.radius.w)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(color: palette.tagBackground, shape: BoxShape.circle),
            child: Icon(AppIcons.brain, size: 22.w, color: palette.tagForeground),
          ),
          Gap.h12,
          Text(
            AppStrings.whyDoesThisMatter,
            style: TextStyle(color: scheme.textPrimary, fontFamily: InsightBentoTheme.fontFamily, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3),
          ),
          Gap.h6,
          Text(
            AppStrings.whyAdditivesMatterBody,
            style: TextStyle(color: scheme.textSecondary, fontFamily: InsightBentoTheme.fontFamily, fontSize: 13, height: 1.35, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}
